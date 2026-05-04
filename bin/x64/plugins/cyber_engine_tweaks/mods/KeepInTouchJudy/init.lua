local JIC = {
    settings = require("settings"),
    runtime = {
        menuRegistered = false,
        timer = 0
    }
}

registerForEvent("onInit", function()
    print("[JIC] Initializing Keep In Touch...")
end)

registerForEvent("onUpdate", function(deltaTime)
    if not JIC.runtime.menuRegistered then
        JIC.runtime.timer = JIC.runtime.timer + deltaTime
        
        -- Check every 2 seconds to be safe
        if JIC.runtime.timer > 2.0 then 
            JIC.runtime.timer = 0
            
            -- Try to find the mods
            local nativeSettings = GetMod("nativeSettings")
            local DQC = GetMod("DeceptiousQuestCore")

            if nativeSettings then
                JIC.settings.Register()
                JIC.runtime.menuRegistered = true
                print("[JIC] Native Settings found and registered!")
            end
            
            if DQC then
                JIC.UpdateRelationshipStatus()
                -- print("[JIC] Deceptious Quest Core found!") -- Only for debugging
            end
        end
    end
end)

function JIC.UpdateRelationshipStatus()
    local romanceFact = Game.GetQuestsSystem():GetFactStr("judy_romance_active")
    JIC.settings.isRomanced = (romanceFact == 1)
end