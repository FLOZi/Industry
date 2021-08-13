function gadget:GetInfo()
	return {
		name = "Resource Manager",
		desc = "Manages Resources",
		author = "FLOZi (C. Lawrence)",
		date = "19/08/2018",
		license = "GNU GPL v2",
		layer = -1,
		enabled = false,--true
	}
end

if (gadgetHandler:IsSyncedCode()) then
--SYNCED

-- TODO: move to lus_helper
local function UnitScriptCall(unitID, func, args)
	env = Spring.UnitScript.GetScriptEnv(unitID)
	if env[func] then
		Spring.UnitScript.CallAsUnit(unitID, env[func], unpack(args))
	end
end

local unitResources = {} -- [unitID] = {resourceName1 = amount, ...}

local unitDefStorages = {} -- [unitDefID] = {resourceName1 = storage, ...}

local function GetUnitResource(unitID, resource)
	if unitResources[unitID] then
		return (unitResources[unitID][resource] or 0)
	else
		Spring.Echo("[game_resources] WARNING: Tried to get resource on an unknown unit")
	end
end

local function SetUnitResource(unitID, resource, amount) -- absolute
	if unitResources[unitID] then
		Spring.Echo("Unit: " .. unitID .. " (" .. UnitDefs[Spring.GetUnitDefID(unitID)].name .. ") now has " .. amount .. " " .. resource)
		--if amount <= unitDefStorages[Spring.GetUnitDefID(unitID)][resource] then
			unitResources[unitID][resource] = amount
			SendToUnsynced("SetUnitResourceEvent", unitID, resource, amount)
		--else
			-- TODO: figure out what to do if storage is full
			--Spring.Echo(unitID, "Storage full for", resource)
		--end
	else
		Spring.Echo("[game_resources] WARNING: Tried to set resource on an unknown unit")
	end
end

local function ChangeUnitResource(unitID, resource, amount) -- relative
	SetUnitResource(unitID, resource, (GetUnitResource(unitID, resource) or 0) + amount)
end

-- Wrappers
local function AddUnitResource(unitID, resource, amount)
	if amount > 0 then
		ChangeUnitResource(unitID, resource, amount)
		UnitScriptCall(unitID, "ResourceGain", {resource, amount})
		return true
	end
	return false
end

local function SubtractUnitResource(unitID, resource, amount)
	if amount > 0 
	and GetUnitResource(unitID, resource) >= amount then
		ChangeUnitResource(unitID, resource, -amount)
		return true
	end
	return false
end

local function TransferUnitResource(from, to, resource, amount)
	if SubtractUnitResource(from, resource, amount) then
		return AddUnitResource(to, resource, amount)
	end
	return false
end

-- Make available globally
GG.Resources = {}
GG.Resources.GetUnitResource = GetUnitResource
GG.Resources.SetUnitResource = SetUnitResource
GG.Resources.ChangeUnitResource = ChangeUnitResource
GG.Resources.AddUnitResource = AddUnitResource
GG.Resources.SubtractUnitResource = SubtractUnitResource
GG.Resources.TransferUnitResource = TransferUnitResource

function gadget:Initialize()
	for unitDefID, unitDef in pairs(UnitDefs) do
		local cp = unitDef.customParams
		for k,v in pairs(cp) do Spring.Echo(k,v) end
		if cp.stores then
			unitDefStorages[unitDefID] = {}
			for resource, storage in pairs(table.unserialize(cp.stores)) do -- TODO: just unserialize everything?
				unitDefStorages[unitDefID][resource] = storage
				Spring.Echo(unitDef.name, resource, storage)
			end
		end
	end
end

local sources = {} -- sources[resource] = {unitID1, ...}
local sinks = {}

function gadget:UnitCreated(unitID, unitDefID, teamID)
	unitResources[unitID] = {}
end

else -- UNSYNCED

local function HandleSetUnitResourceEvent(cmd, unitID, resource, amount)
	-- TODO
	Spring.Echo("UNSYNCED", unitID, resource, amount)
	if Script.LuaUI("UnitResourceSetUIEvent") then
		Script.LuaUI.UnitResourceSetUIEvent(unitID, resource, amount)
	end
end
	
function gadget:Initialize()
	gadgetHandler:AddSyncAction("SetUnitResourceEvent", HandleSetUnitResourceEvent)
end
	
end