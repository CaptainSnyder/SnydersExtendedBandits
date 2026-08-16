-- Distress Beacon: a single consumable item. Right-click it in inventory
-- for a submenu listing every clan with the "Assault" Spawn AI option
-- enabled - pulled live from clan data, not a hardcoded list. Uses each
-- clan's actual configured group-size settings.

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

    local foundItem = nil
    for _, v in ipairs(items) do
        local invItem = v
        if not instanceof(v, "InventoryItem") then
            invItem = v.items and v.items[1] or nil
        end
        if invItem and invItem:getFullType() == "Base.DistressBeacon" then
            foundItem = invItem
            break
        end
    end

    if not foundItem then return end

    BanditCustom.Load()
    local allClans = BanditCustom.ClanGetAllSorted()
    local assaultClans = {}
    for cid, clan in pairs(allClans) do
        if clan.spawn and clan.spawn.assault then
            table.insert(assaultClans, { cid = cid, name = clan.general.name })
        end
    end

    if #assaultClans == 0 then return end

    local option = context:addOption("Use Distress Beacon")
    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)
    for _, c in ipairs(assaultClans) do
        subMenu:addOption("Call In " .. c.name, player, DistressDoSpawn, foundItem, c.cid)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(DistressContextMenu)
