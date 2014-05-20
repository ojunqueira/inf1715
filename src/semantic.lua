--==============================================================================
-- Considerations
--==============================================================================

-- Functions sets new unreach code variable '@ret' as its return VAR variable
-- Functions sets PARAMETER nodes to own scope
-- ALLOW overcharge variable in diferent scopes

--==============================================================================
-- Debug
--==============================================================================

local printTree = false


--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local NodesClass  = require "lib/node_codes"
local PrintClass  = require "lib/util_tree"
local SymbolClass = require "src/symbol_table"


--==============================================================================
-- Data Structure
--==============================================================================

local Semantic = {}

--  list of nodes code
--  {
--    [name] = $number,
--  }
local nodes_codes = NodesClass.GetNodesList()

--  AST tree (structed nodes)
local tree = {}


--==============================================================================
-- Private Methods
--==============================================================================

--Error: Callback of errors that occurs during semantic analysis
--  Parameters:
--    [1] $string
--  Return:
local function Error (msg, line)
  local str = string.format("@%d semantic error: %s", line or 0, msg or "")
  error(str, 0)
end

--VerifyAttribution: Verify integrity of ATTRIBUTION node
--  Parameters:
--    [1] $table  = ATTRIBUTION node
--  Return:
function Semantic.VerifyAttribution (node)
  if (_DEBUG) then print("SEM :: VerifyAttribution") end
  assert(node.id == nodes_codes["ATTRIBUTION"])
  Semantic.VerifyVar(node.var)
  Semantic.VerifyExpression(node.exp)
  Semantic.VerifyCompatibleTypes(node.line, node.var.sem_type, node.var.sem_dimension, node.exp.sem_type, node.exp.sem_dimension)
  -- MUST UPDATE SYMBOL TABLE VALUE
end

--VerifyBlock: Verify integrity of BLOCK/COMMANDS nodes
--  Parameters:
--    [1] $table  = collection of ATTRIBUTION, CALL, DECLARE, IF, RETURN and WHILE nodes
--  Return:
function Semantic.VerifyBlock (block)
  if (_DEBUG) then print("SEM :: VerifyBlock") end
  for _, node in ipairs(block or {}) do
    if (node.id == nodes_codes["ATTRIBUTION"]) then
      Semantic.VerifyAttribution(node)
    elseif (node.id == nodes_codes["CALL"]) then
      Semantic.VerifyCall(node)
    elseif (node.id == nodes_codes["DECLARE"]) then
      Semantic.VerifyDeclare(node)
    elseif (node.id == nodes_codes["IF"]) then
      Semantic.VerifyIf(node)
    elseif (node.id == nodes_codes["RETURN"]) then
      Semantic.VerifyReturn(node)
    elseif (node.id == nodes_codes["WHILE"]) then
      Semantic.VerifyWhile(node)
    else
      Error("unknown block node")
    end
  end
end

--VerifyCall: Verify integrity of CALL node
--  Parameters:
--    [1] $table  = CALL node
--  Return:
function Semantic.VerifyCall (node)
  if (_DEBUG) then print("SEM :: VerifyCall") end
  assert(node.id == nodes_codes["CALL"])
  local symbol = SymbolClass.GetSymbol(node.name)
  if (not symbol) then
    Error(string.format("symbol '%s' was not declared.", node.name), node.line)
  end
  if (symbol.id ~= "function") then
    Error(string.format("attempt to call %s '%s', which is a '%s', not a 'function'.", symbol.id, symbol.name, symbol.type), node.line)
  end
  local num_func_params = symbol.params and #symbol.params or 0
  local num_call_params = node.exps and #node.exps or 0
  if (num_func_params ~= num_call_params) then
    Error(string.format("attempt to call function '%s' with '%d' parameter(s), but it demands '%d'.", symbol.name, num_func_params, num_call_params), node.line)
  end
  for i = 1, num_func_params do
    Semantic.VerifyExpression(node.exps[i])
    Semantic.VerifyCompatibleTypes(node.line, symbol.params[i].type, symbol.params[i].dimension, node.exps[i].sem_type, node.exps[i].sem_dimension)
  end
  node.sem_type = symbol.ret_type
  node.sem_dimension = symbol.ret_dimension
end

