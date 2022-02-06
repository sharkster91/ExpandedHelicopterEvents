
local WeatherImpact = {};

function WeatherImpact.Get()
    local CM = getClimateManager()

	local willFly = true
	local impactOnFlightSafety = 0

	local wind = CM:getWindIntensity()
	local fog = CM:getFogIntensity()
	local rain = CM:getRainIntensity()/2
	local snow = CM:getSnowIntensity()/2
	local thunder = CM:getIsThunderStorming()

	if (wind+rain+snow > 1.1) or (fog > 0.33) or (thunder == true) then
		willFly = false
	end

	impactOnFlightSafety = math.floor(((wind+rain+snow+(fog*3))/6)+0.5)

	return willFly, impactOnFlightSafety
end

return WeatherImpact;
