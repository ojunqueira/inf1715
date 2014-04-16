--==============================================================================
-- Debug
--==============================================================================



--==============================================================================
-- Dependency
--==============================================================================



--==============================================================================
-- Data Structure
--==============================================================================

local Nodes = {}

-- code of each node
--  {
--    ["node id"] = $number,
--  }
local codes = {
  ["ATTRIBUTION"] = 01,
  ["CALL"]        = 02,
  ["DECLARE"]     = 03,
  ["DENY"]        = 04,
  ["ELSEIF"]      = 05,
  ["FUNCTION"]    = 06,
  ["IF"]          = 07,
  ["NEWVAR"]      = 08,
  ["OPERATOR"]    = 09,
  ["PARAMETER"]   = 10,
  ["PARENTHESIS"] = 11,
  ["PROGRAM"]     = 12,
  ["RETURN"]      = 13,
  ["VALUE"]       = 14,
  ["VAR"]         = 15,
  ["WHILE"]       = 16,
}


--==============================================================================
-- Public Methods
--==============================================================================

function Nodes.GetNodesList ()
  return codes
end

function Nodes.GetNodeName (node_code)
  assert(type(node_code) == "number")
  for name, code in pairs(codes) do
    if (code == node_code) then
      return name
    end
  end
  return nil
end


--==============================================================================
-- Private Methods
--==============================================================================



--==============================================================================
-- Return
--==============================================================================

return Nodes