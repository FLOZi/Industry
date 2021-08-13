function gadget:GetInfo()
	return {
		name = "LUS Helper",
		desc = "Parses UnitDef and Model data for LUS",
		author = "FLOZi (C. Lawrence)",
		date = "20/02/2011", -- 25 today ;_;
		license = "GNU GPL v2",
		layer = -1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
--SYNCED

-- Localisations
GG.lusHelper = {}
local sqrt = math.sqrt
local random = math.random
-- Synced Read
local GetUnitPieceInfo 		= Spring.GetUnitPieceInfo
local GetUnitPieceMap		= Spring.GetUnitPieceMap
local GetUnitPiecePosDir	= Spring.GetUnitPiecePosDir
local GetUnitPosition		= Spring.GetUnitPosition
local GetUnitWeaponTarget	= Spring.GetUnitWeaponTarget
local GetUnitRulesParam		= Spring.GetUnitRulesParam
local GetCommandQueue		= Spring.GetCommandQueue
-- Synced Ctrl
local PlaySoundFile			= Spring.PlaySoundFile
local SpawnCEG				= Spring.SpawnCEG
local SetUnitWeaponState	= Spring.SetUnitWeaponState
local SetGroundMoveTypeData	= Spring.MoveCtrl.SetGroundMoveTypeData
local GiveOrderToUnit		= Spring.GiveOrderToUnit
local SetUnitRulesParam		= Spring.SetUnitRulesParam
-- LUS
local CallAsUnit 			= Spring.UnitScript.CallAsUnit	

-- Unsynced Ctrl
-- Constants
local RANGE_INACCURACY_PERCENT = 5
-- Variables

-- Useful functions for GG

function GG.RemoveGrassSquare(x, z, r)
	local startX = math.floor(x - r/2)
	local startZ = math.floor(z - r/2)
	for i = 0, r, Game.squareSize * 4 do
		for j = 0, r, Game.squareSize * 4 do
			Spring.RemoveGrass((startX + i)/Game.squareSize, (startZ + j)/Game.squareSize)
		end
	end
end

function GG.RemoveGrassCircle(cx, cz, r)
	local r2 = r * r
	for z = 0, 2 * r, Game.squareSize * 4 do -- top to bottom diameter
		local lineLength = sqrt(r2 - (r - z) ^ 2)
		for x = -lineLength, lineLength, Game.squareSize * 4 do
			Spring.RemoveGrass((cx + x)/Game.squareSize, (cz + z - r)/Game.squareSize)
		end
	end
end

function GG.SpawnDecal(decalType, x, y, z, teamID, delay, duration)
	if delay then
		GG.Delay.DelayCall(SpawnDecal, {decalType, x, y, z, teamID, nil, duration}, delay)
	else
		local decalID = Spring.CreateUnit(decalType, x, y + 1, z, 0, Spring.GetGaiaTeamID(), false, false)
		Spring.SetUnitAlwaysVisible(decalID, teamID == nil and true)
		Spring.SetUnitNoSelect(decalID, true)
		Spring.SetUnitBlocking(decalID, false, false, false, false, false, false, false)
		if duration then
			GG.Delay.DelayCall(Spring.DestroyUnit, {decalID, false, true}, duration)
		end
	end
end

--[[function GG.EmitSfxName(unitID, pieceNum, effectName) -- currently unused
	local px, py, pz, dx, dy, dz = GetUnitPiecePosDir(unitID, pieceNum)
	dx, dy, dz = GG.Vector.Normalized(dx, dy, dz)
	SpawnCEG(effectName, px, py, pz, dx, dy, dz)
end]]



function GG.LimitRange(unitID, weaponNum, defaultRange)
	local targetType, _, targetID = GetUnitWeaponTarget(unitID, weaponNum)
	if targetType == 1 then -- it's a unit
		local tx, ty, tz = GetUnitPosition(targetID)
		local ux, uy, uz = GetUnitPosition(unitID)
		local distance = sqrt((tx - ux)^2 + (ty - uy)^2 + (tz - uz)^2)
		local distanceMult = 1 + (random(-RANGE_INACCURACY_PERCENT, RANGE_INACCURACY_PERCENT) / 100)
		SetUnitWeaponState(unitID, weaponNum, "range", distanceMult * distance)
	end
	SetUnitWeaponState(unitID, weaponNum, "range", defaultRange)
end


function GG.RecursiveHide(unitID, pieceNum, hide)
	-- Hide this piece
	local func = (hide and Spring.UnitScript.Hide) or Spring.UnitScript.Show
	CallAsUnit(unitID, func, pieceNum)
	-- Recursively hide children
	local pieceMap = GetUnitPieceMap(unitID)
	local children = GetUnitPieceInfo(unitID, pieceNum).children
	if children then
		for _, pieceName in pairs(children) do
			GG.RecursiveHide(unitID, pieceMap[pieceName], hide)
		end
	end
end

function GG.UnitSay(unitID, sound)
	local velx, vely, velz = Spring.GetUnitVelocity(unitID)
	GG.PlaySoundAtUnit(unitID, sound, 1, velx, vely, velz, 'voice')
end

function GG.PlaySoundAtUnit(unitID, sound, volume, sx, sy, sz, channel)
	local x,y,z = GetUnitPosition(unitID)
	volume = volume or 5
	channel = channel or "sfx"
	PlaySoundFile(sound, volume, x, y, z, sx, sy, sz, channel)
end

local unsyncedBuffer = {}
function GG.PlaySoundForTeam(teamID, sound, volume)
	table.insert(unsyncedBuffer, {teamID, sound, volume})
end

function gadget:GameFrame(n)
	for _, callInfo in pairs(unsyncedBuffer) do
		SendToUnsynced("SOUND", callInfo[1], callInfo[2], callInfo[3])
	end
	unsyncedBuffer = {}
end

function GG.GetUnitDistanceToPoint(unitID, tx, ty, tz, bool3D)
	local x,y,z = GetUnitPosition(unitID)
	local dy = (bool3D and ty and (ty - y)^2) or 0
	local distanceSquared = (tx - x)^2 + (tz - z)^2 + dy
	return sqrt(distanceSquared)
end

-- Include table utilities
VFS.Include("LuaRules/Includes/utilities.lua", nil, VFS.ZIP)

local udCache = {}

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	-- Pass unitID to constructor
	env = Spring.UnitScript.GetScriptEnv(builderID)
	if env and env.build then
		Spring.UnitScript.CallAsUnit(builderID, env.build, unitID, unitDefID)
	end
	local info = GG.lusHelper[unitDefID]
	local cp = UnitDefs[unitDefID].customParams
	if not udCache[unitDefID] then
		udCache[unitDefID] = true
		-- Parse Model Data
		local pieceMap = GetUnitPieceMap(unitID)
		for pieceName, pieceNum in pairs(pieceMap) do
		end
	end
end

-- Movement speed changes
function GG.ApplySpeedChanges(unitID)
	-- no need to attempt this
	if GetUnitRulesParam(unitID, 'movectrl') == 1 then
		return
	end

	local unitDefID = GetUnitDefID(unitID)
	local UnitDef = UnitDefs[unitDefID]
	local origSpeed = UnitDef.speed
	local origReverseSpeed = Spring.GetUnitMoveTypeData(unitID).maxReverseSpeed

	local newSpeed = origSpeed
	local newReverseSpeed = origReverseSpeed
	local currentSpeed = GetUnitRulesParam(unitID, "current_speed") or origSpeed

	local immobilized = false
	local immobilizedMult = 1.0
	if (GetUnitRulesParam(unitID, "immobilized") or 0) > 0 then
		immobilized = true
		immobilizedMult = 0
	end

	newSpeed = newSpeed * fearMult * deployedMult * amphibMult * immobilizedMult
	newReverseSpeed = newReverseSpeed * fearMult * deployedMult * amphibMult * immobilizedMult

	--Spring.Echo('fearMult ' .. fearMult .. ' deployedMult ' .. deployedMult .. ' amphibMult ' .. amphibMult .. ' newSpeed ' .. newSpeed .. ' origSpeed ' .. origSpeed)

	-- only deployed mult overrides turn rates so far
	if deployedMult == 1.0 and not immobilized then
		SetGroundMoveTypeData(unitID, {maxSpeed = newSpeed, maxReverseSpeed = newReverseSpeed, turnRate = UnitDef.turnRate, accRate = UnitDef.maxAcc})
	else
		SetGroundMoveTypeData(unitID, {maxSpeed = newSpeed, maxReverseSpeed = origReverseSpeed, turnRate = 0.001, accRate = 0})
	end

	if currentSpeed ~= newSpeed then
		local cmds = GetCommandQueue(unitID, 2)
		--if #cmds >= 2 then
		if #cmds >= 1 then
			if cmds[1].id == CMD.MOVE or cmds[1].id == CMD.FIGHT or cmds[1].id == CMD.ATTACK then
				if cmds[2] and cmds[2].id == CMD.SET_WANTED_MAX_SPEED then
					GiveOrderToUnit(unitID,CMD.REMOVE,{cmds[2].tag},{})
				end
				local params = {1, CMD.SET_WANTED_MAX_SPEED, 0, newSpeed}
				SetGroundMoveTypeData(unitID, {maxSpeed = newSpeed, maxReverseSpeed = newReverseSpeed})
				GiveOrderToUnit(unitID, CMD.INSERT, params, {"alt"})
			end
		end
		SetUnitRulesParam(unitID, "current_speed", newSpeed)
	end
end

function gadget:GamePreload()
	-- Parse UnitDef Data
	for unitDefID, unitDef in pairs(UnitDefs) do
		local info = {}
		local cp = unitDef.customParams
		
		-- UnitDef Level Info
		local corpse = FeatureDefNames[unitDef.wreckName:lower()]
		info.numCorpses = 0
		if corpse then
			corpse = corpse.id
			while FeatureDefs[corpse] do
				info.numCorpses = info.numCorpses + 1
				local corpseDef = FeatureDefs[corpse]
				corpse = corpseDef.deathFeatureID
			end
		end
		
		info.facing = cp.facing or 0 -- default to front
		--[[info.turretTurnSpeed = math.rad(tonumber(cp.turretturnspeed) or 24)
		info.wheelSpeed = math.rad(tonumber(cp.wheelspeed) or 100)
		info.wheelAccel = math.rad(tonumber(cp.wheelaccel) or info.wheelSpeed * 2)
		-- General
		info.mainAnimation = cp.scriptanimation
		info.deathAnim = table.unserialize(cp.deathanim) or {}
		info.axes = {["x"] = 1, ["y"] = 2, ["z"] = 3}

		-- deploy anims
		if cp.customanims then
			info.customAnimsName = cp.customanims
		end
		
		-- Children
		info.children = table.unserialize(cp.children)]]
		-- And finally, stick it in GG for the script to access
		GG.lusHelper[unitDefID] = info
	end
end

function gadget:Initialize()
	gadget:GamePreload()
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = Spring.GetUnitTeam(unitID)
		local unitDefID = GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

else

-- UNSYNCED

local PlaySoundFile	= Spring.PlaySoundFile
local MY_TEAM_ID = Spring.GetMyTeamID()

function PlayTeamSound(eventID, teamID, sound, volume)
	if teamID == MY_TEAM_ID then
		PlaySoundFile(sound, volume, "ui")
	end
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("SOUND", PlayTeamSound)
end

end
