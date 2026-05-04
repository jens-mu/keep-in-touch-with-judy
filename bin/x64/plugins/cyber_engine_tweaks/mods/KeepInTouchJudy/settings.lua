local ModSettings = {
    enabled = true,
    showPhotos = true,
    isRomanced = false,
    platonicIndex = 2,
    romanceIndex = 2,

    platonicWindows = {
        [1] = { min = 72, max = 120 },
        [2] = { min = 36, max = 72 },
        [3] = { min = 20, max = 36 }
    },

    romanceWindows = {
        [1] = { min = 24, max = 48 },
        [2] = { min = 12, max = 24 },
        [3] = { min = 4,  max = 10 }
    }
}

function ModSettings.Register()
    local nativeSettings = GetMod("nativeSettings")
    if not nativeSettings then return end
    
    -- Create Tab
    nativeSettings.addTab("/JIC", "Keep In Touch") 

    -- Toggle (Switch)
    nativeSettings.addSwitch("/JIC", "Enable Mod", "Judy will send you messages periodically.", ModSettings.enabled, true, function(state)
        ModSettings.enabled = state
    end)

    nativeSettings.addSwitch("/JIC", "Enable Photos", "Allow Judy to send personal photos.", ModSettings.showPhotos, true, function(state)
        ModSettings.showPhotos = state
    end)

    -- String List (Dropdown)
    local options = {[1] = "Rare", [2] = "Normal", [3] = "Frequent"}

    nativeSettings.addSelectorString("/JIC", "Frequency (Friendship)", "Frequency when just friends", options, ModSettings.platonicIndex, 2, function(index)
        ModSettings.platonicIndex = index
    end)

    nativeSettings.addSelectorString("/JIC", "Frequency (Romance)", "Frequency when in a relationship", options, ModSettings.romanceIndex, 2, function(index)
        ModSettings.romanceIndex = index
    end)
end

function ModSettings.GetNextWaitTime()
    local window
    if ModSettings.isRomanced then
        window = ModSettings.romanceWindows[ModSettings.romanceIndex]
    else
        window = ModSettings.platonicWindows[ModSettings.platonicIndex]
    end
    return math.random(window.min, window.max)
end

return ModSettings