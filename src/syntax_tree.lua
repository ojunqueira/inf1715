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


--==============================================================================
-- Data Structure
--==============================================================================

local AbstractSyntaxTree = {}

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



--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

--GetTree:
--  parameters:
--  return:
function AbstractSyntaxTree.GetTree ()
  --return util.TableCopy(tree)
  return tree
end

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
  if (node.type == "string") then
    node.type = "char"
    node.dimension = node.dimension + 1
  end
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

--NewNegateNode:
--  {
--    id    = $number - NEGATE code
--    exp   = $table  - EXPRESSION node
--    line  = $number - line number
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewNegateNode (line, expression)
  if (_DEBUG) then print("AST :: NewNegateNode") end
  local node = {
    id    = nodes_codes["NEGATE"],
    exp   = expression,
    line  = line,
  }
  return node
end

--NewNewVarNode:
--  {
--    id        = $number - NEWVAR code
--    dimension = $number - var dimension
--    exp       = $table  - EXPRESSION node
--    line      = $number - line number
--    type      = $string - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewNewVarNode (line, expression, type, dimension)
  if (_DEBUG) then print("AST :: NewNewVarNode") end
  local node = {
    id        = nodes_codes["NEWVAR"],
    dimension = dimension,
    exp       = expression,
    line      = line,
    type      = type,
  }
  return node
end

--NewOperatorNode:
--  {
--    id    = $number - OPERATOR code
--    line  = $number - line number
--    op    = $string - [and or + - * / > < >= <= = <>], one of possible operations
--    [1]   = $table  - EXPRESSION node, left side of operator
--    [2]   = $table  - EXPRESSION node, right side of operator
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewOperatorNode (line, left, operator, right)
  if (_DEBUG) then print("AST :: NewOperatorNode") end
  local node = {
    id    = nodes_codes["OPERATOR"],
    line  = line,
    op    = operator,
    left,
    right,
  }
  return node
end

--NewParameterNode:
--  {
--    id        = $number - PARAMETER code
--    dimension = $number - var dimension
--    line      = $number - line number
--    name      = $string - var name
--    type      = $string - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewParameterNode (line, name, typebase, size)
  if (_DEBUG) then print("AST :: NewProgramNode") end
  local node = {
    id        = nodes_codes["PARAMETER"],
    line      = line,
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
--    line  = $number - line number
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewParenthesisNode (line, expression)
  if (_DEBUG) then print("AST :: NewParenthesisNode") end
  local node = {
    id    = nodes_codes["PARENTHESIS"],
    exp   = expression,
    line  = line,
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

--NewUnaryNode:
--  {
--    id    = $number - UNARY code
--    exp   = $table  - EXPRESSION node
--    line  = $number - line number
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewUnaryNode (line, expression)
  if (_DEBUG) then print("AST :: NewUnaryNode") end
  local node = {
    id    = nodes_codes["UNARY"],
    exp   = expression,
    line  = line,
  }
  return node
end

--NewValueNode:
--  {
--    id    = $number   - VALUE code
--    line  = $number - line number
--    type  = $string   - [bool, char, int, string]
--    value = $string   - if type == char or string,
--            $number   - if type == int,
--            $boolean  - if type == bool,
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewValueNode (line, type, value)
  if (_DEBUG) then print("AST :: NewValueNode") end
  local node = {
    id    = nodes_codes["VALUE"],
    line  = line,
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
  PrintClass.Print(tree)
end


--==============================================================================
-- Return
--==============================================================================

return AbstractSyntaxTree