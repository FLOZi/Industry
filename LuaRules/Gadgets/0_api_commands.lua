function gadget:GetInfo()
  return {
    name      = "1944 Custom Command Handler",
    desc      = "Generates Custom Command IDs",
    author    = "FLOZi (C. Lawrence)",
    date      = "21 January 2012",
    license   = "GNU GPL v2",
    layer     = -math.huge,
    enabled   = true,
  }
end

-- DRAGONS BE HERE! Do not rename this file!
-- The filename of this file starts with a 0 to ensure that it is loaded before all other gadgets
-- Note that loading order != execution order, which is what layer in GetInfo controls!

-- Setup
GG.CustomCommands = {}
GG.CustomCommands.numCmds = 0
GG.CustomCommands.IDs = {}
GG.CustomCommands.names = {}

_G.CustomCommandIDs = {}

-- Constants
local BASE_CMD_ID = 1001

-- Variables
local customCommands = GG.CustomCommands

local function GetCmdID(name)
	if (not customCommands) then
		customCommands = GG.CustomCommands
	end
	local cmdID = customCommands.IDs[name]
	if not cmdID then
		cmdID = BASE_CMD_ID + customCommands.numCmds
		customCommands.numCmds = customCommands.numCmds + 1
		customCommands.IDs[name] = cmdID
		_G.CustomCommandIDs[name] = cmdID
		GG.CustomCommands.names[cmdID] = name
		gadgetHandler:RegisterCMDID(cmdID)
	end
	return cmdID
end

GG.CustomCommands.GetCmdID = GetCmdID

if (gadgetHandler:IsSyncedCode()) then
  function gadget:Initialize()
    for name, cmdID in pairs(customCommands.IDs) do
      Spring.SetGameRulesParam(name, cmdID)
    end
  end
end

