local Utilities = require("EHEShared/Utilities");
local PresetAPI = require("EHEShared/Presets");
local AnnouncerAPI = require("EHEShared/Announcers");
local SpawnerAPI = require("EHEShared/SpawnerAPI");
local GlobalModData = require("EHEShared/GlobalModData");
local WeatherImpact = require("EHEShared/WeatherImpact");
local BodyPartSelection = require("EHEShared/BodyPartSelection");

local AllHelicopters = {};

---@class Helicopter
local Helicopter = {

    --ID must not be reset ever
    ---@field ID number
    ID = 0,

    ---@field forScheduling string|nil string used for scheduler; leaving it as nil means the event will not spawn from the scheduler
    forScheduling = false,

    ---@field schedulingFactor number multiplied against frequency to make them more or less likely - high number = more likely to be scheduled
    schedulingFactor = 1,

    ---@field eventSpawnWeight number This number is how many times this event is included in the scheduler's pool of events
    eventSpawnWeight = 10,

    ---@field eventStartDayFactor number This is number is multiplied against cutOffDay to act as when it will be able to spawn.
    eventStartDayFactor = 0,

    ---@field doNotListForTwitchIntegration
    doNotListForTwitchIntegration = false,

    ---@field ignoreNeverEnding
    ignoreNeverEnding = false,

    ---@field eventSpecialDates table table of specific in-game months/day tables; inGameDates/systemDates (table of tables)
    --- EXAMPLES: {{1,1}} = 1st month and 1st day only
    ---           {{1}} = Entire 1st Month
    ---           {{2}, {3,15}} = Entire 2nd month to 3rd Month 15th day.
    ---If no day is provided it is assumed to use the entire month
    eventSpecialDates = false, --example: { systemDates = {{1,1}}, inGameDates = {{2}, {3,15}}}

    ---@field eventCutOffDayFactor number This is multiplied against cutOffDay to act as the day this event no longer spawns
    eventCutOffDayFactor = 0.34,

    ---@field radioChatter string
    radioChatter = "AEBS_Choppah",

    ---@field flightHours table
    flightHours = {5, 22},

    ---@field hoverOnTargetDuration number|boolean How long the helicopter will hover over the player, this is subtracted from every tick
    hoverOnTargetDuration = false,

    ---@field searchForTargetDurationMS number How long the helicopter will search for last seen targets
    searchForTargetDuration = 30000,

    ---@field shadow boolean | WorldMarkers.GridSquareMarker
    shadow = true,

    ---@field shadowTexture string
    shadowTexture = "helicopter_shadow",

    ---@field eventMarkerIcon string
    eventMarkerIcon = "media/ui/helievent.png",

    ---@field crashType boolean
    crashType = {"UH1HFuselage"},

    ---@field addedCrashChance number
    addedCrashChance = 0,

    ---Useful for submodders seeking to add more functionality to events.
    ---Simply make your preset's table filled with the names of functions you want to call.
    ---NOTE: Presets' file must be loaded after any called function's file to work.
    ---If you want your event to occur only once simply set the entry to false afterwards.
    ---
    ---All functions called have the following arguments: self (eHelicopter)
    ---OnCrash has the additional argument of: currentSquare (IsoGridSquare)
    ---OnAttack has the additional argument of: targetHostile (IsoObject|IsoMovingObject|IsoGameCharacter|IsoPlayer|IsoZombie)
    ---@field addedFunctionsToEvents table
    addedFunctionsToEvents = {
        ["OnCrash"] = false,
        ["OnHover"] = false,
        ["OnFlyaway"] = false,
        ["OnAttack"] = false,
        ["OnSpawnCrew"] = false,
        ["OnArrived"] = false
    },

    ---@field scrapVehicles table
    scrapVehicles = {"UH1HTail"}, --{"Base.TYPE","Base.TYPE"}

    ---@field scrapItems table
    scrapItems = {"EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},

    ---@field crew table list of IDs and chances (similar to how loot distribution is handled)
    ---Example: crew = {"pilot", 100, "crew", 75, "crew", 50}
    ---If there is no number following a string a chance of 100% will be applied.
    crew = {"AirCrew", 100},

    ---@field formation table table of IDs to generate follower helis
    formationIDs = {},

    ---@field dropItems table
    dropItems = false,

    ---@field dropPackages table
    dropPackages = false,

    ---@field looperEventIDs table
    looperEventIDs = {["additionalFlightSound"]=true, ["flightSound"]=true},

    ---@field eventSoundEffects table
    eventSoundEffects = {
        ["hoverOverTarget"]="IGNORE",
        ["flyOverTarget"]="IGNORE",
        ["lostTarget"]="IGNORE",
        ["foundTarget"]="IGNORE",
        ["droppingPackage"]="IGNORE",
        ["additionalAttackingSound"]="IGNORE",
        ["additionalFlightSound"]="IGNORE",--LOOP
        ["soundAtEventOrigin"]="IGNORE",
        --
        ["attackSingle"] = "eHeli_machine_gun_fire_single",
        ["attackLooped"] = "eHeli_machine_gun_fire_looped",
        ["attackImpacts"] = "eHeli_fire_impact",
        ["flightSound"] = "eMiliHeli",--LOOP
        ["crashEvent"] = "eHelicopterCrash",
    },

    ---@field announcerVoice string
    announcerVoice = false,

    ---@field randomEdgeStart boolean
    randomEdgeStart = true,

    ---example: {["preset1"]=0,["preset2"]=25,["preset3"]=50} = at 0% (days out of cutoff day) preset1 is chosen, at 25% preset2 is chosen, etc.
    ---@field presetProgression table Table of presetIDs and corresponding % preset is compared to Days/CuttOffDay
    presetProgression = false,

    ---Example: {"preset1",2,"preset2","preset3",4} = a list equal to {"preset1","preset1","preset2","preset3","preset3","preset3","preset3"}
    ---@field presetRandomSelection table Table of presetIDs and optional corresponding weight (weight is 1 if none found) in list to be chosen from.
    presetRandomSelection = false,

    ---@field speed number
    speed = 1,

    ---@field topSpeedFactor number speed x this = top "speed"
    topSpeedFactor = 1.5,

    ---@field flightVolume number
    flightVolume = 75,

    ---@field hostilePreference string
    ---set to 'false' for *none*, otherwise has to be 'IsoPlayer' or 'IsoZombie' or 'IsoGameCharacter'
    hostilePreference = false,

    ---@field attackDelay number delay in milliseconds between attacks
    attackDelay = 60,

    ---@field attackScope number number of rows from "center" IsoGridSquare out
    --- **area formula:** ((Scope*2)+1) ^2
    ---
    --- scope:⠀0=1x1;⠀1=3x3;⠀2=5x5;⠀3=7x7;⠀4=9x9
    attackScope = 1,

    ---@field attackSpread number number of rows made of "scopes" from center-scope out
    ---**formula for ScopeSpread area:**
    ---
    ---((Scope * 2)+1) * ((Spread * 2)+1) ^2
    ---
    --- **Examples:**
    ---
    ---⠀  ⠀*scope* 🡇
    --- -----------------------------------
    --- *spread*⠀🡆 ⠀ | 00 | 01 | 02 | 03 |
    --- -----------------------------------
    --- ⠀  ⠀⠀⠀ ⠀| 00 | 01 | 09 | 25 | 49 |
    --- -----------------------------------
    --- ⠀  ⠀⠀⠀ ⠀| 01 | 09 | 81 | 225 | 441 |
    --- -----------------------------------
    --- ⠀  ⠀⠀⠀⠀  | 02 | 25 | 225 | 625 | 1225 |
    --- -----------------------------------
    --- ⠀  ⠀⠀⠀  ⠀| 03 | 49 | 441 | 1225 | 2401 |
    --- -----------------------------------
    attackSpread = 3,

    ---@field attackHitChance number multiplied against chance to hit in attacking
    attackHitChance = 85,

    ---@field attackDamage number damage dealt to zombies/players on hit (gets randomized to: attackDamage * random(1 to 1.5))
    attackDamage = 10,

    --the below variables are to be considered "temporary"
    ---@field updateTicksPassed number
    updateTicksPassed = 0,

    ---@field height number
    height = 7,

    ---@field state string
    state = false,

    ---@field crashing
    crashing = false,

    ---@field timeUntilCanAnnounce number
    timeUntilCanAnnounce = -1,

    ---@field preflightDistance number
    preflightDistance = false,

    ---@field lastAnnouncedLine string
    lastAnnouncedLine = false,

    ---@field heldEventSoundEffectEmitters table
    heldEventSoundEffectEmitters = {},

    ---@field placedEventSoundEffectEmitters table
    placedEventSoundEffectEmitters = {},

    ---@field delayedEventSounds table
    delayedEventSounds = {},

    ---@field target IsoObject
    target = false,

    ---@field trueTarget IsoGameCharacter
    trueTarget = false,

    ---@field timeSinceLastSeenTarget number
    timeSinceLastSeenTarget = -1,

    ---@field timeSinceLastRoamed number
    timeSinceLastRoamed = -1,

    ---@field attackDistance number
    attackDistance = false,

    ---@field targetPosition Vector3 "position" of target, pair of coordinates which can utilize Vector3 math
    targetPosition = false,

    ---@field lastMovement Vector3 consider this to be velocity (direction/angle and speed/step-size)
    lastMovement = false,

    ---@field currentPosition Vector3 consider this a pair of coordinates which can utilize Vector3 math
    currentPosition = false,

    ---@field lastAttackTime number
    lastAttackTime = -1,

    ---@field hostilesToFireOnIndex number
    hostilesToFireOnIndex = 0,

    ---@field hostilesToFireOn table
    hostilesToFireOn = {},

    ---@field hostilesAlreadyFiredOn table
    hostilesAlreadyFiredOn = {},

    ---@field lastScanTime number
    lastScanTime = -1,

    ---@field formationFollowingHelis table table of actual flying helis
    formationFollowingHelis = {},

    ---@field currentPresetID string
    currentPresetID = "<none>",

    ---@field masterPresetID string
    masterPresetID = false, --"<none>"

};

function Helicopter.GetAllHelicopters()
    return AllHelicopters;
end

function Helicopter.GetFreeHelicopter(preset)
	---@type eHelicopter heli
	local heli
	for _,h in ipairs(AllHelicopters) do
		if h.state == "unLaunched" then
			heli = h
			break
		end
	end

	if not heli then
		heli = Helicopter:new()
	end

	if preset then
		heli:loadPreset(preset)
	end

	return heli
end

function Helicopter:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self
	table.insert(AllHelicopters, o)
	o.ID = #AllHelicopters
	return o
end

function Helicopter:loadPreset(presetName)
	if not presetName then return; end

	local preset = PresetAPI.Get(presetName)
	local masterPresetName = presetName

	if not preset then return; end

	eventSoundHandler:stopAllHeldEventSounds(self)

	--[DEBUG]] print("\n------------[loadPreset:"..ID.."]------------")
	self:loadVarsFrom(eHelicopter_initialVars, "initialVars")

	if preset.inherit then
		for k,inheritedPresetID in pairs(preset.inherit) do
			local presetFound = PresetAPI.Get(inheritedPresetID)
			if presetFound then
				self:loadVarsFrom(presetFound, "presetInherited")
			end
		end
	end

	preset = self:recursivePresetCheck(preset, nil, masterPresetName)

	--reset other vars not included with initialVars
	self:loadVarsFrom(eHelicopter_temporaryVariables, "temporaryVars")

	for name,vars in pairs(PresetAPI.GetAll()) do
		if vars == preset then
			presetName = name
		end
	end

	self.currentPresetID = presetName
	self.masterPresetID = masterPresetName

	--[[DEBUG]
	print("=-=-=-=-=-=-=[Confirming]=-=-=-=-=-=-=-=")
	for var, _ in pairs(eHelicopter_initialVars) do print(" - "..var.." = "..tostring(self[var])) end
	for var, _ in pairs(eHelicopter_temporaryVariables) do print(" - "..var.." = "..tostring(self[var])) end
	print("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=")
	--]]
