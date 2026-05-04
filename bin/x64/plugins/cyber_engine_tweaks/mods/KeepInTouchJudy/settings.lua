-- Integration for https://www.nexusmods.com/cyberpunk2077/mods/4885
local ModSettings = {
    enabled = true,
    showPhotos = true,
    isRomanced = false, -- This will be updated by the main logic

    -- Selected indices for the dropdowns
    platonicIndex = 2, 
    romanceIndex = 2,

    -- Intervals for Platonic (Friendship)
    platonicWindows = {
        [1] = { min = 72, max = 120 }, -- Rare: Every 3 to 5 days
        [2] = { min = 36, max = 72 },  -- Normal: Every 1.5 to 3 days
        [3] = { min = 20, max = 36 }   -- Frequent: Almost daily
    },

    -- Intervals for Romance (Relationship)
    romanceWindows = {
        [1] = { min = 24, max = 48 }, -- Rare: Every 1 to 2 days
        [2] = { min = 12, max = 24 }, -- Normal: Every 12 to 24 hours
        [3] = { min = 4,  max = 10 }  -- Frequent: Every few hours ("Honeymoon")
    }
}

function ModSettings.Register()
    local nativeSettings = GetMod("nativeSettings")
    if not nativeSettings then return end
    
    nativeSettings.addTab("/JIC", "Keep In Touch - Judy") 

    -- Master Switch
    nativeSettings.addCheckBox("/JIC", "Enable Mod", "Judy will send you messages periodically.", ModSettings.enabled, ModSettings.enabled, function(value)
        ModSettings.enabled = value
    end)

    -- Photo Switch
    nativeSettings.addCheckBox("/JIC", "Enable Photos", "Allow Judy to send personal photos.", ModSettings.showPhotos, ModSettings.showPhotos, function(value)
        ModSettings.showPhotos = value
    end)

    -- Frequency Options
    local options = {"Rare", "Normal", "Frequent"}

    -- Platonic Setting
    nativeSettings.addSelectorString("/JIC", "Frequency (Friendship)", "How often should she text when you are just friends?", options, ModSettings.platonicIndex, ModSettings.platonicIndex, function(index)
        ModSettings.platonicIndex = index
    end)

    -- Romance Setting
    nativeSettings.addSelectorString("/JIC", "Frequency (Romance)", "How often should she text when in a relationship?", options, ModSettings.romanceIndex, ModSettings.romanceIndex, function(index)
        ModSettings.romanceIndex = index
    end)
end

-- Calculation logic for the next random interval
function ModSettings.GetNextWaitTime()
    local window
    if ModSettings.isRomanced then
        window = ModSettings.romanceWindows[ModSettings.romanceIndex]
    else
        window = ModSettings.platonicWindows[ModSettings.platonicIndex]
    end
    
    -- Pick a random hour count within the selected window
    return math.random(window.min, window.max)
end

return ModSettings