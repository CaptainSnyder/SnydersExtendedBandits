-- Distress Beacons: two consumable items. Hostile Distress Beacon calls in
-- a clan's "Assault" squad, Friendly Distress Beacon calls in a clan's
-- "Companions". Each right-click menu lists every clan with the matching
-- Spawn AI option enabled - pulled live from clan data, not a hardcoded
-- list. Uses each clan's actual configured group-size settings.

local BEACON_TYPES = {
    ["Base.DistressBeacon"] = { flag = "assault", label = "Use Hostile Distress Beacon" },
    ["Base.FriendlyDistressBeacon"] = { flag = "companion", label = "Use Friendly Distress Beacon" },
}

local function DistressDoSpawn(player, item, cid)
    BanditCustom.Load()
    local clan = BanditCustom.ClanGet(cid)
    local groupMin = 1
    local groupMax = 1
    if clan and clan.spawn and clan.spawn.groupMin and clan.spawn.groupMax then
        groupMin = tonumber(clan.spawn.groupMin) or 1
        groupMax = tonumber(clan.spawn.groupMax) or groupMin
    end
    local size = groupMin + ZombRand(groupMax - groupMin + 1)

    -- Offset the call-in point the same way the scheduler places ambush
    -- spawns (BanditServerSpawner.lua) instead of the player's own tile -
    -- generateSpawnPointHere() puts every bandit at the exact point it's
    -- given, so without this the whole squad spawned stacked on the player.
    local theta = ZombRandFloat(0, 2 * math.pi)
    local nearDist = 55 + ZombRand(10)

    local args = {}
    args.cid = cid
    args.x = player:getX() + (nearDist * math.cos(theta))
    args.y = player:getY() + (nearDist * math.sin(theta))
    args.z = player:getZ()
    args.size = size
    sendClientCommand(player, 'Spawner', 'Clan', args)

    player:getInventory():Remove(item)
end

local function DistressContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    for fullType, config in pairs(BEACON_TYPES) do
        local foundItem = nil
        for _, v in ipairs(items) do
            local invItem = v
            if not instanceof(v, "InventoryItem") then
                invItem = v.items and v.items[1] or nil
            end
            if invItem and invItem:getFullType() == fullType then
                foundItem = invItem
                break
            end
        end

        if foundItem then
            BanditCustom.Load()
            local allClans = BanditCustom.ClanGetAllSorted()
            local matchingClans = {}
            for cid, clan in pairs(allClans) do
                if clan.spawn and clan.spawn[config.flag] then
                    table.insert(matchingClans, { cid = cid, name = clan.general.name })
                end
            end

            if #matchingClans > 0 then
                local option = context:addOption(config.label)
                local subMenu = context:getNew(context)
                context:addSubMenu(option, subMenu)
                for _, c in ipairs(matchingClans) do
                    subMenu:addOption("Call In " .. c.name, player, DistressDoSpawn, foundItem, c.cid)
                end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(DistressContextMenu)
