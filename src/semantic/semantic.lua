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

require "util"
local TreeNodesCode = require "tree_nodes_code"
local UtilTree      = require "util_tree"
local SymbolTable   = require "semantic/symbol_table"


--==============================================================================
-- Data Structure
--==============================================================================

local Class = {}

--  list of nodes code
--  {
--    [name] = $number,
--  }
local tree_nodes = TreeNodesCode.GetList()

--  AST tree (structed nodes)
local tree = {}


--==============================================================================
-- Private Methods
--==============================================================================

--Error: Stop class execution and generate error message
--  Parameters:
--    [1] $string
--  Return:
local function Error (msg, line)
  if (_DEBUG) then print("SEM :: Error") end
  local str = string.format("@%d semantic error: %s", line or 0, msg or "")
  error(str, 0)
end

--VerifyAttribution: Verify integrity of ATTRIBUTION node
--  Parameters:
--    [1] $table  = ATTRIBUTION node
--  Return:
function Class.VerifyAttribution (node)
  if (_DEBUG) then print("SEM :: VerifyAttribution") end
  assert(node.id == tree_nodes["ATTRIBUTION"])
  Class.VerifyVar(node.var)
  Class.VerifyExpression(node.exp)
  Class.VerifyCompatibleTypes(node.line, node.var.sem_type, node.var.sem_dimension, node.exp.sem_type, node.exp.sem_dimension)
end

--VerifyBlock: Verify integrity of BLOCK/COMMANDS nodes
--  Parameters:
--    [1] $table  = collection of ATTRIBUTION, CALL, DECLARE, IF, RETURN and WHILE nodes
--  Return:
function Class.VerifyBlock (block)
  if (_DEBUG) then print("SEM :: VerifyBlock") end
  for _, node in ipairs(block or {}) do
    if (node.id == tree_nodes["ATTRIBUTION"]) then
      Class.VerifyAttribution(node)
    elseif (node.id == tree_nodes["CALL"]) then
      Class.VerifyCall(node)
    elseif (node.id == tree_nodes["DECLARE"]) then
      Class.VerifyDeclare(node)
    elseif (node.id == tree_nodes["IF"]) then
      Class.VerifyIf(node)
    elseif (node.id == tree_nodes["RETURN"]) then
      Class.VerifyReturn(node)
    elseif (node.id == tree_nodes["WHILE"]) then
      Class.VerifyWhile(node)
    else
      Error("unknown block node")
    end
  end
end

--VerifyCall: Verify integrity of CALL node
--  Parameters:
--    [1] $table  = CALL node
--  Return:
function Class.VerifyCall (node)
  if (_DEBUG) then print("SEM :: VerifyCall") end
  assert(node.id == tree_nodes["CALL"])
  local symbol = SymbolTable.GetSymbol(node.name)
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
    Class.VerifyExpression(node.exps[i])
    Class.VerifyCompatibleTypes(node.line, symbol.params[i].type, symbol.params[i].dimension, node.exps[i].sem_type, node.exps[i].sem_dimension)
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
function Class.VerifyCompatibleTypes (line, first_type, first_dimension, second_type, second_dimension)
  local err = false
  if (first_type ~= second_type) then
    if (first_type == "int" and second_type == "char") or (first_type == "char" and second_type == "int") then
      if (first_dimension ~= 0 or second_dimension ~= 0) then
        err = true
      end
    else
      err = true
    end
  else
    if (first_dimension ~= second_dimension) then
      err = true
    end
  end
  if (err) then
    Error(string.format("uncompatible types '%s' dimension '%d' and '%s' dimension '%d'.", first_type, first_dimension, second_type or "void", second_dimension or 0), line)
  end
  return true
end

--VerifyDeclare: Verify integrity of DECLARE node
--  Parameters:
--    [1] $table  = DECLARE node
--  Return:
function Class.VerifyDeclare (node)
  if (_DEBUG) then print("SEM :: VerifyDeclare") end
  assert(node.id == tree_nodes["DECLARE"])
  --local symbol = SymbolTable.GetCurrentScopeSymbol(node.name)
  local symbol = SymbolTable.GetSymbol(node.name)
  if (symbol) then
    Error(string.format("symbol '%s' was already declared at line %d.", symbol.name, symbol.line), node.line)
  else
    SymbolTable.SetSymbol(node)
  end
end

--VerifyElseIf: Verify integrity of ELSEIF node
--  Parameters:
--    [1] $table  = ELSEIF node
--  Return:
function Class.VerifyElseIf (node)
  if (_DEBUG) then print("SEM :: VerifyElseIf") end
  assert(node.id == tree_nodes["ELSEIF"])
  SymbolTable.AddScope()
  Class.VerifyExpression(node.cond)
  if (node.cond.sem_type ~= "bool" or node.cond.sem_dimension ~= 0) then
    Error(string.format("'else if' expects expression of type 'bool' with dimension '0', but got type '%s' with dimension '%d'.", node.cond.sem_type, node.cond.sem_dimension), node.line)
  end
  Class.VerifyBlock(node.block)
  SymbolTable.RemoveScope()
