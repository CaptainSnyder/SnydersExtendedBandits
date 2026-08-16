-- Custom Dialogue Creator: per-clan custom dialogue lines.
-- Stored locally only (Zomboid/Lua/bandits/dialogue.txt), separate from
-- BanditCustom's bandit/clan data, to keep this simple and avoid the
-- multi-storage-location footgun that local/mod storage caused elsewhere.

require "BanditCompatibility"

BanditDialogueCustom = BanditDialogueCustom or {}
BanditDialogueCustom.data = {}

BanditDialogueCustom.filePath = BanditCompatibility.GetConfigPath()
BanditDialogueCustom.dialogueFile = "dialogue.txt"

local function splitString(input, separator)
    local result = {}
    for match in (input .. separator):gmatch("(.-)" .. separator) do
        table.insert(result, match:match("^%s*(.-)%s*$"))
    end
    return result
end

BanditDialogueCustom.Load = function()
    BanditDialogueCustom.data = {}

    local fileName = BanditDialogueCustom.filePath .. BanditDialogueCustom.dialogueFile
    local file = getFileReader(fileName, false)
    if not file then return end

    local id
    while true do
        local line = file:readLine()
        if line == nil then
            file:close()
            break
        end

        local guid = line:match("%[(%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x)%]")
        if guid then
            id = guid
        end

        local s, k, v = line:match("([%w_]+)%s*:%s*([%w_]+)%s*=%s*(.*)")
        if id and k and v then
            if v == "true" then
                v = true
            elseif v == "false" then
                v = false
            elseif v:match("^%-?%d+%.?%d*$") then
                v = tonumber(v)
            end

            if not BanditDialogueCustom.data[id] then
                BanditDialogueCustom.data[id] = {}
            end
            if not BanditDialogueCustom.data[id][s] then
                BanditDialogueCustom.data[id][s] = {}
            end
            BanditDialogueCustom.data[id][s][k] = v
        end
    end
end

BanditDialogueCustom.Save = function()
    local fileName = BanditDialogueCustom.filePath .. BanditDialogueCustom.dialogueFile
    local writer = getFileWriter(fileName, true, false)
    if not writer then return end

    for id, sections in pairs(BanditDialogueCustom.data) do
        writer:write("[" .. id .. "]\n")
        for sname, tab in pairs(sections) do
            for k, v in pairs(tab) do
                writer:write("\t" .. sname .. ": " .. k .. " = " .. tostring(v) .. "\n")
            end
        end
        writer:write("\n")
    end
    writer:close()
end

BanditDialogueCustom.Create = function(id, cid)
    local data = {}
    data.general = {}
    data.general.cid = cid
    data.general.trigger = "SPOTTED"
    data.general.text = ""
    data.general.chance = 30

    BanditDialogueCustom.data[id] = data
    return BanditDialogueCustom.data[id]
end

BanditDialogueCustom.Delete = function(id)
    BanditDialogueCustom.data[id] = nil
end

BanditDialogueCustom.Get = function(id)
    return BanditDialogueCustom.data[id]
end

-- Gameplay-side lookups (GetFromClan/GetFromClanAndTrigger) can run long
-- before the Custom Dialogue editor UI is ever opened this session, so make
-- sure the data is loaded at least once on first use rather than depending
-- on the UI to have done it already.
local hasLoadedOnce = false
local function ensureLoaded()
    if not hasLoadedOnce then
        hasLoadedOnce = true
        BanditDialogueCustom.Load()
    end
end

BanditDialogueCustom.GetFromClan = function(cid)
    ensureLoaded()
    local ret = {}
    for id, data in pairs(BanditDialogueCustom.data) do
        if data.general and data.general.cid == cid then
            ret[id] = data
        end
    end
    return ret
end

BanditDialogueCustom.GetFromClanAndTrigger = function(cid, trigger)
    ensureLoaded()
    local ret = {}
    for id, data in pairs(BanditDialogueCustom.data) do
        if data.general and data.general.cid == cid and data.general.trigger == trigger then
            table.insert(ret, data.general)
        end
    end
    return ret
end
