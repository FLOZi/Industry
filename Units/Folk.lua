local Folk_Male = Folk:New{
	description			= "Men Folk",
	--iconType			= "rifle",
	objectName			= "folk/folk_man.s3o",
	customParams = {
		names = {
			[1] = {
				"Adam",
				"Bertrand",
				"Clarence",
				"David",
				"Edward",
				"Florian",
				"George",
				"Harrison",
				"Isembard",
				"Johnathon",
				"Karl",
				"Lawrence",
				"Merrit",
				"Nigel",
				"Oscar",
				"Phineas",
				"Raymond",
				"Sterling",
				"Thaddeus",
				"Victor",
				"Warren",
			},
			[2] = {
				"Adamson",
				"Burton",
				"Clarkson",
				"Faulkner",
				"Goldrick",
				"Lawrence",
				"Sheard",
				"Wilkinson",
			},
		},
	},	
}

local builder = Folk_Male:New{
	builder = true,
	workerTime = 1,
	terraformSpeed = 100,
	
	buildOptions = {
		"test",
		"log_buildersyard",
	},
}

local boat = Folk:New{
	objectName			= "folk/boat.s3o",
	script 				= "boat.lua",
	holdSteady = true,
	isFirePlatform = true,
}

local boat2 = boat:New{
	objectName			= "folk/boat2.s3o",
	script = "",
}

return lowerkeys({
	["folk_male"] = Folk_Male,
	["folk_builder"] = builder,
	["boat"] = boat,
	["boat2"] = boat2,
})