end

function Helicopter:loadVarsFrom(tableToLoadFrom, DEBUG_ID)
	--[DEBUG]] print("-- loadVarsFrom: "..DEBUG_ID)
	--[DEBUG]] local debugPrint = ""
	for var, value in pairs(tableToLoadFrom) do
		local newValue
		local ignore = ((var=="presetProgression") or (var=="presetRandomSelection") or (var=="inherit"))

		if not ignore then
			newValue = value
			--tables needs to be copied piece by piece to avoid direct references links
			if type(newValue) == "table" then
				--[DEBUG]] debugPrint = debugPrint..("--- "..var.." is a table (#"..#newValue.."); generating copy:\n")
				self[var] = Utilities.DeepCopyTable(newValue)
			else
				--[DEBUG]] debugPrint = debugPrint..("-- "..var..": "..tostring(newValue).."\n")
				self[var] = newValue
			end
		end
	end
	--[DEBUG]] if DEBUG_ID~="initialVars" and DEBUG_ID~="temporaryVars" then print(debugPrint) end
end

function Helicopter:randomSelectPreset(preset)
	local selection = preset.presetRandomSelection
	local pool = {}

	for key,entry in pairs(selection) do
		if type(entry) == "string" then
			local id = entry
			local iterations = 1
			local next = selection[key+1]
			if type(next) == "number" then
				iterations = next
			end

			for i=1, iterations do
				table.insert(pool, id)
			end
		end
	end

	local randomNum = ZombRand(#pool)+1
	local choice = pool[randomNum]

	if not choice then
		print(" -- ERR: No choice selected in randomSelectPreset")
		return preset
	end

	print(" -- randomSelectPreset:   pool size: "..#pool.."   choice: "..choice)

	return PresetAPI.Get(choice)
end

function Helicopter:progressionSelectPreset(preset)
	local pp = preset.presetProgression
	if pp then

		local globalModData = GlobalModData.Get()
        if globalModData then
            local DaysSinceApoc = globalModData.DaysBeforeApoc + getGameTime():getNightsSurvived()
            local startDay, cutOffDay = fetchStartDayAndCutOffDay(preset)
            local DaysOverCutOff = DaysSinceApoc/cutOffDay
            local presetIDTmp
            --run through presetProgression list
            for pID,pCutOff in pairs(pp) do
                --if progression % is less than DaysOverCutOff
                if pCutOff <= DaysOverCutOff then
                    --if there is no stored % or progression % > stored %
                    if (not presetIDTmp) or (presetIDTmp and (pCutOff > pp[presetIDTmp])) then
                        --store qualifying choice
                        presetIDTmp = pID
                    end
                end
            end
            if presetIDTmp then
                print(" -- progressionSelectPreset:  selection: "..presetIDTmp)
                return PresetAPI.Get(presetIDTmp)
            end
        end
	end
end

function Helicopter:recursivePresetCheck(preset, iteration, recursiveID)
    local allPresets = PresetAPI.GetAll();

	iteration = iteration or 0
	--Load preset vars
	self:loadVarsFrom(preset, "presetLoad:"..tostring(recursiveID))

	--[[DEBUG]] local rpcText
	if preset.presetRandomSelection then
		preset = self:randomSelectPreset(preset)
		local presetID
		for id,vars in pairs(allPresets) do
			if vars == preset then
				presetID = id
			end
		end
		self:loadVarsFrom(preset, "-- presetRand:"..tostring(presetID))
	end

	if preset.presetProgression then
		preset = self:progressionSelectPreset(preset)
		local presetID
		for id,vars in pairs(allPresets) do
			if vars == preset then
				presetID = id
			end
		end
		self:loadVarsFrom(preset, "-- presetProg:"..tostring(presetID))
	end

	if (preset.presetProgression or preset.presetRandomSelection) and (iteration < 4) then
		--[[DEBUG]] rpcText = rpcText.."\n -- EHE: progression/selection: found; recursive: "..iteration
		--[[DEBUG]] print(rpcText)
		local presetID
		for id,vars in pairs(allPresets) do
			if vars == preset then
				presetID = id
			end
		end
		return self:recursivePresetCheck(preset,iteration+1, presetID)
	end

	--[[DEBUG]] if iteration >= 4 then rpcText = rpcText.."\n -- EHE: ERR: progression/selection: high recursive iteration: "..iteration end
	--[[DEBUG]] if rpcText then print(rpcText) end

	return preset
end

function Helicopter:getXYZAsInt()
	if not self.currentPosition then return; end

	local ehX = math.floor(Vector3GetX(self.currentPosition) + 0.5)
	local ehY = math.floor(Vector3GetY(self.currentPosition) + 0.5)
	local ehZ = self.height

	return ehX, ehY, ehZ
end

function Helicopter:initPos(targetedPlayer, randomEdge, initX, initY)
	if not targetedPlayer then return; end

	setDynamicGlobalXY()

	--player's location
	local tpX = targetedPlayer:getX()
	local tpY = targetedPlayer:getY()

	--assign a random spawn point for the helicopter within a radius from the player
	--these values are being clamped to not go passed MIN_XY/MAX edges
	local offset = 500
	initX = initX or ZombRand(math.max(eheBounds.MIN_X, tpX-offset), math.min(eheBounds.MAX_X, tpX+offset)+1)
	initY = initY or ZombRand(math.max(eheBounds.MIN_Y, tpY-offset), math.min(eheBounds.MAX_Y, tpY+offset)+1)

	self.currentPosition = self.currentPosition or Vector3.new()

	if randomEdge then
		local initPosXY = {initX, initY}
		local minMax = {eheBounds.MIN_X, eheBounds.MIN_Y, eheBounds.MAX_X, eheBounds.MAX_Y}

		--pick X=1 or Y=2 position
		local randXYEdge = ZombRand(1, #initPosXY+1)

		--pick min=1,2 or max=3,4 (50% to be max)
		local randXYMinMax = randXYEdge
		if ZombRand(101) <= 50 then
			randXYMinMax = randXYMinMax+2
		end

		--[DEBUG]] print(" -- EHE: randomEdge:true; randXYEdge: "..randXYEdge.." randXYMinMax: "..randXYMinMax)
		--this sets either [1] or [2] of initPosXY as [1] through [4] of minMax
		initPosXY[randXYEdge] = minMax[randXYMinMax]

		self.currentPosition:set(initPosXY[1], initPosXY[2], self.height)
		return
	end

	--Looks for the closest edge to initX and initY to modify it to be along either eheBounds.MIN_X/Y/MAX_X/Y
	--differences between initX and eheBounds.MIN_X/Y/MAX_X/Y edge values
	local xDiffToMin = math.abs(initX-eheBounds.MIN_X)
	local xDiffToMax = math.abs(initX-eheBounds.MAX_X)
	local yDiffToMin = math.abs(initY-eheBounds.MIN_Y)
	local yDiffToMax = math.abs(initY-eheBounds.MAX_Y)
	--this list uses x/yDifftoMin/Max's values as keys storing their respective corresponding edges
	local xyDiffCorrespondingEdge = {[xDiffToMin]=eheBounds.MIN_X, [xDiffToMax]=eheBounds.MAX_X, [yDiffToMin]=eheBounds.MIN_Y, [yDiffToMax]=eheBounds.MAX_Y}
	--get the smallest of the four differences
	local smallestDiff = math.min(xDiffToMin,xDiffToMax,yDiffToMin,yDiffToMax)

	--if the smallest is a X local var then set initX to the closer edge
	if (smallestDiff == xDiffToMin) or (smallestDiff == xDiffToMax) then
		initX = xyDiffCorrespondingEdge[smallestDiff]
	else
		--otherwise, set initY to the closer edge
		initY = xyDiffCorrespondingEdge[smallestDiff]
	end

	self.currentPosition:set(initX, initY, self.height)
end

function Helicopter:getIsoGridSquare()
	local ehX, ehY, _ = self:getXYZAsInt()
	if not ehX or not ehY then return; end

	local square
	local cell = getCell()
	if cell then
		square = cell:getOrCreateGridSquare(ehX, ehY, 0)
	end
	return square
end

function Helicopter:isInBounds()
	local h_x, h_y, _ = self:getXYZAsInt()

	if h_x < eheBounds.MAX_X+1 and h_x > eheBounds.MIN_X-1 and h_y < eheBounds.MAX_Y+1 and h_y > eheBounds.MIN_Y-1 then
		return true
	end

	if self.state == "following" then
		--Ignore followers being out of bounds
		return true
	end
	
	--[[DEBUG]] print("- EHE: OUT OF BOUNDS: HELI: " .. self:heliToString(true))
	return false
end

function Helicopter:getDistanceToVector(vector)

	if (not vector) or (not self.currentPosition) then
		print("ERR: getDistanceToVector: no vector or no currentPosition")
		return
	end

	local a = Vector3GetX(vector) - Vector3GetX(self.currentPosition)
	local b = Vector3GetY(vector) - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end

function Helicopter:getDistanceToIsoObject(object)
	if (not object) or (not self.currentPosition) then
		print("ERR: getDistanceToIsoObject: no object or no currentPosition")
		return
	end

	local a = object:getX() - Vector3GetX(self.currentPosition)
	local b = object:getY() - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end

function Helicopter:dampen(movement)
	if self.state == "crashed" or self.state == "unLaunched" then
		return
	end
	self:setTargetPos()

	if not self.targetPosition or not self.preflightDistance then
		return movement
	end

	--finds the fraction of distance to target and preflight distance to target
	local distanceCompare = self:getDistanceToVector(self.targetPosition) / self.preflightDistance
	--clamp with a max of self.topSpeedFactor and min of 0.1 (10%) is applied to the fraction
	local dampenFactor = math.max(self.topSpeedFactor, math.min(0.025, distanceCompare))
	--this will slow-down/speed-up eHelicopter the closer/farther it is to the target
	local x_movement = Vector3GetX(movement) * dampenFactor
	local y_movement = Vector3GetY(movement) * dampenFactor

	return movement:set(x_movement,y_movement,self.height)
end

function Helicopter:setTargetPos()
	if not self.target then return; end
	local tx, ty, tz = self.target:getX(), self.target:getY(), 0

	if not self.targetPosition then
		self.targetPosition = Vector3.new(tx, ty, tz)
	else
		self.targetPosition:set(tx, ty, tz)
	end
end

function Helicopter:aimAtTarget()
	self:setTargetPos()

	if not self.targetPosition or not self.currentPosition then
		return
	end

	local movement_x = Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)
	local movement_y = Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)

	--difference between target's and current's x/y
	---@type Vector3 local_movement
	local local_movement = Vector3.new(movement_x,movement_y,0)
	--normalize (shrink) the difference
	local_movement:normalize()
	--multiply the difference based on speed
	local_movement:setLength(self.speed)

	return local_movement
