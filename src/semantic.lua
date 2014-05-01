--==============================================================================
-- Considerations
--==============================================================================

-- Functions sets new unreach code variable '@ret' as its return VAR variable
-- Functions sets PARAMETER nodes to own scope
-- ALLOW overcharge variable in diferent scopes

--==============================================================================
-- Debug
--==============================================================================

local printTree = true


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


--==============================================================================
-- Private Methods
--==============================================================================

--Error: Callback of errors that occurs during semantic analysis
--  Parameters:
--    [1] $string
--  Return:
local function Error (msg, line)
  local str = string.format("Semantic error: @%d %s", line or 0, msg)
  error(str, 0)
end

--ErrorDeclaredSymbol: Callback of errors that occurs during semantic analysis
--  Parameters:
--    [1] $string
--  Return:
local function ErrorDeclaredSymbol (sym_prev, sym_new)
  error(string.format("Semantic error: @%d Symbol '%s' was declared at line %d", sym_new.line, sym_prev.name, sym_prev.line), 0)
end



--VerifyAttribution:
--  Parameters:
--    [1] $table  = ATTRIBUTION node
--  Return:
function Semantic.VerifyAttribution (node)
  if (_DEBUG) then print("SEM :: VerifyAttribution") end
  assert(node.id == nodes_codes["ATTRIBUTION"])
  Semantic.VerifyVar(node.var)
  Semantic.VerifyExpression(node.exp)
  if (node.var.sem_type ~= node.exp.sem_type) then
    if (node.var.sem_type == "bool" or node.exp.sem_type == "bool") then
      Error(string.format("Attribution of variable '%s' type '%s' cannot receive type '%s'.", node.var.name, node.var.sem_type, node.exp.sem_type), node.line)
    elseif (node.var.sem_type == "char" or node.exp.sem_type == "string") then
      if not (node.var.sem_dimension - 1 == node.exp.sem_dimension) then
        Error(string.format("Attribution of '%s' 'char' dimension '%d' not compatible with expression 'string' dimension '%d'.", node.var.name, node.var.sem_dimension, node.exp.sem_dimension), node.line)
      end
    elseif (node.var.sem_type == "string" or node.exp.sem_type == "char") then
      if not (node.var.sem_dimension == node.exp.sem_dimension - 1) then
        Error(string.format("Attribution of '%s' 'string' dimension '%d' not compatible with expression 'char' dimension '%d'.", node.var.name, node.var.sem_dimension, node.exp.sem_dimension), node.line)
      end
    else
      if (node.var.sem_dimension ~= node.exp.sem_dimension) then
        Error(string.format("Attribution expects same dimension at both sides, but got '%d' and '%d'.", node.var.sem_dimension, node.exp.sem_dimension), node.line)
      end
    end
  else
    if (node.var.sem_dimension ~= node.exp.sem_dimension) then
      Error(string.format("Attribution expects same dimension at both sides, but got '%d' and '%d'.", node.var.sem_dimension, node.exp.sem_dimension), node.line)
    end
  end
  -- MUST UPDATE SYMBOL TABLE VALUE
end

--VerifyBlock:
--  Parameters:
--  Return:
function Semantic.VerifyBlock (block)
  if (_DEBUG) then print("SEM :: VerifyBlock") end
  for _, node in ipairs(block) do
    if (node.id == nodes_codes["DECLARE"]) then
      Semantic.VerifyDeclare(node)
    elseif (node.id == nodes_codes["ATTRIBUTION"]) then
      Semantic.VerifyAttribution(node)
    elseif (node.id == nodes_codes["CALL"]) then
      Semantic.VerifyCall(node)
    elseif (node.id == nodes_codes["IF"]) then
      Semantic.VerifyIf(node)
    elseif (node.id == nodes_codes["RETURN"]) then
      Semantic.VerifyReturn(node)
    elseif (node.id == nodes_codes["WHILE"]) then
      Semantic.VerifyWhile(node)
    else
      Error("Unknown block node")
    end
  end
end

