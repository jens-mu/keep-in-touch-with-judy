-- init.lua
local GameSession = require('GameSession')
local GameUI = require('GameUI')

local KIT = {
    settings = require('settings'),
    messages = require('messages'),
    sms_storage = require('sms_storage'),
    runtime = {
        gameReady = false,
        menuRegistered = false,
        messageTimer = 0,
        timer = 0,
        nextWaitTime = 0,
        isRomanced = false,
        paused = false,
        journalNotificationQueue = nil,
    },
}

function KIT.Log(message)
    print('[KIT] ' .. tostring(message))
end

-- QUEST CHECK: Is Judy ready for small talk?
function KIT.IsJudyReady()
    local questSystem = Game.GetQuestsSystem()
    if not questSystem then
        KIT.Log('Quest system unavailable. Judy is not ready.')
        return false
    end

    -- q105 is the quest "Disasterpiece" (Evelyn rescue)
    local evelynRescued = questSystem:GetFactStr('q105_done')
    KIT.Log('Quest check q105_done = ' .. tostring(evelynRescued))

    local ready = (evelynRescued and evelynRescued >= 1)
    KIT.Log('Judy ready status = ' .. tostring(ready))
    return ready
end

function KIT.UpdateRelationshipStatus()
    local questSystem = Game.GetQuestsSystem()
    if questSystem then
        local romanceFact = questSystem:GetFactStr('judy_romance_active')
        KIT.runtime.isRomanced = (romanceFact == 1)
        KIT.Log(
            'Relationship Check: romanceFact='
                .. tostring(romanceFact)
                .. ' -> isRomanced='
                .. tostring(KIT.runtime.isRomanced)
        )
    else
        KIT.Log('Relationship Check: quest system unavailable.')
    end
end

