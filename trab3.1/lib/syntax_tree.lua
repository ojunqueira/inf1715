--==============================================================================
-- Debug
--==============================================================================

local printTree = true

--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local NodesClass = require "lib/node_codes"


--==============================================================================
-- Data Structure
--==============================================================================

local AbstractSyntaxTree = {}

--  list of nodes print functions
local Print = {}

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

function Print.FunctionCall (indent, t)
  print(indent .. "CALL [" .. t.name .. "] @" .. t.line .. "  {")
  for _, node in ipairs(t.exps) do
    print(Print.Expression(node))
  end
  print(indent .. "}")
end

function Print.ComandAttribution (indent, t)
  print(indent .. "ATRIB @" .. t.line .. " {")
  Print.Variable(indent .. "  ", t.var)
  print(Print.Expression(t.exp))
  print(indent .. "}")
end

function Print.ComandReturn (indent, t)
  print(indent .. "RETURN @" .. t.line .. " {")
  print(Print.Expression(t.exp))
  print(indent .. "}")
end

function Print.ComandWhile (indent, t)
  print(indent .. "WHILE @" .. t.line .. " {")
  -- CONTINUE
  print(indent .. "}")
end

function Print.Declare (indent, t)
  print(indent .. "DECLARE @" .. t.line .. "{")
  print(indent .. "  ID [" .. t.name .. "] " .. t.type .. " " .. t.size .. " @" .. t.line)
  print(indent .. "}")
end

function Print.Expression (exp)
  return ""
end

function Print.Function (indent, t)
  print(indent .. "FUN [" .. t.name .. "] @" .. t.line .. " {")
  for _, node in ipairs(t.params) do
    Print.Parameter(indent .. "  ", node)
  end
  print(indent .. "  FUNC_RETURN " .. t.r_type .. " - " .. t.r_size)
  for _, node in ipairs(t.block) do
    if (node.id == nodes_codes["DECLARE"]) then
      Print.Declare(indent .. "  ", node)
    elseif (node.id == nodes_codes["FUNCTION_CALL"]) then
      Print.FunctionCall(indent .. "  ", node)
    elseif (node.id == nodes_codes["COMAND_ATTRIBUTION"]) then
      Print.ComandAttribution(indent .. "  ", node)
    elseif (node.id == nodes_codes["COMAND_RETURN"]) then
      Print.ComandReturn(indent .. "  ", node)
    elseif (node.id == nodes_codes["COMAND_WHILE"]) then
      Print.ComandWhile(indent .. "  ", node)
    end
  end
  print(indent .. "}")
end

function Print.Parameter (indent, t)
  local str = indent .. "FUNC_PARAMETER [" .. t.name .. "] " .. t.type .. " - " .. t.size
  print(str)
end

function Print.Program (indent, t)
  print(indent .. "PROGRAM {")
  for _, node in ipairs(t) do
    if (node.id == nodes_codes["DECLARE"]) then
      Print.Declare(indent .. "  ", node)
    elseif (node.id == nodes_codes["FUNCTION"]) then
      Print.Function(indent .. "  ", node)
    end
  end
  print(indent .. "}")
end

function Print.Variable (indent, t)
  local array_str = ""
  for _, exp in ipairs(t.array) do
    array_str = array_str .. "[" .. Print.Expression() .. "]"
  end
  print(indent .. "ID [" .. t.name .. "] " .. array_str .. " @" .. t.line)
end


--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

