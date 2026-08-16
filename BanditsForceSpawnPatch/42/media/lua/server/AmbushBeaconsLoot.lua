-- Adds the Distress Beacon to military-themed loot containers so it can be
-- found naturally in the world, not just handed out via admin commands.
-- Runs after ProceduralDistributions.lua has populated its list (mod load
-- order places this file after the base game's own distribution files).

if ProceduralDistributions and ProceduralDistributions.list then

    -- Radio/comms storage - thematically the best fit (it's a radio-style item)
    local electronics = ProceduralDistributions.list.ArmyStorageElectronics
    if electronics and electronics.items then
        table.insert(electronics.items, "Base.DistressBeacon")
        table.insert(electronics.items, 1)
    end

    -- Secure bunker storage - rarer, matches this table's much lower weight scale
    local bunkerStorage = ProceduralDistributions.list.ArmyBunkerStorage
    if bunkerStorage and bunkerStorage.items then
        table.insert(bunkerStorage.items, "Base.DistressBeacon")
        table.insert(bunkerStorage.items, 0.02)
    end

end
