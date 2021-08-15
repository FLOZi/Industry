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
local HEIGHT = 80
local LENGTH = 100.5
local U = 2
local V = 1.75

--------------------------------------------------------- previous attempt using transports
--[[local tow = {}
tow[1] = piece("tow1")
tow[2] = piece("tow2")]]

--[[function CurveTrain(angle)
	Sleep(200)
	Turn(tow[1], y_axis, angle, 0.05) -- l=r0 -> 0 = l/r
	WaitForTurn(tow[1], y_axis)
	--Sleep(500)
	Turn(tow[2], y_axis, angle, 0.05) -- l=r0 -> 0 = l/r
end]]
--------------------------------------------------------- previous attempt using transports
	
local B2, B3
--[[function Curve(ID, radius, angle, velocity)
	-- radius in elmo, angle in degrees, velocity in elmo/frame
	-- convert to radians
	angle = math.rad(angle)
	local x, _, z = Spring.GetUnitPosition(ID)
	local dx, dy, dz = Spring.GetUnitDirection(ID)
	GG.DrawCurve(x,HEIGHT,z, dx,dy,dz, angle, radius)
	--Spring.MarkerAddPoint(x+radius -radius* math.cos(angle), HEIGHT, z-radius*math.sin(angle))
	--Spring.MoveCtrl.SetLimits(ID, x, HEIGHT, z, x+radius -radius* math.cos(angle), HEIGHT, z-radius*math.sin(angle))
	local neg = angle < 0
	-- elmo / (elmo/frame) = frames
	local time = radius * math.abs(angle) / velocity
	local omega = velocity / radius * (neg and -1 or 1)
	--Spring.Echo("FARTYBUTT", angle, neg, omega)
	Spring.MoveCtrl.SetRotationVelocity(ID, 0, omega, 0)
	Spring.MoveCtrl.SetRelativeVelocity(ID, 0, 0, velocity)
	--StartThread(CurveTrain, -math.deg(LENGTH/radius))
	Sleep(math.floor(time / 30 * 1000)) -- 30 frame / second
	Spring.MoveCtrl.SetRotationVelocity(ID, 0, 0, 0)
	--StartThread(CurveTrain, 0)
	-- force final angle accuracy
	Spring.MoveCtrl.SetRotation(ID, 0, angle, 0)
	-- wait for the whole train to clear the bend before accelerating
	if ID == B3 then
		GG.Straight(unitID, U, 1000)
		GG.Straight(B2, U, 1000)
		GG.Straight(B3, U, 1000)
	end
end

function CurveThread(ID, radius, angle, velocity)
	StartThread(Curve, ID, radius, angle, velocity)
end
--GG.Curve = CurveThread
]]
function TurnIt(x, z)
	Spring.MoveCtrl.SetTrackLimits(unitID, true)
	Spring.MoveCtrl.SetLimitsStop(unitID, false)
	Sleep(30)
	local pause = (LENGTH+(30+U)/3)/V * 30--6650--3350
	--local b2 = Spring.CreateUnit("boat2", x, HEIGHT, z-LENGTH, 0, 0, false, false)
	--local b3 = Spring.CreateUnit("boat2", x, HEIGHT, z-2*LENGTH, 0, 0, false, false)
	--B2 = b2
	--B3 = b3
	--Spring.SetUnitDirection(unitID, 0,0,1)
	GG.Straight(unitID, U, 300)
	--GG.Straight(b2, U, 1000)
	--GG.Straight(b3, U, 1000)
	--[[Spring.UnitAttach(unitID, b2, tow[1])
	Spring.UnitAttach(unitID, b3, tow[2])]]
	--Sleep(10000/U)
	--GG.Straight(b2, V, 1000)
	--GG.Straight(b3, V, 1000)
	--local _,_,z1 = Spring.GetUnitPosition(unitID)
	--local _,_,z2 = Spring.GetUnitPosition(B2)
	--Spring.Echo("ACTUAL DIST", z1-z2)
	--StartThread(Curve,unitID, 300, -90, V)
	Sleep(pause)
	--StartThread(Curve,b2, 300, 90, V)
	Sleep(pause)
	--StartThread(Curve,b3, 300, -90, V)
end

-- Info from lusHelper gadget
function script.Create()
--	Move(tow[1], z_axis, -5)
--	Move(tow[2], z_axis, -LENGTH)
	local x, y, z = GetUnitPosition(unitID)
	StartThread(TurnIt, x, z)
end


function script.Killed(recentDamage, maxHealth)
	return 1
end
