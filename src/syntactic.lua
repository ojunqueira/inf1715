--==============================================================================
-- Debug
--==============================================================================



--==============================================================================
-- Dependency
--==============================================================================

local ParserClass 	= require "src/parser"
local LanguageClass = require "src/grammar"
local ASTClass		  = require "src/syntax_tree"


--==============================================================================
-- Data Structure
--==============================================================================

local Syntactic = {}


--==============================================================================
-- Private Methods
--==============================================================================



--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

--GetTree:
function Syntactic.GetTree()
  if (_DEBUG) then print("SYN :: GetTree") end
  return ASTClass.GetTree()
end

--Open:
--  parameters:
--    [1] $table   - table with tokens read in lexical
--  return:
--    [1] $boolean - false if found any problem, true otherwise
--    [2] $string  - only when [1] is false, informing which error occurs
function Syntactic.Open (t)
  if (_DEBUG) then print("SYN :: Open") end
  assert(t and type(t) == "table")
  ParserClass.Open(t)
  local ok, msg = LanguageClass.Start(ParserClass.Advance, ParserClass.Peek, ParserClass.Peek2)
  if (not ok) then
  	return false, msg
  end
  return true
end

--PrintTree:
function Syntactic.PrintTree()
  if (_DEBUG) then print("SYN :: PrintTree") end
  return ASTClass.Print()
end


--==============================================================================
-- Return
--==============================================================================

return Syntactic