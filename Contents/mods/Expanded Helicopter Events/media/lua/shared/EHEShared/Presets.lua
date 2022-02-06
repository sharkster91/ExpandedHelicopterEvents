--[[
	To create preset from an other mod
	
	local EHEPresetAPI = require("EHEShared/Presets");
	
	EHEPresetAPI.AddOrReplace("MyNewPresetName", {
		
	});

]]--

local presets = {}; -- local db

local PresetAPI = {}; -- Exported API Object

-- API method to get all presets
function PresetAPI.GetAll()
    return presets;
end

-- API method to get an preset by name
function PresetAPI.Get(name)
    return presets[name];
end

-- API method to add an preset by name
function PresetAPI.AddOrReplace(name, data)
    if type(data) == "table" then
        presets[name] = data;
        return presets[name];
    end
end

-- API method to remove an preset by name
function PresetAPI.Remove(name)
    presets[name] = nil;
end

-- Default Presets included with this mod

presets["military"] = {
	presetRandomSelection = {"increasingly_hostile",3,"increasingly_helpful",1},
	announcerVoice = true,
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	forScheduling = true,
	eventSpawnWeight = 20,
	schedulingFactor = 1.5,
}

presets["increasingly_hostile"] = {
	presetProgression = {
		["patrol_only"] = 0,
		["patrol_only_emergency"] = 0.0066,
		["patrol_only_quarantine"] = 0.0165,
		["attack_only_undead_evac"] = 0.033,
		["attack_only_undead"] = 0.066,
		["attack_only_all"] = 0.2145,
	}
}

presets["increasingly_helpful"] = {
	presetProgression = {
		["patrol_only"] = 0,
		["patrol_only_emergency"] = 0.0066,
		["patrol_only_quarantine"] = 0.0165,
		["attack_only_undead_evac"] = 0.033,
		["aid_helicopter"] = 0.066,
		["attack_only_all"] = 0.2145,
	}
}

presets["patrol_only"] = {
	inherit = {"military"},
}

