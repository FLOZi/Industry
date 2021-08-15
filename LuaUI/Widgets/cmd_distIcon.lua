function widget:GetInfo()
	return {
		name = "1944 Icon Distance",
		desc = "Sets Icon Distance to a suitable level for Spring: 1944",
		author = "Craig Lawrence",
		date = "09-12-2008",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local unitIconDist = 0

local unitResources = {}


local function SetUnitResourceUI(unitID, resource, amount)
	--Spring.Echo("LUAUI", unitID, resource, amount)
	if not unitResources[unitID] then unitResources[unitID] = {} end
	unitResources[unitID][resource] = amount
end

function widget:Initialize()
	unitIconDist = Spring.GetConfigInt('UnitIconDist')
	Spring.SendCommands("disticon 2500")
	
	widgetHandler:RegisterGlobal("SetUnitResourceUIEvent", SetUnitResourceUI)
end

function widget:Shutdown()
	Spring.SetConfigInt('UnitIconDist', unitIconDist)
	widgetHandler:DeregisterGlobal("SetUnitResourceUIEvent")
end

local function ResourceCounter(resourceTable, height)
	gl.PushMatrix()
	gl.Billboard()
	for resource, amount in pairs(resourceTable) do
		if amount > 0 then
			gl.Text(resource .. ": " .. amount, 0, height + 8, 20, "c")
			height = height + 16
		end
	end
	gl.PopMatrix()
end

function widget:DrawWorldPreUnit()
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		if (Spring.IsUnitVisible(unitID)) then
			if unitResources[unitID] then
				gl.DrawFuncAtUnit(unitID, true, ResourceCounter, unitResources[unitID], math.max(Spring.GetUnitHeight(unitID), 0))
			end
		end
	end
end