local Utilities = require("EHEShared/Utilites");

local loadedModData;

local function onInitGlobalModData()
	loadedModData = ModData.getOrCreate("ExpandedHelicopterEvents")
    loadedModData.EventsOnSchedule = loadedModData.EventsOnSchedule or {}
    loadedModData.DayOfLastCrash = loadedModData.DayOfLastCrash or getGameTime():getNightsSurvived()
    loadedModData.DaysBeforeApoc = loadedModData.DaysBeforeApo or Utilities.GetDaysSinceApocalypse()
end
Events.OnInitGlobalModData.Add(onInitGlobalModData);

return {
    Get = function()
        return loadedModData;
    end
}
