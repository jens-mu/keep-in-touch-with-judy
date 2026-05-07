local GameSession = require("GameSession")

local KIT = {
    settings = require("settings"),
    messages = require("messages"),
    runtime = {
        menuRegistered = false,
        gameReady = false,
        paused = false,
        timer = 0,
        messageTimer = 0,
        nextWaitTime = 0,
        isRomanced = false,
        initialDelayPassed = false, -- Neuer Sicherheits-Anker
        journalNotificationQueue = nil -- Wird durch Observer initialisiert
    }
}

function KIT.StartSession()
    -- Wir prüfen zusätzlich, ob das HUD bereit ist
        KIT.runtime.gameReady = true
        KIT.UpdateRelationshipStatus()
        print("[KIT] Session fully stabilized. Starting timer.")
end

registerForEvent("onInit", function()
    print("[KIT] Initializing Keep In Touch...")
    KIT.runtime.nextWaitTime = KIT.settings.GetNextWaitTime()
    
    -- JournalNotificationQueue Observer (aus Discord-Channel)
    Observe('JournalNotificationQueue', 'OnMenuUpdate', function(self)
        KIT.runtime.journalNotificationQueue = self
        print("[KIT] JournalNotificationQueue erfolgreich initialisiert.")
    end)

    GameSession.OnStart(function()
        if not KIT.runtime.gameReady then
            KIT.runtime.gameReady = true
            KIT.runtime.messageTimer = 0
            KIT.runtime.nextWaitTime = KIT.settings.GetNextWaitTime()
            KIT.UpdateRelationshipStatus()
            print("[KIT] GameSession.OnStart fired - session ready.")
        end
    end)

    GameSession.OnEnd(function()
        KIT.runtime.gameReady = false
        KIT.runtime.messageTimer = 0
        print("[KIT] GameSession.OnEnd fired - session reset.")
    end)

    GameSession.OnPause(function()
        KIT.runtime.paused = true
    end)

    GameSession.OnResume(function()
        KIT.runtime.paused = false
    end)
end)

registerForEvent("onUpdate", function(deltaTime)
    -- 1. Native Settings
    if not KIT.runtime.menuRegistered then
        KIT.runtime.timer = KIT.runtime.timer + deltaTime
        if KIT.runtime.timer > 2.0 then 
            KIT.runtime.timer = 0
            local nativeSettings = GetMod("nativeSettings")
            if nativeSettings then
                KIT.settings.Register()
                KIT.runtime.menuRegistered = true
            end
        end
    end

    -- 2. Message Loop Logic
    if KIT.settings.enabled and KIT.runtime.gameReady and not KIT.runtime.paused then
        KIT.runtime.messageTimer = KIT.runtime.messageTimer + deltaTime

        if KIT.runtime.messageTimer >= KIT.runtime.nextWaitTime then
            KIT.runtime.messageTimer = 0
            KIT.runtime.nextWaitTime = KIT.settings.GetNextWaitTime()
            
            KIT.SendMessage()
            print("[KIT] Next message in " .. KIT.runtime.nextWaitTime .. " units.")
        end
    end
end)

-- Restliche Funktionen (UpdateRelationshipStatus, SendMessage) wie zuvor

function KIT.UpdateRelationshipStatus()
    local questSystem = Game.GetQuestsSystem()
    if questSystem then
        local romanceFact = questSystem:GetFactStr("judy_romance_active")
        KIT.runtime.isRomanced = (romanceFact == 1)
        KIT.settings.isRomanced = KIT.runtime.isRomanced
    end
end

function KIT.SendMessage()
    local message = KIT.messages.GetRandomMessage(KIT.runtime.isRomanced)
    
    -- Sicherheitscheck: Ist die Queue initialisiert?
    if not KIT.runtime.journalNotificationQueue then
        print("[KIT] ERROR: journalNotificationQueue nicht verfügbar!")
        return
    end
    
    local openAction = OpenMessengerNotificationAction.new()
    openAction.eventDispatcher = KIT.runtime.journalNotificationQueue
    
    local userData = PhoneMessageNotificationViewData.new()
    userData.title = 'Judy Alvarez'
    userData.SMSText = message.text
    userData.action = openAction
    userData.animation = CName('notification_phone_MSG')
    userData.soundEvent = CName('PhoneSmsPopup')
    userData.soundAction = CName('OnOpen')
    
    local notificationData = gameuiGenericNotificationData.new()
    notificationData.time = 14.0
    notificationData.widgetLibraryItemName = CName('notification_message')
    notificationData.notificationData = userData

    KIT.runtime.journalNotificationQueue:AddNewNotificationData(notificationData)
    
    print("[KIT] JUDY SAYS: " .. message.text)
end