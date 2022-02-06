--[[
	To create announcer from an other mod
	
	local EHEAnnouncersAPI = require("EHEShared/Announcers");
    
	EHEAnnouncersAPI.AddOrReplace("MyNewAnnouncerName", {
		
	});
	
]]--

local announcers = {} -- local db

local AnnouncersAPI = {}; -- Exported API Object

-- API method to get all announcers
function AnnouncersAPI.GetAll()
    return announcers;
end

-- API method to get an announcer by name
function AnnouncersAPI.Get(name)
    return announcers[name];
end

-- API method to add an announcer by name
function AnnouncersAPI.AddOrReplace(name, data)
    if type(data) == "table" then
        announcers[name] = data;
        return announcers[name];
    end
end

-- API method to remove an announcer by name
function AnnouncersAPI.Remove(name)
    announcers[name] = nil;
end

-- Default Announcers included with this mod

announcers["Raven Male"] = {
    ["Lines"] = {
        ["PleaseReturnToYourHomes"] = {7500, "eHeli_lineM_1"},
        ["TheSituationIsUnderControl"] = {7500, "eHeli_lineM_2"},
        ["ThisAreaIsNowInQuarantine"] = {8000, "eHeli_lineM_3"},
        ["DoNotTryToLeaveTheArea"] = {7500, "eHeli_lineM_5"},
        ["LockAllEntrances"] = {8000, "eHeli_lineM_7"},
        ["AvoidContact"] = {7500, "eHeli_lineM_8"},
        ["DoNotTryToReachOut"] = {8000, "eHeli_lineM_9"},
        ["AnyCriminalActivity"] = {9500, "eHeli_lineM_10"},
        ["AnyPersonsTryingToLeave"] = {9500, "eHeli_lineM_6"},
    }
}

announcers["Gabby Female"] = {
    ["Lines"] = {
        ["PleaseReturnToYourHomes"] = {6750, "eHeli_lineF_1"},
        ["TheSituationIsUnderControl"] = {7200, "eHeli_lineF_2"},
        ["ThisAreaIsNowInQuarantine"] = {7500, "eHeli_lineF_3"},
        ["DoNotTryToLeaveTheArea"] = {7500, "eHeli_lineF_5"},
        ["LockAllEntrances"] = {7500, "eHeli_lineF_7"},
        ["AvoidContact"] = {6750, "eHeli_lineF_8"},
        ["DoNotTryToReachOut"] = {7750, "eHeli_lineF_9"},
        ["AnyCriminalActivity"] = {9750, "eHeli_lineF_10"},
        ["AnyPersonsTryingToLeave"] = {8500, "eHeli_lineF_6"},
    }
}

announcers["Jade Male A"] = {
    ["LineCount"] = 0,
    ["Lines"] = {
        ["ThisAreaIsUnderQuarantine"] = {9500*2, "eHeli_Jade_1a"},
        ["ForTheSafetyOfYourSelf"] = {10500*2, "eHeli_Jade_2a"},
        ["RepeatedAttemptsAtBreaching"] = {9250*2, "eHeli_Jade_3a"},
    }
}

announcers["Jade Male B"] = {
    ["Lines"] = {
        ["ThisAreaIsUnderQuarantine"] = {10500*2, "eHeli_Jade_1b"},
        ["ForTheSafetyOfYourSelf"] = {11500*2, "eHeli_Jade_2b"},
        ["RepeatedAttemptsAtBreaching"] = {9250*2, "eHeli_Jade_3b"},
    }
}

announcers["Jade Male C"] = {
    ["Lines"] = {
        ["ThisAreaIsUnderQuarantine"] = {10500*2, "eHeli_Jade_1c"},
        ["ForTheSafetyOfYourSelf"] = {11500*2, "eHeli_Jade_2c"},
        ["RepeatedAttemptsAtBreaching"] = {9250*2, "eHeli_Jade_3c"},
    }
}

announcers["FlyerChoppers"] = {
    ["LeaveOutOfRandomSelection"] = true,
    ["Lines"] = {
        ["FlyerChoppers"] = {10500*2, "eHeli_lineM_11"},
    }
}


announcers["Police"] = {
    ["LeaveOutOfRandomSelection"] = true,
    ["Lines"] = {
        ["PoliceLines"] = {8500, "eHeli_police_lines"},
    }
}

return AnnouncersAPI