end

function Helicopter:updatePosition(heliX, heliY)
	--The actual movement occurs here when the modified `velocity` is added to `self.currentPosition`
	self.currentPosition:set(heliX, heliY, self.height)
	eventSoundHandler:updatePos(self,heliX,heliY)
end

function Helicopter:move(re_aim, dampen)
	if self.state == "crashed" then return; end

	---@type Vector3
	local velocity

	if not self.lastMovement then
		re_aim = true
	end

	local storedSpeed = self.speed
	--if there's targets
	if #self.hostilesToFireOn > 1 then
		--slow speed down while shooting
		self.speed = math.min(self.speed/3, self.speed/#self.hostilesToFireOn)
		
	end

	if re_aim then
		velocity = self:aimAtTarget()

		if not self.lastMovement then
			self.lastMovement = Vector3.new(velocity)
		else
			self.lastMovement:set(velocity)
		end

	else
		velocity = self.lastMovement:clone()
	end

	if dampen then
		velocity = self:dampen(velocity)
	end

	--restore speed
	self.speed = storedSpeed

	--account for sped up time
	local timeSpeed = getGameSpeed()
	local v_x = Vector3GetX(self.currentPosition)+(Vector3GetX(velocity)*timeSpeed)
	local v_y = Vector3GetY(self.currentPosition)+(Vector3GetY(velocity)*timeSpeed)

	self:updatePosition(v_x, v_y)

	for heli,offsets in pairs(self.formationFollowingHelis) do
		---@type eHelicopter
		local followingHeli = heli
		if followingHeli then
			followingHeli:updatePosition(v_x+offsets[1], v_y+offsets[2])
		end
	end
	--self:Report(re_aim, dampen)
end

function Helicopter:findAlternativeTarget(character)
	if not character then return false; end

	local newTargets = {}
	local fractalCenters = Utilities.GetIsoRange(character, 1, 50)

	for _,square in pairs(fractalCenters) do
		---@type IsoCell
		local cellOfFC = square:getCell()
		if cellOfFC then
			--[DEBUG]] print(" ----- cell found for isoSquare diff: <"..k.."> x:"..math.floor(character:getX()-square:getX())..", y:"..math.floor(character:getY()-square:getY()))
			---Targeting buildings don't seem to return results
