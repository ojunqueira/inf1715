--==============================================================================
-- Debug
--==============================================================================

local printTree = false

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

function Print.Block (indent, t)
  if (t) then
    for _, node in ipairs(t) do
      if (node.id == nodes_codes["ATTRIBUTION"]) then
        Print.ComandAttribution(indent, node)
      elseif (node.id == nodes_codes["IF"]) then
        Print.ComandIf(indent, node)
      elseif (node.id == nodes_codes["RETURN"]) then
        Print.ComandReturn(indent, node)
      elseif (node.id == nodes_codes["WHILE"]) then
        Print.ComandWhile(indent, node)
      elseif (node.id == nodes_codes["DECLARE"]) then
        Print.Declare(indent, node)
      elseif (node.id == nodes_codes["CALL"]) then
        Print.Call(indent, node)
      elseif (node.id == nodes_codes["VAR"]) then
        Print.Variable(indent, node)
      else
        error("block node error")
      end
    end
  end
end

function Print.Call (indent, t)
  print(indent .. "CALL [" .. t.name .. "] @" .. t.line .. "  {")
  for _, node in ipairs(t.exps) do
    print(indent .. "  PARAM " .. Print.Expression(node))
  end
  print(indent .. "}")
end

function Print.ComandAttribution (indent, t)
  print(indent .. "ATRIB @" .. t.line .. " {")
  local str = ""
  str = str .. t.var.name
  if (t.var.array) then
    for _, exp in ipairs(t.var.array) do
      str = str .. "[" .. Print.Expression(exp) .. "]"
    end
  end
  Print.Variable(indent .. "  ", t.var)

  print(indent .. "  =" .. Print.Expression(t.exp))
  print(indent .. "}")
end

function Print.ComandElseIf (indent, t)
  print(indent .. "ELSEIF [" .. Print.Expression(t.cond) .. "] @" .. t.line)
  Print.Block(indent .. "  ", t.block)
end

function Print.ComandIf (indent, t)
  print(indent .. "IF [" .. Print.Expression(t.cond) .. "] @" .. t.line .. " {")
  Print.Block(indent .. "  ", t.block)
  if (t["elseif"]) then
    for _, elseif_node in ipairs(t["elseif"]) do
      Print.ComandElseIf(indent, elseif_node)
    end
  end
  if (t["else"]) then
    print(indent .. "ELSE ")
    Print.Block(indent .. "  ", t["else"])
  end
  print(indent .. "}")
end

function Print.ComandReturn (indent, t)
  print(indent .. "RETURN @" .. t.line .. " {")
  print(indent .. "  " .. Print.Expression(t.exp))
  print(indent .. "}")
  -- print(indent .. "RETURN [" .. Print.Expression(t.exp) .. "] @" .. t.line)
end

function Print.ComandWhile (indent, t)
  print(indent .. "WHILE [" .. Print.Expression(t.cond) .. "] @" .. t.line .. " {")
  Print.Block(indent .. "  ", t.block)
  print(indent .. "}")
end

function Print.Declare (indent, t)
  print(indent .. "DECLARE @" .. t.line .. "{")
  print(indent .. "  ID [" .. t.name .. "] " .. t.type .. string.rep("[]", t.dimension) .. " @" .. t.line)
  print(indent .. "}")
  -- print(indent .. "DECLARE [" .. t.name .. "] " .. t.type .. string.rep("[]", t.dimension) .. " @" .. t.line)
end

function Print.Expression (node)
  local str = ""
  if (not node) then
    return ""
  end
  if (node.id == nodes_codes["PARENTHESIS"]) then
    str = str .. " (" .. Print.Expression(node.exp) .. ")"
  elseif (node.id == nodes_codes["NEWVAR"]) then
    str = str .. " new [" .. Print.Expression(node.exp) .. "] " .. node.type
  elseif (node.id == nodes_codes["DENY"]) then
    str = str .. " not " .. Print.Expression(node.exp)
  elseif (node.id == nodes_codes["OPERATOR"]) then
    str = str .. Print.Expression(node[1]) .. " " .. node.op .. " " .. Print.Expression(node[2])
  elseif (node.id == nodes_codes["VALUE"]) then
    str = str .. " " .. node.value
  elseif (node.id == nodes_codes["CALL"]) then
    str = str .. " " .. node.name .. "("
    if (node.exps) then
      str = str .. Print.Expression(node.exps[1])
      if (node.exps[2]) then
        for i = 2, #node.exps do
          str = str .. ", " .. Print.Expression(node.exps[i])
        end
      end
    end
    str = str .. ")"
  elseif (node.id == nodes_codes["VAR"]) then
    str = str .. " " .. node.name
    if (node.array) then
      for _, exp in ipairs(node.array) do
        str = str .. "["
        str = str .. Print.Expression(exp)
        str = str .. "]"
      end
    end
  else
    error("expression node error")
  end
  return str
