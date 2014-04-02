--==============================================================================
-- Debug
--==============================================================================



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
  current = 0
  tokens_list = t
end

--Peek: peek the next token
--  parameters:
--  return:
function Parser.Peek ()
  if (_DEBUG) then print("PAR :: Peek") end
  return tokens_list[current + 1]
end

--Peek2: peek the second next token
--  parameters:
--  return:
function Parser.Peek2 ()
  if (_DEBUG) then print("PAR :: Peek2") end
  return tokens_list[current + 2]
end


--==============================================================================
-- Return
--==============================================================================

return Parser