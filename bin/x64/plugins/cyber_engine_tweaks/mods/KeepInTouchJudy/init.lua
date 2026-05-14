-- init.lua
local GameSession = require('GameSession')
local GameUI = require('GameUI')

local KIT = {
    settings = require('settings'),
    messages = require('messages'),
    sms_storage = require('sms_storage'),
    runtime = {
        gameReady = false,
        currentSlotIndex = 1,
        menuRegistered = false,
        maxSlots = 40,
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
    -- If this fact is >= 1, the quest is complete.
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
    KIT.Log('DEBUG: --- SendMessage Sequence Started ---')
    KIT.Log(
        'SendMessage state: enabled='
            .. tostring(KIT.settings.enabled)
            .. ', gameReady='
            .. tostring(KIT.runtime.gameReady)
            .. ', paused='
            .. tostring(KIT.runtime.paused)
    )

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
        'Selected message ID: ' .. tostring(messageData.id) .. ' (romance: ' .. tostring(KIT.runtime.isRomanced) .. ')'
    )

    local journalManager = Game.GetJournalManager()
    local slotIndex = KIT.runtime.currentSlotIndex or 1
    local msgPath = 'KeepInTouch.MsgSlot_' .. string.format('%02d', slotIndex)
    KIT.Log('Using slot index: ' .. tostring(slotIndex) .. ', path: ' .. msgPath)

    -- 1. TweakDB Update (write content to the slot)
    KIT.Log('Step 1: Updating TweakDB with message text.')
    TweakDB:SetFlat(msgPath .. '.text', messageData.text)
    TweakDB:Update(msgPath)
    KIT.Log('TweakDB updated for ' .. msgPath)

    -- 2. Journal Sync (The 'wake-up' sequence for the messenger)
    -- We activate the chain from top to bottom
    KIT.Log('Step 2: Syncing journal entries to activate messenger.')
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

    journalSet('Characters.judy_alvarez', 'gameJournalContact')
    journalSet('KeepInTouch.JudyConversation', 'gameJournalPhoneConversation')
    journalSet(msgPath, 'gameJournalPhoneMessage')

    -- Verify TweakXL actually registered the entries (ChangeEntryState silently does nothing on missing entries)
    ---@diagnostic disable-next-line: missing-parameter
    local convEntry = journalManager:GetEntryByString('KeepInTouch.JudyConversation')
    ---@diagnostic disable-next-line: missing-parameter
    local msgEntry = journalManager:GetEntryByString(msgPath)
    KIT.Log('TweakXL check - JudyConversation: ' .. (convEntry and 'FOUND' or 'NOT FOUND - TweakXL may have failed'))
    KIT.Log('TweakXL check - ' .. msgPath .. ': ' .. (msgEntry and 'FOUND' or 'NOT FOUND - TweakXL may have failed'))
    KIT.Log('Journal sync complete.')

    -- 3. HUD Popup
    if KIT.runtime.journalNotificationQueue then
        KIT.Log('Step 3: Creating HUD popup notification.')

        -- Optional: try to link journal entry for tap-to-open. Fails gracefully if class unavailable.
        local openAction = nil
        pcall(function()
            local action = OpenJournalAction.new()
            local entry = journalManager:GetEntryByString(msgPath)
            if entry then
                action.journalEntry = entry
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

    -- 4. Save progress
    KIT.Log('Step 4: Saving message as used and updating slot index.')
    KIT.sms_storage.SaveUsedId(messageData.id)
    KIT.runtime.currentSlotIndex = (slotIndex % 40) + 1
    KIT.Log('Next slot index: ' .. tostring(KIT.runtime.currentSlotIndex))

    KIT.Log('--- SendMessage Sequence Finished: ' .. messageData.id .. ' ---')
end

registerForEvent('onInit', function()
    KIT.Log('DEBUG: onInit Start -------------------------------------------')

    -- 1. Initialize TweakDB Slots (IMPORTANT!)
    -- This ensures the engine knows the IDs before we use them
    KIT.Log('Step 1: Initializing 40 TweakDB slots.')
    for i = 1, 40 do
        local slotID = string.format('KeepInTouch.MsgSlot_%02d', i)
        -- We set an empty string so the slot technically exists
        TweakDB:SetFlat(slotID .. '.text', '')
        TweakDB:Update(slotID)
        if i % 10 == 0 then
            KIT.Log('Initialized slots up to ' .. tostring(i))
        end
    end
    KIT.Log('DEBUG: 40 TweakDB Slots registered.')

    -- 2. Popup Observer (so the HUD event arrives)
    KIT.Log('Step 2: Setting up HUD Queue Observer.')
    Observe('JournalNotificationQueue', 'OnMenuUpdate', function(self)
        if not KIT.runtime.journalNotificationQueue then
            KIT.runtime.journalNotificationQueue = self
            KIT.Log('DEBUG: HUD Queue Observer linked.')
        end
    end)

    -- 3. Initialize modules
    KIT.Log('Step 3: Initializing modules.')
    local ok, err = pcall(KIT.sms_storage.Init)
    if not ok then
        KIT.Log('ERROR in sms_storage.Init: ' .. tostring(err))
    end
    -- settings.Register() is intentionally deferred to onUpdate (nativeSettings may not be ready at onInit)
    KIT.runtime.nextWaitTime = KIT.settings.GetNextWaitTime()
    KIT.Log('Initial next wait time set to ' .. tostring(KIT.runtime.nextWaitTime) .. ' seconds.')

    -- 4. Game Session Hooks
    KIT.Log('Step 4: Setting up Game Session Hooks.')
    GameSession.OnStart(function()
        KIT.Log('DEBUG: Session Start - Setting up Judy...')
        KIT.runtime.gameReady = true
        KIT.runtime.messageTimer = 0
        KIT.UpdateRelationshipStatus()
        KIT.Log('Game session ready. isRomanced: ' .. tostring(KIT.runtime.isRomanced))
    end)

    GameSession.OnEnd(function()
        KIT.runtime.gameReady = false
        KIT.Log('GameSession ended. gameReady=false')
    end)

    KIT.Log('DEBUG: onInit Complete -------------------------------------------')
end)

registerForEvent('onUpdate', function(deltaTime)
    -- Settings registration delay
    if not KIT.runtime.menuRegistered then
        KIT.runtime.timer = KIT.runtime.timer + deltaTime
        if KIT.runtime.timer > 2.0 then
            KIT.runtime.timer = 0
            if GetMod('nativeSettings') then
                KIT.settings.Register()
                KIT.runtime.menuRegistered = true
                KIT.Log('Native settings registered successfully.')
            else
                KIT.Log('Waiting for nativeSettings mod to become available.')
            end
        end
    end

    -- Message timer loop
    if KIT.settings.enabled and KIT.runtime.gameReady and not KIT.runtime.paused then
        KIT.runtime.messageTimer = KIT.runtime.messageTimer + deltaTime

        if KIT.runtime.messageTimer >= KIT.runtime.nextWaitTime then
            KIT.runtime.messageTimer = 0
            KIT.runtime.nextWaitTime = KIT.settings.GetNextWaitTime()
            KIT.Log('Message timer expired. Next wait time = ' .. tostring(KIT.runtime.nextWaitTime) .. ' seconds.')
            KIT.SendMessage()
        end
    else
        -- Optional: Log why not sending messages, but only occasionally to avoid spam
        if math.floor(KIT.runtime.messageTimer) % 60 == 0 and KIT.runtime.messageTimer > 0 then
            KIT.Log(
                'Message sending paused. enabled='
                    .. tostring(KIT.settings.enabled)
                    .. ', gameReady='
                    .. tostring(KIT.runtime.gameReady)
                    .. ', paused='
                    .. tostring(KIT.runtime.paused)
            )
        end
    end
end)

return KIT
