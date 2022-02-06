local Helicopter = require("EHEShared/Helicopter");
local EventScheduler = require("EHEShared/EventScheduler");

Events.OnGameBoot.Add(print(require("EHEShared/Version")));

-- INITIALIZATION

local function initialize()
	Events.OnTick.Remove(initialize);

	-- Start Event Scheduler on server
	EventScheduler.Init();
end
Events.OnTick.Add(initialize);

-- UPDATE

local lastUpdateAllHelicopters = 0
local function update()

	-- Update EventScheduler
	EventScheduler.EveryHour();

	-- Update All Helicopter on server
	lastUpdateAllHelicopters = lastUpdateAllHelicopters + getGameTime():getMultiplier()
	if (lastUpdateAllHelicopters >= 5) then
		lastUpdateAllHelicopters = 0
		for _,helicopter in ipairs(Helicopter.GetAllHelicopters()) do
			---@type eHelicopter heli
			local heli = helicopter

			if heli and heli.state and (not (heli.state == "unLaunched")) and (not (heli.state == "following")) then
				heli:update()
			end
		end
	end

end
Events.OnTick.Add(update)
