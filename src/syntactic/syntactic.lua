--==============================================================================
-- Debug
--==============================================================================



--==============================================================================
-- Dependency
--==============================================================================

local Parser 	= require "syntactic/parser"
local Grammar = require "syntactic/grammar"
local AST		  = require "syntactic/ast"


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

--GetTree:
--  parameters:
--  return:
function Class.GetTree()
  if (_DEBUG) then print("SYN :: GetTree") end
  return AST.GetTree()
end

--Open:
--  parameters:
--    [1] $table   - table with tokens read in lexical
--  return:
--    [1] $boolean - false if found any problem, true otherwise
--    [2] $string  - only when [1] is false, informing which error occurs
function Class.Open (t)
  if (_DEBUG) then print("SYN :: Open") end
  assert(t and type(t) == "table")
  Parser.Open(t)
  local ok, msg = Grammar.Start(Parser.Advance, Parser.Peek, Parser.Peek2)
  if (not ok) then
  	return false, msg
  end
  return true
end

--PrintTree:
function Class.PrintTree()
  if (_DEBUG) then print("SYN :: PrintTree") end
  return AST.Print()
end


--==============================================================================
-- Return
--==============================================================================

return Class