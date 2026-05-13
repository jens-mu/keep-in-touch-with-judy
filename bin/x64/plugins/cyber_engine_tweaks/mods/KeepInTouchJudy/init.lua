-- init.lua
local GameSession = require("GameSession")
local GameUI = require("GameUI")

local KIT = {
    settings = require("settings"),
    messages = require("messages"),
    sms_storage = require("sms_storage"),
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
        journalNotificationQueue = nil
    }
}

function KIT.Log(message)
    print("[KIT] " .. tostring(message))
end

-- QUEST CHECK: Is Judy ready for small talk?
function KIT.IsJudyReady()
    local questSystem = Game.GetQuestsSystem()
    if not questSystem then
        KIT.Log("Quest system unavailable. Judy is not ready.")
        return false
    end

    -- q105 is the quest "Disasterpiece" (Evelyn rescue)
    -- If this fact is >= 1, the quest is complete.
    local evelynRescued = questSystem:GetFactStr("q105_done")
    KIT.Log("Quest check q105_done = " .. tostring(evelynRescued))
    
    local ready = (evelynRescued and evelynRescued >= 1)
    KIT.Log("Judy ready status = " .. tostring(ready))
    return ready
end

function KIT.UpdateRelationshipStatus()
    local questSystem = Game.GetQuestsSystem()
    if questSystem then
        local romanceFact = questSystem:GetFactStr("judy_romance_active")
        KIT.runtime.isRomanced = (romanceFact == 1)
        KIT.Log("Relationship Check: romanceFact=" .. tostring(romanceFact) .. " -> isRomanced=" .. tostring(KIT.runtime.isRomanced))
    else
        KIT.Log("Relationship Check: quest system unavailable.")
    end
end

function KIT.SendMessage()
    KIT.Log("--- SendMessage Sequence Started ---")
    KIT.Log("SendMessage state: enabled=" .. tostring(KIT.settings.enabled) .. ", gameReady=" .. tostring(KIT.runtime.gameReady) .. ", paused=" .. tostring(KIT.runtime.paused))

    -- 1. QUEST CHECK: Has V already rescued Evelyn? (story gate)
    if not KIT.IsJudyReady() then
        KIT.Log("Aborted: Judy is not ready yet (Evelyn rescue quest q105 not finished).")
        return
    end

    -- 2. STATUS UPDATE: Is this romance or friendship?
    KIT.UpdateRelationshipStatus()

    -- 3. MESSAGE SELECTION (exclude IDs already used)
    local usedIds = KIT.sms_storage.usedIds
    local messageData, shouldReset = KIT.messages.GetRandomMessage(KIT.runtime.isRomanced, usedIds)

    -- If all messages have been sent: clear the list and start again
    if shouldReset then
        KIT.Log("All messages used. Resetting history...")
        KIT.sms_storage.Clear()
        usedIds = {}
        messageData = KIT.messages.GetRandomMessage(KIT.runtime.isRomanced, usedIds)
    end

    if not messageData then
        KIT.Log("Error: No message data found.")
        return
    end

    KIT.Log("Selected message: " .. tostring(messageData.id) .. " (" .. (KIT.runtime.isRomanced and "romance" or "platonic") .. ")")

    -- 4. CYBERSCRIPT: Write message into the phone archive
    -- This avoids freezes on key press because CyberScript manages the journal.
    if Cyberscript then
        local ok, err = pcall(function()
            -- Use the message ID or a fallback root ID for complex conversations.
            local activeId = messageData.rootId or "kit_msg_slot"

            Cyberscript.SetMessageText("kit_msg_slot", messageData.text)
            Cyberscript.SetMessageActive("kit_msg_slot", true)
            Cyberscript.ReloadConversation("judy_kit_conv")
            KIT.Log("CyberScript: Archive updated for ID: " .. activeId)
        end)
        if not ok then
            KIT.Log("CyberScript error: " .. tostring(err))
        end
    else
        KIT.Log("CyberScript module unavailable. Skipping archive update.")
    end

    -- 5. NATIVE NOTIFICATION: The visual HUD popup
    if KIT.runtime.journalNotificationQueue then
        local ok, err = pcall(function()
            -- OpenJournalAction is the safest way to trigger the "T" key behavior.
            local openAction = OpenJournalAction.new()

            -- Optional: attach a real journal entry if available,
            -- otherwise the action opens the messenger directly.
            local journalManager = Game.GetJournalManager()
            local entry = journalManager:GetEntryByString("KeepInTouch.MsgSlot_01")
            if entry then
                openAction.journalEntry = entry
                KIT.Log("Notification action linked to journal entry.")
            else
                KIT.Log("Notification action using direct messenger open. Journal entry not found.")
            end

            local userData = PhoneMessageNotificationViewData.new()
            userData.title = 'Judy Alvarez'
            userData.SMSText = messageData.text
            userData.action = openAction
            userData.animation = CName.new('notification_phone_MSG')
            userData.soundEvent = CName.new('PhoneSmsPopup')
            userData.soundAction = CName.new('OnOpen')

            local notificationData = gameuiGenericNotificationData.new()
            notificationData.time = 7.0
            notificationData.widgetLibraryItemName = CName.new('notification_message')
            notificationData.notificationData = userData

            KIT.runtime.journalNotificationQueue:AddNewNotificationData(notificationData)
            KIT.Log("HUD notification enqueued successfully.")
        end)
        if not ok then
            KIT.Log("Popup UI Error: " .. tostring(err))
        end
    else
        KIT.Log("Warning: HUD Queue not ready. Message sent to archive only.")
    end

    -- 6. SAVE: mark the ID as used
    KIT.sms_storage.SaveUsedId(messageData.id)

    KIT.Log("--- SendMessage Sequence Finished: " .. messageData.id .. " ---")