end

--VerifyExpression: Verify integrity of EXPRESSION node
--  Parameters:
--    [1] $table  = CALL, NEGATE, NEWVAR, OPERATOR, UNARY, VALUE or VAR node
--  Return:
function Class.VerifyExpression (node)
  if (_DEBUG) then print("SEM :: VerifyExpression") end
  if (node.id == tree_nodes["CALL"]) then
    Class.VerifyCall(node)
  elseif (node.id == tree_nodes["NEGATE"]) then
    Class.VerifyNegate(node)
  elseif (node.id == tree_nodes["NEWVAR"]) then
    Class.VerifyNewVar(node)
  elseif (node.id == tree_nodes["OPERATOR"]) then
    Class.VerifyOperator(node)
  elseif (node.id == tree_nodes["UNARY"]) then
    Class.VerifyUnary(node)
  elseif (node.id == tree_nodes["LITERAL"]) then
    Class.VerifyLiteral(node)
  elseif (node.id == tree_nodes["VAR"]) then
    Class.VerifyVar(node)
  else
    Error("unknown expression node", node.line)
  end
end

--VerifyFunction: Verify integrity of FUNCTION node
--  Parameters:
--    [1] $table  = FUNCTION node
--  Return:
function Class.VerifyFunction (node)
  if (_DEBUG) then print("SEM :: VerifyFunction") end
  assert(node.id == tree_nodes["FUNCTION"])
  SymbolTable.AddScope()
  for _, param in ipairs(node.params) do
    if (SymbolTable.GetSymbol(param.name)) then
    --if (SymbolTable.GetCurrentScopeSymbol(param.name)) then
      Error(string.format("function parameter '%s' already declared.", param.name), node.line)
    end
    SymbolTable.SetSymbol(param)
  end
  if (node.ret_type) then
    local ret = {
      id        = tree_nodes["DECLARE"],
      name      = "@ret",
      line      = node.line,
      type      = node.ret_type,
      dimension = node.ret_dimension,
    }
    SymbolTable.SetSymbol(ret)
  end
  Class.VerifyBlock(node.block)
  SymbolTable.RemoveScope()
end

--VerifyGlobals: Add global functions, externs and variables to scope
--  Parameters:
--    [1] $table  = PROGRAM node
--  Return:
function Class.VerifyGlobals (t)
  if (_DEBUG) then print("SEM :: VerifyGlobals") end
  assert(t.id == tree_nodes["PROGRAM"])
  for _, node in ipairs(t) do
    local symbol = SymbolTable.GetSymbol(node.name)
    if (symbol) then
      Error(string.format("global symbol '%s' was already declared at line %d.", symbol.name, symbol.line), node.line)
    end
    SymbolTable.SetSymbol(node)
  end
end

--VerifyIf: Verify integrity of IF node
--  Parameters:
--    [1] $table  = IF node
--  Return:
function Class.VerifyIf (node)
  if (_DEBUG) then print("SEM :: VerifyIf") end
  assert(node.id == tree_nodes["IF"])
  SymbolTable.AddScope()
  Class.VerifyExpression(node.cond)
  if (node.cond.sem_type ~= "bool" or node.cond.sem_dimension ~= 0) then
    Error(string.format("'if' expects expression of type 'bool' with dimension '0', but got type '%s' with dimension '%d'.", node.cond.sem_type, node.cond.sem_dimension), node.line)
  end
  Class.VerifyBlock(node.block)
  if (node["elseif"]) then
    for _, n in ipairs (node["elseif"]) do
      Class.VerifyElseIf(n)
    end
  end
  SymbolTable.AddScope()
  Class.VerifyBlock(node["else"])
  SymbolTable.RemoveScope()
  SymbolTable.RemoveScope()
end

--VerifyLiteral: Verify integrity of LITERAL node
--  Parameters:
--    [1] $table  = LITERAL node
--  Return:
function Class.VerifyLiteral (node)
  if (_DEBUG) then print("SEM :: VerifyLiteral") end
  assert(node.id == tree_nodes["LITERAL"])
  node.sem_type = node.type
  node.sem_dimension = node.dimension
end

