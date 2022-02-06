local Utilities = require("EHEShared/Utilites");
local GlobalModData = require("EHEShared/GlobalModData");
local SpawnerFunctionsAPI = require("EHEShared/SpawnerFunctions");

local SpawnerAPI = {};

local function processExtraFunctionsOnto(spawned, functions)
	if spawned and functions and type(functions) == "table" then
		for k, funcID in pairs(functions) do
			--print("EHE: DEBUG: processExtraFunctionsOnto: "..funcID)
			SpawnerFunctionsAPI.CallFunction(funcID, spawned)
		end
	end
end

---@param spawnFuncType string This string is concated to the end of 'SpawnerTEMP.spawn' to run a corresponding function.
---@param objectType string Module.Type for Items and Vehicles, OutfitID for Zombies
---@param x number
---@param y number
---@param z number
---@param funcsToApply table Table of functions which gets applied on the results of whatever is spawned.
local function setToSpawn(spawnFuncType, objectType, x, y, z, funcsToApply, extraParam, processSquare)
	local farSquarePendingSpawns = SpawnerAPI.getOrSetPendingSpawnsList();
    if not farSquarePendingSpawns then return; end

	local positionID = Utilities.PositionToId(x, y, z)
	if not farSquarePendingSpawns[positionID] then
		farSquarePendingSpawns[positionID] = {}
	end

	local newEntry = {
		spawnFuncType=spawnFuncType,
		objectType=objectType,
		x=x,
		y=y,
		z=z,
		funcsToApply=funcsToApply,
		extraParam=extraParam,
		processSquare=processSquare
	}

	table.insert(farSquarePendingSpawns[positionID],newEntry)
end

function SpawnerAPI.getOrSetPendingSpawnsList()
	local modData = GlobalModData.Get();
    if modData then
        if not modData.FarSquarePendingSpawns then modData.FarSquarePendingSpawns = {} end
        return modData.FarSquarePendingSpawns
    end
end

function SpawnerAPI.spawnItem(itemType, x, y, z, extraFunctions, extraParam, processSquare)
    if not itemType then return; end

	SpawnerFunctionsAPI.SetSpawnerAPI(SpawnerAPI);

	if isClient() then
        local data = {
            itemType=itemType,
            x=x,
            y=y,
            z=z,
            extraFunctions=extraFunctions,
            extraParam=extraParam,
            processSquare=processSquare
        };

        Utilities.SendCommandToServer("SpawnerAPI", "spawnItem", data);
	else
		local currentSquare = getSquare(x,y,z)

		if currentSquare then
			if processSquare then
				currentSquare = SpawnerFunctionsAPI.CallFunction(processSquare, currentSquare)
			end
		end

		if currentSquare then
			--x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
			local item = currentSquare:AddWorldInventoryItem(itemType, 0, 0, 0)
			if item and extraFunctions then
				processExtraFunctionsOnto(item, extraFunctions)
			end
		else
			setToSpawn("Item", itemType, x, y, z, extraFunctions, extraParam, processSquare)
		end
	end
end

function SpawnerAPI.spawnVehicle(vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
    if not vehicleType then return; end

	SpawnerFunctionsAPI.SetSpawnerAPI(SpawnerAPI);

	if isClient() then
		local data = {
            vehicleType=vehicleType,
            x=x,
            y=y,
            z=z,
            extraFunctions=extraFunctions,
            extraParam=extraParam,
            processSquare=processSquare
        };

        Utilities.SendCommandToServer("SpawnerAPI", "spawnVehicle", data);
	else
		local currentSquare = getSquare(x,y,z)

		if currentSquare then
			if processSquare then
				currentSquare = SpawnerFunctionsAPI.CallFunction(processSquare, currentSquare)
			end
		end

		if currentSquare then
			local vehicle = addVehicleDebug(vehicleType, IsoDirections.getRandom(), nil, currentSquare)
			if vehicle then
				processExtraFunctionsOnto(vehicle,extraFunctions)
			end
		else
			setToSpawn("Vehicle", vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
		end
	end
end

function SpawnerAPI.spawnZombie(outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
    if not outfitID then return; end

	SpawnerFunctionsAPI.SetSpawnerAPI(SpawnerAPI);

	if isClient() then
        local data = {
            outfitID=outfitID,
            x=x,
            y=y,
            z=z,
            extraFunctions=extraFunctions,
            femaleChance=femaleChance,
            processSquare=processSquare
        };

        Utilities.SendCommandToServer("SpawnerAPI", "spawnZombie", data);
	else
		local currentSquare = getSquare(x,y,z)

		if currentSquare then
			if processSquare then
				currentSquare = SpawnerFunctionsAPI.CallFunction(processSquare, currentSquare)
			end
		end

		if currentSquare then
			x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
			local zombies = addZombiesInOutfit(x, y, z, 1, outfitID, femaleChance)
			if zombies and zombies:size()>0 then
				processExtraFunctionsOnto(zombies, extraFunctions)
			end
		else
			setToSpawn("Zombie", outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
		end
	end
end

-- Process pending spawns on loading squares
local function parseSquare(square)
	local farSquarePendingSpawns = SpawnerAPI.getOrSetPendingSpawnsList()
    if not farSquarePendingSpawns then return; end

	local positionID = Utilities.SquareToId(square)
	local pendingItems = farSquarePendingSpawns[positionID]

	if not pendingItems or #pendingItems < 1 then return; end

	SpawnerFunctionsAPI.SetSpawnerAPI(SpawnerAPI);

	for key, entry in pairs(pendingItems) do
		local shiftedSquare = square
		if entry.processSquare then
			shiftedSquare = SpawnerFunctionsAPI.CallFunction(entry.processSquare, shiftedSquare)
		end

		if shiftedSquare then
			local spawnFunc = SpawnerAPI["spawn" .. entry.spawnFuncType]
			if spawnFunc then
				local spawnedObject = spawnFunc(entry.objectType, entry.x, entry.y, entry.z, entry.funcsToApply, entry.extraParam)
			end
		end
		--farSquarePendingSpawns[positionID][key] = nil
	end
	farSquarePendingSpawns[positionID] = nil
end
Events.LoadGridsquare.Add(parseSquare);

return SpawnerAPI;
