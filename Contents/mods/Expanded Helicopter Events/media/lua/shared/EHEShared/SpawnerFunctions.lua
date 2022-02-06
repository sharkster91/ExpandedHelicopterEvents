local PresetAPI = require("EHEShared/Presets");
local Utilities = require("EHEShared/Utilities");

local spawnerAPIInstance; -- we use SetSpawnerAPI to set this variable, this way we do not require the file here
local SpawnerFunctions = {};

-- We add default functions here

function SpawnerFunctions.getOutsideSquareFromAbove_vehicle(...)
    return Utilities.GetOutsideSquareFromAbove_vehicle(...);
end

function SpawnerFunctions.getOutsideSquareFromAbove(...)
	return Utilities.GetOutsideSquareFromAbove(...);
end

function SpawnerFunctions.applyCrashOnVehicle(...)
	return Utilities.ApplyCrashOnVehicle(...);
end

function SpawnerFunctions.ageInventoryItem(...)
	return Utilities.AgeInventoryItem(...);
end

function SpawnerFunctions.applyDeathOrCrawlerToCrew(...)
	return Utilities.ApplyDeathOrCrawlerToCrew(...);
end

-- This method is defined here cause it require access to the SpawnerAPI instance
function Utilities.applyParachuteToCarePackage(vehicle)
    if not spawnerAPIInstance or not vehicle then return; end

    spawnerAPIInstance.spawnItem("EHE.EHE_Parachute", vehicle:getX(), vehicle:getY(), 0, nil, nil, "getOutsideSquareFromAbove")
end

-- This method is defined here cause it require access to the SpawnerAPI instance
function SpawnerFunctions.helicopterDropTrash(heli)
    if not spawnerAPIInstance then return; end

	local heliX, heliY, _ = heli:getXYZAsInt()
	local trashItems = {"MayonnaiseEmpty","SmashedBottle","Pop3Empty","PopEmpty","Pop2Empty","WhiskeyEmpty","BeerCanEmpty","BeerEmpty"}
	local iterations = 10

	for i=1, iterations do

		heliY = heliY+ZombRand(-2,3)
		heliX = heliX+ZombRand(-2,3)

		local trashType = trashItems[(ZombRand(#trashItems)+1)]
		--more likely to drop the same thing
		table.insert(trashItems, trashType)

		spawnerAPIInstance.spawnItem(trashType, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
	end
end

-- We load the preset added functions on game boot

local function getPresetAddedFunctions()
    local presets = PresetAPI.GetAll();
    for presetName, presetData in pairs(presets) do
        if type(presetData.addedFunctionsToEvents) == "table" then
            for eventID, eventFunction in pairs(presetData.addedFunctionsToEvents) do
                if type(eventFunction) == "string" then
                    SpawnerFunctions[presetName .. eventID] = SpawnerFunctions[eventFunction];
                elseif type(eventFunction) == "function" then
                    SpawnerFunctions[presetName .. eventID] = eventFunction;
                end
            end
        end
    end
end
Events.OnGameBoot.Add(getPresetAddedFunctions);

-- We return getters to use in Spawner API

local SpawnerFunctionsAPI = {};

function SpawnerFunctionsAPI.SetSpawnerAPI(SpawnerAPI)
    if not spawnerAPIInstance then spawnerAPIInstance = SpawnerAPI; end
end

function SpawnerFunctionsAPI.GetAllFunctions()
    return SpawnerFunctions;
end

function SpawnerFunctionsAPI.CallFunction(id, ...)
    if SpawnerFunctions[id] then
        return SpawnerFunctions[id](...);
    end
end

return SpawnerFunctionsAPI;
