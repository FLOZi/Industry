
function ResourceGain(resource, amount)
	--Spring.Echo("Hey, I gained", resource, amount)
end

local costs = table.unserialize(unitDef.customParams.costs)
local pCents = {}
pCents.bricks = 0
pCents.timber = 0
local stage = 1
local numParts = #(Spring.GetUnitPieceList(unitID)) - 1-- TODO: read & cache in lushelper

local parts = {}
for i = 1, numParts do
	parts[i] = piece(tostring(i))
end

function AddUnitBuildProgress(toAdd)
	local curr = select(5, Spring.GetUnitHealth(unitID)) * 100
	curr = curr + (toAdd or 1)
	--Spring.Echo("My current buildprogress", curr, curr/100, stage/numParts, stage)
	Spring.SetUnitHealth(unitID, {build = curr/100})
		if (curr/100) > (stage/numParts) then
			Show(parts[stage])
			stage = stage + 1
		end
end


function ConstructGain(resource, amountRequired)
	pCents[resource] = 1 - amountRequired/costs[resource]
end

--[[local function Cheat()
	while select(5, Spring.GetUnitHealth(unitID)) < 1 do 
		Spring.Echo("Cheat!")
		--GG.Resources.ConstructUnitResource(unitID, nil, "bricks", 2)
		--GG.Resources.ConstructUnitResource(unitID, nil, "timber", 1)
		AddUnitBuildProgress(unitID, 10)
		Sleep(2000)
	end
end]]

--[[local function BuildUp()
	local stage = 1
	while select(5, Spring.GetUnitHealth(unitID)) < 1 do -- build percent left
		local buildProgress = select(5, Spring.GetUnitHealth(unitID))
		if buildProgress > stage/numParts then
			Show(piece(tostring(stage)))
			stage = stage + 1
		end
		--Spring.Echo("My buildprogress is", buildProgress)
		Sleep(500)
	end
	-- for cheated units, force everything to be visible TODO: remove this depending on final model hiearchy and 'scaffolds'
	for i = 1, numParts do
		Show(piece(tostring(i)))
	end
end]]

function script.Create()
	Sleep(32)
	local buildProgress = select(5, Spring.GetUnitHealth(unitID))
	--Spring.Echo("BP", buildProgress)
	if select(5, Spring.GetUnitHealth(unitID)) == 0 then
		for i = 1, numParts do
			local j = piece(tostring(i))
			Hide(j)
		end
	end
	--StartThread(BuildUp)
	if unitDef.name == "log_buildersyard" then
		Spring.SetUnitBlocking(unitID, false, false)
	end
	if not unitDef.name:find("field") then
		Spring.SetUnitHealth(unitID, {build = 1/100}) -- prevent decay
	end
	--StartThread(Cheat)
end