--[[
			local buildings = cellOfFC:getBuildingList()
			--print(" ------ buildings:size: "..buildings:size())
			for i=0, buildings:size()-1 do
				---@type IsoBuilding
				local isoBuilding = buildings:get(i)
				print(" ------- building?")
				if isoBuilding then
					print(" -------- building")
					local squareFromBuilding = isoBuilding:getFreeTile()
					print(" ------- square?")
					if squareFromBuilding then
						print(" -------- square")
						table.insert(newTargets,squareFromBuilding)
					end
				end
			end
--]]
			---target zombies instead
			if #newTargets <= 0 then
				local zombies = cellOfFC:getZombieList()
				if zombies then
					local zombiesSize = zombies:size()-1
					if zombiesSize > 0 then
						table.insert(newTargets,zombies:get(ZombRand(zombiesSize)))
					end
				end
			end

		end
	end

	if (#newTargets > 0) then
		local newTarget = newTargets[ZombRand(#newTargets)+1]
		return newTarget
	end

	local x, y = character:getX(), character:getY()

	local xOffset = ZombRand(55,80)
	local yOffset = ZombRand(55,80)

	if ZombRand(101) <= 50 then
		yOffset=0-yOffset
	end
	if ZombRand(101) <= 50 then
		yOffset=0-yOffset
	end

	local square = getCell():getOrCreateGridSquare(x+xOffset, y+yOffset, 0)

	if square then
		return square
	end

	return false
end

function Helicopter:findTarget(range, DEBUGID)
	--the -1 is to offset playerIDs starting at 0
	local weightPlayersList = {}
	local maxWeight = 15

	addActualPlayersToEIP()

	for character,_ in pairs(EHEIsoPlayers) do
		---@type IsoPlayer | IsoGameCharacter p
		local p = character
		--[DEBUG]] print("EHE: Potential Target:"..p:getFullName().." = "..tostring(value))
		if p and ((not range) or (self:getDistanceToIsoObject(p) <= range)) then

			local iterations = 7
			local zone = p:getCurrentZone()
			--[[DEBUG]] local DEBUGzoneID = "<none>"
			if zone then
				local zoneType = zone:getType()
				if zoneType then
					--[[DEBUG]] DEBUGzoneID = zoneType
					if (zoneType == "DeepForest") then
						iterations = 3
					elseif (zoneType == "Forest" or zoneType == "Vegitation") then
						iterations = 4
					elseif (zoneType == "FarmLand") then
						iterations = 6
					elseif (zoneType == "Farm") then
						iterations = 7
					elseif (zoneType == "TrailerPark" or zoneType == "Nav") then
						iterations = 9
					elseif (zoneType == "TownZone") then
						iterations = 10
					end
				end
			end

			for _=1, maxWeight do
				if iterations > 0 then
					iterations = iterations-1
					table.insert(weightPlayersList, p)
				else
					local altTarget = self:findAlternativeTarget(p)
					if altTarget then
						table.insert(weightPlayersList, altTarget)
					end
				end
			end
		end
	end

	if DEBUGID then
		DEBUGID = "["..DEBUGID.."]: "
	end

	local DEBUGallTargetsText = " -- "..DEBUGID.."HELI "..self:heliToString().." selecting targets <"..#weightPlayersList.."> x "

	--really convoluted printout method that counts repeated targets accordingly
	--[[DEBUG] if getDebug() then
		local DEBUGallTargets = {}
		for _,target in pairs(weightPlayersList) do
			if instanceof(target, "IsoPlayer") then
				local knownTarget =  DEBUGallTargets[target:getFullName()]
				if knownTarget then DEBUGallTargets[target:getFullName()] = DEBUGallTargets[target:getFullName()]+1
				else DEBUGallTargets[target:getFullName()] = 1 end
			elseif instanceof(target, "IsoZombie") then
				local zombieAlreadyTargeted = DEBUGallTargets["z"]
				if zombieAlreadyTargeted then DEBUGallTargets["z"] = DEBUGallTargets["z"]+1
				else DEBUGallTargets["z"] = 1 end
			else
				local unknownTarget =  DEBUGallTargets[tostring(target)]
				if unknownTarget then DEBUGallTargets[tostring(target)] = DEBUGallTargets[tostring(target)]+1
				else DEBUGallTargets[tostring(target)] = 1 end
			end
		end

		for targetID,numberOf in pairs(DEBUGallTargets) do
			DEBUGallTargetsText = DEBUGallTargetsText.."["..targetID.." x"..numberOf.."] "
		end

	end --]]

	print(DEBUGallTargetsText)

	local target
	if #weightPlayersList then
		target = weightPlayersList[ZombRand(1, #weightPlayersList+1)]
	end

	if not target then
		print(" --- HELI "..self:heliToString().."- WARN: unable to find target: grabbing random square nearby.")
		target = self:grabRandomSquareNearby(range)
		if not target then
			self:goHome()
			print(" ------ HELI "..self:heliToString().."- ERROR: unable to find square: going home.")
		end
		return
	end

	return target
end

function Helicopter:grabRandomSquareNearby(range)
	local x,y,z = self:getXYZAsInt()
	range = range or 25

	if not x or not y or not z then return; end

	local xShift = ZombRand(range/2, range+1)+1
	local yShift = ZombRand(range/2, range+1)+1

	if ZombRand(101) >= 50 then
		xShift = 0-xShift
	end
	if ZombRand(101) >= 50 then
		yShift = 0-yShift
	end

	local square = getSquare(x+xShift,y+yShift, 0)

	return square
end

function Helicopter:formationInit()
	if not self.formationIDs then return; end

	local h_x, h_y, _ = self:getXYZAsInt()

	local formationSize = 0
	--parse formationIDs for formation info, strings are IDs, following numbers are assumed values -- use false for skipped values
	for key,value in pairs(self.formationIDs) do

		if (type(value) == "string") and PresetAPI.Get(value) then

			--The chance this extra heli is spawned
			local chance = self.formationIDs[key+1] or 100
			--If the next entry in the list is a number consider it to be a chance, otherwise use 100%
			if type(chance) ~= "number" then
				chance = 100
			end

			local xyPosOffset = self.formationIDs[key+2] or {6, 12}
			--checks if entry 2 spaces after string (ID) is a table,
			if ((type(xyPosOffset) ~= "table")) or (#xyPosOffset < 2) or ((type(xyPosOffset[1]) ~= "number")) or ((type(xyPosOffset[2]) ~= "number")) then
				--fills in offsets is not enough or incorrect entries are present
				xyPosOffset = {6, 12}
			end

			--if new heli is spawned
			if (ZombRand(101) <= chance) then
				--track formation's current size
				formationSize = formationSize+1
				--multiply offset by formation size
				local heliX = ZombRand(xyPosOffset[1]*formationSize,xyPosOffset[2]*formationSize)
				local heliY = ZombRand(xyPosOffset[1]*formationSize,xyPosOffset[2]*formationSize)

				if (ZombRand(101) <= 50) then
					heliX = 0-heliX
				end
				if (ZombRand(101) <= 50) then
					heliY = 0-heliY
				end
				
				local newHeli = Helicopter.GetFreeHelicopter(value)
				newHeli.state = "following"
				newHeli.currentPosition = newHeli.currentPosition or Vector3.new()
				newHeli.currentPosition:set(h_x, h_y, newHeli.height)
				self.formationFollowingHelis[newHeli] = {heliX,heliY}
			end

		end
	end
end

function Helicopter:applyCrashChance(applyEnvironmentalCrashChance)
	local globalModData = GlobalModData.Get();
	--increase crash chance as the apocalypse goes on
	local startDay, cutOffDay = fetchStartDayAndCutOffDay(self)
	local eventFrequency = SandboxVars.ExpandedHeli["Frequency_"..self.masterPresetID] or 2

	--[DEBUG]] print("EHE: DEBUG: Crash Chance Freq: "..self.masterPresetID)

	if not cutOffDay then return; end

	local crashChance = self.addedCrashChance
	applyEnvironmentalCrashChance = applyEnvironmentalCrashChance or true

	if applyEnvironmentalCrashChance and globalModData then
		local _, weatherImpact = WeatherImpact.Get()
		local daysIntoApoc = globalModData.DaysBeforeApoc + getGameTime():getNightsSurvived()
		local apocImpact = (daysIntoApoc/cutOffDay)/10
		local dayOfLastCrash = globalModData.DayOfLastCrash
		local crashDayCap = 28
		local daysSinceCrashImpact = ((getGameTime():getNightsSurvived()-dayOfLastCrash)/crashDayCap)/2

		crashChance = self.addedCrashChance+((weatherImpact+apocImpact+daysSinceCrashImpact)*100)
		crashChance = math.min(100,math.floor(crashChance))
		crashChance = crashChance/(eventFrequency/2)

		--[DEBUG]] print(" ---- cutOffDay:"..cutOffDay.." | daysIntoApoc:"..daysIntoApoc .. " | apocImpact:"..apocImpact.." | weatherImpact:"..weatherImpact)
		--[DEBUG]] print(" ---- expectedMaxDaysWithOutCrash:"..expectedMaxDaysWithOutCrash)
		--[DEBUG]] print(" ---- dayOfLastCrash:"..dayOfLastCrash.." | daysSinceCrashImpact:"..math.floor(daysSinceCrashImpact))
	end

	if self.crashType and (not self.crashing) and (ZombRand(0,101) <= crashChance) then
		self.crashing = true
	end
	--[[DEBUG]] print(" --- "..self:heliToString().." crashChance:"..crashChance.." crashing:"..tostring(self.crashing))
end

