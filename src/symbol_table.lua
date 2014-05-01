--==============================================================================
-- Debug
--==============================================================================



--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local NodesClass  = require "lib/node_codes"


--==============================================================================
-- Data Structure
--==============================================================================

local SymbolTable = {}

local scopes = {}

--  list of nodes code
--  {
--    [name] = $number,
--  }
local nodes_codes = NodesClass.GetNodesList()


--==============================================================================
-- Private Methods
--==============================================================================

function Error ()
  error("Symbol error.", 0)
end

--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

--AddScope: Insert a new scope level
--  parameters:
--  return:
function SymbolTable.AddScope ()
  if (_DEBUG) then print("SYB :: AddScope") end
  scopes[#scopes + 1] = {}
end

--Clear: Remove all scopes
--  parameters:
--  return:
function SymbolTable.Clear ()
  if (_DEBUG) then print("SYB :: Clear") end
  scopes = {}
end

--GetCurrentScopeSymbol: Get symbol only if present in current scope
--  parameters:
--    [1] $string         - Symbol name
--  return:
--    [1] $table or $nil  - Copy of symbol structure if found, otherwise nil
function SymbolTable.GetCurrentScopeSymbol (name)
  if (_DEBUG) then print("SYB :: GetCurrentScopeSymbol") end
  local num_scope = #scopes
  if (scopes[#scopes][name]) then
    local symbol = util.TableCopy(scopes[#scopes][name])
    symbol.name = name
    return symbol
  end
  return nil
end

--GetSymbol: Get symbol if present in current or above scopes
--  parameters:
--    [1] $string         - Symbol name
--  return:
--    [1] $table or $nil  - Copy of symbol structure if found, otherwise nil
function SymbolTable.GetSymbol (name)
  if (_DEBUG) then print("SYB :: GetSymbol") end
  local num_scope = #scopes
  while (num_scope > 0) do
    if (scopes[num_scope][name]) then
      local symbol = util.TableCopy(scopes[num_scope][name])
      symbol.name = name
      return symbol
    end
    num_scope = num_scope - 1
  end
  return nil
end

--Print: Print symbol table
--  parameters:
--  return:
function SymbolTable.Print ()
  if (_DEBUG) then print("SYB :: Print") end
  util.TablePrint(scopes)
end

--RemoveScope: Remove current scope
--  parameters:
--  return:
function SymbolTable.RemoveScope ()
  if (_DEBUG) then print("SYB :: RemoveScope") end
  scopes[#scopes] = nil
end

--SetSymbol: Create a new symbol in current scope
--          function or var
--  parameters:
--    [1] $table  - 
--              id   = $number - 
--              name = $string - 
--              line = $number - 
--              func_params {
--                params        = $table  - 
--                ret_type      = $string - 
--                ret_dimension = $number - 
--              }
--              var_params {
--                type
--                dimension = $number - 
--              }
--  return:
function SymbolTable.SetSymbol (t)
  if (_DEBUG) then print("SYB :: SetSymbol") end
  assert(t and type(t) == "table")
  assert(t.line and type(t.line) == "number")
  assert(t.name and type(t.name) == "string")
  local symbol = {}
  symbol.line = t.line
  symbol.name = t.name
  if (t.id == nodes_codes["FUNCTION"]) then
    symbol.id = "function"
    symbol.params = util.TableCopy(t.params)
    symbol.ret_type = t.ret_type
    symbol.ret_dimension = t.ret_dimension
  elseif (t.id == nodes_codes["DECLARE"] or t.id == nodes_codes["PARAMETER"]) then
    symbol.id = "variable"
    symbol.type = t.type
    symbol.dimension = t.dimension
  else
    Error()
  end
  scopes[#scopes] = scopes[#scopes] or {}
  scopes[#scopes][t.name] = symbol
  --util.TablePrint(scopes)
end


--==============================================================================
-- Return
--==============================================================================

return SymbolTable