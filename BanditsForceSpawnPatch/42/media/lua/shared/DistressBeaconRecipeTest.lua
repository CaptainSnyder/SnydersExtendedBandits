-- OnTest hook for the Distress Beacon craft recipes - gates them on the
-- BanditsForceSpawnPatch.DistressBeaconsCraftable sandbox toggle (default
-- true). Returning false makes the recipe unavailable to craft.

DistressBeaconRecipeTest = DistressBeaconRecipeTest or {}

function DistressBeaconRecipeTest.craftable(craftRecipeData, playerObj)
    if SandboxVars.BanditsForceSpawnPatch and SandboxVars.BanditsForceSpawnPatch.DistressBeaconsCraftable ~= nil then
        return SandboxVars.BanditsForceSpawnPatch.DistressBeaconsCraftable
    end
    return true
end
