local Utilities = require("EHEShared/Utilities");
local SpawnerAPI = require("EHEShared/SpawnerAPI");

local Modules = {
    SpawnerAPI = {},
    EventMarkers = {},
};

-- SpawnerAPI

function Modules.SpawnerAPI.spawnZombie(playerObj, data)
    SpawnerAPI.spawnZombie(data.outfitID, data.x, data.y, data.z, data.extraFunctions, data.femaleChance, data.processSquare);
end

function Modules.SpawnerAPI.spawnVehicle(playerObj, data)
    SpawnerAPI.spawnVehicle(data.vehicleType, data.x, data.y, data.z, data.extraFunctions, data.extraParam, data.processSquare);
end

function Modules.SpawnerAPI.spawnItem(playerObj, data)
    SpawnerAPI.spawnItem(data.itemType, data.x, data.y, data.z, data.extraFunctions, data.extraParam, data.processSquare);
end

-- EventMarkers

function Modules.EventMarkers.SetOrUpdate(playerObj, data)
    Utilities.SendCommandToAllClients("EventMarkers", "SetOrUpdate", data);
end

-- Server recieve a command from a client
local function onClientCommand(module, command, playerObj, data)
    for _moduleName, _module in pairs(Modules) do
        if _moduleName == module then
            if _module[command] and type(_module[command]) == "function" then
                _module[command](playerObj, data);
            end
        end
    end
end
Events.OnClientCommand.Add(onClientCommand);
