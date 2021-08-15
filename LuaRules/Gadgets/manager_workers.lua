function gadget:GetInfo()
	return {
		name = "Worker Manager",
		desc = "Manages worker command issuing",
		author = "FLOZi (C. Lawrence)",
		date = "30/10/2018",
		license = "GNU GPL v2",
		layer = -1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
--SYNCED

local OBJECTS = {}
local OBJECTFACTORY = {}
local TICKERS = {}

function GetObjectFromID(id)
	return OBJECTS[id]
end
GG.GetObjectFromID = GetObjectFromID
GG.ObjectFactory = OBJECTFACTORY

local Object = {}
-- attributes
Object.resources = {}
Object.defName = ""

-- methods
Object.New = function(self, typeName)
	local new = {}
	table.copy(self, new)
	new.type = typeName or ""
	OBJECTFACTORY[new.type] = new
	return new
end

Object.Begin = function(self, defName, x,y,z, facing, noBuild)
	local new = self:New()
	if type(defName) ~= "string" then -- TODO: get rid of this crap
		defName = UnitDefs[defName].name
	end
	new.defName = defName
	if not x then
		x, y, z = Spring.GetTeamStartPosition(0)
	end
	new.xyz = {x, y, z}
	new.id = Spring.CreateUnit(defName, x,y,z, facing or 0, 0, (not noBuild) and self.buildSite)
	local ud = UnitDefNames[defName]
	local cp = ud.customParams
	new.buildTime = ud.buildTime
	new.buildLeft = ud.buildTime
	if cp.costs then
		new.costs = table.unserialize(cp.costs)
		new.needs = table.unserialize(cp.costs)
	end
	new.stores = table.unserialize(cp.stores)
	
	OBJECTS[new.id] = new
	return new
end

Object.ReceiveResource = function(self, resource, amount)
	--Spring.Echo(self.id .. "(" .. self.defName .. ") received " .. amount .. " " .. resource)
	if self.costs and self.costs[resource] then -- if for construction deduct from costs
		self.costs[resource] = math.max(self.costs[resource] - amount, 0)
		local remain = 0
		for resource, cost in pairs(self.costs) do
			remain = remain + cost
		end
		if remain <= 0 then
			Spring.Echo(self.defName, "All costs satisfied! Commence building.")
			self.readyToBuild = true
			self.costsTask:Finish()
		end
	else -- otherwise add to our stockpile TODO: limited storage
		self.resources[resource] = (self.resources[resource] or 0) + amount
		SendToUnsynced("SetUnitResourceEvent", self.id, resource, self.resources[resource])
	end
	--SendToUnsynced("SetUnitResourceEvent", self.id, resource, self.resources[resource])
end

Object.TransferResource = function(self, to, resource, amount)
	-- TODO: sanity check on separation?
	if (self.resources[resource] or 0) >= amount then
		self.resources[resource] = self.resources[resource] - amount
		SendToUnsynced("SetUnitResourceEvent", self.id, resource, self.resources[resource])
	end
	OBJECTS[to]:ReceiveResource(resource, amount)
end

GG.Object = Object

-- WORKER
local Worker = Object:New("worker")
-- attributes
Worker.name = ""
Worker.workplace = nil
Worker.idle = true
Worker.currTask = {}

-- methods
Worker.SetName = function(self, newName)
	self.name = newName
	--Spring.Echo("Hello, my name is " .. newName)
end

Worker.Begin = function(self, x, y, z)
	local newWorker = Object.Begin(self, "folk_male", x,y,z)
	local ud = UnitDefs[Spring.GetUnitDefID(newWorker.id)]
	local cp = ud.customParams
	local names = table.unserialize(cp.names)
	newWorker:SetName(names[1][math.random(1, #names[1])] .. " " .. names[2][math.random(1, #names[2])])
	Spring.SetUnitTooltip(newWorker.id, newWorker.name)
	return newWorker
end

Worker.Assign = function(self, buildingID)
	self.workplace = buildingID
end
Worker.SetIdle = function(self, idle)
	--Spring.Echo("Worker", self.name, "is now idle")
	self.idle = idle
	local building = GetObjectFromID(self.workplace)
	building.idleWorkers[self.id] = idle or nil
	--if idle then
		-- insert at end of queue
		--table.insert(building.idleWorkers, self.id, #building.idleWorkers)
	--else
		-- remove from start of queue
		-- this should be safe so long as this function is always used to do it?
		--table.remove(building.idleWorkers, self.id)
	--end
end

Worker.TaskAllocated = function(self, task)
	self.currTask = task
	self:SetIdle(false)
end

Worker.TaskNextCmd = function(self)
	self.currTask:NextCommand(self.id)
end

Worker.TaskFinished = function(self)
	self.currTask = nil
	self:SetIdle(true)
end

-- TASK
local Task = Object:New("task")
Task.name = ""

Task.limit = nil
Task.allocated = 0

Task.cmdQ = {} -- {[1]={id = cmdID, params = {cmdParams}}, ...}
Task.workerIndex = {} -- workerID = CmdQIndex
Task.building = nil

Task.Create = function (self, cmdQ, limit, name)
	local new = Task:New()
	new.cmdQ = cmdQ
	new.limit = limit
	new.name = name
	return new
end

Task.NextCommand = function(self, workerID)
	local nextIndex = self.workerIndex[workerID] + 1
	if nextIndex > #self.cmdQ then nextIndex = 1 end -- commands can repeat without the task being finished 
	local nextCmd = self.cmdQ[nextIndex]
	Spring.Echo(workerID, "NextCommand", GG.CustomCommands.names[nextCmd.id])
	GG.Delay.DelayCall(Spring.GiveOrderToUnit, {workerID, nextCmd.id, nextCmd.params, table.empty}, 10)
	self.workerIndex[workerID] = nextIndex
end

Task.AllocateWorker = function(self, workerID) -- or worker object?
	-- Allocation tracking
	if self.allocated == self.limit then return false end
	self.allocated = self.allocated + 1
	-- Start the worker on the task
	self.workerIndex[workerID] = 0
	self:NextCommand(workerID)
	local workerObject = OBJECTS[workerID]
	workerObject:TaskAllocated(self)
end

Task.Finish = function(self)
	-- let the workers know
	for workerID in pairs(self.workerIndex) do
		local workerObject = OBJECTS[workerID]
		workerObject:TaskFinished()
	end
	-- cleanup
	self.allocated = 0
	self.workerIndex = nil
	-- let the building know
	self.building:TaskFinished(self)
end

-- BUILDING
local Building = Object:New("building")
-- attributes
Building.workers = {}
Building.workerCount = 0
Building.maxWorkers = 2 -- probably overriden by most buildings?
Building.idleWorkers = {} -- FIFO list

Building.costs = nil
Building.needs = nil
Building.buildTime = 0
Building.buildLeft = 0
Building.buildSite = true
Building.yardID = nil
Building.readyToBuild = false
Building.inProgress = false
Building.finished = false
Building.maxBuilders = 2
Building.costsTask = nil
Building.buildTask = nil

Building.stores = nil

-- methods
-- Worker methods
Building.AssignWorker = function (self, worker)
	if self.workerCount < self.maxWorkers then
		worker:Assign(self.id)
		self.workers[worker.id] = true
		self.workerCount = self.workerCount + 1
		--table.insert(self.idleWorkers, worker.id)--, #self.idleWorkers)
		self.idleWorkers[worker.id] = true
		--Spring.Echo("Building " .. self.defName .. " now has " .. self.workerCount .. " workers")
	else
		Spring.Echo("Building " .. self.id .. "tried to AssignWorker but has maximum (" .. self.maxWorkers .. ")")
	end
end
Building.UnassignWorker = function (self, workerID)
	if self.workerCount > 0 then
		self.workers[workerID] = nil
		self.workerCount = self.workerCount - 1
		--Spring.Echo("Building " .. self.id .. " now has " .. self.workerCount .. " workers")
		-- TODO: call Worker:SetIdle() to remove from idle queue?
		self.idleWorkers[workerID] = nil
	else
		Spring.Echo("Building " .. self.id .. " tried to UnassignWorker but already has 0")
	end
end
--[[Building.OrderWorker = function (self, cmdID, cmdParams, cmdOpts, limit)
	if self.workerCount > 0 then
		local availableWorkers = #self.idleWorkers
		limit = limit or #self.idleWorkers
		Spring.Echo("Building", self.defName, "has ", limit, "workers to order about")
		--if availableWorker then
		if availableWorkers > 0 then
			Spring.GiveOrderToUnitArray({unpack(self.idleWorkers, 1, limit)}, cmdID, cmdParams, cmdOpts or table.empty)
			table.remove(self.idleWorkers, limit)
		else
			Spring.Echo("Building " .. self.id .. " has no available worker to execute command")
		end
	end
end]]

-- Building site construction methods
Building.BuildStep = function(self, amount)
	env = Spring.UnitScript.GetScriptEnv(self.id)
	if env and env.AddUnitBuildProgress then
		Spring.UnitScript.CallAsUnit(self.id, env.AddUnitBuildProgress, (amount/self.buildTime)*100)
	end
	self.buildLeft = self.buildLeft - amount
	if self.buildLeft <= 0 then
		local yard = OBJECTS[self.yardID]
		yard:RemoveSite()
		self.finished = true
		table.insert(TICKERS, self)
		self.buildTask:Finish()
	end
end
Building.SetYard = function (self, yardID)
	self.yardID = yardID
end

-- YARD (subclass of Building)
local Yard = Building:New("yard")
-- attributes
Yard.maxWorkers = 10
Yard.sites = GG.pqueue:new() -- priority queue

local function PriorityFunction(dist, cost, priority)
	return dist * cost * (priority or 1)
end

-- method
Yard.AddSite = function(self, siteID)
	local site = GetObjectFromID(siteID)
	local priority = PriorityFunction(Spring.GetUnitSeparation(self.id, siteID), (site.costs.bricks or 0) + (site.costs.timber or 0))
	Spring.Echo("Adding site " .. siteID .. " to yard " ..self.id .. " priority " .. priority)
	site.yardID = self.id
	self.sites:insert(site, priority)
	local costsCmdQ = {
		[1] = {
			id = GG.CustomCommands.GetCmdID("CMD_DELIVER"),
			params = {siteID},
		},
		[2] = {
			id = GG.CustomCommands.GetCmdID("CMD_RETURN"),
			params = table.empty,
		},
	}
	local buildCmdQ = {
		[1] = {
			id = GG.CustomCommands.GetCmdID("CMD_BUILD"),
			params = {siteID},
		},
	}
	site.costsTask = Task:Create(costsCmdQ, site.maxBuilders, "costs")
	site.costsTask.building = self
	local allocated = 0
	while allocated <= site.maxBuilders do
		local workerID = next(self.idleWorkers)
		Spring.Echo("allocated", allocated, "workerID", workerID)
		if workerID then
			site.costsTask:AllocateWorker(workerID)
			allocated = allocated + 1
		else break end -- no more idle workers
	end
		
	--[[if self.idleWorkers[1] then
		local allocated = 0
		
		for i = 1, math.min(site.maxBuilders, #self.idleWorkers) do
			site.costsTask:AllocateWorker(self.idleWorkers[i])
			allocated = i
		end
		for i = 1, allocated do -- TODO: improve this mess. Maybe implement as a stack from the end rather than the start?
			table.remove(self.idleWorkers, 1)
		end
	end]]
	site.buildTask = Task:Create(buildCmdQ, site.maxBuilders, "build")
	site.buildTask.building = self
end

Yard.TaskFinished = function(self, task)
	if task.name == "costs" then
		--[[if self.idleWorkers[1] then
			local taskSite = GetObjectFromID(task.cmdQ[1].params[1])
			for i = 1, math.min(task.limit, #self.idleWorkers) do
				taskSite.buildTask:AllocateWorker(self.idleWorkers[i])
			end
		end]]
		local taskSite = GetObjectFromID(task.cmdQ[1].params[1])
		local allocated = 0
		while allocated <= task.limit do
			local workerID = next(self.idleWorkers)
			Spring.Echo("allocated", allocated, "workerID", workerID)
			if workerID then
				taskSite.buildTask:AllocateWorker(workerID)
				allocated = allocated + 1
			else break end -- no more idle workers
		end
	elseif task.name == "build" then
		Spring.Echo("Build task completed")
	end
end

Yard.CurrentSite = function(self)
	return self.sites:peek()
end

Yard.RemoveSite = function(self)
	local site, p = self.sites:pop()
	--local task, _ = self.tasks:pop()
	--task:Finish()
	Spring.Echo("Site is finished, remove it", site.id, site.defName)
end

Yard.Tick = function (self)
	--[[local site, p = self:CurrentSite()
	if site then
		--Spring.Echo("Yard Tick", site.id, site.defName, p)
		if self.idleWorkers[1] then -- we have a current site and idle workers
			--Spring.Echo("Yard has currSite and idle workers")
			if not site.readyToBuild then -- needs more building resources
				--Spring.Echo("Site is not readyToBuild")
				self:OrderWorker(GG.CustomCommands.GetCmdID("CMD_DELIVER"), {site.id}, table.empty, site.maxBuilders)
			elseif not site.inProgress then -- has resources, now build
				--Spring.Echo("Site is not inProgress")
				self:OrderWorker(GG.CustomCommands.GetCmdID("CMD_BUILD"), {site.id},  table.empty, site.maxBuilders)
				site.inProgress = true
			end
		end
	end]]
end

-- FIELD (Subclass of Building)

local Wheat = {} -- todo, stick all this in a unitdef customparam
Wheat.resource = "wheat"
Wheat.sowingRate = 1 -- how many worker ticks are required to sow each square
Wheat.growthRate = 1 -- %/tick
Wheat.harvestRate = 1 -- how much is harvested per worker tick
Wheat.spoilRate = 1 -- how quickly the crop deteriorates after harvesting window passes

local Field = Building:New("field")

-- attributes
--Field.rotation = {"wheat", "turnip", "barley", "clover"}
Field.crop = Wheat
Field.yieldMult = 1 -- for +/- effects like manure, disease etc
Field.yield = 0 -- each 'square' produces 1 so a 16x16 produces 256 if all is sown and harvested
Field.state = 0 -- 1 sowing, 2 growing, 3 harvesting, 4 spoiling
Field.growth = 0
Field.maxWorkers = 5 

Field.Tick = function (self)
	--Spring.Echo("I'm ticking!", self.crop.resource)
	self:ReceiveResource(self.crop.resource, 1)
	if self.workerCount > 0 then
		if self.state == 1 then -- sowing
			self.yield = self.yield + self.workerCount * self.crop.sowingRate
		elseif self.state >= 3 and self.yield > 0 then -- harvesting
			local collected = self.workerCount * self.crop.harvestRate
			self.yield = math.max(self.yield - collected, 0)
			GG.Resources.AddUnitResource(self.id, self.crop.resource, collected)
		end
	elseif self.state == 2 then -- growing doesn't require workers present
		self.growth = self.growth + self.crop.growthRate
	end
	if self.state == 4 and self.yield > 0 then -- spoiling
		self.yield = self.yield - self.crop.spoilRate
	end	
end


function gadget:GameStart()
	-- TODO: Move all this to game setup gadget
	local x, y, z = Spring.GetTeamStartPosition(0)
	local yard1 = Yard:Begin("log_buildersyard", x,y,z, 0, true)
	yard1.costs = nil
	yard1:ReceiveResource("bricks", 100)
	yard1:ReceiveResource("timber", 100)
	TICKERS[1] = yard1
	for i = 1, 10 do
		yard1:AssignWorker(Worker:Begin())
	end
end

function gadget:GameFrame(n)
	if n % 10 == 0 then
		for i = 1, #TICKERS do
			TICKERS[i]:Tick()
		end
	end
end

function gadget:UnitFinished(unitID)
	local object = GetObjectFromID(unitID)
	if object and object.type ~= "worker" then
		for i = 1, 2 do -- TODO: remove hack!
			object:AssignWorker(Worker:Begin(unpack(object.xyz)))
		end
	end
end


else -- UNSYNCED

local function HandleSetUnitResourceEvent(cmd, unitID, resource, amount)
	--Spring.Echo("UNSYNCED", unitID, resource, amount)
	if Script.LuaUI("SetUnitResourceUIEvent") then
		Script.LuaUI.SetUnitResourceUIEvent(unitID, resource, amount)
	end
end
	
function gadget:Initialize()
	gadgetHandler:AddSyncAction("SetUnitResourceEvent", HandleSetUnitResourceEvent)
end

end