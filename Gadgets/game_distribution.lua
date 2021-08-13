function gadget:GetInfo()
	return {
		name = "Distribution Manager",
		desc = "Distributes Resources",
		author = "FLOZi (C. Lawrence)",
		date = "31/08/2018",
		license = "GNU GPL v2",
		layer = -1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
--SYNCED

--sourceData = {x, z, output, allocated}
--sinkData = {x, z, requires, allocated}

--mySinkData = {id, dist, eta, requires, allocated} 

--resourceSourceDatas[resource][unitID] = sourceData
--resourceSinkDatas[resource][unitID] = sinkData

--sourceSinks[unitID] = {sinkdata1, ...}
local sourceSinks = {}
--sinkSources[unitID] = {

--unallocatedCache[unitID] = amountUnallocated



--[[ new source appears for resource x =>
function NewSource(resource, source, output)
	local x,z = GetUnitPosition(source)
	CreateSourceData()
	for sinkID, sinkData in resourceSinkDatas[resource] do
		local dist = FindDistance(source, sinkID)
		local eta = EstimateTime(dist)
		local mySinkData = {dist = dist, eta = eta, requires = sinkData.requires, allocated = sinkData.allocated}
		Insert(sourceSinks[sinkID], sinkData)
	end
	table.sort(sourceSinks[source]) -- into ascending order of eta
	AllocateSource(source, output) -- allocate the entire new output
end]]


-- new sink appears for x =>
-- well crap, we need to reallocate a bunch of stuff
-- start with sources in increasing order of distance from the new sink and quit once the new sink is satiated?


-- i got pies!
-- look through list of pie eaters
-- priority = distance / time_since_last_pie
-- sort the pie eaters by priority
-- this pie gets sent to that pie eater

end