--==============================================================================
-- Considerations
--==============================================================================

-- Functions sets new unreach code variable '@ret' as its return VAR variable
-- Functions sets PARAMETER nodes to own scope

--==============================================================================
-- Debug
--==============================================================================

-- char dentro de array


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
  error(string.format("Semantic error at line %d. Symbol '%s' was declared at line %d", sym_new.line, sym_prev.name, sym_prev.line), 0)
end



--VerifyAttribution:
--    verify if variable and expression types are equal
--    verify if variable or expression are type bool
--    verify if variable and expression types 'string' and 'char' are compatible
--    verify if variable and expression dimensions are equal
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
      Error(string.format("Attribution of variable '%s' type '%s' cannot receive type '%s' at line %d.", node.var.name, node.var.sem_type, node.exp.sem_type, node.line))
    elseif (node.var.sem_type == "char" or node.exp.sem_type == "string") then
      if not (node.var.sem_dimension - 1 == node.exp.sem_dimension) then
        Error(string.format("Attribution of '%s' 'char' dimension '%d' not compatible with expression 'string' dimension '%d' at line %d", node.var.name, node.var.sem_dimension, node.exp.sem_dimension, node.line))
      end
    elseif (node.var.sem_type == "string" or node.exp.sem_type == "char") then
      if not (node.var.sem_dimension == node.exp.sem_dimension - 1) then
        Error(string.format("Attribution of '%s' 'string' dimension '%d' not compatible with expression 'char' dimension '%d' at line %d", node.var.name, node.var.sem_dimension, node.exp.sem_dimension, node.line))
      end
    else
      if (node.var.sem_dimension ~= node.exp.sem_dimension) then
        Error(string.format("Attribution expects same dimension at both sides, but got '%d' and '%d' at line %d.", node.var.sem_dimension, node.exp.sem_dimension, node.line))
      end
    end
  else
    if (node.var.sem_dimension ~= node.exp.sem_dimension) then
      Error(string.format("Attribution expects same dimension at both sides, but got '%d' and '%d' at line %d.", node.var.sem_dimension, node.exp.sem_dimension, node.line))
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
    --elseif (node.id == nodes_codes["ELSEIF"]) then -- just inside if
      -- TO IMPLEMENT
    elseif (node.id == nodes_codes["CALL"]) then
      -- TO IMPLEMENT
    elseif (node.id == nodes_codes["IF"]) then
      -- TO IMPLEMENT
    elseif (node.id == nodes_codes["RETURN"]) then
      Semantic.VerifyReturn(node)
    elseif (node.id == nodes_codes["WHILE"]) then
      -- TO IMPLEMENT
    else
      Error("Unknown block node")
    end
  end
end

--VerifyDeclare:
--    verify if symbol was already used
--    set new symbol
--  Parameters:
--    [1] $table  = DECLARE node
--  Return:
function Semantic.VerifyDeclare (t)
  if (_DEBUG) then print("SEM :: VerifyDeclare") end
  assert(t.id == nodes_codes["DECLARE"])
  local symbol = SymbolClass.GetSymbol(t.name)
  if (symbol) then
    ErrorDeclaredSymbol(symbol, t)
  else
    SymbolClass.SetSymbol(t)
  end
end

