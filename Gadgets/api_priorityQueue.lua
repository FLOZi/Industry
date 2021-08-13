function gadget:GetInfo()
	return {
		name      = "API Priority Queue",
		desc      = "Naieve min priority queue",
		author    = "FLOZi",
		date      = "3 August 2021", -- lol rona
		license   = "GNU LGPL, v2.1 or later",
		layer     = -10000,
		enabled   = true  --  loaded by default?
	}
end

local pqueue = {}
GG.pqueue = pqueue

pqueue.new = function(self)
	local new = {}
	table.copy(self, new)
	return new
end

--synced only
if not gadgetHandler:IsSyncedCode() then return end

pqueue.insert = function (self, item, priority)
	local entry = {}
	entry["item"] = item
	entry["p"] = priority
	
	local index = #self + 1 -- assume we are the highest (worst) priority
	for i, element in ipairs(self) do
		if priority > element.p then
			index = i
			break
		end
	end
	table.insert(self, index, entry)

	--[[Spring.Echo("BEGIN PQUEUE DUMP")
	for i, element in ipairs(self) do
		if element then
			Spring.Echo("\t", i, element.item, element.p)
		end
	end
	Spring.Echo("END PQUEUE DUMP")--]]
end

pqueue.peek = function (self)
	if #self > 0 then 
		return self[#self].item, self[#self].p
	else
		return nil
	end
end

pqueue.pop = function (self)
	if #self > 0 then 
		local element = self[#self]
		self[#self] = nil
		return element.item, element.p
	else
		return nil
	end
end