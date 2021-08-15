-- Folk ----
local Folk = Unit:New{
	airSightDistance	= 2000,
	acceleration		= 0.375,
	brakeRate			= 0.9,
	buildCostMetal		= 65, -- used only for power XP calcs
	canMove				= true,
	category			= "FOLK",
	--corpse				= "<SIDE>soldier_dead",
	footprintX			= 1,
	footprintZ			= 1,
	mass				= 50,
	maxDamage			= 100, -- default only, <SIDE>Folk.lua should overwrite
	maxVelocity			= 1.6,
	movementClass		= "folk",
	radardistance		= 650,
	repairable			= false,
	script				= "Folk.lua",
	seismicDistance		= 1400,
	seismicSignature	= 0, -- required, not default
	sightDistance		= 650,
	stealth				= true,
	turnRate			= 1010,
	upright				= true,
	
	customParams = {
		capacity			= 1,
		--soundcategory 		= "<SIDE>/Folk",
	},
}


return {
	Folk = Folk,
	-- Basic Types
}
