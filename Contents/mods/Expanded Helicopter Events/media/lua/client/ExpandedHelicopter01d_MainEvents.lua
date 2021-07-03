---Heli goes down
function eHelicopter:crash()

	if self.crashType then
		---@type IsoGridSquare

		local heliX, heliY, _ = self:getXYZAsInt()
		local currentSquare = getOutsideSquareFromAbove(getCell():getOrCreateGridSquare(heliX,heliY,0))

		if currentSquare and currentSquare:isSolidTrans() then
			--[DEBUG]] print("--- EHE: currentSquare is solid-trans")
			currentSquare = nil
		end
		--[DEBUG]] print("-- EHE: squares for crashing: "..tostring(currentSquare))
		if currentSquare then
			local vehicleType = self.crashType[ZombRand(1,#self.crashType+1)]
			---@type BaseVehicle
			local heli = addVehicleDebug("Base."..vehicleType, IsoDirections.getRandom(), nil, currentSquare)
			if heli then
				--drop package on crash
				if self.dropPackages then
					self:dropCarePackage(2)
				end
				--drop all items
				if self.dropItems then
					self:dropAllItems(4)
				end
				--[[DEBUG]] print("---- EHE: CRASH EVENT: HELI: "..self.ID..": "..vehicleType.."  "..currentSquare:getX()..", "..currentSquare:getY()..", "..currentSquare:getZ())
				self:spawnCrew()
				addSound(nil, currentSquare:getX(), currentSquare:getY(), 0, 250, 300)
				self:playEventSound("crashEvent")
				self:unlaunch()
				getGameTime():getModData()["DayOfLastCrash"] = math.max(1,getGameTime():getNightsSurvived())
				return true
			end
		end
	end
	return false
end


---Heli spawn crew
function eHelicopter:spawnCrew()
	if not self.crew then
		return
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
		if (type(outfitID) == "string") and (ZombRand(100) <= chance) then
			local heliX, heliY, _ = self:getXYZAsInt()
			--fuzz up the location
			local fuzzNums = {-5,-4,-3,-3,3,3,4,5}
			if heliX and heliY then
				heliX = heliX+fuzzNums[ZombRand(#fuzzNums)+1]
				heliY = heliY+fuzzNums[ZombRand(#fuzzNums)+1]
			end

			local bodyLoc = getOutsideSquareFromAbove(getCell():getOrCreateGridSquare(heliX,heliY,0))
			--if there is an actual location - IsoGridSquare may not be loaded in under certain circumstances
			if bodyLoc then
				local spawnedZombies = addZombiesInOutfit(bodyLoc:getX(), bodyLoc:getY(), bodyLoc:getZ(), 1, outfitID, femaleChance)
				---@type IsoGameCharacter | IsoZombie
				local zombie = spawnedZombies:get(0)
				--if there's an actual zombie
				if zombie then
					--33% to be dead on arrival
					if ZombRand(100) <= 33 then
						print("crash spawned: "..outfitID.." killed")
						zombie:setHealth(0)
					else
						--+1 because zombRand starts at 0
						local typeChange = ZombRand(6)+1
						--2/6 chance to be a crawler
						if typeChange >= 5 then
							print("crash spawned: "..outfitID.." crawler")
							zombie:setCanWalk(false)
							zombie:setBecomeCrawler(true)
							zombie:knockDown(true)
							--4/6 chance for normaltype zombie
						else
							print("crash spawned: "..outfitID)
						end
					end
				end
			end
		end
	end
end


---Heli drops all items
function eHelicopter:dropAllItems(fuzz)
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


---Heli drop items with chance
function eHelicopter:tryToDropItem(chance, fuzz)
	fuzz = fuzz or 0
	chance = (ZombRand(100) <= chance)
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


---Heli drop item
function eHelicopter:dropItem(type, fuzz)
	fuzz = fuzz or 0
	if self.dropItems then

		local heliX, heliY, _ = self:getXYZAsInt()
		if heliX and heliY then
			local range = 3+fuzz
			heliX = heliX+ZombRand(0-range,range)
			heliY = heliY+ZombRand(0-range,range)
		end
		local currentSquare = getOutsideSquareFromAbove(getCell():getOrCreateGridSquare(heliX,heliY,0))

		if currentSquare and currentSquare:isSolidTrans() then
			currentSquare = nil
		end

		if currentSquare then
			local _ = currentSquare:AddWorldInventoryItem("EHE."..type, 0, 0, 0)
		end
	end
end


---Heli drop carePackage
function eHelicopter:dropCarePackage(fuzz)
	fuzz = fuzz or 0
	local carePackage = self.dropPackages[ZombRand(1,#self.dropPackages+1)]

	local heliX, heliY, _ = self:getXYZAsInt()
	if heliX and heliY then
		local range = 3+fuzz
		heliX = heliX+ZombRand(0-range,range)
		heliY = heliY+ZombRand(0-range,range)
	end
	local currentSquare = getOutsideSquareFromAbove(getSquare(heliX, heliY, 0))

	if currentSquare and currentSquare:isSolidTrans() then
		currentSquare = nil
	end

	if currentSquare then
		--[DEBUG]] print("EHE: "..carePackage.." dropped: "..currentSquare:getX()..", "..currentSquare:getY())
		---@type BaseVehicle airDrop
		local airDrop = addVehicleDebug("Base."..carePackage, IsoDirections.getRandom(), nil, currentSquare)
		if airDrop then
			self:playEventSound("droppingPackage")
			self.dropPackages = false
			return airDrop
		end
	end
end

