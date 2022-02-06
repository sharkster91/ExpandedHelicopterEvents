
--[[
    Utilities Method that doesn't depend on anything.
    They are used to do specific stuff that will be used in other codes.

    local Utilities = require("EHEShared/Utilites");
]]--

local Json = require("EHEShared/Json");

local Utilities = {};

-- Deep copy a lua table
function Utilities.DeepCopyTable(tableToCopy)
	local newTable = copyTable(tableToCopy); -- copyTable java code seem to deep copy already now
	return newTable;
end

-- Split a string
function Utilities.SplitString(str, delimiter)
    local result = {}
    for match in (str..delimiter):gmatch("(.-)%"..delimiter) do
        table.insert(result, match)
    end
    return result;
end

-- Get a unique string id from a position coordinates
function Utilities.PositionToId(x, y, z)
	return x .. "|" .. y .. "|" .. z
end

-- Get a unique string id from a square
function Utilities.SquareToId(square)
    return square:getX() .. "|" .. square:getY() .. "|" .. square:getZ()
end

-- Get a square from it's unique string id
function Utilities.IdToSquare(stringId)
    local splitted = Utilities.SplitString(stringId, "|");
    if #splitted == 3 then
        local x, y, z = tonumber(splitted[1]), tonumber(splitted[2]), tonumber(splitted[3])
        local square = getCell():getIsoGridSquare(x, y, z);
        return square;
    end
end

-- Check if game is single player only
-- Can be used anywhere.
function Utilities.IsSinglePlayer()
    return (not isClient() and not isServer());
end

-- Check if player is admin or single player with debug mode enabled
-- If used in a server script, param _playerObj must be given.
-- If used in a client script, param _playerObj can be ignored.
function Utilities.IsAdmin(_playerObj)
    local playerObj = _playerObj or getPlayer();
    return (Utilities.IsSinglePlayer() and isDebugEnabled()) or (playerObj and playerObj:getAccessLevel() == "Admin");
end

-- Check if player is admin or moderator or single player with debug mode enabled
-- If used in a server script, param _playerObj must be given.
-- If used in a client script, param _playerObj can be ignored.
function Utilities.IsStaff(_playerObj)
    local playerObj = _playerObj or getPlayer();
    return Utilities.IsAdmin() or (playerObj and playerObj:getAccessLevel() == "Moderator");
end

-- Send a command to the server from the client
-- Can only be used in a client script.
function Utilities.SendCommandToServer(module, command, data)
    if Utilities.IsSinglePlayer() or isClient() then
        sendClientCommand(module, command, data);
    end
end

-- Send a command to a specific client from the server
-- Can only be used in a server script.
function Utilities.SendCommandToClient(targetPlayerObj, module, command, data)
    if Utilities.IsSinglePlayer() then
        triggerEvent("sendServerCommand", module, command, data);
    elseif isServer() then
        sendServerCommand(targetPlayerObj, module, command, data);
    end
end

-- Send command to all clients from the server
-- Can only be used in a server script.
function Utilities.SendCommandToAllClients(module, command, data)
    if Utilities.IsSinglePlayer() then
        triggerEvent("sendServerCommand", module, command, data);
    elseif isServer() then
        sendServerCommand(module, command, data);
    end
end

-- Send a command to all clients from the server within a specific range from a square
-- Can only be used in a server script.
function Utilities.SendCommandToAllClientsInRange(fromSquare, maxDistance, module, command, data)
    if Utilities.IsSinglePlayer() then
        triggerEvent("sendServerCommand", module, command, data);

    elseif isServer() and instanceof(fromSquare, "IsoGridSquare") then
        if not maxDistance or maxDistance <= 0 then maxDistance = 1; end

        local x1, y1, z1 = fromSquare:getX(), fromSquare:getY(), fromSquare:getZ();
        local players = getOnlinePlayers();
        if players then
            for i = 0, players:size() - 1 do
                local targetPlayer = players:get(i);
                local targetSquare = targetPlayer:getSquare();
                local x2, y2, z2 = targetSquare:getX(), targetSquare:getY(), targetSquare:getZ();
                if IsoUtils.DistanceTo(x1, y1, z1, x2, y2, z2) <= maxDistance then
                    Utilities.SendCommandToClient(targetPlayer, module, command, data);
                end
            end
        end
    end