--NewComandAttributionNode:
--  {
--    id    = $number - one of nodes_codes values
--    var   = $table  - VAR node
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewComandAttributionNode (var, expression)
  if (_DEBUG) then print("AST :: NewComandAttributionNode") end
  local node = {
    id    = nodes_codes["COMAND_ATTRIBUTION"],
    exp   = expression,
    line  = var.line,
    var   = var,
  }
  return node
end

--NewComandIfNode:


--NewComandReturnNode:
--  {
--    id    = $number - one of nodes_codes values
--    line  = $number - line number
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewComandReturnNode (line, expression)
  if (_DEBUG) then print("AST :: NewComandReturnNode") end
  local node = {
    id    = nodes_codes["COMAND_RETURN"],
    exp   = expression,
    line  = line,
  }
  return node
end

--NewComandWhileNode:
--  {
--    id    = $number - one of nodes_codes values
--    block = $table  - list of COMMANDS that will be executed if [cond] is true
--    cond  = $table  - EXPRESSION NODE, represents condition
--    line  = $number - line number
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewComandWhileNode (line, condition, block)
  if (_DEBUG) then print("AST :: NewComandWhileNode") end
  local node = {
    id    = nodes_codes["COMAND_WHILE"],
    block = block,
    cond  = condition,
    line  = line,
  }
  return node
end

--NewDeclareVariableNode:
--  {
--    id    = $number - one of nodes_codes values
--    line  = $number - line number
--    name  = $string - var name
--    size  = $number - 
--    type  = $string - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewDeclareVariableNode (line, name, typebase, size)
  if (_DEBUG) then print("AST :: NewDeclareVariableNode") end
  local node = {
    id    = nodes_codes["DECLARE"],
    line  = line,
    name  = name,
    size  = size,
    type  = typebase,
  }
  return node
end

--NewExpNewNode:
--  {
--    id    = $number - one of nodes_codes values
--    exp   = $table  - EXPRESSION node
--    type  = $string - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpNewNode (expression, type)
  if (_DEBUG) then print("AST :: NewExpNotNode") end
  local node = {
    id    = nodes_codes["EXPRESSION_NEW"],
    exp   = expression,
    type  = type,
  }
  return node
end

--NewExpNotNode:
--  {
--    id    = $number - one of nodes_codes values
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpNotNode (expression)
  if (_DEBUG) then print("AST :: NewExpNotNode") end
  local node = {
    id    = nodes_codes["EXPRESSION_NOT"],
    exp   = expression,
  }
  return node
end

--NewExpOperatorNode:
--  {
--    id    = $number - one of nodes_codes values
--    op    = $string - 
--    [1]   = 
--    [2]   = 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpOperatorNode (left, operator, right)
  if (_DEBUG) then print("AST :: NewExpOperatorNode") end
  local node = {
    id    = nodes_codes["EXPRESSION_OPERATOR"],
    op    = operator,
    left,
    right,
  }
  return node
end

--NewExpParenthesisNode:
--  {
--    id    = $number - one of nodes_codes values
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpParenthesisNode (expression)
  if (_DEBUG) then print("AST :: NewExpParenthesisNode") end
  local node = {
    id  = nodes_codes["EXPRESSION_PARENTHESIS"],
    exp = unpack(expression)
  }
  return node
end

--NewExpValueNode:
--  {
--    id    = $number - one of nodes_codes values
--    type  = $string - 
--    value = $string or $number or $boolean - 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpValueNode (type, value)
  if (_DEBUG) then print("AST :: NewExpValueNode") end
  local node = {
    id    = nodes_codes["EXPRESSION_VALUE"],
    type  = type,
    value = value,
  }
  return node
end

--NewFunctionNode:
--  {
--    id      = $number - one of nodes_codes values
--    block   = $table  - list of COMMANDS that will be executed if [cond] is true
--    line    = $number - line number
--    name    = $string - var name
--    params  = $table  - list of PARAMETER nodes
--    r_type  = $string - [bool, char, int, string], represents functino return type
--    r_size  = $number - 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewFunctionNode (line, name, parameters, return_type, return_size, block)
  if (_DEBUG) then print("AST :: NewFunctionNode") end
  local node = {
    id      = nodes_codes["FUNCTION"],
    line    = line,
    name    = name,
    params  = parameters,
    r_type  = return_type,
    r_size  = return_size,
    block   = block,
  }
  return node
end

--NewFunctionCallNode:
--  {
--    id    = $number - one of nodes_codes values
--    line  = $number - line number
--    name  = $string - var name
--    exps  = $table  - list of EXPRESSIONS nodes
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewFunctionCallNode (line, name, expressions)
  if (_DEBUG) then print("AST :: NewFunctionCallNode") end
  local node = {
    id   = nodes_codes["FUNCTION_CALL"],
    line = line,
    name = name,
    exps = expressions,
  }
  return node
end

--NewParameterNode:
--  {
--    id    = $number - one of nodes_codes values
--    name  = $string - var name
--    size  = $number - 
--    type  = $string - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewParameterNode (name, typebase, size)
  if (_DEBUG) then print("AST :: NewProgramNode") end
  local node = {
    id    = nodes_codes["PARAMETER"],
    name  = name,
    size  = size,
    type  = typebase,
  }
  return node
end

--NewProgramNode:
--  {
--    id       = $number - one of nodes_codes values
--    [1 to N] = DECLARE or FUNCTION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewProgramNode (ast_tree)
  if (_DEBUG) then print("AST :: NewProgramNode") end
  tree = {}
  tree = util.TableCopy(ast_tree)
  tree.id = nodes_codes["PROGRAM"]
  if (printTree) then AbstractSyntaxTree.Print() end
end

--NewVariableNode:
--  {
--    id    = $number - one of nodes_codes values
--    line  = $number - line number
--    name  = $string - var name
--    array = $table  - 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewVariableNode (line, name, array)
  if (_DEBUG) then print("AST :: NewVariableNode") end
  local node = {
    id    = nodes_codes["VARIABLE"],
    line  = line,
    name  = name,
    array = array,
  }
  return node
end

--Print: Print Abstract Syntax Tree with comprehensible format
--  parameters:
--  return:
function AbstractSyntaxTree.Print ()
  if (_DEBUG) then print("AST :: Print") end
  Print.Program("", tree)
end


--==============================================================================
-- Return
--==============================================================================

return AbstractSyntaxTree