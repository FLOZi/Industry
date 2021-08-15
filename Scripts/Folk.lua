-- Test Mech Script
-- useful global stuff
info = GG.lusHelper[unitDefID]
-- the following have to be non-local for the walkscript include to find them
rad = math.rad

SIG_ANIMATE = {}
moving = false
speedMod = (GG.modOptions and GG.modOptions.speed) or 1.0

-- localised API functions
local SetUnitRulesParam 		= Spring.SetUnitRulesParam
local GetUnitSeparation 		= Spring.GetUnitSeparation
local GetUnitCommands   		= Spring.GetUnitCommands
local GetUnitPosition 			= Spring.GetUnitPosition
local SpawnCEG 					= Spring.SpawnCEG
-- localised GG functions


-- includes
--include "smokeunit.lua"
include ("anims/atlas.lua")-- .. unitDef.name:sub(4, (unitDef.name:find("_", 4) or 0) - 1) .. ".lua")

-- Info from lusHelper gadget

--Turning/Movement Locals
local TORSO_SPEED = info.torsoTurnSpeed

--piece defines
local pelvis, torso, rlowerleg, llowerleg = piece ("pelvis", "torso", "rleg", "lleg")

rupperarm = piece("ruparm")
lupperarm = piece("luparm")



--[[local function RestoreAfterDelay(unitID)
	Sleep(RESTORE_DELAY)
	Turn(torso, y_axis, 0, TORSO_SPEED)
	for id in pairs(mantlets) do
		Turn(mantlets[id], x_axis, 0, ELEVATION_SPEED)
	end
	if lupperarm then
		Turn(lupperarm, x_axis, 0, ELEVATION_SPEED)
	end
	if rupperarm then
		Turn(rupperarm, x_axis, 0, ELEVATION_SPEED)
	end
end]]

-- non-local function called by gadgets/game_ammo.lua

--[[function script.setSFXoccupy(terrainType)
	if terrainType == 2 or terrainType == 1 then -- water
		inWater = true
	else
		inWater = false
		coolRate = baseCoolRate
	end
end]]

function StartTurn(clockwise)
	StartThread(anim_Turn, clockwise)
end

function StopTurn()
	StartThread(anim_Reset)
end

function script.StartMoving(reversing)
	--Spring.Echo("Reversing?", reversing)
	StartThread(anim_Walk)
	moving = true
end

function script.StopMoving()
	StartThread(anim_Reset)
	moving = false
end

function script.Create()
	Spring.SetUnitNanoPieces(unitID, {pelvis})
end

function script.StartBuilding(heading, pitch)
    -- TODO: This is where you would add your unpack / point towards animation
    SetUnitValue(COB.INBUILDSTANCE, true)
end

function script.StopBuilding()
    -- TODO: This is where you would add your pack-up animation
    SetUnitValue(COB.INBUILDSTANCE, false)
end

function script.Killed(recentDamage, maxHealth)
	return 1
end
