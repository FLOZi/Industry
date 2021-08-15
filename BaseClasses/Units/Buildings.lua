-- Buildings ----
local Building = Unit:New{
	airSightDistance			= 2000,
	--buildingGroundDecalType		= "Dirt2.dds",
	category					= "BUILDING",
	maxSlope					= 15,
	maxWaterDepth				= 0,
	radardistance				= 650,
	sightDistance				= 300,
	script						= "Building.lua",
	stealth						= true,
	--useBuildingGroundDecal		= true,
	
	customParams = {
		baseclass = "Building", -- TODO: annoying that both of these are needed atm
		object = "building",
	},
}

-- Yards --
local Yard = Building:New{
	builder 					= true,
	--buildingGroundDecalSizeX	= 8,
	--buildingGroundDecalSizeY	= 8,
	canBeAssisted				= false,
	canMove						= true, -- required for setting waypoints
	collisionVolumeType			= "box",
	collisionVolumeScales		= "100 17 100",
	footprintX					= 7,
	footprintZ					= 7,
	energyStorage				= 0.01, -- TODO: why?
	iconType					= "factory",
	idleAutoHeal				= 3,
	maxDamage					= 6250,
	maxSlope					= 10,
	reclaimable					= true,
	showNanoSpray				= false,
	workerTime					= 30,
	
	customParams = {
		object = "yard",
	},
}


return {
	Building = Building,
	-- Yards
	Yard = Yard,
}
