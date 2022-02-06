local BodyPartSelection = {};

local bodyPartSelections = {}
local bodyPartSelectionWeight = {
	["Hand_L"]=5,["Hand_R"]=5,["ForeArm_L"]=10,["ForeArm_R"]=10,
	["UpperArm_L"]=15,["UpperArm_R"]=15,["Torso_Upper"]=15,["Torso_Lower"]=15,
	["Head"]=1,["Neck"]=1,["Groin"]=2,["UpperLeg_L"]=15,["UpperLeg_R"]=15,
	["LowerLeg_L"]=10,["LowerLeg_R"]=10,["Foot_L"]=5,["Foot_R"]=5
}

for type,weight in pairs(bodyPartSelectionWeight) do
	for i=1, weight do
		--print("body parts: "..i.." - "..type)
		table.insert(bodyPartSelections, type)
	end
end

function BodyPartSelection.GetCount()
    return #bodyPartSelections;
end

function BodyPartSelection.Get(index)
    return bodyPartSelections[index];
end

function BodyPartSelection.GetAll()
    return bodyPartSelections;
end

function BodyPartSelection.GetRandom()
    return bodyPartSelections[ZombRand(#bodyPartSelections) + 1];
end

return BodyPartSelection