--VerifyCompatibleTypes: Check if two different variables can be matched
--  Parameters:
--    [1] $number = line number
--    [2] $string = type of first variable
--    [3] $number = dimension of first variable
--    [4] $string = type of second variable
--    [5] $number = dimension of second variable
--  Return:
function Semantic.VerifyCompatibleTypes (line, first_type, first_dimension, second_type, second_dimension)
  local err = false
  if (first_type ~= second_type) then
    if (first_type == "int" and second_type == "char") or (first_type == "char" and second_type == "int") then
      if (first_dimension ~= 0 or second_dimension ~= 0) then
        err = true
      end
      --[[
    elseif (first_type == "string" and second_type == "char") then
      if (first_dimension + 1 ~= second_dimension) then
        err = true
      end
    elseif (first_type == "char" and second_type == "string") then
      if (first_dimension ~= second_dimension + 1) then
        err = true
      end
      --]]
    else
      err = true
    end
  else
    if (first_dimension ~= second_dimension) then
      err = true
    end
  end
  if (err) then
    Error(string.format("uncompatible types '%s' dimension '%d' and '%s' dimension '%d'.", first_type, first_dimension, second_type, second_dimension), line)
  end
  return true
end

--VerifyDeclare: Verify integrity of DECLARE node
--  Parameters:
--    [1] $table  = DECLARE node
--  Return:
function Semantic.VerifyDeclare (node)
  if (_DEBUG) then print("SEM :: VerifyDeclare") end
  assert(node.id == nodes_codes["DECLARE"])
  --local symbol = SymbolClass.GetCurrentScopeSymbol(node.name)
  local symbol = SymbolClass.GetSymbol(node.name)
  if (symbol) then
    Error(string.format("symbol '%s' was already declared at line %d.", symbol.name, symbol.line), node.line)
  else
    SymbolClass.SetSymbol(node)
  end
end

--VerifyElseIf: Verify integrity of ELSEIF node
--  Parameters:
--    [1] $table  = ELSEIF node
--  Return:
function Semantic.VerifyElseIf (node)
  if (_DEBUG) then print("SEM :: VerifyElseIf") end
  assert(node.id == nodes_codes["ELSEIF"])
  SymbolClass.AddScope()
  Semantic.VerifyExpression(node.cond)
  if (node.cond.sem_type ~= "bool" or node.cond.sem_dimension ~= 0) then
    Error(string.format("'else if' expects expression of type 'bool' with dimension '0', but got type '%s' with dimension '%d'.", node.cond.sem_type, node.cond.sem_dimension), node.line)
  end
  Semantic.VerifyBlock(node.block)
  SymbolClass.RemoveScope()
end

--VerifyExpression: Verify integrity of EXPRESSION node
--  Parameters:
--    [1] $table  = CALL, NEGATE, NEWVAR, OPERATOR, UNARY, VALUE or VAR node
--  Return:
function Semantic.VerifyExpression (node)
  if (_DEBUG) then print("SEM :: VerifyExpression") end
  if (node.id == nodes_codes["CALL"]) then
    Semantic.VerifyCall(node)
  elseif (node.id == nodes_codes["NEGATE"]) then
    Semantic.VerifyNegate(node)
  elseif (node.id == nodes_codes["NEWVAR"]) then
    Semantic.VerifyNewVar(node)
  elseif (node.id == nodes_codes["OPERATOR"]) then
    Semantic.VerifyOperator(node)
  elseif (node.id == nodes_codes["UNARY"]) then
    Semantic.VerifyUnary(node)
  elseif (node.id == nodes_codes["VALUE"]) then
    Semantic.VerifyValue(node)
  elseif (node.id == nodes_codes["VAR"]) then
    Semantic.VerifyVar(node)
  else
    Error("unknown expression node", node.line)
  end
end

--VerifyFunction: Verify integrity of FUNCTION node
--  Parameters:
--    [1] $table  = FUNCTION node
--  Return:
function Semantic.VerifyFunction (node)
  if (_DEBUG) then print("SEM :: VerifyFunction") end
  assert(node.id == nodes_codes["FUNCTION"])
  SymbolClass.AddScope()
  for _, param in ipairs(node.params) do
    if (SymbolClass.GetCurrentScopeSymbol(param.name)) then
      Error(string.format("function parameter '%s' already declared.", param.name), node.line)
    end
    SymbolClass.SetSymbol(param)
  end
  if (node.ret_type) then
    local ret = {
      id        = nodes_codes["DECLARE"],
      name      = "@ret",
      line      = node.line,
      type      = node.ret_type,
      dimension = node.ret_dimension,
    }
    SymbolClass.SetSymbol(ret)
  end
  Semantic.VerifyBlock(node.block)
  SymbolClass.RemoveScope()