--VerifyCall:
--  Parameters:
--    [1] $table  = CALL node
--  Return:
function Semantic.VerifyCall (node)
  if (_DEBUG) then print("SEM :: VerifyCall") end
  assert(node.id == nodes_codes["CALL"])
  local symbol = SymbolClass.GetSymbol(node.name)
  if (not symbol) then
    Error(string.format("Undeclared symbol '%s'.", node.name), node.line)
  end
  if (symbol.id ~= "function") then
    Error(string.format("Attempt to call %s '%s', but it is a '%s', not a 'function'.", symbol.id, symbol.name, symbol.type), node.line)
  end
  local num_func_params = symbol.params and #symbol.params or 0
  local num_call_params = node.exps and #node.exps or 0
  if (num_func_params ~= num_call_params) then
    Error(string.format("Function '%s' expects '%d' parameters, but got '%d'.", symbol.name, num_func_params, num_call_params), node.line)
  end
  for i = 1, num_func_params do
    Semantic.VerifyExpression(node.exps[i])
    Semantic.VerifyCompatibleTypes(node.line, symbol.params[i].type, symbol.params[i].dimension, node.exps[i].sem_type, node.exps[i].sem_dimension)
  end
  node.sem_type = symbol.ret_type
  node.sem_dimension = symbol.ret_dimension
end

function Semantic.VerifyCompatibleTypes (line, first_type, first_dimension, second_type, second_dimension)
  local err = false
  if (first_type ~= second_type) then
    if (first_type == "int" and second_type == "char") or (first_type == "char" and second_type == "int") then
      if (first_dimension ~= second_dimension) then
        err = true
      end
    elseif (first_type == "string" and second_type == "char") then
      if (first_dimension + 1 ~= second_dimension) then
        err = true
      end
    elseif (first_type == "char" and second_type == "string") then
      if (first_dimension ~= second_dimension + 1) then
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
    Error(string.format("Uncompatible types '%s' dimension '%d' and '%s' dimension '%d'.", first_type, first_dimension, second_type, second_dimension), line)
  end
  return true
end

--VerifyDeclare:
--    verify if symbol was already used
--    set new symbol
--  Parameters:
--    [1] $table  = DECLARE node
--  Return:
function Semantic.VerifyDeclare (node)
  if (_DEBUG) then print("SEM :: VerifyDeclare") end
  assert(node.id == nodes_codes["DECLARE"])
  local symbol = SymbolClass.GetCurrentScopeSymbol(node.name)
  if (symbol) then
    ErrorDeclaredSymbol(symbol, node)
  else
    SymbolClass.SetSymbol(node)
  end
end

--VerifyElseIf
--  Parameters:
--    [1] $table  = ELSEIF node
--  Return:
function Semantic.VerifyElseIf (node)
  if (_DEBUG) then print("SEM :: VerifyElseIf") end
  assert(node.id == nodes_codes["ELSEIF"])
  SymbolClass.AddScope()
  Semantic.VerifyExpression(node.cond)
  if (node.cond.sem_type ~= "bool" or node.cond.sem_dimension ~= 0) then
    Error(string.format("Else if expects 'bool' expression with dimension '0', but got type '%s' with dimension '%d'.", node.cond.sem_type, node.cond.sem_dimension), node.line)
  end
  Semantic.VerifyBlock(node.block)
  SymbolClass.RemoveScope()
end