end

-- Save a string to a file
-- if used from a client script it will save on the client Zomboid/lua directory
-- if used from a server script it will save on the server Zomboid/lua directory
-- param filename dont need the file extension, .txt will be automatically added.
function Utilities.SaveStringToFile(filename, stringData)
    if type(filename) == "string" and type(stringData) == "string" then
        local fileWriterObj = getFileWriter(filename .. ".txt", true, false);
        fileWriterObj:write(stringData);
        fileWriterObj:close();
        print("[EHE] Saved string into " .. filename .. ".txt");
    end
end

-- Load a string from a file or save a default value if file doesn't exist
-- if used from a client script it will load from the client Zomboid/lua directory
-- if used from a server script it will load from the server Zomboid/lua directory
-- param filename dont need the file extension, .txt will be automatically added.
function Utilities.LoadStringFromFile(filename, _default)
    if type(filename) == "string" then
        local fileReaderObj = getFileReader(filename .. ".txt", true);
        local lines;
        local line = fileReaderObj:readLine();
        if not line then
            print("[EHE] " .. filename .. ".txt was not found, attempt to save default string...");
            if type(_default) == "string" then
                Utilities.SaveStringToFile(filename .. ".txt", _default);
                return _default;
            end
        else
            lines = line;
            while true do
                line = fileReaderObj:readLine();
                if line then
                    lines = lines .. "\n" .. line;
                else break; end
            end

            print("[EHE] " .. filename .. ".txt has been loaded!");
            return lines;
        end
    end
end

-- Save a lua table to a file
-- if used from a client script it will save on the client Zomboid/lua directory
-- if used from a server script it will save on the server Zomboid/lua directory
-- param filename dont need the file extension, .json will be automatically added.
function Utilities.SaveTableToFile(filename, table)
    if type(filename) == "string" and type(table) == "table" then
        local json = Json.Encode(table);
        local fileWriterObj = getFileWriter(filename .. ".json", true, false);
        fileWriterObj:write(json);
        fileWriterObj:close();
        print("[EHE] Saved table data into " .. filename .. ".json");
    end
end

-- Load a lua table from a file or save a default table if file doesn't exist
-- if used from a client script it will load from the client Zomboid/lua directory
-- if used from a server script it will load from the server Zomboid/lua directory
-- param filename dont need the file extension, .json will be automatically added.
function Utilities.LoadTableFromFile(filename, _default)
    if type(filename) == "string" then
        local fileReaderObj = getFileReader(filename .. ".json", true);
        local lines;
        local line = fileReaderObj:readLine();
        if not line then
            print("[EHE] " .. filename .. ".json was not found, attempt to save default table...");
            if type(_default) == "table" then
                Utilities.SaveTableToFile(filename .. ".json", _default);
                return _default;
            end
        else
            lines = line;
            while true do
                line = fileReaderObj:readLine();
                if line then
                    lines = lines .. "\n" .. line;
                else break; end
            end

            local result = Json.Decode(lines);
            print("[EHE] " .. filename .. ".json has been loaded!");
            return result;
        end
    end
end

---Check how many days it has been since the start of the apocalypse; corrects for sandbox option "Months since Apoc"
---@return number Days since start of in-game apocalypse
function Utilities.GetDaysSinceApocalypse()
	local monthsAfterApo = getSandboxOptions():getTimeSinceApo() - 1
	--no months to count, go away
	if monthsAfterApo <= 0 then
		return 0
	end

	local gameTime = getGameTime()
	local startYear = gameTime:getStartYear()
	--months of the year start at 0
	local apocStartMonth = (gameTime:getStartMonth()+1)-monthsAfterApo

	--roll the year back if apocStartMonth is negative
	if apocStartMonth <= 0 then
		apocStartMonth = 12 + apocStartMonth
		startYear = startYear - 1
	end

	local apocDays = 0
	--count each month at a time to get correct day count
	for month=0, monthsAfterApo do
		apocStartMonth = apocStartMonth + 1
		--roll year forward if needed, reset month
		if apocStartMonth > 12 then
			apocStartMonth = 1
			startYear = startYear + 1
		end
		--months of the year start at 0
		local daysInM = gameTime:daysInMonth(startYear, apocStartMonth - 1)
		--if this is the first month being counted subtract starting day date
		if month == 0 then
			daysInM = daysInM - gameTime:getStartDay() + 1
		end
		apocDays = apocDays + daysInM
	end

	return apocDays
