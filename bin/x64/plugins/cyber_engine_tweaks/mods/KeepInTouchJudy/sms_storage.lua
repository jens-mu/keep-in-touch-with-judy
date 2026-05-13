-- sms_storage.lua
local storage = {
    path = "data/used_messages.json",
    usedIds = {}
end

function storage.Init()
    print("[KIT] Storage: loading used message IDs from " .. storage.path)
    local file = io.open(storage.path, "r")
    if file then
        local content = file:read("*a")
        storage.usedIds = json.decode(content) or {}
        file:close()
        print("[KIT] Storage: loaded " .. tostring(#storage.usedIds) .. " used IDs.")
    else
        storage.usedIds = {}
        print("[KIT] Storage: no existing history file found. Starting fresh.")
    end
end

function storage.SaveUsedId(id)
    table.insert(storage.usedIds, id)
    print("[KIT] Storage: saving used ID = " .. tostring(id) .. " (total used=" .. tostring(#storage.usedIds) .. ")")
    local file = io.open(storage.path, "w")
    file:write(json.encode(storage.usedIds))
    file:close()
end

function storage.Clear()
    storage.usedIds = {}
    os.remove(storage.path)
    print("[KIT] Storage: cleared used message history.")
end

return storage  