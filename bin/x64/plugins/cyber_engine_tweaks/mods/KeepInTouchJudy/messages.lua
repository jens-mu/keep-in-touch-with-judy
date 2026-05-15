-- messages.lua
local messages = {}

messages.data = {
    -- Platonic messages (friendly, after Evelyn rescue)
    platonic = {
        {
            id = 'judy_plat_01',
            text = "Hey V. Been sorting through some old braindances. Wild how people used to call that entertainment. Hope things are less hectic on your end than in Watson right now.",
        },
        {
            id = 'judy_plat_02',
            text = "Still thinking about what went down back there. Wouldn't have turned out the same without you. If you're ever around and need a break from all the Night City bullshit - coffee's on me.",
        },
    },

    -- Romance messages (emotional, deeper)
    romance = {
        {
            id = 'judy_rom_01',
            text = "Been thinking about that dive we did. The quiet down there. Sometimes I wish we could just stay. Away from all this noise. Take care of yourself, okay? I need you up here.",
        },
        {
            id = 'judy_rom_02',
            text = "V? Looking out the window right now. City lights almost look peaceful tonight. Almost. But something's missing. Someone. Check in when you get a chance to breathe between all those gigs.",
        },
    },
}

-- Message selection logic with exclusion list
function messages.GetRandomMessage(isRomanced, usedIds)
    local category = isRomanced and 'romance' or 'platonic'
    local pool = messages.data[category]
    local availableMessages = {}

    print('[KIT] Message selection started. category=' .. category .. ', usedIdsCount=' .. tostring(#usedIds))

    -- Filter: only messages whose ID is not in usedIds
    for _, msg in ipairs(pool) do
        local isUsed = false
        for _, usedId in ipairs(usedIds) do
            if msg.id == usedId then
                isUsed = true
                break
            end
        end
        if not isUsed then
            table.insert(availableMessages, msg)
        else
            print('[KIT] Message excluded because already used: ' .. msg.id)
        end
    end

    -- If the pool is empty, return a reset signal
    if #availableMessages == 0 then
        print('[KIT] Message selection: no available messages left in category=' .. category)
        return nil, true
    end

    -- Random selection from available messages
    local randomIndex = math.random(1, #availableMessages)
    local chosen = availableMessages[randomIndex]
    print('[KIT] Message selection: chosen=' .. chosen.id .. ', availableCount=' .. tostring(#availableMessages))
    return chosen, false
end

return messages
