---@param targetType string IsoZombie or IsoPlayer
function eHelicopter:lookForHostiles(targetType)

	local selfSquare = self:getIsoGridSquare()
	if not selfSquare then
		return
	end

	local timeStamp = getTimestampMs()
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


---@param targetHostile IsoObject|IsoMovingObject|IsoGameCharacter|IsoPlayer|IsoZombie
function eHelicopter:fireOn(targetHostile)

	self.lastAttackTime = getTimestampMs()

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
	self:playEventSound(eventSound)
	self:playEventSound("additionalAttackingSound")

	local ehX, ehY, _ = self:getXYZAsInt()
	--virtual sound event to attract zombies
	addSound(nil, ehX, ehY, 0, 250, 75)

	local chance = self.attackHitChance

	--IsoGameCharacter:getMoveSpeed() doesn't seem to work on IsoPlayers (works on IsoZombie)
	local getxsublx = math.abs(targetHostile:getX()-targetHostile:getLx())
	local getysubly = math.abs(targetHostile:getY()-targetHostile:getLy())
	local eheMoveSpeed = math.sqrt((getxsublx * getxsublx + getysubly * getysubly))
	--floors float to 1000ths place decimal
	eheMoveSpeed = math.floor(eheMoveSpeed * 1000) / 1000

	--convert eheMoveSpeed to a %
	local movementThrowOffAim = math.floor((100*eheMoveSpeed)+0.5)
	if instanceof(targetHostile, "IsoPlayer") then
		movementThrowOffAim = movementThrowOffAim*1.5
		chance = (chance/timesFiredOnSpecificHostile)
	elseif instanceof(targetHostile, "IsoZombie") then
		--allow firing on zombies more for shock value
		chance = (chance/(timesFiredOnSpecificHostile/2))
	end
	chance = chance-movementThrowOffAim


	if (targetHostile:getSquare():getTree()) or (targetHostile:checkIsNearWall()>0) then
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

	--[[DEBUG]] local hitReport = "-hit_report: "..self:heliToString(false)..--[[" n:"..eventSound.." t:"..]]timesFiredOnSpecificHostile..
			"  eMS:"..eheMoveSpeed.." %:"..chance.." "..tostring(targetHostile:getClass()) --]]

	if ZombRand(0, 101) <= chance then

		--apply swiss-cheesification (holes and blood)
		--bodyparts list has a length of 18 (0-17)
		local bpIndexNum = ZombRand(0, 17)
		--apply hole and blood
		local bpType = BodyPartType.FromIndex(bpIndexNum)
		local clothingBP = BloodBodyPartType.FromIndex(bpIndexNum)

		--[[DEBUG]] local preHealth = targetHostile:getHealth()
		--apply damage to body part
		local damage = (ZombRand(10,16) * self.attackDamage)/10

		if (bpType == BodyPartType.Neck) or (bpType == BodyPartType.Head) then
			damage = damage*4
		elseif (bpType == BodyPartType.Torso_Upper) then
			damage = damage*2
		end

		if instanceof(targetHostile, "IsoZombie") then
			--Zombies receive damage directly because they don't have body parts or clothing protection
			damage = damage*3
			targetHostile:setHealth(targetHostile:getHealth()-(damage/100))
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
				local bodyParts = bodyDMG:getBodyParts()
				if bodyParts then
					local actualBP = bodyParts:get(bpIndexNum)
					if actualBP then

						local protection = targetHostile:getBodyPartClothingDefense(bpIndexNum, false, true)/100
						damage = damage * (1-(protection*0.75))
						print("  EHE:[hit-dampened]: new damage:"..damage.." protection:"..protection)

						targetHostile:setHealth(targetHostile:getHealth()-(damage/100))
						bodyDMG:AddDamage(bpIndexNum,damage)
						actualBP:damageFromFirearm(damage)
					end
				end
			end
		end

		targetHostile:addHole(clothingBP)
		targetHostile:addBlood(clothingBP, true, true, true)

		--splatter a few times
		local splatIterations = ZombRand(1,3)
		for _=1, splatIterations do
			targetHostile:splatBloodFloor(0.9)
		end
		--[[DEBUG]] hitReport = hitReport .. "  [HIT] dmg:"..(damage/100).." hp:"..preHealth.." > "..targetHostile:getHealth()
	end
	--[[DEBUG]] print(hitReport)

	if self.addedFunctionsToEvents then
		local eventFunction = self.addedFunctionsToEvents["OnAttack"]
		if eventFunction then
			eventFunction(self, targetHostile)
		end
	end

	--fireImpacts
	self:playEventSound("attackImpacts", targetHostile:getSquare())
end


---@param targetType string IsoZombie or IsoPlayer or IsoGameCharacter
---@return table
function eHelicopter:attackScan(location, targetType)

	if not location then
		return {}
	end

	local fractalObjectsFound = getHumanoidsInFractalRange(location, self.attackScope, self.attackSpread, targetType)
	local objectsToFireOn = {}

	for fractalIndex=1, #fractalObjectsFound do
		local objectsArray = fractalObjectsFound[fractalIndex]

		if (not objectsToFireOn) or (#objectsArray > #objectsToFireOn) then
			objectsToFireOn = objectsArray
		end
	end

	return objectsToFireOn
end