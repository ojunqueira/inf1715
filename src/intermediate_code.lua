--==============================================================================
-- Debug
--==============================================================================



--==============================================================================
-- Dependency
--==============================================================================

local NodesClass = require "lib/node_codes"


--==============================================================================
-- Data Structure
--==============================================================================

local IntermediateCodeGen = {}

local file

--  list of nodes code
--  {
--    [name] = $number,
--  }
local nodes_codes = NodesClass.GetNodesList()


--==============================================================================
-- Private Methods
--==============================================================================

local function Error (msg)
  local str = string.format("intermediate code generator error: %s", msg or "")
  error(str, 0)
end

local function Write (msg)
  file:write(msg)
end


--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

--Open:
--  parameters:
--    [1] $string   - 
--    [2] $table    - 
--  return:
--    [1] $boolean  - false if found any problem, true otherwise
--    [2] $string   - only when [1] is false, informing which error occurs
function IntermediateCodeGen.Open (path, tree)
  if (_DEBUG) then print("ICG :: Open") end
  local ok, msg = pcall(function ()
    local f = io.open(path, "w")
    if (not f) then
      Error(string.format("output file '%s' could not be opened"), path)
    end
    file = f
    --  GENERATE CODE
    f:close()
  end)
  if (not ok) then
    return false, msg
  end
  return true
end


--==============================================================================
-- Return
--==============================================================================

return IntermediateCodeGen