-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
presets["patrol_only_emergency"] = {
	inherit = {"military"},
	dropItems = {["EHE.EmergencyFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"patrol_only_emergency", 25, {20,25}, "patrol_only_emergency", 10, {20,25}},
}

presets["patrol_only_quarantine"] = {
	inherit = {"military"},
	dropItems = {["EHE.QuarantineFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"patrol_only_quarantine", 25, {20,25}, "patrol_only_quarantine", 10, {20,25}},
}

presets["attack_only_undead_evac"] = {
	announcerVoice = false,
	inherit = {"military"},
	hostilePreference = "IsoZombie",
	dropItems = {["EHE.EvacuationFlyer"]=250},
	formationIDs = {"attack_only_undead_evac", 25, {20,25}, "attack_only_undead_evac", 10, {20,25}},--"air_raid",
}

presets["attack_only_undead"] = {
	inherit = {"military"},
	announcerVoice = false,
	hostilePreference = "IsoZombie",
	formationIDs = {"attack_only_undead", 25, {12,17}, "attack_only_undead", 10, {12,17}},--"air_raid",
}

presets["aid_helicopter"] = {
	inherit = {"military"},
	announcerVoice = false,
	crashType = {"UH1HMedevacFuselage"},
	hoverOnTargetDuration = 500,
	dropPackages = {"FEMASupplyDrop"},
	dropItems = {["EHE.NoticeFlyer"]=250},
	speed = 0.9,
	scrapItems = {"EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH1HMedevacTail"},
	eventSoundEffects = {
		["foundTarget"] = "eHeli_AidDrop_2",
		["droppingPackage"] = "eHeli_AidDrop_1and3",
	},
	formationIDs = {"patrol_only", 25, {12,17}, "patrol_only", 10, {12,17}},
	radioChatter = "AEBS_SupplyDrop",
}

presets["attack_only_all"] = {
	inherit = {"military"},
	announcerVoice = false,
	hostilePreference = "IsoGameCharacter",
	scrapItems = {"EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH1HTail"},
	--formationIDs = {"air_raid"},
}

presets["jet"] = {
	speed = 18,
	topSpeedFactor = 2,
	flightVolume = 25,
	eventSoundEffects = {["flightSound"] = "eJetFlight"},
	crashType = false,
	shadow = false,
	eventMarkerIcon = "media/ui/jet.png",
	forScheduling = true,
	schedulingFactor = 4,
	eventSpawnWeight = 5,
	radioChatter = "AEBS_JetPass",
}

presets["air_raid"] = {
	doNotListForTwitchIntegration = true,
	crashType = false,
	shadow = false,
	speed = 0.5,
	topSpeedFactor = 3,
	flightVolume = 0,
	eventSoundEffects = {["flightSound"]="IGNORE",["soundAtEventOrigin"] = "eAirRaid"},
	eventMarkerIcon = false,
	forScheduling = true,
	flightHours = {11, 11},
	eventSpawnWeight = 50,
	schedulingFactor = 99999,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.067,
	ignoreNeverEnding = true,
	radioChatter = "AEBS_AirRaid",
}

presets["jet_bombing"] = {
	doNotListForTwitchIntegration = true,
	speed = 18,
	topSpeedFactor = 2,
	flightVolume = 25,
	eventSoundEffects = {["flightSound"] = "eJetFlight", ["soundAtEventOrigin"] = "eCarpetBomb"},
	crashType = false,
	shadow = false,
	eventMarkerIcon = "media/ui/jet.png",
	forScheduling = true,
	flightHours = {12, 12},
	eventSpawnWeight = 50,
	schedulingFactor = 99999,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.067,
	ignoreNeverEnding = true,
	radioChatter = "AEBS_JetBombing",
}

presets["news_chopper"] = {
	presetRandomSelection = {"news_chopper_hover", 1, "news_chopper_fleeing", 2, },
	eventSoundEffects = { ["additionalFlightSound"] = "eHeli_newscaster", ["flightSound"] = "eHelicopter", },
	speed = 1,
	crew = {"EHECivilianPilot", "EHENewsReporterVest", "EHENewsReporterVest", 40},
	crashType = {"Bell206LBMWFuselage"},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206LBMWTail"},
	forScheduling = true,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	radioChatter = "AEBS_UnauthorizedEntryNews",
}

presets["news_chopper_hover"] = {
	inherit = {"news_chopper"},
	hoverOnTargetDuration = {750,1200},
}

presets["news_chopper_fleeing"] = {
	inherit = {"news_chopper"},
	speed = 1.6,
}

presets["police"] = {
	presetRandomSelection = {"police_heli_emergency",3, "police_heli_firing",2},
	crashType = {"Bell206PoliceFuselage"},
	crew = {"EHEPolicePilot", "EHEPoliceOfficer", "EHEPoliceOfficer", 75},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206PoliceTail"},
	announcerVoice = "Police",
	forScheduling = true,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	radioChatter = "AEBS_UnauthorizedEntryPolice",
}

presets["police_heli_emergency"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["additionalFlightSound"] = "eHeliPoliceEmergencyWarning",
		["flightSound"] = "eHelicopter",
	},

}

presets["police_heli_firing"] = {
	inherit = {"police"},
	attackDelay = 1700,
	attackSpread = 4,
	speed = 1.0,
	attackHitChance = 95,
	attackDamage = 12,
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["attackSingle"] = "eHeliM16GunfireSingle",
		["attackLooped"] = "eHeliM16GunfireSingle",
		["additionalFlightSound"] = "eHeliPoliceSiren",
		["flightSound"] = "eHelicopter",
	},
	hoverOnTargetDuration = {375,575},
}

presets["samaritan_drop"] = {
	crashType = false,
	crew = {"EHESurvivorPilot", 100, 0},
	dropPackages = {"SurvivorSupplyDrop"},
	speed = 1.0,
	eventSoundEffects = {["flightSound"] = "ePropPlane"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	eventSpawnWeight = 3,
	radioChatter = "AEBS_SamaritanDrop"
}

presets["survivor_heli"] = {
	speed = 1.5,
	crashType = {"Bell206SurvivalistFuselage"},
	crew = {"EHESurvivorPilot", 100, 0, "EHESurvivor", 100, 0, "EHESurvivor", 75, 0},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206SurvivalistTail"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_SurvivorHeli",
}

presets["raiders"] = {
	presetRandomSelection = {"raider_heli_passive",3,"raider_heli_harasser",1},
	speed = 2.0,
	crashType = {"UH1HRaiderFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10,},
	scrapVehicles = {"UH1HRaiderTail"},
	addedFunctionsToEvents = {["OnFlyaway"] = "helicopterDropTrash"},
	crew = {"EHERaiderPilot", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaiderLeader", 75, 0},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_Raiders",
}

presets["raider_heli_passive"] = {
	inherit = {"raiders"},
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
	},
}

presets["raider_heli_harasser"] = {
	inherit = {"raiders"},
	hoverOnTargetDuration = {1250,1500},
	attackDelay = 1700,
	attackSpread = 4,
	attackHitChance = 40,
	attackDamage = 70,
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
		["attackSingle"] = "eHeliM16GunfireSingle",
		["attackLooped"] = "eHeliM16GunfireSingle",
		["additionalFlightSound"] = "eHeliMusicAggressive",
	},
}

return PresetAPI;