end

---These is the equivalent of getters for Vector3
--tostring output of a Vector3: "Vector2 (X: %f, Y: %f) (L: %f, D:%f)"
---@param ShmectorTree Vector3
---@return float x of ShmectorTree
function Utilities.Vector3GetX(ShmectorTree)
	if not instanceof(ShmectorTree, "Vector3") then
		return ""
	end
	local tostring = tostring(ShmectorTree)
	local coordinate = string.match(tostring, "%(X%: (.-)%, Y%: ")
	coordinate = string.gsub(coordinate, ",",".")
	--[debug]] print("EHE: Vector3-GetX-Workaround:  "..tostring.."  =  "..coordinate)
	return coordinate
end

---@param ShmectorTree Vector3
---@return float y of ShmectorTree
function Utilities.Vector3GetY(ShmectorTree)
	if not instanceof(ShmectorTree, "Vector3") then
		return ""
	end
	local tostring = tostring(ShmectorTree)
	local coordinate = string.match(tostring, "%, Y%: (.-)%) %(")
	coordinate = string.gsub(coordinate, ",",".")
	--[debug]] print("EHE: Vector3-GetY-Workaround:  "..tostring.."  =  "..coordinate)
	return coordinate
end

---This is an utility function meant for large scale scans of isoGridSquares around a given IsoObject.
---The scans are done fractally - that is to say from a center (or centers) outward to fill a larger area.

---@param center IsoGameCharacter
function Utilities.RecursiveGetSquare(center)
	if not center then return nil; end

	if instanceof(center, "IsoGameCharacter") and center:getVehicle() then
		center = center:getVehicle()
	end

	if not instanceof(center, "IsoGridSquare") then
		center = center:getSquare()
	end

	return center
end

---@param center IsoObject|IsoGridSquare
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param lookForType string
function Utilities.GetHumanoidsInRange(center, range, lookForType)

	if center then
		center = Utilities.RecursiveGetSquare(center)
	else
		return {}
	end

	local squaresInRange = Utilities.GetIsoRange(center, range)
	local objectsFound = {}

	for sq=1, #squaresInRange do

		---@type IsoGridSquare
		local square = squaresInRange[sq]
		local squareContents = square:getLuaMovingObjectList()

		for i=1, #squareContents do
			---@type IsoMovingObject|IsoGameCharacter foundObject
			local foundObj = squareContents[i]

			if instanceof(foundObj, lookForType) and instanceof(foundObj, "IsoGameCharacter") then
				if foundObj:isOutside() then
					table.insert(objectsFound, foundObj)
				end
			end
		end
	end

	return objectsFound
end