function Helicopter:launch(targetedObject,blockCrashing)

	print(" - EHE: LAUNCH: "..self:heliToString().." day:"..getGameTime():getNightsSurvived().." hour:"..getGameTime():getHour())

	if not targetedObject then
		targetedObject = self:findTarget(nil, "launch")
	end

	if targetedObject then
		if instanceof(targetedObject, "IsoGameCharacter") then
			print(" -- Target: "..tostring(targetedObject)..": "..targetedObject:getFullName())
		else
			print(" -- Target: "..tostring(targetedObject)..": "..targetedObject:getX()..", "..targetedObject:getY())
		end
	end

	--sets target to a square near the player so that the heli doesn't necessarily head straight for the player
	local tpX = targetedObject:getX()
	local tpY = targetedObject:getY()

	if not targetedObject:isOutside() then
		tpX = tpX+ZombRand(-25,25)
		tpY = tpY+ZombRand(-25,25)
	end

	self.target = getCell():getOrCreateGridSquare(tpX, tpY, 0)
	--maintain trueTarget
	self.trueTarget = targetedObject
	--setTargetPos is a vector format of self.target
	self:setTargetPos()

	self:initPos(self.target, self.randomEdgeStart)
	self.preflightDistance = self:getDistanceToVector(self.targetPosition)

	self:formationInit()
	eventSoundHandler:playEventSound(self,"flightSound", nil, true)
	eventSoundHandler:playEventSound(self,"additionalFlightSound", nil, true)

	local currentSquare = self:getIsoGridSquare()
	eventSoundHandler:playEventSound(self,"soundAtEventOrigin", currentSquare, true, false)
	
	if self.hoverOnTargetDuration and type(self.hoverOnTargetDuration) == "table" then
		if #self.hoverOnTargetDuration >= 2 then
			self.hoverOnTargetDuration = ZombRand(self.hoverOnTargetDuration[1],self.hoverOnTargetDuration[2])
		else
			print("EHE: ERROR: "..self:heliToString().." -- hoverOnTargetDuration is table with less than 2 entries - nulling hover time.")
			self.hoverOnTargetDuration = false
		end
	end

	if not self.attackDistance then
		self.attackDistance = ((self.attackScope*2)+1)*((self.attackSpread*2)+1)
	end

	if self.announcerVoice ~= false then
		self:chooseVoice(self.announcerVoice)
	end

	self.state = "gotoTarget"

	if not blockCrashing then
		self:applyCrashChance()
	end

	for heli,_ in pairs(self.formationFollowingHelis) do
		---@type eHelicopter
		local followingHeli = heli
		if followingHeli then
			followingHeli.attackDistance = self.attackDistance
			local randSoundDelay = ZombRand(5,15)
			eventSoundHandler:playEventSound(followingHeli, "soundAtEventOrigin", currentSquare, true, false, randSoundDelay)
			eventSoundHandler:playEventSound(followingHeli, "flightSound", nil, true, false, randSoundDelay)
			eventSoundHandler:playEventSound(followingHeli, "additionalFlightSound", nil, true, false, randSoundDelay)
			if not blockCrashing then
				followingHeli:applyCrashChance()
			end
		end
	end
end

function Helicopter:goHome()
	self.state = "goHome"
	self.hoverOnTargetDuration = 0
	--set truTarget to target's current location -- this prevents changing course while flying away
	local selfSquare = self:getIsoGridSquare()

	if not selfSquare then
		print(" --- HELI "..self:heliToString()..": unable to go home; unlaunching.")
		self:unlaunch()
		return
	end

	self.trueTarget = selfSquare
	self.target = self.trueTarget
	self:setTargetPos()
	return selfSquare
end

function Helicopter:unlaunch()
	print(" ---- UN-LAUNCH: "..self:heliToString(true).." day:"..getGameTime():getNightsSurvived().." hour:"..getGameTime():getHour())

	eventSoundHandler:stopAllHeldEventSounds(self)

	if self.shadow==true then
		eventShadowHandler:setShadowPos(self.ID)
	end
	if self.eventMarkerIcon ~= false then
		eventMarkerHandler.setOrUpdate("HELI"..self.ID, self.eventMarkerIcon, 0)
	end

	self.state = "unLaunched"

	for heli,_ in pairs(self.formationFollowingHelis) do
		---@type eHelicopter
		local followingHeli = heli
		if followingHeli then
			followingHeli:unlaunch()
		end
	end
end

function Helicopter:hoverAndFlyOverReport(STATE)
	if self.trueTarget and self.trueTarget:getClass() and self.target and self.target:getClass() then
		print(" - "..self:heliToString(true).." "..STATE..(self.trueTarget:getClass():getSimpleName()).." "..(self.target:getClass():getSimpleName()))
	end
end

function Helicopter:Report(aiming, dampen)
	---@type eHelicopter heli
	local report = " a:"..tostring(aiming).." d:"..tostring(dampen).." "
	print(" > "..self:heliToString(true))
	print("   TARGET: (x:"..Utilities.Vector3GetX(self.targetPosition)..", y:"..Utilities.Vector3GetY(self.targetPosition)..")")
	print("   (dist: "..self:getDistanceToVector(self.target).."  "..report)
	print("-----------------------------------------------------------------")
end

function Helicopter:heliToString(location)
	local returnString = "HELI "..self.ID.." ("..self.currentPresetID..") ["..tostring(self.state).."]"
	if location then
		local h_x, h_y, _ = self:getXYZAsInt()
		if h_x and h_y then
			returnString = returnString.." (x:"..h_x..", y:"..h_y..")"
		else
			returnString = returnString.." (x:?, y:?)"
		end
	end
	return returnString
end