end

--VerifyGlobals: Add global functions and variables to scope
--  Parameters:
--    [1] $table  = PROGRAM node
--  Return:
function Semantic.VerifyGlobals (t)
  if (_DEBUG) then print("SEM :: VerifyGlobals") end
  assert(t.id == nodes_codes["PROGRAM"])
  for _, node in ipairs(t) do
    local symbol = SymbolClass.GetSymbol(node.name)
    if (symbol) then
      Error(string.format("global symbol '%s' was already declared at line %d.", symbol.name, symbol.line), node.line)
    end
    SymbolClass.SetSymbol(node)
  end
end

--VerifyIf: Verify integrity of IF node
--  Parameters:
--    [1] $table  = IF node
--  Return:
function Semantic.VerifyIf (node)
  if (_DEBUG) then print("SEM :: VerifyIf") end
  assert(node.id == nodes_codes["IF"])
  SymbolClass.AddScope()
  Semantic.VerifyExpression(node.cond)
  if (node.cond.sem_type ~= "bool" or node.cond.sem_dimension ~= 0) then
    Error(string.format("'if' expects expression of type 'bool' with dimension '0', but got type '%s' with dimension '%d'.", node.cond.sem_type, node.cond.sem_dimension), node.line)
  end
  Semantic.VerifyBlock(node.block)
  for _, n in ipairs (node["elseif"]) do
    Semantic.VerifyElseIf(n)
  end
  SymbolClass.AddScope()
  Semantic.VerifyBlock(node["else"])
  SymbolClass.RemoveScope()
  SymbolClass.RemoveScope()
end

--VerifyNewVar: Verify integrity of NEWVAR node
--  Parameters:
--    [1] $table  = NEWVAR node
--  Return:
function Semantic.VerifyNewVar (node)
  if (_DEBUG) then print("SEM :: VerifyNewVar") end
  assert(node.id == nodes_codes["NEWVAR"])
  Semantic.VerifyExpression(node.exp)
  if (node.exp.sem_type ~= "int" and node.exp.sem_type ~= "char") then
    Error(string.format("'new var' expression must have type 'int' or 'char', but got type '%s'.", node.exp.sem_type), node.line)
  end
  node.sem_type = node.type
  node.sem_dimension = node.dimension + 1
end

--VerifyNegate: Verify integrity of NEGATE node
--  Parameters:
--    [1] $table  = NEGATE node
--  Return:
function Semantic.VerifyNegate (node)
  if (_DEBUG) then print("SEM :: VerifyNegate") end
  assert(node.id == nodes_codes["NEGATE"])
  Semantic.VerifyExpression(node.exp)
  if (node.exp.sem_type ~= "bool" or node.exp.sem_dimension ~= 0) then
    Error(string.format("'not' must be done over type 'bool' with dimension '0', but got type '%s' with dimension '%d'.", node.exp.sem_type, node.exp.sem_dimension))
  end
  node.sem_type = "bool"
  node.sem_dimension = 0
end