--VerifyExpression:
--  Parameters:
--  Return:
function Semantic.VerifyExpression (node)
  if (_DEBUG) then print("SEM :: VerifyExpression") end
  if (node.id == nodes_codes["CALL"]) then
    Semantic.VerifyCall(node)
  elseif (node.id == nodes_codes["NEGATE"]) then
    Semantic.VerifyExpression(node.exp)
    if (node.exp.sem_type ~= "bool" or node.exp.sem_dimension ~= 0) then
      Error(string.format("Operation 'negate' must be done over type 'bool' with dimension '0', but got type '%s' with dimension '%d'.", node.exp.sem_type, node.exp.sem_dimension))
    end
    node.sem_type = "bool"
    node.sem_dimension = 0
  elseif (node.id == nodes_codes["NEWVAR"]) then
    Semantic.VerifyExpression(node.exp)
    if (node.exp.sem_type ~= "int" and node.exp.sem_type ~= "char") then
      Error(string.format("New var expression must have type 'int' or 'char', but got type '%s'.", node.exp.sem_type), node.line)
    end
    node.sem_type = node.type
    node.sem_dimension = node.dimension + 1
  elseif (node.id == nodes_codes["OPERATOR"]) then
    Semantic.VerifyExpression(node[1])
    Semantic.VerifyExpression(node[2])
    if (node.op == "and" or node.op == "or") then
      if (node[1].sem_type ~= "bool" or node[2].sem_type ~= "bool") then
        Error(string.format(""))
      end
      if (node[1].sem_dimension ~= 0 or node[2].sem_dimension ~= 0) then
        Error(string.format("Operation '%s' cannot be made over arrays values.", node.op))
      end
      node.sem_type = "bool"
      node.sem_dimension = 0
    elseif (node.op == "=" or node.op == "<>") then
      if (node[1].sem_type ~= node[2].sem_type) then
        if ((node[1].sem_type ~= "int" and node[1].sem_type ~= "char") or (node[2].sem_type ~= "int" and node[2].sem_type ~= "char")) then
          Error(string.format("Operation '%s' require 'int' or 'char' expressions on both sides, but got '%s' and '%s'.", node.op, node[1].sem_type, node[2].sem_type))
        end
      end
      if (node[1].sem_dimension ~= node[2].sem_dimension) then
        Error(string.format("Operation '%s' must have equal variables dimension, but got '%s' and '%s'.", node.op, node[1].sem_dimension, node[2].sem_dimension))
      end
      node.sem_type = "bool"
      node.sem_dimension = 0
    elseif (node.op == ">" or node.op == "<" or node.op == ">=" or node.op == "<=") then
      if ((node[1].sem_type ~= "int" and node[1].sem_type ~= "char") or (node[2].sem_type ~= "int" and node[2].sem_type ~= "char")) then
        Error(string.format("Operation '%s' require 'int' or 'char' expressions on both sides, but got '%s' and '%s'.", node.op, node[1].sem_type, node[2].sem_type))
      end
      if (node[1].sem_dimension ~= 0 or node[2].sem_dimension ~= 0) then
        Error(string.format("Operation '%s' cannot be made over arrays values.", node.op))
      end
      node.sem_type = "bool"
      node.sem_dimension = 0
    elseif (node.op == "+" or node.op == "-" or node.op == "*" or node.op == "/") then
      if ((node[1].sem_type ~= "int" and node[1].sem_type ~= "char") or (node[2].sem_type ~= "int" and node[2].sem_type ~= "char")) then
        Error(string.format("Operation '%s' require 'int' or 'char' expressions on both sides, but got '%s' and '%s'.", node.op, node[1].sem_type, node[2].sem_type))
      end
      if (node[1].sem_dimension ~= 0 or node[2].sem_dimension ~= 0) then
        Error(string.format("Operation '%s' cannot be made over arrays values.", node.op))
      end
      node.sem_type = "int"
      node.sem_dimension = 0
    else
      Error("Unknown operation '%s'.", node.op)
    end
  elseif (node.id == nodes_codes["UNARY"]) then
    Semantic.VerifyExpression(node.exp)
    if ((node.exp.sem_type ~= "int" and node.exp.sem_type ~= "char") or node.exp.sem_dimension ~= 0) then
      Error(string.format("Operation 'unary' must be done over type 'char' or 'int' with dimension '0', but got type '%s' with dimension '%d'.", node.exp.sem_type, node.exp.sem_dimension))
    end
    node.sem_type = node.exp.sem_type
    node.sem_dimension = node.exp.sem_dimension
  elseif (node.id == nodes_codes["VALUE"]) then
    node.sem_type = node.type
    node.sem_dimension = 0
  elseif (node.id == nodes_codes["VAR"]) then
    Semantic.VerifyVar(node)
  else
    Error("Unknown expression node")
  end
end

--VerifyFunction:
--    add scope
--    add function parameters as symbols
--    add function return as symbol '@ret'
--    call verifications for block
--    remove scope
--  Parameters:
--    [1] $table  = FUNCTION node
--  Return:
function Semantic.VerifyFunction (node)
  if (_DEBUG) then print("SEM :: VerifyFunction") end
  assert(node.id == nodes_codes["FUNCTION"])
  SymbolClass.AddScope()
  if (node.params) then
    for _, param in ipairs(node.params) do
      if (SymbolClass.GetCurrentScopeSymbol(param.name)) then
        Error()
      end
      SymbolClass.SetSymbol(param)
    end
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

--VerifyGlobals:
--    add global functions and variables to scope
--  Parameters:
--    [1] $table  = PROGRAM node
--  Return:
function Semantic.VerifyGlobals (t)
  if (_DEBUG) then print("SEM :: VerifyGlobals") end
  assert(t.id == nodes_codes["PROGRAM"])
  for _, node in ipairs(t) do
    local symbol = SymbolClass.GetSymbol(node.name)
    if (symbol) then
      ErrorDeclaredSymbol(symbol, node)
    end
    SymbolClass.SetSymbol(node)
  end
