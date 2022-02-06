local Utilities = require("EHEShared/Utilities");
local EventMarkers = require("EHEShared/EventMarkers");

local Modules = {
    EventMarkers = {},
};

-- EventMarkers

function Modules.EventMarkers.SetOrUpdate(data)
    EventMarkers.SetOrUpdate(data.eventID, data.icon, data.duration, data.posX, data.posY, true);
end

-- Client recieve a command from the server
local function onServerCommand(module, command, data)
    for _moduleName, _module in pairs(Modules) do
        if _moduleName == module then
            if _module[command] and type(_module[command]) == "function" then
                _module[command](data);
            end
        end
    end
end
Events.OnServerCommand.Add(onServerCommand);