--VerifyOperator: Verify integrity of OPERATOR node
--  Parameters:
--    [1] $table  = NEGATE node
--  Return:
function Semantic.VerifyOperator (node)
  if (_DEBUG) then print("SEM :: VerifyOperator") end
  assert(node.id == nodes_codes["OPERATOR"])
  Semantic.VerifyExpression(node[1])
  Semantic.VerifyExpression(node[2])
  if (node.op == "and" or node.op == "or") then
    if (node[1].sem_type ~= "bool") then
      Error(string.format("operation '%s' cannot be made over left type '%s'.", node.op, node[1].sem_type), node.line)
    elseif (node[2].sem_type ~= "bool") then
      Error(string.format("operation '%s' cannot be made over right type '%s'.", node.op, node[2].sem_type), node.line)
    end
    if (node[1].sem_dimension ~= 0) then
      Error(string.format("operation '%s' cannot be made over arrays values, but left side of expression has dimension '%d'.", node.op, node[1].sem_dimension), node.line)
    elseif (node[2].sem_dimension ~= 0) then
      Error(string.format("operation '%s' cannot be made over arrays values, but right side of expression has dimension '%d'.", node.op, node[2].sem_dimension), node.line)
    end
    node.sem_type = "bool"
    node.sem_dimension = 0
  elseif (node.op == "=" or node.op == "<>") then
    if (node[1].sem_type ~= node[2].sem_type) then
      if ((node[1].sem_type ~= "int" and node[1].sem_type ~= "char") or (node[2].sem_type ~= "int" and node[2].sem_type ~= "char")) then
        Error(string.format("operation '%s' require 'int' or 'char' expressions on both sides, but got '%s' and '%s'.", node.op, node[1].sem_type, node[2].sem_type), node.line)
      end
    end
    if (node[1].sem_dimension ~= node[2].sem_dimension) then
      Error(string.format("operation '%s' require variables with same dimension, but got dimensions '%s' and '%s'.", node.op, node[1].sem_dimension, node[2].sem_dimension), node.line)
    end
    node.sem_type = "bool"
    node.sem_dimension = 0
  elseif (node.op == ">" or node.op == "<" or node.op == ">=" or node.op == "<=" or 
          node.op == "+" or node.op == "-" or node.op == "*" or node.op == "/") then
    if (node[1].sem_type ~= "int" and node[1].sem_type ~= "char") then
      Error(string.format("operation '%s' require 'int' or 'char' expression on both sides, but got type '%s' on left side.", node.op, node[1].sem_type), node.line)
    elseif (node[2].sem_type ~= "int" and node[2].sem_type ~= "char") then
      Error(string.format("operation '%s' require 'int' or 'char' expression on both sides, but got type '%s' on right side.", node.op, node[2].sem_type), node.line)
    elseif (node[1].sem_dimension ~= 0) then
      Error(string.format("operation '%s' require dimension '0' on both sides, but got dimension '%d' on left side.", node.op, node[1].sem_dimension), node.line)
    elseif (node[2].sem_dimension ~= 0) then
      Error(string.format("operation '%s' require dimension '0' on both sides, but got dimension '%d' on right side.", node.op, node[2].sem_dimension), node.line)
    end
    node.sem_dimension = 0
    if (node.op == ">" or node.op == "<" or node.op == ">=" or node.op == "<=") then
      node.sem_type = "bool"
    else
      node.sem_type = "int"
    end
  else
    Error(string.format("unknown operation '%s'.", node.op), node.line)
  end
end

--VerifyProgram: Verify integrity of PROGRAM node
--  Parameters:
--    [1] $table  = PROGRAM node
--  Return:
function Semantic.VerifyProgram (t)
  if (_DEBUG) then print("SEM :: VerifyProgram") end
  assert(t.id == nodes_codes["PROGRAM"])
  SymbolClass.AddScope()
  Semantic.VerifyGlobals(t)
  for _, node in ipairs(t) do
    if (node.id == nodes_codes["DECLARE"]) then
      -- DO NOT VERIFY. SYMBOL ADDED IN GLOBALS
    elseif (node.id == nodes_codes["FUNCTION"]) then
      Semantic.VerifyFunction(node)
    else
      Error("unknown program node.")
    end
  end
  SymbolClass.RemoveScope()
end

--VerifyReturn: Verify integrity of RETURN node
--  Parameters:
--    [1] $table  = RETURN node
--  Return:
function Semantic.VerifyReturn (node)
  if (_DEBUG) then print("SEM :: VerifyReturn") end
  assert(node.id == nodes_codes["RETURN"])
  local symbol = SymbolClass.GetSymbol("@ret")
  if (not symbol) then
    if (node.exp) then
      Error(string.format("function with return 'void' must not attempt to call 'return'."), node.line)
    end
  elseif (node.exp) then
    Semantic.VerifyExpression(node.exp)
    Semantic.VerifyCompatibleTypes(node.line, symbol.type, symbol.dimension, node.exp.sem_type, node.exp.sem_dimension)
  elseif (symbol.type) then
    Error(string.format("function expected to return type '%s' but got 'nil'.", symbol.type), node.line)
  else
    Error("unknown function return error.", node.line)
  end