--VerifyExpression:
--  Parameters:
--  Return:
function Semantic.VerifyExpression (t)
  if (_DEBUG) then print("SEM :: VerifyExpression") end
  if (t.id == nodes_codes["CALL"]) then
    -- TO IMPLEMENT
  elseif (t.id == nodes_codes["NEGATE"]) then
    -- NOT int ?
    Semantic.VerifyExpression(t.exp)
    t.sem_type = t.exp.sem_type
    t.sem_dimension = t.exp.sem_dimension
  elseif (t.id == nodes_codes["NEWVAR"]) then
    -- TO IMPLEMENT
  elseif (t.id == nodes_codes["OPERATOR"]) then
    -- TO IMPLEMENT
    Semantic.VerifyExpression(t[1])
    Semantic.VerifyExpression(t[2])
    if (t.op == "and" or t.op == "or") then
      if (t[1].sem_type ~= "bool" or t[2].sem_type ~= "bool") then
        Error(string.format(""))
      end
      if (t[1].sem_dimension ~= 0 or t[2].sem_dimension ~= 0) then
        Error(string.format("Operation '%s' cannot be made over arrays values.", t.op))
      end
      t.sem_type = "bool"
      t.sem_dimension = 0
    elseif (t.op == "=" or t.op == "<>") then
      -- TO IMPLEMENT
      -- DIMENSAO DEVE SER LEVADO EM CONTA
      -- INT e CHAR podem ser comparados
      -- mesmo tipo
      if (t[1].sem_dimension ~= 0 or t[2].sem_dimension ~= 0) then
        Error(string.format("Operation '%s' cannot be made over arrays values.", t.op))
      end
      t.sem_type = "bool"
      t.sem_dimension = 0
    elseif (t.op == ">" or t.op == "<" or t.op == ">=" or t.op == "<=") then
      if ((t[1].sem_type ~= "int" and t[1].sem_type ~= "char") or (t[2].sem_type ~= "int" and t[2].sem_type ~= "char")) then
        Error(string.format("Operation '%s' require 'int' or 'char' expressions on both sides, but got '%s' and '%s'.", t.op, t[1].sem_type, t[2].sem_type))
      end
      if (t[1].sem_dimension ~= 0 or t[2].sem_dimension ~= 0) then
        Error(string.format("Operation '%s' cannot be made over arrays values.", t.op))
      end
      t.sem_type = "bool"
      t.sem_dimension = 0
    elseif (t.op == "+" or t.op == "-" or t.op == "*" or t.op == "/") then
      if ((t[1].sem_type ~= "int" and t[1].sem_type ~= "char") or (t[2].sem_type ~= "int" and t[2].sem_type ~= "char")) then
        Error(string.format("Operation '%s' require 'int' or 'char' expressions on both sides, but got '%s' and '%s'.", t.op, t[1].sem_type, t[2].sem_type))
      end
      if (t[1].sem_dimension ~= 0 or t[2].sem_dimension ~= 0) then
        Error(string.format("Operation '%s' cannot be made over arrays values.", t.op))
      end
      t.sem_type = "int"
      t.sem_dimension = 0
    else
      Error("Unknown operation '%s'.", t.op)
    end
  elseif (t.id == nodes_codes["UNARY"]) then
    Semantic.VerifyExpression(t.exp)
    -- NOT bool ?
    t.sem_type = t.exp.sem_type
    t.sem_dimension = t.exp.sem_dimension
  elseif (t.id == nodes_codes["VALUE"]) then
    t.sem_type = t.type
    t.sem_dimension = 0
  elseif (t.id == nodes_codes["VAR"]) then
    Semantic.VerifyVar(t)
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
function Semantic.VerifyFunction (t)
  if (_DEBUG) then print("SEM :: VerifyFunction") end
  assert(t.id == nodes_codes["FUNCTION"])
  SymbolClass.AddScope()
  if (t.params) then
    for _, param in ipairs(t.params) do
      SymbolClass.SetSymbol(param)
    end
  end
  if (t.ret_type) then
    local ret = {
      id        = nodes_codes["DECLARE"],
      name      = "@ret",
      line      = t.line,
      type      = t.ret_type,
      dimension = t.ret_dimension,
    }
    SymbolClass.SetSymbol(ret)
  end
  Semantic.VerifyBlock(t.block)
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
function Semantic.VerifyReturn (t)
  if (_DEBUG) then print("SEM :: VerifyReturn") end
  assert(t.id == nodes_codes["RETURN"])
  local symbol = SymbolClass.GetSymbol("@ret")
  if (not symbol) then
    Error(string.format("Void function must not return values at line '%s'.", t.line))
  end
  if (t.exp) then
    Semantic.VerifyExpression(t.exp)
    if (t.exp.sem_type ~= symbol.type) then
      Error(string.format("Function expected to return type '%s' but got '%s' at line %d.", symbol.type, t.exp.sem_type, t.line))
    elseif (t.exp.sem_dimension ~= symbol.dimension) then
      Error(string.format("Function expected to return dimension '%d' but got '%d' at line %d.", symbol.dimension, t.exp.sem_dimension, t.line))
    end
  else
    if (symbol.type) then
      Error(string.format("Function expected to return type '%s' but got 'nil' at line %d.", symbol.type, t.line))
    end
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
function Semantic.VerifyVar (var)
  if (_DEBUG) then print("SEM :: VerifyVar") end
  assert(var.id == nodes_codes["VAR"])
  local symbol = SymbolClass.GetSymbol(var.name)
  if (not symbol) then
    Error(string.format("Undeclared symbol '%s' at line %d.", var.name, var.line))
  end
  var.sem_type = symbol.type
  if (symbol.dimension and symbol.dimension > 0) then
    if (var.array) then
      if (#var.array > symbol.dimension) then
        Error(string.format("Symbol '%s' dimension is '%d', but was called with dimension '%d'", var.name, symbol.dimension, #var.array))
      end
      for _, exp in ipairs(var.array) do
        Semantic.VerifyExpression(exp)
        if (exp.sem_type ~= "int" and exp.sem_type ~= "char") then
          Error(string.format("Dimension of symbol '%s' must be a type 'int' or 'char', but got '%s'", var.name, exp.sem_type))
        end
      end
    end
    var.sem_dimension = symbol.dimension - #var.array
  elseif (var.array and #var.array > 0) then
    Error(string.format("Symbol '%s' dimension is '0', but was called with dimension '%d'", var.name, #var.array))
  else
    var.sem_dimension = 0
  end
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
  return true
end


--==============================================================================
-- Return
--==============================================================================

return Semantic