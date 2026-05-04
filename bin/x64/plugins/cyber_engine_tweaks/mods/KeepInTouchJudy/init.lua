-- Keep In Touch - Judy Alvarez Romance Extension
-- Main Logic Entry Point

local JIC = {
    settings = require("settings"),
    runtime = {
        isRomanced = false
    }
}

registerForEvent("onInit", function()
    print("[JIC] Initializing Keep In Touch...")

    -- 1. Register the Mod Settings Menu
    local nativeSettings = GetMod("nativeSettings")
    if nativeSettings then
        JIC.settings.Register()
        print("[JIC] Native Settings Menu registered.")
    else
        print("[JIC] WARNING: Native Settings UI not found. Using default settings.")
    end

    -- 2. Check for Deceptious Quest Core (DQC)
    local DQC = GetMod("DeceptiousQuestCore")
    if not DQC then
        print("[JIC] CRITICAL ERROR: Deceptious Quest Core is missing! Mod will not function.")
        return
    end

    -- 3. Initial Relationship Check
    JIC.UpdateRelationshipStatus()

    -- 4. Start the Logic Loop
    JIC.RunMainLoop()

    print("[JIC] Initialization complete.")
end)

-- Function to check Judy's romance status via Game Facts
function JIC.UpdateRelationshipStatus()
    -- Check the internal game fact for active romance
    local romanceFact = Game.GetQuestsSystem():GetFactStr("judy_romance_active")
    
    if romanceFact == 1 then
        JIC.settings.isRomanced = true
    else
        JIC.settings.isRomanced = false
    end
end



-- The core logic that handles the messaging timing
function JIC.RunMainLoop()
    -- ALWAYS check the enabled flag first
    if not JIC.settings.enabled then
        print("[JIC] Mod is disabled via settings. Skipping logic.")
        return
    end

    -- Logic for scheduling the next message would go here
    -- Using DQC to handle the persistence and timing
    print("[JIC] Messaging system is active. Status: " .. (JIC.settings.isRomanced and "Romance" or "Platonic"))
end

return JIC