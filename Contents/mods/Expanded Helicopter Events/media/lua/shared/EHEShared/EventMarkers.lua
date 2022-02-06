local Utilities = require("EHEShared/Utilities");

local EventMarkers = {};

local markers = {};
local expirations = {};

function EventMarkers.SetOrUpdate(eventID, icon, duration, posX, posY, override)
	if eHelicopterSandbox.config.eventMarkersOn == false then return; end

	--print("eventMarker: eventID:"..tostring(eventID).." icon:"..tostring(icon).." duration:"..tostring(duration).." posX:"..tostring(posX).." posY:"..tostring(posY).." override:"..tostring(override))
	if not override and isClient() then
        local data = {
            eventID=eventID, 
            icon=icon, 
            duration=duration, 
            posX=posX, 
            posY=posY
        };
        Utilities.SendCommandToServer("EventMarkers", "SetOrUpdate", data);
	else
		for p=1, getNumActivePlayers() do
			local player = getSpecificPlayer(p-1)
			if player then

				--print(" - player:"..player:getUsername())
				markers[player] = markers[player] or {}
				expirations[player] = expirations[player] or {}

				local marker = markers[player][eventID]
				expirations[player][eventID] = getGametimeTimestamp()+duration

				if not marker and duration>0 then

					if EHE_EventMarker then

						local dist = IsoUtils.DistanceTo(posX, posY, player:getX(), player:getY())
						if dist and (dist <= EHE_EventMarker.maxRange) then
							--print(" -- not marker: generating")
							local oldX
							local oldY
							local pModData = player:getModData()["EHE_eventMarkerPlacement"]
							if pModData then
								oldX = pModData[1]
								oldY = pModData[2]
							end
							local screenX = oldX or (getCore():getScreenWidth()/2) - (EHE_EventMarker.iconSize/2)
							local screenY = oldY or (EHE_EventMarker.iconSize/2)
							--print("eventMarkerHandler: generateNewMarker: "..p:getUsername().." ".."("..screenX..","..screenY..")")

							marker = EHE_EventMarker:new(eventID, icon, duration, posX, posY, player, screenX, screenY)
							markers[player][eventID] = marker
						else
							--print("-- dist not valid: "..tostring(dist))
						end
					else
						print("EHE: ERR: EHE_EventMarker not found: ".."  isClient:"..tostring(isClient()).." isServer:"..tostring(isServer()) )
					end
				end

				if marker then
					--print(" --- marker given duration")
					marker.textureIcon = getTexture(icon)
					marker:setDuration(duration)
					marker:update(posX,posY)
				end
			end
		end
	end
end

return EventMarkers;
