--==============================================================================
-- Debug
--==============================================================================

_DEBUG = true


--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local SymbolClass = require "src/symbol_table"
local NodesClass  = require "lib/node_codes"


--==============================================================================
-- Data Structure
--==============================================================================

local Semantic = {}

--  list of nodes code
--  {
--    [name] = $number,
--  }
local nodes_codes = NodesClass.GetNodesList()


--==============================================================================
-- Private Methods
--==============================================================================

--Error: Callback of errors that occurs during semantic analysis
--  Parameters:
--    [1] $string
--  Return:
local function Error (msg)
  error("Semantic error: " .. msg, 0)
end

--ErrorDeclaredSymbol: Callback of errors that occurs during semantic analysis
--  Parameters:
--    [1] $string
--  Return:
local function ErrorDeclaredSymbol (sym_prev, sym_new)
  error(string.format("Semantic error at line %d. Symbol %s was declared at line %d", sym_new.line, sym_prev.name, sym_prev.line), 0)
end

function Semantic.VerifyDeclare (t)
  if (_DEBUG) then print("SEM :: VerifyDeclare") end
end

function Semantic.VerifyFunction (t)
  if (_DEBUG) then print("SEM :: VerifyFunction") end
end

function Semantic.VerifyProgram (t)
  if (_DEBUG) then print("SEM :: VerifyProgram") end
  if (t.id ~= nodes_codes["PROGRAM"]) then
    Error("Expected PROGRAM node")
  end
  SymbolClass.AddScope()
  for _, node in ipairs(t) do
    local symbol = SymbolClass.GetSymbol(node.name)
    if (symbol) then
      ErrorDeclaredSymbol(symbol, node)
    end
    SymbolClass.SetSymbol(node)
  end
  for _, node in ipairs(t) do
    if (node.id == nodes_codes["DECLARE"]) then
      Semantic.VerifyDeclare(node) -- DO NOT VERIFY. SYMBOL ADDED ABOVE
    elseif (node.id == nodes_codes["FUNCTION"]) then
      Semantic.VerifyFunction(node)
    else
      Error("Unknown node")
    end
  end
  SymbolClass.RemoveScope()
end

--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

--Open:
--  parameters:
--    [1] $table   - table with AST tree nodes
--  return:
--    [1] $boolean - false if found any problem, true otherwise
--    [2] $string  - only when [1] is false, informing which error occurs
function Semantic.Open (t)
  if (_DEBUG) then print("SEM :: Open") end
  assert(t and type(t) == "table")
  local ok, msg = pcall(function () Semantic.VerifyProgram(t) end)
  if (not ok) then
    return false, msg
  end
  return true
end


--==============================================================================
-- Return
--==============================================================================

return Semantic