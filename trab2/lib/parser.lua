--==============================================================================
-- Dependency
--==============================================================================



--==============================================================================
-- Data Structure
--==============================================================================

local Parser = {}

-- store tokens list received in input
local tokens_list = {}

-- keep the number of the current token
local current = 0


--==============================================================================
-- Private Methods
--==============================================================================



--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

--Advance:
--  parameters:
--  return:
function Parser.Advance ()
  if (_DEBUG) then print("PAR :: Advance") end
  current = current + 1
end

--Open:
--  parameters:
--    [1] $table   - table with tokens read in lexical
--  return:
function Parser.Open (t)
  if (_DEBUG) then print("PAR :: Open") end
  assert(type(t) == "table")
  tokens_list = t
end

--Peek:
--  parameters:
--  return:
function Parser.Peek ()
  if (_DEBUG) then print("PAR :: Peek") end
  return tokens_list[current + 1]
end


--==============================================================================
-- Return
--==============================================================================

return Parser