--VerifyNewVar: Verify integrity of NEWVAR node
--  Parameters:
--    [1] $table  = NEWVAR node
--  Return:
function Class.VerifyNewVar (node)
  if (_DEBUG) then print("SEM :: VerifyNewVar") end
  assert(node.id == tree_nodes["NEWVAR"])
  Class.VerifyExpression(node.exp)
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
function Class.VerifyNegate (node)
  if (_DEBUG) then print("SEM :: VerifyNegate") end
  assert(node.id == tree_nodes["NEGATE"])
  Class.VerifyExpression(node.exp)
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
function Class.VerifyOperator (node)
  if (_DEBUG) then print("SEM :: VerifyOperator") end
  assert(node.id == tree_nodes["OPERATOR"])
  Class.VerifyExpression(node[1])
  Class.VerifyExpression(node[2])
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
function Class.VerifyProgram (t)
  if (_DEBUG) then print("SEM :: VerifyProgram") end
  assert(t.id == tree_nodes["PROGRAM"])
  SymbolTable.AddScope()
  Class.VerifyGlobals(t)
  for _, node in ipairs(t) do
    if (node.id == tree_nodes["DECLARE"]) then
      -- node already saved in symbol table while verifying globals
    elseif (node.id == tree_nodes["EXTERN"]) then
      -- node already saved in symbol table while verifying globals
    elseif (node.id == tree_nodes["FUNCTION"]) then
      Class.VerifyFunction(node)
    else
      Error("unknown program node.")
    end
  end
  SymbolTable.RemoveScope()
end

--VerifyReturn: Verify integrity of RETURN node
--  Parameters:
--    [1] $table  = RETURN node
--  Return:
function Class.VerifyReturn (node)
  if (_DEBUG) then print("SEM :: VerifyReturn") end
  assert(node.id == tree_nodes["RETURN"])
  local symbol = SymbolTable.GetSymbol("@ret")
  if (not symbol) then
    if (node.exp) then
      Error(string.format("function with return 'void' must not attempt to call 'return'."), node.line)
    end
  elseif (node.exp) then
    Class.VerifyExpression(node.exp)
    Class.VerifyCompatibleTypes(node.line, symbol.type, symbol.dimension, node.exp.sem_type, node.exp.sem_dimension)
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
function Class.VerifyUnary (node)
  if (_DEBUG) then print("SEM :: VerifyUnary") end
  assert(node.id == tree_nodes["UNARY"])
  Class.VerifyExpression(node.exp)
  if ((node.exp.sem_type ~= "int" and node.exp.sem_type ~= "char") or node.exp.sem_dimension ~= 0) then
    Error(string.format("'unary' must be done over type 'char' or 'int' with dimension '0', but got type '%s' with dimension '%d'.", node.exp.sem_type, node.exp.sem_dimension), node.line)
  end
  node.sem_type = node.exp.sem_type
  node.sem_dimension = node.exp.sem_dimension
end

--VerifyVar: Verify integrity of VAR node
--  Parameters:
--    [1] $table  = VAR node
--  Return:
function Class.VerifyVar (node)
  if (_DEBUG) then print("SEM :: VerifyVar") end
  assert(node.id == tree_nodes["VAR"])
  local symbol = SymbolTable.GetSymbol(node.name)
  if (not symbol) then
    Error(string.format("symbol '%s' was not declared.", node.name), node.line)
  end
  node.sem_type = symbol.type
  if (symbol.dimension and symbol.dimension > 0) then
    if (#node.array > symbol.dimension) then
      Error(string.format("symbol '%s' dimension is '%d', but was called with dimension '%d'.", node.name, symbol.dimension, #node.array), node.line)
    end
    for _, exp in ipairs(node.array) do
      Class.VerifyExpression(exp)
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
function Class.VerifyWhile (node)
  if (_DEBUG) then print("SEM :: VerifyWhile") end
  assert(node.id == tree_nodes["WHILE"])
  SymbolTable.AddScope()
  Class.VerifyExpression(node.cond)
  if (node.cond.sem_type ~= "bool" or node.cond.sem_dimension ~= 0) then
    Error(string.format("while expects 'bool' expression with dimension '0', but got type '%s' with dimension '%d'.", node.cond.sem_type, node.cond.sem_dimension), node.line)
  end
  Class.VerifyBlock(node.block)
  SymbolTable.RemoveScope()
end


--==============================================================================
-- Public Methods
--==============================================================================

--GetTree:
--  parameters:
--  return:
--    [1] $boolean - false if found any problem, true otherwise
function Class.GetTree ()
  return tree
end

--Open:
--  parameters:
--    [1] $table   - table with AST tree nodes
--  return:
--    [1] $boolean - false if found any problem, true otherwise
--    [2] $string  - only when [1] is false, informing which error occurs
function Class.Open (t)
  if (_DEBUG) then print("SEM :: Open") end
  assert(t and type(t) == "table")
  SymbolTable.Clear()
  local ok, msg = pcall(function () Class.VerifyProgram(t) end)
  if (not ok) then
    return false, msg
  end
  tree = t
  if (printTree) then
    Class.Print(t)
  end
  return true
end

--Print: Print Abstract Class Tree with comprehensible format
--  parameters:
--  return:
function Class.Print (t)
  UtilTree.Print(t)
end


--==============================================================================
-- Return
--==============================================================================

return Class