end

--VerifyUnary: Verify integrity of UNARY node
--  Parameters:
--    [1] $table  = UNARY node
--  Return:
function Semantic.VerifyUnary (node)
  if (_DEBUG) then print("SEM :: VerifyUnary") end
  assert(node.id == nodes_codes["UNARY"])
  Semantic.VerifyExpression(node.exp)
  if ((node.exp.sem_type ~= "int" and node.exp.sem_type ~= "char") or node.exp.sem_dimension ~= 0) then
    Error(string.format("'unary' must be done over type 'char' or 'int' with dimension '0', but got type '%s' with dimension '%d'.", node.exp.sem_type, node.exp.sem_dimension), node.line)
  end
  node.sem_type = node.exp.sem_type
  node.sem_dimension = node.exp.sem_dimension
end

--VerifyValue: Verify integrity of VALUE node
--  Parameters:
--    [1] $table  = VALUE node
--  Return:
function Semantic.VerifyValue (node)
  if (_DEBUG) then print("SEM :: VerifyValue") end
  assert(node.id == nodes_codes["VALUE"])
  node.sem_type = node.type
  node.sem_dimension = node.dimension
end

--VerifyVar: Verify integrity of VAR node
--  Parameters:
--    [1] $table  = VAR node
--  Return:
function Semantic.VerifyVar (node)
  if (_DEBUG) then print("SEM :: VerifyVar") end
  assert(node.id == nodes_codes["VAR"])
  local symbol = SymbolClass.GetSymbol(node.name)
  if (not symbol) then
    Error(string.format("symbol '%s' was not declared.", node.name), node.line)
  end
  node.sem_type = symbol.type
  if (symbol.dimension and symbol.dimension > 0) then
    if (#node.array > symbol.dimension) then
      Error(string.format("symbol '%s' dimension is '%d', but was called with dimension '%d'.", node.name, symbol.dimension, #node.array), node.line)
    end
    for _, exp in ipairs(node.array) do
      Semantic.VerifyExpression(exp)
      if (exp.sem_type ~= "int" and exp.sem_type ~= "char") then
        Error(string.format("symbol '%s' dimension must be an 'int' or 'char', but was called with dimension '%s'.", node.name, exp.sem_type), node.line)
      end
    end
    node.sem_dimension = symbol.dimension - #node.array
  elseif (node.array and #node.array > 0) then
    Error(string.format("symbol '%s' dimension is '0', but was called with dimension '%d'.", node.name, #node.array), node.line)
  else
    node.sem_dimension = 0
  end
end

--VerifyWhile: Verify integrity of WHILE node
--  Parameters:
--    [1] $table  = WHILE node
--  Return:
function Semantic.VerifyWhile (node)
  if (_DEBUG) then print("SEM :: VerifyWhile") end
  assert(node.id == nodes_codes["WHILE"])
  SymbolClass.AddScope()
  Semantic.VerifyExpression(node.cond)
  if (node.cond.sem_type ~= "bool" or node.cond.sem_dimension ~= 0) then
    Error(string.format("while expects 'bool' expression with dimension '0', but got type '%s' with dimension '%d'.", node.cond.sem_type, node.cond.sem_dimension), node.line)
  end
  Semantic.VerifyBlock(node.block)
  SymbolClass.RemoveScope()
end

--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

--GetTree:
--  parameters:
--  return:
--    [1] $boolean - false if found any problem, true otherwise
function Semantic.GetTree ()
  return tree
end

--Open:
--  parameters:
--    [1] $table   - table with AST tree nodes
--  return:
--    [1] $boolean - false if found any problem, true otherwise
--    [2] $string  - only when [1] is false, informing which error occurs
function Semantic.Open (t)
  if (_DEBUG) then print("SEM :: Open") end
  assert(t and type(t) == "table")
  SymbolClass.Clear()
  local ok, msg = pcall(function () Semantic.VerifyProgram(t) end)
  if (not ok) then
    return false, msg
  end
  tree = t
  if (printTree) then
    Semantic.Print(t)
  end
  return true
end

--Print: Print Abstract Semantic Tree with comprehensible format
--  parameters:
--  return:
function Semantic.Print (t)
  PrintClass.Print(t)
end


--==============================================================================
-- Return
--==============================================================================

return Semantic