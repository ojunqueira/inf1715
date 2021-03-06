--==============================================================================
-- Debug
--==============================================================================



--==============================================================================
-- Dependency
--==============================================================================

require "util"
local TreeNodesCode = require "tree_nodes_code"


--==============================================================================
-- Data Structure
--==============================================================================

local Class = {}

local scopes = {}

--  list of nodes code
--  {
--    [name] = $number,
--  }
local tree_nodes = TreeNodesCode.GetList()


--==============================================================================
-- Private Methods
--==============================================================================

--Error: Stop class execution and generate error message
--  Parameters:
--  Return:
function Error ()
  if (_DEBUG) then print("SYB :: Error") end
  error("Symbol error.", 0)
end


--==============================================================================
-- Public Methods
--==============================================================================

--AddScope: Insert a new scope level
--  parameters:
--  return:
function Class.AddScope ()
  if (_DEBUG) then print("SYB :: AddScope") end
  scopes[#scopes + 1] = {}
end

--Clear: Remove all scopes
--  parameters:
--  return:
function Class.Clear ()
  if (_DEBUG) then print("SYB :: Clear") end
  scopes = {}
end

--GetCurrentScopeSymbol: Get symbol only if present in current scope
--  parameters:
--    [1] $string         - Symbol name
--  return:
--    [1] $table or $nil  - Copy of symbol structure if found, otherwise nil
function Class.GetCurrentScopeSymbol (name)
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
function Class.GetSymbol (name)
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
function Class.Print ()
  if (_DEBUG) then print("SYB :: Print") end
  util.TablePrint(scopes)
end

--RemoveScope: Remove current scope
--  parameters:
--  return:
function Class.RemoveScope ()
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
function Class.SetSymbol (t)
  if (_DEBUG) then print("SYB :: SetSymbol") end
  assert(t and type(t) == "table")
  assert(t.line and type(t.line) == "number")
  assert(t.name and type(t.name) == "string")
  local symbol = {}
  symbol.line = t.line
  symbol.name = t.name
  if (t.id == tree_nodes["FUNCTION"] or t.id == tree_nodes["EXTERN"]) then
    symbol.id = "function"
    symbol.params = util.TableCopy(t.params)
    symbol.ret_type = t.ret_type
    symbol.ret_dimension = t.ret_dimension
  elseif (t.id == tree_nodes["DECLARE"] or t.id == tree_nodes["PARAMETER"]) then
    symbol.id = "variable"
    symbol.type = t.type
    symbol.dimension = t.dimension
  else
    Error()
  end
  scopes[#scopes] = scopes[#scopes] or {}
  scopes[#scopes][t.name] = symbol
end


--==============================================================================
-- Return
--==============================================================================

return Class