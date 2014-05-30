--==============================================================================
-- Debug
--==============================================================================



--==============================================================================
-- Dependency
--==============================================================================



--==============================================================================
-- Data Structure
--==============================================================================

local Class = {}


--==============================================================================
-- Private Methods
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

function Class.Open (path, intermediate_code)
  if (_DEBUG) then print("MCG :: Open") end
  assert(path)
  assert(intermediate_code and type(intermediate_code) == "table")
  local ok, msg = pcall(function ()
  end)
  if (not ok) then
    return false, msg
  end
  return true
end


--==============================================================================
-- Return
--==============================================================================

return Class