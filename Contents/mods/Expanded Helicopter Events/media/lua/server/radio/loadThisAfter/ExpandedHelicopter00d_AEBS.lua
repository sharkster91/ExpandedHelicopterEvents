require "radio/ISWeatherChannel"
require "ExpandedHelicopter00f_WeatherImpact"

local PresetAPI = require("EHEShared/Presets");
local WeatherImpact = require("EHEShared/WeatherImpact");

---stores and adds on to functions found in /media/lua/server/radio/ISWeatherChannel.lua
local EHE_WeatherChannel_FillBroadcast = WeatherChannel.FillBroadcast or nil
function WeatherChannel.FillBroadcast(_gametime, _bc)
	--call stored version from above using the same arguments
	if EHE_WeatherChannel_FillBroadcast then
		EHE_WeatherChannel_FillBroadcast(_gametime, _bc)
	end
	
	local c = { r=1.0, g=1.0, b=1.0 }
	--check if flights would be prevented due to weather
	local willFly,_ = WeatherImpact.Get()
	if willFly then
		--table of radio lines to send out - given keys to prevent repetitive lines
		local linesGoingOut = {}
		WeatherChannel.AddFuzz(c, _bc, 6);

		local globalModData = getExpandedHeliEventsModData()
		if globalModData.EventsOnSchedule then
			for _,event in pairs(globalModData.EventsOnSchedule) do
				if (not event.triggered) and (event.startDay <= getGameTime():getNightsSurvived()) then
					--pulls event's info to see if more lines can be added
					local presetID = event.preset
					local radioChatter = eHelicopter.radioChatter
					local preset = PresetAPI.Get(presetID);
					if preset and preset.radioChatter then
						radioChatter = preset.radioChatter
					end
					linesGoingOut.presetID = getRadioText(radioChatter)
				end
			end
		end
		
		for _,line in pairs(linesGoingOut) do
			_bc:AddRadioLine(RadioLine.new(line, c.r, c.g, c.b))
		end
		WeatherChannel.AddFuzz(c, _bc);
	end
end