function KIT.SendMessage()
    KIT.Log('--- SendMessage Sequence Started ---')
    KIT.Log('state: enabled=' .. tostring(KIT.settings.enabled) .. ', gameReady=' .. tostring(KIT.runtime.gameReady))

    if not KIT.IsJudyReady() then
        KIT.Log('Aborted: Evelyn not yet rescued.')
        return
    end

    KIT.UpdateRelationshipStatus()

    local usedIds = KIT.sms_storage.usedIds
    KIT.Log('Fetching random message. Used IDs count: ' .. tostring(#usedIds))
    local messageData, shouldReset = KIT.messages.GetRandomMessage(KIT.runtime.isRomanced, usedIds)

    if shouldReset then
        KIT.Log('Resetting message history.')
        KIT.sms_storage.Clear()
        usedIds = {}
        messageData = KIT.messages.GetRandomMessage(KIT.runtime.isRomanced, usedIds)
    end

    if not messageData then
        KIT.Log('No message data available after selection.')
        return
    end

    KIT.Log(
        'Selected message: ' .. tostring(messageData.id) .. ' (romance: ' .. tostring(KIT.runtime.isRomanced) .. ')'
    )

    local journalManager = Game.GetJournalManager()

    -- Activate the journal entry chain: Contact → Conversation → Message
    -- The archive (loaded by ArchiveXL) provides the actual entries.
    -- ChangeEntryState returns "OK" even for missing entries, so we log diagnostic info.
    local function journalSet(id, typeName)
        local ok, err = pcall(function()
            journalManager:ChangeEntryState(id, typeName, gameJournalEntryState.Active, gameJournalNotifyOption.Notify)
        end)
        if ok then
            KIT.Log('Journal OK: ' .. id .. ' (' .. typeName .. ')')
        else
            KIT.Log('Journal FAIL: ' .. id .. ' (' .. typeName .. ') -> ' .. tostring(err))
        end
    end

    -- ChangeEntryState uses entry IDs (not paths)
    journalSet('judy_kit', 'gameJournalContact')
    journalSet('judy_kit_conversation', 'gameJournalPhoneConversation')
    journalSet(messageData.id, 'gameJournalPhoneMessage')

    -- Sanity checks: GetEntryByString also uses entry IDs
    local function tryLookup(id, t)
        local result = nil
        pcall(function()
            result = journalManager:GetEntryByString(id, t)
        end)
        KIT.Log('Lookup [' .. id .. '|' .. t .. ']: ' .. (result ~= nil and 'FOUND' or 'NIL'))
        return result
    end
    tryLookup('judy', 'gameJournalContact')
    tryLookup('judy_kit', 'gameJournalContact')
    tryLookup('judy_kit_conversation', 'gameJournalPhoneConversation')
    tryLookup('judy_kit_init', 'gameJournalPhoneMessage')

    local verifyMsg = tryLookup(messageData.id, 'gameJournalPhoneMessage')

    -- HUD Popup
    if KIT.runtime.journalNotificationQueue then
        KIT.Log('Creating HUD popup notification.')

        local openAction = nil
        pcall(function()
            local action = OpenJournalAction.new()
            if verifyMsg then
                action.journalEntry = verifyMsg
                KIT.Log('Journal entry linked to open action.')
            end
            openAction = action
        end)
        if not openAction then
            KIT.Log('Warning: OpenJournalAction unavailable. Popup will show without journal link.')
        end

        local ok, err = pcall(function()
            local userData = PhoneMessageNotificationViewData.new()
            userData.title = 'Judy Alvarez'
            userData.SMSText = messageData.text
            if openAction then
                userData.action = openAction
            end
            userData.animation = CName.new('notification_phone_MSG')
            userData.soundEvent = CName.new('PhoneSmsPopup')
            userData.soundAction = CName.new('OnOpen')

            local notificationData = gameuiGenericNotificationData.new()
            notificationData.time = 7.0
            notificationData.widgetLibraryItemName = CName.new('notification_message')
            notificationData.notificationData = userData

            KIT.runtime.journalNotificationQueue:AddNewNotificationData(notificationData)
            KIT.Log('HUD notification enqueued successfully.')
        end)
        if not ok then
            KIT.Log('Popup Error: ' .. tostring(err))
        end
    else
        KIT.Log('Warning: HUD Queue not ready. Skipping popup.')
    end

    KIT.sms_storage.SaveUsedId(messageData.id)
    KIT.Log('--- SendMessage Finished: ' .. messageData.id .. ' ---')
end

registerForEvent('onInit', function()
    KIT.Log('onInit Start -------------------------------------------')

    -- HUD Queue Observer
    KIT.Log('Setting up HUD Queue Observer.')
    Observe('gameuiGenericNotificationGameController', 'OnMenuUpdate', function(self)
        if not KIT.runtime.journalNotificationQueue then
            KIT.runtime.journalNotificationQueue = self
            KIT.Log('HUD Queue Observer linked.')
        end
    end)

    -- Initialize modules
    KIT.Log('Initializing modules.')
    local ok, err = pcall(KIT.sms_storage.Init)
    if not ok then
        KIT.Log('ERROR in sms_storage.Init: ' .. tostring(err))
    end
    -- settings.Register() deferred to onUpdate (nativeSettings may not be ready at onInit)
    KIT.runtime.nextWaitTime = KIT.settings.GetNextWaitTime()
    KIT.Log('Initial next wait time: ' .. tostring(KIT.runtime.nextWaitTime) .. ' seconds.')

    -- Game Session Hooks
    KIT.Log('Setting up Game Session Hooks.')
    GameSession.OnStart(function()
        KIT.Log('Session Start - game ready.')
        KIT.runtime.gameReady = true
        KIT.runtime.messageTimer = 0
        KIT.UpdateRelationshipStatus()
        KIT.Log('isRomanced: ' .. tostring(KIT.runtime.isRomanced))
    end)

    GameSession.OnEnd(function()
        KIT.runtime.gameReady = false
        KIT.Log('GameSession ended. gameReady=false')
    end)

    KIT.Log('onInit Complete -------------------------------------------')
end)

registerForEvent('onUpdate', function(deltaTime)
    -- Deferred settings registration
    if not KIT.runtime.menuRegistered then
        KIT.runtime.timer = KIT.runtime.timer + deltaTime
        if KIT.runtime.timer > 2.0 then
            KIT.runtime.timer = 0
            if GetMod('nativeSettings') then
                KIT.settings.Register()
                KIT.runtime.menuRegistered = true
                KIT.Log('Native settings registered.')
            else
                KIT.Log('Waiting for nativeSettings...')
            end
        end
    end

    -- Message timer loop
    if KIT.settings.enabled and KIT.runtime.gameReady and not KIT.runtime.paused then
        KIT.runtime.messageTimer = KIT.runtime.messageTimer + deltaTime

        if KIT.runtime.messageTimer >= KIT.runtime.nextWaitTime then
            KIT.runtime.messageTimer = 0
            KIT.runtime.nextWaitTime = KIT.settings.GetNextWaitTime()
            KIT.Log('Timer expired. Next wait: ' .. tostring(KIT.runtime.nextWaitTime) .. 's')
            KIT.SendMessage()
        end
    end
end)

return KIT