end

--VerifyIf
--  Parameters:
--    [1] $table  = IF node
--  Return:
function Semantic.VerifyIf (node)
  if (_DEBUG) then print("SEM :: VerifyIf") end
  assert(node.id == nodes_codes["IF"])
  SymbolClass.AddScope()
  Semantic.VerifyExpression(node.cond)
  if (node.cond.sem_type ~= "bool" or node.cond.sem_dimension ~= 0) then
    Error(string.format("If expects 'bool' expression with dimension '0', but got type '%s' with dimension '%d'.", node.cond.sem_type, node.cond.sem_dimension), node.line)
  end
  Semantic.VerifyBlock(node.block)
  if (node["elseif"]) then
    for _, n in ipairs (node["elseif"]) do
      Semantic.VerifyElseIf(n)
    end
  end
  if (node["else"]) then
    SymbolClass.AddScope()
    Semantic.VerifyBlock(node["else"])
    SymbolClass.RemoveScope()
  end
  SymbolClass.RemoveScope()
end


--VerifyProgram:
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
      Error("Unknown node")
    end
  end
  SymbolClass.RemoveScope()
end

--VerifyReturn:
--    verify if function is void and return value
--    verify if function return nil but expect value
--    verify if type and dimension of return equals function description
--  Parameters:
--    [1] $table  = RETURN node
--  Return:
function Semantic.VerifyReturn (node)
  if (_DEBUG) then print("SEM :: VerifyReturn") end
  assert(node.id == nodes_codes["RETURN"])
  local symbol = SymbolClass.GetSymbol("@ret")
  if (not symbol) then
    Error(string.format("Void function must not return values at line '%s'.", node.line))
  elseif (node.exp) then
    Semantic.VerifyExpression(node.exp)
    Semantic.VerifyCompatibleTypes(node.line, symbol.type, symbol.dimension, node.exp.sem_type, node.exp.sem_dimension)
  elseif (symbol.type) then
    Error(string.format("Function expected to return type '%s' but got 'nil'.", symbol.type), node.line)
  else
    Error("Unknown error.")
  end
end

--VerifyVar:
--    verify if symbol was declared
--    verify if given dimension is greater than symbol dimension
--    verify if array expressions are 'int' or 'char'
--    verify if given dimension exists but symbol dimension is null
--  Parameters:
--    [1] $table  = VAR node
--  Return:
function Semantic.VerifyVar (node)
  if (_DEBUG) then print("SEM :: VerifyVar") end
  assert(node.id == nodes_codes["VAR"])
  local symbol = SymbolClass.GetSymbol(node.name)
  if (not symbol) then
    Error(string.format("Undeclared symbol '%s'.", node.name), node.line)
  end
  node.sem_type = symbol.type
  if (symbol.dimension and symbol.dimension > 0) then
    if (node.array) then
      if (#node.array > symbol.dimension) then
        Error(string.format("Symbol '%s' dimension is '%d', but was called with dimension '%d'.", node.name, symbol.dimension, #node.array), node.line)
      end
      for _, exp in ipairs(node.array) do
        Semantic.VerifyExpression(exp)
        if (exp.sem_type ~= "int" and exp.sem_type ~= "char") then
          Error(string.format("Dimension of symbol '%s' must be a type 'int' or 'char', but got '%s'.", node.name, exp.sem_type), node.line)
        end
      end
    end
    node.sem_dimension = symbol.dimension - #node.array
  elseif (node.array and #node.array > 0) then
    Error(string.format("Symbol '%s' dimension is '0', but was called with dimension '%d'.", node.name, #node.array), node.line)
  else
    node.sem_dimension = 0
  end
end

--VerifyWhile:
--  Parameters:
--    [1] $table  = WHILE node
--  Return:
function Semantic.VerifyWhile (node)
  if (_DEBUG) then print("SEM :: VerifyWhile") end
  assert(node.id == nodes_codes["WHILE"])
  SymbolClass.AddScope()
  Semantic.VerifyExpression(node.cond)
  if (node.cond.sem_type ~= "bool" or node.cond.sem_dimension ~= 0) then
    Error(string.format("While expects 'bool' expression with dimension '0', but got type '%s' with dimension '%d'.", node.cond.sem_type, node.cond.sem_dimension), node.line)
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