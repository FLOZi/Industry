-- USEFUL FUNCTIONS & INCLUDES
VFS.Include("LuaRules/Includes/utilities.lua", nil, VFS.ZIP)

local function RecursiveReplaceStrings(t, name, replacedMap)
	if (replacedMap[t]) then
		return  -- avoid recursion / repetition
	end
	replacedMap[t] = true
	local changes = {}
	for k, v in pairs(t) do
		if (type(v) == 'string') then
			t[k] = v:gsub("<NAME>", name)
		end
		if (type(v) == 'table') then
			RecursiveReplaceStrings(v, name, replacedMap)
		end
	end 
end

local function ReplaceStrings(t, name)
	local replacedMap = {}
	RecursiveReplaceStrings(t, name, replacedMap)
end

local BUILDYARD
local OPTIONS = {}
-- Process ALL the units!
for name, ud in pairs(UnitDefs) do
	if name == "log_buildersyard" then 
		BUILDYARD = ud 
		BUILDYARD["buildoptions"] = {}
	end
	-- Replace all occurences of <NAME> with the respective values
	ReplaceStrings(ud, ud.unitname or name)
	--Spring.Echo(name)
	local cp = ud.customparams
	-- convert all customparams subtables back into strings for Spring
	if cp then
		if cp.baseclass == "Building" then
			table.insert(OPTIONS, name)
		end
		for k, v in pairs (cp) do
			if type(v) == "table" or type(v) == "boolean" then
				cp[k] = table.serialize(v)
			end
		end
	end
	
end

for name, ud in pairs(UnitDefs) do
	--table.insert(BUILDYARD["buildoptions"], name)
end
BUILDYARD["buildoptions"] = OPTIONS