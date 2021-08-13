function gadget:GetInfo()
	return {
		name = "Deliver",
		desc = "-",
		author = "FLOZi",
		date = "05 Sept 2018",
		license = "GNU GPL v2",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
--SYNCED


-- Synced Read
local GetUnitDefID		= Spring.GetUnitDefID
local GetUnitPosition		= Spring.GetUnitPosition
local GetUnitsInCylinder	= Spring.GetUnitsInCylinder
local GetFeaturesInCylinder	= Spring.GetFeaturesInCylinder
local GetFeatureBlocking	= Spring.GetFeatureBlocking
local ValidUnitID		= Spring.ValidUnitID
local GetGroundHeight		= Spring.GetGroundHeight

-- Synced Ctrl
local SetUnitMoveGoal		= Spring.SetUnitMoveGoal
local GiveOrderToUnit		= Spring.GiveOrderToUnit


-- Commands
local CMD_DELIVER = GG.CustomCommands.GetCmdID("CMD_DELIVER")
local CMD_RETURN = GG.CustomCommands.GetCmdID("CMD_RETURN")
local CMD_BUILD = GG.CustomCommands.GetCmdID("CMD_BUILD")

local localCMDs = {}
if CMD_DELIVER then
	localCMDs[CMD_DELIVER] = true
	localCMDs[CMD_RETURN] = true
	localCMDs[CMD_BUILD] = true
end

-- Constants
local STOP_DIST = 5
local MIN_DIST2 = 20^2
local WAYPOINT_DIST = 100
local DELIVER_TIME = 3000 -- time in ms to deliver an item once inside

-- Variables
local deliverys = {} -- deliverys[unitID] = {
local buildsites = {} -- buildsites[unitID] = {
local returning = {}


-- Callins

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_DELIVER then
		--Spring.Echo("CMD_DELIVER issued to", unitID, deliverys[unitID])
		local ud = UnitDefs[unitDefID]
		local cp = ud.customParams
		if cp and cp.capacity and not deliverys[unitID] then
			local targetID = cmdParams[1]
			local x,y,z = GetUnitPosition(targetID)
			local delivery = {}
			local worker = GG.GetObjectFromID(unitID)
			--if not worker.idle then return false end
			delivery.target = targetID
			delivery.base = worker.workplace --GG.Workers.GetWorkerBase(unitID)
			delivery.x = x
			delivery.z = z
			deliverys[unitID] = delivery
			delivery.resource = "bricks" -- TODO: not sure how to deal with this
			delivery.amount = tonumber(cp.capacity) -- assuming that units always carry full amount, which seems a sensible simplification to enforce
			returning[unitID] = nil
			-- check if target is fillings its costs
			local target = GG.GetObjectFromID(targetID)
			if target.needs then
				local resourceNeeded = target.needs[delivery.resource]
				if resourceNeeded <= 0 then 
					Spring.Echo("Nah blud, I'm full")
					return false -- we already allocated all needed resources
				end
				target.needs[delivery.resource] = resourceNeeded - delivery.amount
				--Spring.Echo("target", targetID, "needs ", target.needs[delivery.resource], delivery.resource)
			end
			local name = GG.GetObjectFromID(unitID).name
			--Spring.Echo("Transfer", delivery.resource, delivery.amount, "from base", delivery.base, "to worker", name, unitID)
			--GG.Resources.TransferUnitResource(delivery.base, unitID, delivery.resource, delivery.amount)
			local base = GG.GetObjectFromID(delivery.base)
			base:TransferResource(unitID, delivery.resource, delivery.amount)
			worker.idle = false
			--Spring.Echo("CMD_DELIVER issued to", unitID, "no really")
			return true
		else
			-- Only allow CMD_DELIVER for units with carrying capacity
			return false
		end
	elseif cmdID == CMD_RETURN then
		--Spring.Echo("CMD_RETURN issued to", unitID)
		local worker = GG.GetObjectFromID(unitID)
		local base = worker.workplace --GG.Workers.GetWorkerBase(unitID)
		local x,y,z = GetUnitPosition(base)
		local params = {}
		params.target = base
		params.x = x - 30
		params.z = z + 20
		returning[unitID] = params
		deliverys[unitID] = nil
		worker.idle = false
		return true
	elseif cmdID == CMD_BUILD then
		--Spring.Echo("CMD_BUILD issued to", unitID)
		local worker = GG.GetObjectFromID(unitID)
		local targetID = cmdParams[1]
		local x,y,z = GetUnitPosition(targetID)
		local buildsite = {}
		buildsite.target = targetID
		buildsite.x = x
		buildsite.z = z
		buildsites[unitID] = buildsite
		worker.idle = false
		return true
	elseif UnitDefs[unitDefID].name == "log_buildersyard" then
		if cmdID < 0 then
			local ud = UnitDefs[-cmdID]
			local cp = ud.customParams
			local site = GG.ObjectFactory[cp.object]:Begin(-cmdID,unpack(cmdParams))
			site:SetYard(unitID)
			local yard = GG.GetObjectFromID(unitID)
			yard:AddSite(site.id)
		end
		return true
	else
		-- Allow any other command
		return true
	end
end

local function GoHome(unitID)
	--Spring.Echo("DELIVERED! I'mma goin' home")
	deliverys[unitID] = nil
	GG.Delay.DelayCall(Spring.GiveOrderToUnit, {unitID, GG.CustomCommands.GetCmdID("CMD_RETURN"), {}, {}}, 5)
	--[[x, _, z = GetUnitPosition(delivery.home)
	delivery.x = x
	delivery.z = z
	delivery.outbound = false
	delivery.inbound = true -- switch states to head home]]
end

--[[function gadget:UnitIdle(unitID, unitDefID)
	if UnitDefs[unitDefID].speed > 0 then
		Spring.Echo(unitID, "is IDLE!")
		GG.Delay.DelayCall(Spring.GiveOrderToUnit, {unitID, GG.CustomCommands.GetCmdID("CMD_RETURN"), {}, {}}, 5)
	end
end]]


function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	--Spring.Echo("CommandFallback",unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if not localCMDs[cmdID] then
		-- It was a different command, do nothing
		return false
	end
	local ud = UnitDefs[unitDefID]
	local cp = ud and ud.customParams
	if not cp or not cp.capacity then
		-- Don't take any action, the unit shouldn't be able to seliver 
		--(we consider that they didn't get a delivery command)
		return false
	end
	if cmdID == CMD_DELIVER then
		local delivery = deliverys[unitID]
		-- unit already on a delivery? => (should always be true if this point is reached)
		--if delivery then 
		--Spring.Echo("CommandFallback found a CMD_DELIVERY")
		local x, y, z = GetUnitPosition(unitID)
		-- target still exists? =>
		if Spring.ValidUnitID(delivery.target) and not Spring.GetUnitIsDead(delivery.target) then
			-- unit arrived at target?=>
			local distance2 = (x - delivery.x)^2 + (z - delivery.z)^2
			if distance2 < MIN_DIST2 then -- arrived, transfer resource
				--Spring.Echo("I arrived! Better transfer resources", delivery.resource, delivery.amount)
				--GG.Resources.TransferUnitResource(unitID, delivery.target, delivery.resource, delivery.amount)
				local worker = GG.GetObjectFromID(unitID)
				worker:TransferResource(delivery.target, delivery.resource, delivery.amount)
				--GoHome(unitID)
				worker:TaskNextCmd()
				return true, true
			else -- not there yet, move closer
				SetUnitMoveGoal(unitID, delivery.x, 0, delivery.z, STOP_DIST)
				return true, false -- used, not finished
			end
		else -- target no longer exists, rtb with cargo
			GoHome(unitID)
			return true, true
		end
	elseif cmdID == CMD_RETURN then
		if returning[unitID] then -- returning home
			local delivery = returning[unitID] -- TODO rename
			local x, y, z = GetUnitPosition(unitID)
			if Spring.ValidUnitID(delivery.target) and not Spring.GetUnitIsDead(delivery.target) then
				-- unit arrived at target?=>
				local distance2 = (x - delivery.x)^2 + (z - delivery.z)^2
				--Spring.Echo("CommandFallback found a CMD_RETURN", distance2, MIN_DIST2)
				if distance2 < MIN_DIST2 then -- arrived home, delivery complete
					--Spring.Echo("I'm home mofo!", math.sqrt(distance2), MIN_DIST2)
					returning[unitID] = nil
					local worker = GG.GetObjectFromID(unitID)
					--worker:SetIdle()
					worker:TaskNextCmd()
					return true, true -- used, finished
				else -- not there yet, move closer
					SetUnitMoveGoal(unitID, delivery.x, 0, delivery.z, STOP_DIST)
					--Spring.MarkerAddPoint(delivery.x, 0, delivery.z)
					--Spring.Echo("brap")
					return true, false
				end
			else -- home base no longer exists, now what? probably go there first and find out, then nearest warehouse? or force all workers home before decomissioning? (exploitable?)
				Spring.Echo("Ummm, my home base no longer exists, halp please")
			end
		end
	elseif cmdID == CMD_BUILD then
		local delivery = buildsites[unitID]
		local x, y, z = GetUnitPosition(unitID)
		-- TODO: work until tired, rather than until the building is finished
		if Spring.ValidUnitID(delivery.target) and not Spring.GetUnitIsDead(delivery.target) then
			-- unit arrived at target?=>
			local distance2 = (x - delivery.x)^2 + (z - delivery.z)^2
			if distance2 < MIN_DIST2 then -- arrived, now build
				local site = GG.GetObjectFromID(delivery.target)
				if site and site.readyToBuild then
					if site.buildLeft > 0 then
						site:BuildStep(1)
						return true, false -- used, not yet finished check again
					end
				end
				GoHome(unitID)
				return false, true -- no site, finish
			else -- not there yet, move closer
				SetUnitMoveGoal(unitID, delivery.x, 0, delivery.z, STOP_DIST)
				--Spring.MarkerAddPoint(delivery.x, 0, delivery.z)
				--Spring.Echo("brap")
				return true, false
			end
		end
	else
		return false, true
	end
end

function gadget:UnitDestroyed(unitID)
	deliverys[unitID] = nil
	returning[unitID] = nil
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local ud = UnitDefs[unitDefID]
	local cp = ud.customParams

end

function gadget:Initialize()
	-- Fake UnitCreated events for existing units. (for '/luarules reload')
	local allUnits = Spring.GetAllUnits()
	for i=1,#allUnits do
		local unitID = allUnits[i]
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
	Spring.SetCustomCommandDrawData(CMD_RETURN, "Returning", {1,0.5,0,.8}, false)
	Spring.SetCustomCommandDrawData(CMD_DELIVER, "Delivery", {1,0.5,0,.8}, false)
end


else

-- UNSYNCED

end
