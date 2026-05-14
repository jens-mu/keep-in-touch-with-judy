-- sms_storage.lua
local storage = {
    path = 'used_messages.json',
    usedIds = {},
}

function storage.Init()
    print('[KIT] Storage: loading used message IDs from ' .. storage.path)
    local file = io.open(storage.path, 'r')
    if not file then
        storage.usedIds = {}
        print('[KIT] Storage: no existing history file found. Starting fresh.')
        return
    end

    local content = file:read('*a')
    file:close()

    local ok, result = pcall(json.decode, content)
    if ok and type(result) == 'table' then
        storage.usedIds = result
        print('[KIT] Storage: loaded ' .. tostring(#storage.usedIds) .. ' used IDs.')
    else
        storage.usedIds = {}
        print('[KIT] Storage: corrupt or invalid JSON detected, resetting history.')
    end
end

function storage.SaveUsedId(id)
    table.insert(storage.usedIds, id)
    print('[KIT] Storage: saving used ID = ' .. tostring(id) .. ' (total used=' .. tostring(#storage.usedIds) .. ')')
    local file = io.open(storage.path, 'w')
    if not file then
        print('[KIT] Storage: ERROR - could not open ' .. storage.path .. ' for writing.')
        return
    end
    file:write(json.encode(storage.usedIds))
    file:close()
end

function storage.Clear()
    storage.usedIds = {}
    os.remove(storage.path)
    print('[KIT] Storage: cleared used message history.')
end

return storage
