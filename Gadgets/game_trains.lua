function gadget:GetInfo()
	return {
		name = "Game Trains",
		desc = "Choo Choooo!",
		author = "FLOZi (C. Lawrence)",
		date = "11/01/2020",
		license = "GNU GPL v2",
		layer = 20,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
--SYNCED

-- Localisations
local sqrt = math.sqrt
local random = math.random
-- Synced Read

-- Synced Ctrl
-- LUS
local CallAsUnit 			= Spring.UnitScript.CallAsUnit	

-- Unsynced Ctrl
-- Constants
local HEIGHT = 80 -- TODO: remove and track ground
-- Variables

-- Useful functions for GG


-- Include table utilities
VFS.Include("LuaRules/Includes/utilities.lua", nil, VFS.ZIP)

local UnitNodes = {} -- [unitID] = nodeNumber


-- Draw functions
function DrawStraight(x1,y1,z1,x2,y2,z2)
	Spring.MarkerAddLine(x1,y1,z1, x2,y2,z2)
	Spring.MarkerAddPoint(x2,y2,z2, "next stop: (" .. x2 .. ", " .. z2 .. ")")
end

function DrawCurve(x,y,z, dx,dy,dz, angle, radius)
	--Spring.Echo("DrawCurve", x,y,z, dx,dy,dz, angle, radius)
	local sin = math.sin
	local cos = math.cos
	local sign = angle < 0 and -1 or 1
	local theta = math.abs(angle) / 10
	local cx = x + dz * radius * sign
	local cz = z - dx * radius * sign
	Spring.MarkerAddPoint(cx, y, cz, "Centre of Rotation" .. sign)
	for i = 0, 9 do
		local rsintheta1 = radius*sin(theta*i)
		local rcostheta1 = radius*cos(theta*i)
		local rsintheta2 = radius*sin(theta*(i+1))
		local rcostheta2 = radius*cos(theta*(i+1))
		--Spring.MarkerAddPoint(cx + dx*rcostheta1 + dz*rcostheta1, y ,cz + dz*rsintheta1 + dx*rcostheta1, i)
		Spring.MarkerAddLine(cx + dx*rsintheta1 - dz*sign*rcostheta1, y, cz + dz*rsintheta1 + dx*sign*rcostheta1,
							 cx + dx*rsintheta2 - dz*sign*rcostheta2, y, cz + dz*rsintheta2 + dx*sign*rcostheta2)
		if i == 9 then
			--Spring.MarkerAddPoint(cx + dx*rsintheta2 - dz*sign*rcostheta2, y, cz + dz*rsintheta2 + dx*sign*rcostheta2, "next stop")
		end
	end
end
GG.DrawCurve = DrawCurve

-- Track Section Functions
function SetLimits(unitID, x1,y1,z1, x2,y2,z2)
	Spring.MoveCtrl.SetLimits(unitID, 
							  math.min(x1, x2),math.min(y1,y2),math.min(z1,z2), 
							  math.max(x1, x2),math.max(y1,y2),math.max(z1,z2))
end

function Straight(unitID, velocity, length)
	local x, y, z = Spring.GetUnitPosition(unitID)
	Spring.MoveCtrl.Enable(unitID)
	Spring.MoveCtrl.SetPosition(unitID, x, HEIGHT, z)
	Spring.MoveCtrl.SetRelativeVelocity(unitID, 0, 0, velocity)
	local dx, dy, dz = Spring.GetUnitDirection(unitID)
	--Spring.Echo("DIRECTION", dx, dy, dz)
	local mx, my, mz = math.floor(x+length*dx), HEIGHT, math.floor(z+length*dz)
	SetLimits(unitID, x,y,z, mx,my,mz)
	Spring.MoveCtrl.SetTrackLimits(unitID, true)
	Spring.MoveCtrl.SetLimitsStop(unitID, false)
	DrawStraight(x,HEIGHT,z, mx,HEIGHT,mz)
end	
GG.Straight = Straight

function FinishCurve(unitID, dx, dz, angle)
	Spring.MoveCtrl.SetRotationVelocity(unitID, 0, 0, 0)
	-- force final angle accuracy
	local x, z = GG.Vector.RotateYXZ(dx, dz, angle)
	Spring.Echo("dx", dx, "dz", dz, x, z, math.deg(math.atan2(x,z)))
	Spring.MoveCtrl.SetRotation(unitID, 0, math.atan2(x, z), 0)
end
	
function Curve(unitID, radius, angle, velocity)
	-- radius in elmo, angle in degrees, velocity in elmo/frame
	-- convert to radians
	angle = math.rad(angle)
	local x, _, z = Spring.GetUnitPosition(unitID)
	local dx, dy, dz = Spring.GetUnitDirection(unitID)
	GG.DrawCurve(x,HEIGHT,z, dx,dy,dz, angle, radius)
	local sign = angle < 0 and -1 or 1
	local theta = math.abs(angle) / 10
	local cx = x + dz * radius * sign
	local cz = z - dx * radius * sign
	local mx = math.floor(cx + dx*radius * math.sin(angle) - dz*sign*radius*math.cos(angle))
	local mz = math.floor(cz + dz*radius*math.sin(angle) + dx*sign*radius*math.cos(angle))
	SetLimits(unitID, x, HEIGHT, z, mx, HEIGHT, mz)
	Spring.MarkerAddPoint(mx, HEIGHT, mz, "next stop: (" .. mx .. ", " .. mz .. ")")
	-- elmo / (elmo/frame) = frames
	local time = radius * math.abs(angle) / velocity
	local omega = velocity / radius * sign
	Spring.MoveCtrl.SetRotationVelocity(unitID, 0, omega, 0)
	Spring.MoveCtrl.SetRelativeVelocity(unitID, 0, 0, velocity)
	GG.Delay.DelayCall(FinishCurve, {unitID, dx, dz, angle}, time)
end
GG.Curve = Curve

-- Node consumer
local nodes = {
	[1] = {
		exe = GG.Straight,
		args = {2,300},
		name = "Straight",
	},
	[2] = {
		exe = GG.Curve,
		args = {300, 45, 2},
		name = "Curve",
	},
}

function gadget:MoveCtrlNotify(unitID, unitDefID, unitTeam, data)
	--Spring.Echo("AHOY!", unitID, UnitDefs[unitDefID].name, data)
	Spring.MoveCtrl.SetLimits(unitID, 0,-2*HEIGHT,0, Game.mapSizeX, 2*HEIGHT, Game.mapSizeZ)
	UnitNodes[unitID] = (UnitNodes[unitID] or 1) + 1
	if UnitNodes[unitID] > #nodes then
		UnitNodes[unitID] = 1
	end
	local node = nodes[UnitNodes[unitID]]
	Spring.Echo(node.name, unpack(node.args))
	node.exe(unitID, unpack(node.args))
	return false
end
----------------------------------------------------------------------------------------- aqueduct crap


function Setup(unitID)
	local x,y,z = Spring.GetUnitPosition(unitID)
	Spring.MoveCtrl.Enable(unitID)
	Spring.MoveCtrl.SetPosition(unitID, x, 70, z)
end

function More(x, z)
	local new = Spring.CreateUnit("aqueduct", x, 100, z, 0, 0, false, false)
	Setup(new)
end
local first

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	if UnitDefs[unitDefID].name == "aqueduct" and not first then
		Spring.Echo("AQUEDUCT!")
		Setup(unitID)
		local x,y,z = Spring.GetUnitPosition(unitID)
		for i = 1, 10 do
			GG.Delay.DelayCall(More, {x, z+ i*150}, 1)
		end
		first = true
		GG.Delay.DelayCall(Spring.CreateUnit, {"boat", x, 100, z, 0, 0, false, false}, 1)
		--GG.Delay.DelayCall(Spring.CreateUnit, {"boat", x, 100, z, 0, 0, false, false}, 101)
		--GG.Delay.DelayCall(Spring.CreateUnit, {"boat", x, 100, z, 0, 0, false, false}, 201)
	end
end
----------------------------------------------------------------------------------------- aqueduct crap

else

-- UNSYNCED

end