end

function Print.Function (indent, t)
  print(indent .. "FUN [" .. t.name .. "] @" .. t.line .. " {")
  for _, node in ipairs(t.params) do
    print(indent .. "  FUNC_PARAMETER [" .. node.name .. "] " .. node.type .. string.rep("[]", node.dimension))
  end
  print(indent .. "  FUNC_RETURN " .. t.ret_type .. string.rep("[]", t.ret_dimension))
  for _, node in ipairs(t.block) do
    if (node.id == nodes_codes["DECLARE"]) then
      Print.Declare(indent .. "  ", node)
    elseif (node.id == nodes_codes["CALL"]) then
      Print.Call(indent .. "  ", node)
    elseif (node.id == nodes_codes["ATTRIBUTION"]) then
      Print.ComandAttribution(indent .. "  ", node)
    elseif (node.id == nodes_codes["IF"]) then
      Print.ComandIf(indent .. "  ", node)
    elseif (node.id == nodes_codes["RETURN"]) then
      Print.ComandReturn(indent .. "  ", node)
    elseif (node.id == nodes_codes["WHILE"]) then
      Print.ComandWhile(indent .. "  ", node)
    end
  end
  print(indent .. "}")
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

--NewAttributionNode:
--  {
--    id    = $number - ATTRIBUTION code
--    exp   = $table  - EXPRESSION node
--    line  = $number - line number
--    var   = $table  - VAR node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewAttributionNode (var, expression)
  if (_DEBUG) then print("AST :: NewAttributionNode") end
  local node = {
    id    = nodes_codes["ATTRIBUTION"],
    exp   = expression,
    line  = var.line,
    var   = var,
  }
  return node
end

--NewCallNode:
--  {
--    id    = $number - CALL code
--    line  = $number - line number
--    name  = $string - var name
--    exps  = $table  - list of EXPRESSION nodes
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewCallNode (line, name, expressions)
  if (_DEBUG) then print("AST :: NewCallNode") end
  local node = {
    id   = nodes_codes["CALL"],
    line = line,
    name = name,
    exps = expressions,
  }
  return node
end

--NewDeclVarNode:
--  {
--    id        = $number - DECLARE code
--    line      = $number - line number
--    name      = $string - var name
--    dimension = $number - var dimension
--    type      = $string - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewDeclVarNode (line, name, typebase, size)
  if (_DEBUG) then print("AST :: NewDeclVarNode") end
  local node = {
    id        = nodes_codes["DECLARE"],
    line      = line,
    name      = name,
    dimension = size,
    type      = typebase,
  }
  return node
end

--NewDenyNode:
--  {
--    id    = $number - DENY code
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewDenyNode (expression)
  if (_DEBUG) then print("AST :: NewDenyNode") end
  local node = {
    id    = nodes_codes["DENY"],
    exp   = expression,
  }
  return node
end

--NewElseIfNode:
--  {
--    id    = $number - ELSEIF code
--    block = $table  - list of COMMANDS that will be executed if [cond] is true
--    cond  = $table  - EXPRESSION NODE, represents condition
--    line  = $number - line number
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewElseIfNode (line, condition, block)
  if (_DEBUG) then print("AST :: NewElseIfNode") end
  local node = {
    id          = nodes_codes["ELSEIF"],
    block       = block,
    cond        = condition,
    line        = line,
  }
  return node
end

--NewFunctionNode:
--  {
--    id            = $number - FUNCTION code
--    block         = $table  - list of COMMANDS that will be executed
--    line          = $number - line number
--    name          = $string - var name
--    params        = $table  - list of PARAMETER nodes
--    ret_type      = $string - [bool, char, int, string], represents function return type
--    ret_dimension = $number - function return dimension
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewFunctionNode (line, name, parameters, return_type, return_size, block)
  if (_DEBUG) then print("AST :: NewFunctionNode") end
  local node = {
    id            = nodes_codes["FUNCTION"],
    line          = line,
    name          = name,
    params        = parameters,
    ret_type      = return_type,
    ret_dimension = return_size,
    block         = block,
  }
  return node
end

--NewIfNode:
--  {
--    id      = $number - IF code
--    block   = $table  - list of COMMANDS that will be executed if [cond] is true
--    cond    = $table  - EXPRESSION NODE, represents condition
--    else    = $table  - list of COMMANDS that will be executed none conditions are true
--    elseif  = $table  - list of ELSEIF nodes
--    line    = $number - line number
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewIfNode (line, condition, block, elseif_node, else_block)
  if (_DEBUG) then print("AST :: NewIfNode") end
  local node = {
    id          = nodes_codes["IF"],
    block       = block,
    cond        = condition,
    ["else"]    = else_block,
    ["elseif"]  = elseif_node,
    line        = line,
  }
  return node
end

--NewNewVarNode:
--  {
--    id    = $number - NEWVAR code
--    exp   = $table  - EXPRESSION node
--    type  = $string - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewNewVarNode (expression, type)
  if (_DEBUG) then print("AST :: NewNewVarNode") end
  local node = {
    id    = nodes_codes["NEWVAR"],
    exp   = expression,
    type  = type,
  }
  return node
end

--NewOperatorNode:
--  {
--    id    = $number - OPERATOR code
--    op    = $string - [+ - * / > < >= <= == <>], one of possible operations
--    [1]   = $table  - EXPRESSION node, left side of operator
--    [2]   = $table  - EXPRESSION node, right side of operator
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewOperatorNode (left, operator, right)
  if (_DEBUG) then print("AST :: NewOperatorNode") end
  local node = {
    id    = nodes_codes["OPERATOR"],
    op    = operator,
    left,
    right,
  }
  return node
end

--NewParameterNode:
--  {
--    id        = $number - PARAMETER code
--    name      = $string - var name
--    dimension = $number - var dimension
--    type      = $string - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewParameterNode (name, typebase, size)
  if (_DEBUG) then print("AST :: NewProgramNode") end
  local node = {
    id        = nodes_codes["PARAMETER"],
    name      = name,
    dimension = size,
    type      = typebase,
  }
  return node
end

--NewParenthesisNode:
--  {
--    id    = $number - PARENTHESIS code
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewParenthesisNode (expression)
  if (_DEBUG) then print("AST :: NewParenthesisNode") end
  local node = {
    id  = nodes_codes["PARENTHESIS"],
    exp = expression,
  }
  return node
end

--NewProgramNode:
--  {
--    id       = $number - PROGRAM code
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

--NewReturnNode:
--  {
--    id    = $number - RETURN code
--    line  = $number - line number
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewReturnNode (line, expression)
  if (_DEBUG) then print("AST :: NewReturnNode") end
  local node = {
    id    = nodes_codes["RETURN"],
    exp   = expression,
    line  = line,
  }
  return node
end

--NewValueNode:
--  {
--    id    = $number   - VALUE code
--    type  = $string   - [bool, char, int, string]
--    value = $string   - if type == char or string,
--            $number   - if type == int,
--            $boolean  - if type == bool,
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewValueNode (type, value)
  if (_DEBUG) then print("AST :: NewValueNode") end
  local node = {
    id    = nodes_codes["VALUE"],
    type  = type,
    value = value,
  }
  return node
end

--NewVarNode:
--  {
--    id    = $number - VAR code
--    array = $table  - list of EXPRESSIONS, one for each dimension
--    line  = $number - line number
--    name  = $string - var name
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewVarNode (line, name, array)
  if (_DEBUG) then print("AST :: NewVarNode") end
  local node = {
    id    = nodes_codes["VAR"],
    line  = line,
    name  = name,
    array = array,
  }
  return node
end

--NewWhileNode:
--  {
--    id    = $number - WHILE code
--    block = $table  - list of COMMANDS that will be executed if [cond] is true
--    cond  = $table  - EXPRESSION node, represents condition
--    line  = $number - line number
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewWhileNode (line, condition, block)
  if (_DEBUG) then print("AST :: NewWhileNode") end
  local node = {
    id    = nodes_codes["WHILE"],
    block = block,
    cond  = condition,
    line  = line,
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