---@param center
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param fractalRange number number of rows, made up of `range`, from the center range
---@param lookForType string
function Utilities.GetHumanoidsInFractalRange(center, range, fractalRange, lookForType)

	if center then
		center = Utilities.RecursiveGetSquare(center)
	else
		return {}
	end

	--range and fractalRange are flipped in the parameters here because:
	-- "fractalRange" represents the number of rows from center out but with an offset of "range" instead
	local fractalCenters = Utilities.GetIsoRange(center, fractalRange, range)
	local fractalObjectsFound = {}
	---print("getHumanoidsInFractalRange: centers found: "..#fractalCenters)
	--pass through each "center square" found
	for i=1, #fractalCenters do
		local objectsFound = Utilities.GetHumanoidsInRange(fractalCenters[i], range, lookForType)
		---print(" fractal center "..i..":  "..#objectsFound)
		--store a list of objectsFound within the fractalObjectsFound list
		table.insert(fractalObjectsFound, objectsFound)
	end

	return fractalObjectsFound
end

---@param center IsoObject | IsoGridSquare
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param fractalOffset number fractal offset - spreads out squares by this number
---@return table of IsoGridSquare
function Utilities.GetIsoRange(center, range, fractalOffset)

	if center and center~= false then
		center = Utilities.RecursiveGetSquare(center)
	end

	if not center then
		return {}
	end

	if not fractalOffset then
		fractalOffset = 1
	else
		fractalOffset = (fractalOffset*2)+1
	end

	--true center
	local centerX, centerY = center:getX(), center:getY()
	--add center to squares at the start
	local squares = {center}

	--no point in running everything below, return squares
	if range < 1 then return squares end

	--create a ring of IsoGridSquare around center, i=1 skips center
	for i=1, range do

		local fractalFactor = i*fractalOffset
		--currentX and currentY have to pushed off center for the logic below to kick in
		local currentX, currentY = centerX-fractalFactor, centerY+fractalFactor
		-- ring refers to the path going around center, -1 to skip center
		local expectedRingLength = (8*i)-1

		for _=0, expectedRingLength do
			--if on top-row and not at the upper-right
			if (currentY == centerY+fractalFactor) and (currentX < centerX+fractalFactor) then
				--move-right
				currentX = currentX+fractalOffset
				--if on right-column and not the bottom-right
			elseif (currentX == centerX+fractalFactor) and (currentY > centerY-fractalFactor) then
				--move down
				currentY = currentY-fractalOffset
				--if on bottom-row and not on far-left
			elseif (currentY == centerY-fractalFactor) and (currentX > centerX-fractalFactor) then
				--move left
				currentX = currentX-fractalOffset
				--if on left-column and not on top-left
			elseif (currentX == centerX-fractalFactor) and (currentY < centerY+fractalFactor) then
				--move up
				currentY = currentY+fractalOffset
			end

			---@type IsoGridSquare square
			local square = getCell():getOrCreateGridSquare(currentX, currentY, 0)
			--[DEBUG]] getWorldMarkers():addGridSquareMarker(square, 0.8, fractalOffset-1, 0, false, 0.5)
			table.insert(squares, square)
		end
	end
	--[[DEBUG
	print("---[ IsoRange ]---\n total "..#squares.."/"..((range*2)+1)^2)
	for k,v in pairs(squares) do
		---@type IsoGridSquare vSquare
		local vSquare = v
		print(" "..k..": "..centerX-vSquare:getX()..", "..centerY-vSquare:getY())
	end
	]]
	return squares
end

function Utilities.GetOutsideSquareFromAbove_vehicle(square)
    local foundSquare
	local aSqOutsideAbove = {}
	for k,sq in pairs(Utilities.GetIsoRange(square, 2)) do
		local outsideSq = Utilities.GetOutsideSquareFromAbove(sq, true)
		if outsideSq then
			table.insert(aSqOutsideAbove,outsideSq)
		end
	end
	if #aSqOutsideAbove > 0 then
		foundSquare = aSqOutsideAbove[ZombRand(#aSqOutsideAbove)+1]
	end

	return foundSquare
end

function Utilities.GetOutsideSquareFromAbove(square, isVehicle)
    if not square then return; end

	if square:isOutside() and square:isSolidFloor() then
		return square
	end

	--if isVehicle is true don't allow the code to look for roof tiles
	if isVehicle then return; end

	local x, y = square:getX(), square:getY()

	for i=1, 7 do
		local sq = getSquare(x, y, i)
		if sq and sq:isOutside() and sq:isSolidFloor() then
			return sq
		end
	end
end

function Utilities.ApplyCrashOnVehicle(vehicle)
    if not vehicle then return; end

	vehicle:crash(1000,true)
	vehicle:crash(1000,false)

	for i=0, vehicle:getPartCount() do
		---@type VehiclePart
		local part = vehicle:getPartByIndex(i) --VehiclePart
		if part then
			local partDoor = part:getDoor()
			if partDoor ~= nil then
				partDoor:setLocked(false)
			end
		end
	end
end

function Utilities.AgeInventoryItem(item)
    if not item then return; end

    item:setAutoAge()
end

function Utilities.ApplyDeathOrCrawlerToCrew(arrayOfZombies)
    if arrayOfZombies and arrayOfZombies:size() > 0 then
		local zombie = arrayOfZombies:get(0)
		--33% to be dead on arrival
		if ZombRand(1,101) <= 33 then
			--print("crash spawned: "..outfitID.." killed")
			zombie:setHealth(0)
		else
			if ZombRand(1,101) <= 25 then
				--print("crash spawned: "..outfitID.." crawler")
				zombie:setCanWalk(false)
				zombie:setBecomeCrawler(true)
				zombie:knockDown(true)
			end
		end
	end
end

return Utilities;