end

registerForEvent("onInit", function()
    KIT.Log("Initializing Judy - Keep In Touch...")
    
    -- Popup Observer
    Observe('JournalNotificationQueue', 'OnMenuUpdate', function(self)
        KIT.runtime.journalNotificationQueue = self
        KIT.Log("JournalNotificationQueue observed and stored.")
    end)

    KIT.sms_storage.Init()
    KIT.settings.Register()
    KIT.runtime.nextWaitTime = KIT.settings.GetNextWaitTime()
    KIT.Log("Initial next wait time set to " .. tostring(KIT.runtime.nextWaitTime) .. " seconds.")

    GameSession.OnStart(function()
        KIT.runtime.gameReady = true
        KIT.runtime.messageTimer = 0
        KIT.UpdateRelationshipStatus()
        KIT.Log("GameSession started. gameReady=true")
    end)

    GameSession.OnEnd(function()
        KIT.runtime.gameReady = false
        KIT.Log("GameSession ended. gameReady=false")
    end)
end)

registerForEvent("onUpdate", function(deltaTime)
    -- Settings registration delay
    if not KIT.runtime.menuRegistered then
        KIT.runtime.timer = KIT.runtime.timer + deltaTime
        if KIT.runtime.timer > 2.0 then 
            KIT.runtime.timer = 0
            if GetMod("nativeSettings") then
                KIT.settings.Register()
                KIT.runtime.menuRegistered = true
                KIT.Log("Native settings registered successfully.")
            else
                KIT.Log("Waiting for nativeSettings mod to become available.")
            end
        end
    end

    -- Message timer loop
    if KIT.settings.enabled and KIT.runtime.gameReady and not KIT.runtime.paused then
        KIT.runtime.messageTimer = KIT.runtime.messageTimer + deltaTime

        if KIT.runtime.messageTimer >= KIT.runtime.nextWaitTime then
            KIT.runtime.messageTimer = 0
            KIT.runtime.nextWaitTime = KIT.settings.GetNextWaitTime()
            KIT.Log("Message timer expired. Next wait time = " .. tostring(KIT.runtime.nextWaitTime) .. " seconds.")
            KIT.SendMessage()
        end
    end
end)

return KIT