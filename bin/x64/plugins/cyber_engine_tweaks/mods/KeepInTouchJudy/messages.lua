-- messages.lua
local messages = {}

messages.data = {
    -- Platonic messages (friendly, after Evelyn rescue)
    platonic = {
        {
            id = "judy_plat_01",
            text = "Hey V, hab gerade ein paar alte Braindances sortiert. Echt schräg, was die Leute früher für 'Unterhaltung' hielten... Hoffe, bei dir ist es weniger stressig als in Watson gerade."
        },
        {
            id = "judy_plat_02",
            text = "V, danke nochmal für alles neulich. Ohne dich wäre das im Apartment ganz anders ausgegangen. Falls du mal in der Nähe bist und 'ne Pause von der ganzen Night-City-Scheiße brauchst – Kaffee steht bereit."
        }
    },

    -- Romance messages (emotional, deeper)
    romance = {
        {
            id = "judy_rom_01",
            text = "Hab gerade an unser Tauchen gedacht... die Stille da unten. Manchmal wünschte ich, wir könnten einfach dort bleiben, weit weg vom Lärm der Stadt. Pass auf dich auf, okay? Ich brauch dich hier oben noch."
        },
        {
            id = "judy_rom_02",
            text = "V? Ich schau gerade aus dem Fenster und die Lichter der Stadt sehen heute fast... friedlich aus. Aber irgendwas fehlt. Oder eher jemand. Melde dich mal, wenn du zwischen deinen ganzen Aufträgen Zeit zum Atmen hast."
        }
    }
}

-- Message selection logic with exclusion list
function messages.GetRandomMessage(isRomanced, usedIds)
    local category = isRomanced and "romance" or "platonic"
    local pool = messages.data[category]
    local availableMessages = {}

    print("[KIT] Message selection started. category=" .. category .. ", usedIdsCount=" .. tostring(#usedIds))

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
            print("[KIT] Message excluded because already used: " .. msg.id)
        end
    end

    -- If the pool is empty, return a reset signal
    if #availableMessages == 0 then
        print("[KIT] Message selection: no available messages left in category=" .. category)
        return nil, true
    end

    -- Random selection from available messages
    local randomIndex = math.random(1, #availableMessages)
    local chosen = availableMessages[randomIndex]
    print("[KIT] Message selection: chosen=" .. chosen.id .. ", availableCount=" .. tostring(#availableMessages))
    return chosen, false
end

return messages