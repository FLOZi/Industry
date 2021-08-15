local log_buildersyard = Yard:New{
	description			= "Builder's Yard",
	objectName			= "building/log_buildersyard.s3o",
	builddistance		= 9999999999999,
	buildTime			= 100,
	customParams = {
		costs = {
			bricks = 100,
			timber = 100,
		},
		stores = {
			bricks = 500,
			timber = 500,
		},
	},	
}

local test = Yard:New{
	description			= "Test Unit",
	objectName			= "building/test.s3o",
	buildTime			= 100,
	yardmap = [[yy
				yy]],
	footprintX = 2,
	footprintZ = 2,
	customParams = {
		costs = {
			bricks = 10,
			--timber = 5,
		},
	},	
}
local test2 = test:New{
	description			= "Big Test Unit",
	objectName			= "building/test2.s3o",
	footprintX = 20,
	footprintZ = 10,
	yardmap = [[yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy]],
}

local aqueduct = Yard:New{
	objectName			= "building/aqueduct.s3o",
	footprintX = 3,
	footprintZ = 10,
	flattenGround = false,
}

local returnable = {
	["log_buildersyard"] = log_buildersyard,
	["test"] = test,
	["test2"] = test2,
	["aqueduct"] = aqueduct,
}
local fields = {}
for j = 1, 6 do
	local i = 2 ^ j
	local yard = ""
	for k = 1, i*i do
		yard = yard .. "y"
	end
	fields[i] = Yard:New{
		footprintX = i,
		footprintZ = i,
		yardmap = yard,
		objectName			= "building/empty.s3o",
		useBuildingGroundDecal  = true,
		buildingGroundDecalType = "field.jpg",
		buildingGroundDecalSizeX = i,
		buildingGroundDecalSizeY = i,
		buildTime = i,
		customParams = {
			object = "field",
			costs = {
				bricks = i,
				--timber = i,
			},
		},
	}
	returnable["field_" .. i] = fields[i]
end
	
return lowerkeys(returnable)