function Helicopter:update()
    if self.state == "following" then return; end

	if (self.state == "arrived" or self.state == "gotoTarget") and ((not self.target) or (not self.trueTarget)) then
		if (not self.target) then
			print(" - EHE: ERR: "..self:heliToString().." no target in update()")
		end
		if (not self.trueTarget) then
			print(" - EHE: ERR: "..self:heliToString().." no trueTarget in update()")
		end

		self.trueTarget = self:findTarget(self.attackDistance, "update")
		self.target = self.trueTarget
		self:setTargetPos()
		return
	end

	local timeStampMS = getGametimeTimestamp()
	local thatIsCloseEnough = ((self.topSpeedFactor*self.speed)*tonumber(getGameSpeed()))+4
	local distanceToTrueTarget = self:getDistanceToIsoObject(self.trueTarget)

	--if trueTarget is within range
	if distanceToTrueTarget and (distanceToTrueTarget <= (self.attackDistance*4)) then
		--if trueTarget is outside then sync targets
		if self.trueTarget:isOutside() then
			if (distanceToTrueTarget <= self.attackDistance*2) then
				if (self.target ~= self.trueTarget) then
					self.target = self.trueTarget
					eventSoundHandler:playEventSound(self, "foundTarget")
				end
				self.timeSinceLastSeenTarget = timeStampMS
			end
		else
			--prevent constantly changing targets during roaming
			if (self.timeSinceLastRoamed < timeStampMS) then
				self.timeSinceLastRoamed = timeStampMS+10000 --10 seconds

				--random offset used for roaming
				local offset = self.attackDistance
				if self.crashing then
					offset = math.floor(offset*(ZombRand(13,26)/10))
				end
				local randOffset = {-offset,offset}

				local tx = self.trueTarget:getX()
				--50% chance to offset x
				if ZombRand(1,101) <= 50 then
					--pick from randOffset, 50% negative or positive
					tx = tx+randOffset[ZombRand(1,#randOffset+1)]
				end
				local ty = self.trueTarget:getY()
				--50% chance to offset y
				if ZombRand(1,101) <= 50 then
					--pick from randOffset, 50% negative or positive
					tx = tx+randOffset[ZombRand(1,#randOffset+1)]
				end
				--set target to square from calculated offset
				self.target = getCell():getOrCreateGridSquare(tx,ty,0)
			end
		end

		--if trueTarget is not a gridSquare and timeSinceLastSeenTarget exceeds searchForTargetDuration set trueTarget to current target
		if self.state == "arrived" and (not instanceof(self.trueTarget, "IsoGridSquare")) and (self.timeSinceLastSeenTarget+self.searchForTargetDuration < timeStampMS) then
			self.trueTarget = self.target
			eventSoundHandler:playEventSound(self, "lostTarget")
		end

		if self.state == "arrived" and instanceof(self.trueTarget, "IsoGridSquare") and self.hoverOnTargetDuration and (self.timeSinceLastSeenTarget+self.searchForTargetDuration < timeStampMS) then
			local newTarget = self:findTarget(self.attackDistance*4, "retrackTarget")
			if newTarget and not instanceof(newTarget, "IsoGridSquare") then
				self.trueTarget = newTarget
			else
				--look again later
				self.timeSinceLastSeenTarget = timeStampMS+(self.searchForTargetDuration/5)
			end
		end

	end

	self:setTargetPos()
	local distToTarget = self:getDistanceToIsoObject(self.trueTarget)
	local crashDist = ZombRand(75,200)
	if self.crashing and distToTarget and (distToTarget <= crashDist) and (ZombRand(10)>0) then
		if self:crash() then
			--[[DEBUG]] print("EHE: crash: dist:"..math.floor(distToTarget).." ("..crashDist..")")
			return
		end
	end

	--[[
	---EVENTS SHOULD HIT A MAX TICK THRESHOLD (TAKING INTO ACCOUNT HOVER TIME) THEN GET "SENT HOME" IF STUCK
	self.updateTicksPassed = (self.updateTicksPassed+1)*getGameSpeed()
	local maxTicksAllowed = eheBounds.threshold*10
	if self.hoverOnTargetDuration and self.hoverOnTargetDuration > 0 then
		maxTicksAllowed = maxTicksAllowed+(self.hoverOnTargetDuration*10)
	end
	if (self.updateTicksPassed > maxTicksAllowed) and (self.state ~= "goHome") then
		print(" - EHE: Update Tick Cap Reached: "..self:heliToString())
		self:goHome()
	end
	-]]

	local preventMovement = false

	if (self.state == "gotoTarget") and (distToTarget <= thatIsCloseEnough*2.5) then
		self.state = "arrived"
		if self.addedFunctionsToEvents then
			local eventFunction = self.addedFunctionsToEvents["OnArrive"]
			if eventFunction then
				eventFunction(self)
			end
		end
	end

	if (self.state == "arrived" or self.state == "gotoTarget") and (distToTarget <= thatIsCloseEnough*1.5) then
		if self.hoverOnTargetDuration then

			if type(self.hoverOnTargetDuration)=="number" and self.hoverOnTargetDuration>0 then

				eventSoundHandler:playEventSound(self, "hoverOverTarget", nil, true)

				if self.addedFunctionsToEvents then
					local eventFunction = self.addedFunctionsToEvents["OnHover"]
					if eventFunction then
						--[[DEBUG]] if getDebug() then self:hoverAndFlyOverReport(" - HOVERING OVER TARGET") end
						eventFunction(self)
					end
				end

				--[DEBUG]] if getDebug() then print("self.hoverOnTargetDuration: "..self.hoverOnTargetDuration.." "..self:heliToString()) end

				self.hoverOnTargetDuration = self.hoverOnTargetDuration-math.max(1,(1*getGameSpeed()))
				if self.hoverOnTargetDuration <= 0 then
					self.hoverOnTargetDuration = false
				end
				preventMovement=true
			else
				self.hoverOnTargetDuration = false
			end
		else

			--[[DEBUG]
			if getDebug() then
				local debugTargetText = " (square)"
				if self.trueTarget then
					if instanceof(self.trueTarget, "IsoPlayer") then debugTargetText = " ("..self.trueTarget:getFullName()..")" end
					self:hoverAndFlyOverReport(" - FLEW OVER TARGET"..debugTargetText)
				end
			end
			--]]

			eventSoundHandler:playEventSound(self, "hoverOverTarget",nil, nil, true)
			eventSoundHandler:playEventSound(self, "flyOverTarget")

			if self.addedFunctionsToEvents then
				local eventFunction = self.addedFunctionsToEvents["OnFlyaway"]
				if eventFunction then
					eventFunction(self)
				end
			end

			self:goHome()
		end
	end

	local lockOn = true
	if self.state == "goHome" then
		lockOn = false
	end

	--if it's ok to move do so, and update the shadow's position
	if not preventMovement then
		self:move(lockOn, true)
	end

	if self.eventMarkerIcon ~= false then
		local hX, hY, _ = self:getXYZAsInt()
		eventMarkerHandler.setOrUpdate("HELI"..self.ID, self.eventMarkerIcon, 3, hX, hY)
	end

	if self.announcerVoice and (not self.crashing) and distToTarget and (distToTarget <= thatIsCloseEnough*1000) then
		self:announce()
	end

	self:updateSubFunctions(thatIsCloseEnough, distToTarget, timeStampMS)
	for heli,offsets in pairs(self.formationFollowingHelis) do
		---@type Helicopter
		local followingHeli = heli
		if followingHeli then
			followingHeli:updateSubFunctions(thatIsCloseEnough, distToTarget, timeStampMS)
		end
	end

	if not self:isInBounds() then
		self:unlaunch()
	end
end

function Helicopter:updateSubFunctions(thatIsCloseEnough, distToTarget, timeStampMS)
	local currentSquare = self:getIsoGridSquare()
	--Wake up (Wake up) / Grab a brush and put a little make-up
	for character,value in pairs(EHEIsoPlayers) do
		---@type IsoGameCharacter p
		local p = character
		if p:getSleepingTabletEffect() < 2000 then
			local distanceImpact = self.flightVolume*0.5
			if not p:isOutside() then
				distanceImpact = distanceImpact/2
			end

			if self:getDistanceToIsoObject(p) < distanceImpact then
				p:forceAwake()
			end
		end
	end

	eventSoundHandler:checkEventSounds(self)

	if thatIsCloseEnough and distToTarget then
		--drop carpackage
		local packageDropRange = ZombRand(50, 75)
		local packageDropRateChance = ZombRand(101) <= ((distToTarget/packageDropRange)*100)+10
		if self.dropPackages and packageDropRateChance and (distToTarget <= packageDropRange) then
			local drop = self:dropCarePackage()
			if drop then
				if self.hoverOnTargetDuration and self.hoverOnTargetDuration~=false and self.hoverOnTargetDuration>0 then
					self.trueTarget = currentSquare
					self:setTargetPos()
				end
			else
				if self.hoverOnTargetDuration ~= false then
					self.hoverOnTargetDuration = false
				end
			end
		end

		--drop items
		local itemDropRange = math.min(225,thatIsCloseEnough*225)
		if self.dropItems and (distToTarget <= itemDropRange) then
			local dropChance = ((itemDropRange-distToTarget)/itemDropRange)*10
			self:tryToDropItem(dropChance)
		end
	end

	--shadow
	if self.shadow==true then
		eventShadowHandler:setShadowPos(self.ID, self.shadowTexture, currentSquare:getX(),currentSquare:getY(),currentSquare:getZ())
	end

	if self.flightVolume>0 then
		local volumeFactor = 1
		local zoneType = currentSquare:getZoneType()
		if (zoneType == "Forest") or (zoneType == "DeepForest") then
			volumeFactor = 0.75
		end
		addSound(nil, currentSquare:getX(),currentSquare:getY(), 0, (self.flightVolume*2)*volumeFactor, self.flightVolume*volumeFactor)
	end

	if self.hostilePreference and (not self.crashing) then
		self:lookForHostiles(self.hostilePreference)
	end
end

function Helicopter:chooseVoice(specificVoice)
	local voiceSelectionOptions = {}

	if type(specificVoice) == "table" then
		voiceSelectionOptions = specificVoice
		specificVoice = false
	else
		for voiceID,voiceData in pairs(AnnouncerAPI.GetAll()) do
			if (not voiceData["LeaveOutOfRandomSelection"]) and (eHelicopterSandbox.config[voiceID] == true) then
				table.insert(voiceSelectionOptions,voiceID)
			end
		end
	end

	if (not specificVoice) or (specificVoice==true) then
		if #voiceSelectionOptions > 0 then
			local randAnn = ZombRand(1, #voiceSelectionOptions+1)
			specificVoice = voiceSelectionOptions[randAnn]
		end
	end

	if not specificVoice then
		print("EHE: ERR: Unable to initiate voice: "..specificVoice)
		self.announcerVoice = false
		return
	end
	self.announcerVoice = AnnouncerAPI.Get(specificVoice)
end

function Helicopter:announce(specificLine)
	if type(self.announcerVoice) == "boolean" then return; end

	local timeStamp = getTimeInMillis()
	if (self.timeUntilCanAnnounce > timeStamp) or (self.lastAttackTime > timeStamp) or (#self.hostilesToFireOn > 0) then
		return
	end

	if not specificLine then

		if self.announcerVoice and not self.announcerVoice["LineCount"] then
			local line_length = 0
			--for each entry in announcer's lines list
			if self.announcerVoice["Lines"] then
				for _,_ in pairs(self.announcerVoice["Lines"]) do
					line_length = line_length+1
				end
			end
			--line count is stored
			self.announcerVoice["LineCount"]=line_length
		end

		local ann_num = ZombRand(1,self.announcerVoice["LineCount"])

		for k,_ in pairs(self.announcerVoice["Lines"]) do
			ann_num = ann_num-1
			if ann_num <= 0 then
				specificLine = k
				break
			end
		end
	end

	local line = self.announcerVoice["Lines"][specificLine]
	local announcePick = line[ZombRand(2,#line+1)]
	local lineDelay = line[1]

	self.timeUntilCanAnnounce = timeStamp+lineDelay

	if self.lastAnnouncedLine then
		eventSoundHandler:playEventSound(self, self.lastAnnouncedLine,nil, nil, true)
	end
	self.lastAnnouncedLine = announcePick
	eventSoundHandler:playEventSound(self, announcePick)
end

function Helicopter:lookForHostiles(targetType)
	local selfSquare = self:getIsoGridSquare()
	if not selfSquare then return; end

	local timeStamp = getTimeInMillis()
	--too soon to attack again OR will overlap with an announcement
	if (self.lastAttackTime+self.attackDelay >= timeStamp) then
		return
	end

	--store numeration (length) of self.hostilesToFireOn
	local n = #self.hostilesToFireOn

	--clear entries that are too far
	for i=1, n do
		local hostile = self.hostilesToFireOn[i]
		local distanceTo = tonumber(hostile:getSquare():DistTo(selfSquare))
		--if hostile is too far set to nil
		if distanceTo > self.attackDistance then
			self.hostilesToFireOn[i] = nil
		end
	end
	--prepare new index for self.hostilesToFireOn
	local newIndex = 0
	--iterate through and overwrite nil entries
	for i=1, n do
		if self.hostilesToFireOn[i]~=nil then
			newIndex = newIndex+1
			self.hostilesToFireOn[newIndex]=self.hostilesToFireOn[i]
		end
	end
	--cut off end of list based on newIndex
	for i=newIndex+1, n do
		self.hostilesToFireOn[i]=nil
	end

	if self.lastScanTime <= timeStamp then
		self.lastScanTime = timeStamp+(self.attackDelay*2)
		--keep an eye out for new targets
		local scanningForTargets = self:attackScan(selfSquare, targetType)
		--if no more targets or newly scanned targets are greater size change target
		if (#self.hostilesToFireOn <=0) or (#scanningForTargets > self.hostilesToFireOnIndex) then
			--set targets
			self.hostilesToFireOn = scanningForTargets
			self.hostilesToFireOnIndex = #self.hostilesToFireOn
		end
	end

	--if there are hostiles identified
	if #self.hostilesToFireOn > 0 then
		--just grab the first target
		---@type IsoObject|IsoMovingObject|IsoGameCharacter hostile
		local hostile = self.hostilesToFireOn[1]
		self:fireOn(hostile)
		--remove target
		table.remove(self.hostilesToFireOn,1)
	end
end

function Helicopter:fireOn(targetHostile)
	self.lastAttackTime = getTimeInMillis()

	local timesFiredOnSpecificHostile = 0
	table.insert(self.hostilesAlreadyFiredOn, targetHostile)
	for _,v in pairs(self.hostilesAlreadyFiredOn) do
		if v == targetHostile then
			timesFiredOnSpecificHostile = timesFiredOnSpecificHostile+1
		end
	end

	--fireSound
	local eventSound = "attackSingle"
	if self.hostilesToFireOnIndex > 1 then
		eventSound = "attackLooped"
	end
	--determine location of helicopter
	eventSoundHandler:playEventSound(self, eventSound)
	eventSoundHandler:playEventSound(self, "additionalAttackingSound")

	local ehX, ehY, _ = self:getXYZAsInt()
	--virtual sound event to attract zombies
	addSound(nil, ehX, ehY, 0, 250, 75)

	local chance = self.attackHitChance
	local damage = (ZombRand(10,16) * self.attackDamage)/10

	--IsoGameCharacter:getMoveSpeed() doesn't seem to work on IsoPlayers (works on IsoZombie)
	local getxsublx = math.abs(targetHostile:getX()-targetHostile:getLx())
	local getysubly = math.abs(targetHostile:getY()-targetHostile:getLy())
	local hostileVelocity = math.sqrt((getxsublx * getxsublx + getysubly * getysubly))
	--floors float to 1000ths place decimal
	hostileVelocity = math.floor(hostileVelocity * 1000) / 1000

	--convert hostileVelocity to a %
	local movementThrowOffAim = math.floor((100*hostileVelocity)+0.5)

	if instanceof(targetHostile, "IsoPlayer") then
		movementThrowOffAim = movementThrowOffAim*1.5
		chance = (chance/(timesFiredOnSpecificHostile*2))
	elseif instanceof(targetHostile, "IsoZombie") then
		--allow firing on zombies more for shock value
		movementThrowOffAim = movementThrowOffAim/1.5
		chance = (chance/(timesFiredOnSpecificHostile/2))
	end
	chance = chance-movementThrowOffAim


	local targetSquare = targetHostile:getSquare()

	if (targetSquare:getTree()) then
		chance = (chance*0.8)
	end

	if instanceof(targetHostile, "IsoPlayer") then
		if targetHostile:isNearVehicle() then
			chance = (chance*0.8)
		end
		if (targetHostile:checkIsNearWall()>0) then
			chance = (chance*0.8)
		end
	end

	if targetHostile:getVehicle() then
		chance = (chance*0.6)
		damage = (damage*0.95)
	end

	if (targetSquare:isVehicleIntersecting()) then
		chance = (chance*0.8)
	end

	local zone = targetHostile:getCurrentZone()
	if zone then
		local zoneType = zone:getType()
		if zoneType and (zoneType == "Forest") or (zoneType == "DeepForest") then
			chance = (chance/2)
		end
	end

	--floor things off to a whole number
	chance = math.floor(chance)

	--[[DEBUG] local hitReport = "-hit_report: "..self:heliToString(false)..timesFiredOnSpecificHostile..
			"  eMS:"..hostileVelocity.." %:"..chance.." "..tostring(targetHostile:getClass()) --]]

	if ZombRand(0, 101) <= chance then

		local bpRandSelect = BodyPartSelection.GetRandom()
		local bpType = BodyPartType.FromString(bpRandSelect)
		local clothingBP = BloodBodyPartType.FromString(bpRandSelect)

		--[[DEBUG]] local preHealth = targetHostile:getHealth()
		--apply damage to body part

		if (bpType == BodyPartType.Neck) or (bpType == BodyPartType.Head) then
			damage = damage*4
		elseif (bpType == BodyPartType.Torso_Upper) then
			damage = damage*2
		end

		if instanceof(targetHostile, "IsoZombie") then
			--Zombies receive damage directly because they don't have body parts or clothing protection
			damage = damage*3
			targetHostile:knockDown(true)

		elseif instanceof(targetHostile, "IsoPlayer") then
			--Messy process just to knock down the player effectively
			targetHostile:clearVariable("BumpFallType")
			targetHostile:setBumpType("stagger")
			targetHostile:setBumpDone(false)
			targetHostile:setBumpFall(ZombRand(0, 101) <= 25)
			local bumpFallType = {"pushedBehind","pushedFront"}
			bumpFallType = bumpFallType[ZombRand(1,3)]
			targetHostile:setBumpFallType(bumpFallType)

			--apply localized body part damage
			local bodyDMG = targetHostile:getBodyDamage()
			if bodyDMG then
				local bodyPart = bodyDMG:getBodyPart(bpType)
				if bodyPart then
					local protection = targetHostile:getBodyPartClothingDefense(BodyPartType.ToIndex(bpType), false, true)/100
					damage = damage * (1-(protection*0.75))
					--print("  EHE:[hit-dampened]: new damage:"..damage.." protection:"..protection)

					bodyDMG:AddDamage(bpType,damage)
					bodyPart:damageFromFirearm(damage)
				end
			end
		end

		targetHostile:addHole(clothingBP)
		targetHostile:addBlood(clothingBP, true, true, true)
		targetHostile:setHealth(targetHostile:getHealth()-(damage/100))

		--splatter a few times
		local splatIterations = ZombRand(1,3)
		for _=1, splatIterations do
			targetHostile:splatBloodFloor()
		end
		--[DEBUG]] hitReport = hitReport .. "  [HIT] dmg:"..(damage/100).." hp:"..preHealth.." > "..targetHostile:getHealth()
	end
	--[DEBUG]] print(hitReport)

	if self.addedFunctionsToEvents then
		local eventFunction = self.addedFunctionsToEvents["OnAttack"]
		if eventFunction then
			eventFunction(self, targetHostile)
		end
	end

	--fireImpacts
	eventSoundHandler:playEventSound(self, "attackImpacts", targetHostile:getSquare())
end

function Helicopter:attackScan(location, targetType)
	if not location then return {}; end

	local fractalObjectsFound = Utilities.GetHumanoidsInFractalRange(location, self.attackScope, self.attackSpread, targetType)
	local objectsToFireOn = {}

	for fractalIndex=1, #fractalObjectsFound do
		local objectsArray = fractalObjectsFound[fractalIndex]

		if (not objectsToFireOn) or (#objectsArray > #objectsToFireOn) then
			objectsToFireOn = objectsArray
		end
	end

	return objectsToFireOn
end

function Helicopter:crash()

	if self.crashType then
		---@type IsoGridSquare

		if self.formationFollowingHelis then
			local newLeader
			for heli,offset in pairs(self.formationFollowingHelis) do
				if heli then
					newLeader = heli
					break
				end
			end
			if newLeader then
				newLeader.state = self.state
				self.formationFollowingHelis[newLeader] = nil
				newLeader.formationFollowingHelis = self.formationFollowingHelis
				self.formationFollowingHelis = {}
			end
		end

		local heliX, heliY, _ = self:getXYZAsInt()
		local vehicleType = self.crashType[ZombRand(1,#self.crashType+1)]

		local extraFunctions = {"applyCrashOnVehicle"}
		if self.addedFunctionsToEvents then
			local eventFunction = self.currentPresetID.."OnCrash"--self.addedFunctionsToEvents["OnCrash"]
			if eventFunction then
				table.insert(extraFunctions, eventFunction)
			end
		end

		SpawnerAPI.spawnVehicle(vehicleType, heliX, heliY, 0, extraFunctions, nil, "getOutsideSquareFromAbove_vehicle")

		self.crashType = false
		self.state = "crashed"
		--drop scrap and parts
		if self.scrapItems or self.scrapVehicles then
			self:dropScrap(6)
		end

		--drop package on crash
		if self.dropPackages then
			self:dropCarePackage(2)
		end

		--drop all items
		if self.dropItems then
			self:dropAllItems(4)
		end

		--[[DEBUG]] print("---- EHE: CRASH EVENT: HELI: "..self:heliToString(true)..":"..vehicleType.." day:" ..getGameTime():getNightsSurvived())
		self:spawnCrew()
		addSound(nil, heliX, heliY, 0, 250, 300)
		eventSoundHandler:playEventSound(self, "crashEvent")

		eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/crash.png", 180, heliX, heliY)

		self:unlaunch()

		local globalModData = getExpandedHeliEventsModData()
		globalModData.DayOfLastCrash = math.max(1,getGameTime():getNightsSurvived())
		return true
	end
	return false
end

function Helicopter:spawnCrew(x, y, z)
	if not self.crew then return; end

	local heliX, heliY, heliZ = self:getXYZAsInt()
	x = x or heliX
	y = y or heliY
	z = z or heliZ

	local onSpawnCrewEvents = {"applyDeathOrCrawlerToCrew"}
	local preset = PresetAPI.Get(self.currentPresetID)
	if preset then
		local presetFuncs = preset.addedFunctionsToEvents
		if presetFuncs then
			if presetFuncs.OnSpawnCrew then
				onSpawnCrewEvents = {self.currentPresetID.."OnSpawnCrew"}
			end
		end
	end

	for key,outfitID in pairs(self.crew) do

		--The chance this type of zombie is spawned
		local chance = self.crew[key+1]
		--If the next entry in the list is a number consider it to be a chance, otherwise use 100%
		if type(chance) ~= "number" then
			chance = 100
		end

		--NOTE: This is the chance the zombie will be female - 100% = female, 0% = male
		local femaleChance = self.crew[key+2]
		--If the next entry in the list is a number consider it to be a chance, otherwise use 50%
		if type(femaleChance) ~= "number" then
			femaleChance = 50
		end

		--assume all strings to be outfidID and roll chance/100
		if (type(outfitID) == "string") and (ZombRand(101) <= chance) then

			--fuzz up the location
			local fuzzNums = {-5,-4,-3,-3,3,3,4,5}
			if x and y then
				x = x+fuzzNums[ZombRand(#fuzzNums)+1]
				y = y+fuzzNums[ZombRand(#fuzzNums)+1]
			end

			SpawnerAPI.spawnZombie(outfitID, x, y, 0, onSpawnCrewEvents, femaleChance, "getOutsideSquareFromAbove")

		end
	end
	self.crew = false
end

function Helicopter:dropAllItems(fuzz)
	fuzz = fuzz or 0
	for itemType,quantity in pairs(self.dropItems) do

		local fuzzyWeight = {}
		if fuzz == 0 then
			fuzzyWeight = {0}
		else
			for i=1, fuzz do
				for ii=i, (fuzz+1)-i do
					table.insert(fuzzyWeight, i)
				end
			end
		end

		for i=1, self.dropItems[itemType] do
			self:dropItem(itemType,fuzz*fuzzyWeight[ZombRand(#fuzzyWeight)+1])
		end
		self.dropItems[itemType] = nil
	end
end

function Helicopter:tryToDropItem(chance, fuzz)
	fuzz = fuzz or 0
	chance = (ZombRand(101) <= chance)
	for itemType,quantity in pairs(self.dropItems) do
		if (self.dropItems[itemType] > 0) and chance then
			self.dropItems[itemType] = self.dropItems[itemType]-1
			self:dropItem(itemType,fuzz)
		end
		if (self.dropItems[itemType] <= 0) then
			self.dropItems[itemType] = nil
		end
	end
end

function Helicopter:dropItem(type, fuzz)
	if not self.dropItems then return; end

	fuzz = fuzz or 0

	local heliX, heliY, _ = self:getXYZAsInt()
	if heliX and heliY then
		local min, max = 0-3-fuzz, 3+fuzz
		heliX = heliX+ZombRand(min,max)
		heliY = heliY+ZombRand(min,max)
	end

	SpawnerAPI.spawnItem(type, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
end

function Helicopter:dropCarePackage(fuzz)
	if not self.dropPackages then return; end
    
	fuzz = fuzz or 0

	local carePackage = self.dropPackages[ZombRand(1,#self.dropPackages+1)]
	local carePackagesWithOutChutes = {["FEMASupplyDrop"]=true}

	local heliX, heliY, _ = self:getXYZAsInt()
	if heliX and heliY then
		local minX, maxX = 2, 3+fuzz
		if ZombRand(1, 101) <= 50 then
			minX, maxX = -2, 0-(3+fuzz)
		end
		heliX = heliX+ZombRand(minX,maxX+1)
		local minY, maxY = 2, 3+fuzz
		if ZombRand(1, 101) <= 50 then
			minY, maxY = -2, 0-(3+fuzz)
		end
		heliY = heliY+ZombRand(minY,maxY+1)
	end

	local extraFunctions = {}
	if carePackagesWithOutChutes[carePackage]~=true then
		table.insert(extraFunctions, "applySoundToEvent")
	end

	SpawnerAPI.spawnVehicle(carePackage, heliX, heliY, 0, extraFunctions, nil, "getOutsideSquareFromAbove_vehicle")
	--[[DEBUG]] print("EHE: "..carePackage.." dropped: "..heliX..", "..heliY)
	eventSoundHandler:playEventSound(self, "droppingPackage")
	addSound(nil, heliX, heliY, 0, 200, 150)
	eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/airdrop.png", 180, heliX, heliY)
	self.dropPackages = false
	return true
end

function Helicopter:dropScrap(fuzz)
	fuzz = fuzz or 0

	local heliX, heliY, _ = self:getXYZAsInt()

	for key,partType in pairs(self.scrapItems) do
		if type(partType) == "string" then

			local iterations = self.scrapItems[key+1]
			if type(iterations) ~= "number" then
				iterations = 1
			end

			for i=1, iterations do
				if heliX and heliY then
					local minX, maxX = 2, 3+fuzz
					if ZombRand(101) <= 50 then
						minX, maxX = -2, 0-(3+fuzz)
					end
					heliX = heliX+ZombRand(minX,maxX)
					local minY, maxY = 2, 3+fuzz
					if ZombRand(101) <= 50 then
						minY, maxY = -2, 0-(3+fuzz)
					end
					heliY = heliY+ZombRand(minY,maxY)
				end

				SpawnerAPI.spawnItem(partType, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
			end
		end
	end

	for key,partType in pairs(self.scrapVehicles) do
		if type(partType) == "string" then

			local iterations = self.scrapVehicles[key+1]
			if type(iterations) ~= "number" then
				iterations = 1
			end

			for i=1, iterations do
				if heliX and heliY then
					local minX, maxX = 2, 3+fuzz
					if ZombRand(101) <= 50 then
						minX, maxX = -2, 0-(3+fuzz)
					end
					heliX = heliX+ZombRand(minX,maxX)
					local minY, maxY = 2, 3+fuzz
					if ZombRand(101) <= 50 then
						minY, maxY = -2, 0-(3+fuzz)
					end
					heliY = heliY+ZombRand(minY,maxY)
				end

				SpawnerAPI.spawnVehicle(partType, heliX, heliY, 0, nil, nil, "getOutsideSquareFromAbove")
			end
		end
	end

	self.scrapItems = false
	self.scrapVehicles = false
end

return Helicopter;