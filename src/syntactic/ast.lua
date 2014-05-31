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



--==============================================================================
-- Public Methods
--==============================================================================

--GetTree:
--  Parameters:
--  Return:
--    [1] $table  - Tree structure
function Class.GetTree ()
  if (_DEBUG) then print("AST :: GetTree") end
  return tree
end

--NewAttributionNode:
--  {
--    id    = $number - ATTRIBUTION code
--    exp   = $table  - EXPRESSION node
--    line  = $number - line number
--    var   = $table  - VAR node
--  }
--  Parameters:
--  Return:
function Class.NewAttributionNode (var, expression)
  if (_DEBUG) then print("AST :: NewAttributionNode") end
  local node = {
    id    = tree_nodes["ATTRIBUTION"],
    exp   = expression,
    line  = var.line,
    var   = var,
  }
  return node
end

--NewCallNode: Create a new node
--  {
--    id    = $number - CALL code
--    line  = $number - line number
--    name  = $string - var name
--    exps  = $table  - list of EXPRESSION nodes
--  }
--  Parameters:
--  Return:
function Class.NewCallNode (line, name, expressions)
  if (_DEBUG) then print("AST :: NewCallNode") end
  local node = {
    id   = tree_nodes["CALL"],
    line = line,
    name = name,
    exps = expressions,
  }
  return node
end

--NewDeclVarNode: Create a new node
--  {
--    id        = $number - DECLARE code
--    line      = $number - line number
--    name      = $string - var name
--    dimension = $number - var dimension
--    type      = $string - [bool, char, int]
--  }
--  Parameters:
--  Return:
function Class.NewDeclVarNode (line, name, typebase, size)
  if (_DEBUG) then print("AST :: NewDeclVarNode") end
  local node = {
    id        = tree_nodes["DECLARE"],
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

--NewElseIfNode: Create a new node
--  {
--    id    = $number - ELSEIF code
--    block = $table  - list of COMMANDS that will be executed if [cond] is true
--    cond  = $table  - EXPRESSION NODE, represents condition
--    line  = $number - line number
--  }
--  Parameters:
--  Return:
function Class.NewElseIfNode (line, condition, block)
  if (_DEBUG) then print("AST :: NewElseIfNode") end
  local node = {
    id          = tree_nodes["ELSEIF"],
    block       = block,
    cond        = condition,
    line        = line,
  }
  return node
end

--NewFunctionNode: Create a new node
--  {
--    id            = $number         - FUNCTION code
--    block         = $table          - list of COMMANDS that will be executed
--    line          = $number         - line number
--    name          = $string         - var name
--    params        = $table          - list of PARAMETER nodes
--    ret_type      = $string or $nil - [bool, char, int], represents function return type
--    ret_dimension = $number or $nil - function return dimension
--  }
--  Parameters:
--  Return:
function Class.NewFunctionNode (line, name, parameters, return_type, return_size, block)
  if (_DEBUG) then print("AST :: NewFunctionNode") end
  local node = {
    id            = tree_nodes["FUNCTION"],
    line          = line,
    name          = name,
    params        = parameters,
    ret_type      = return_type,
    ret_dimension = return_size,
    block         = block,
  }
  if (node.ret_type == "string") then
    node.ret_type = "char"
    node.ret_dimension = node.ret_dimension + 1
  end
  return node
end

--NewIfNode: Create a new node
--  {
--    id      = $number - IF code
--    block   = $table  - list of COMMANDS that will be executed if [cond] is true
--    cond    = $table  - EXPRESSION NODE, represents condition
--    else    = $table  - list of COMMANDS that will be executed none conditions are true
--    elseif  = $table  - list of ELSEIF nodes
--    line    = $number - line number
--  }
--  Parameters:
--  Return:
function Class.NewIfNode (line, condition, block, elseif_node, else_block)
  if (_DEBUG) then print("AST :: NewIfNode") end
  if (elseif_node and util.TableIsEmpty(elseif_node)) then
    elseif_node = nil
  end
  local node = {
    id          = tree_nodes["IF"],
    block       = block,
    cond        = condition,
    ["else"]    = else_block,
    ["elseif"]  = elseif_node,
    line        = line,
  }
  return node
end

--NewLiteralNode: Create a new node
--  {
--    id        = $number   - LITERAL code
--    dimension = $number   - var dimension
--    line      = $number   - line number
--    type      = $string   - [bool, char, int, string]
--    value     = $string   - if type == char or string, -- Value cannot be 'char' type.
--                $number   - if type == int,
--                $boolean  - if type == bool,
--  }
--  Parameters:
--  Return:
function Class.NewLiteralNode (line, type, value)
  if (_DEBUG) then print("AST :: NewLiteralNode") end
  local node = {
    id        = tree_nodes["LITERAL"],
    dimension = 0,
    line      = line,
    type      = type,
    value     = value,
  }
  if (node.type == "string") then
    node.type = "char"
    node.dimension = 1
  end
  return node
end

--NewNegateNode: Create a new node
--  {
--    id    = $number - NEGATE code
--    exp   = $table  - EXPRESSION node
--    line  = $number - line number
--  }
--  Parameters:
--  Return:
function Class.NewNegateNode (line, expression)
  if (_DEBUG) then print("AST :: NewNegateNode") end
  local node = {
    id    = tree_nodes["NEGATE"],
    exp   = expression,
    line  = line,
  }
  return node
end

--NewNewVarNode: Create a new node
--  {
--    id        = $number - NEWVAR code
--    dimension = $number - var dimension
--    exp       = $table  - EXPRESSION node
--    line      = $number - line number
--    type      = $string - [bool, char, int]
--  }
--  Parameters:
--  Return:
function Class.NewNewVarNode (line, expression, type, dimension)
  if (_DEBUG) then print("AST :: NewNewVarNode") end
  local node = {
    id        = tree_nodes["NEWVAR"],
    dimension = dimension,
    exp       = expression,
    line      = line,
    type      = type,
  }
  if (node.type == "string") then
    node.type = "char"
    node.dimension = node.dimension + 1
  end
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
--  Parameters:
--  Return:
function Class.NewOperatorNode (line, left, operator, right)
  if (_DEBUG) then print("AST :: NewOperatorNode") end
  local node = {
    id    = tree_nodes["OPERATOR"],
    line  = line,
    op    = operator,
    left,
    right,
  }
  return node
end

--NewParameterNode: Create a new node
--  {
--    id        = $number - PARAMETER code
--    dimension = $number - var dimension
--    line      = $number - line number
--    name      = $string - var name
--    type      = $string - [bool, char, int]
--  }
--  Parameters:
--  Return:
function Class.NewParameterNode (line, name, typebase, size)
  if (_DEBUG) then print("AST :: NewProgramNode") end
  local node = {
    id        = tree_nodes["PARAMETER"],
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

--NewProgramNode: Create a new node, and set class current tree to this one
--  {
--    id       = $number - PROGRAM code
--    [1 to N] = DECLARE or FUNCTION node
--  }
--  Parameters:
--  Return:
function Class.NewProgramNode (ast_tree)
  if (_DEBUG) then print("AST :: NewProgramNode") end
  tree = {}
  tree = util.TableCopy(ast_tree)
  tree.id = tree_nodes["PROGRAM"]
  if (printTree) then Class.Print() end
end

--NewReturnNode: Create a new node
--  {
--    id    = $number - RETURN code
--    line  = $number - line number
--    exp   = $table  - EXPRESSION node
--  }
--  Parameters:
--  Return:
function Class.NewReturnNode (line, expression)
  if (_DEBUG) then print("AST :: NewReturnNode") end
  local node = {
    id    = tree_nodes["RETURN"],
    exp   = expression,
    line  = line,
  }
  return node
end

--NewUnaryNode: Create a new node
--  {
--    id    = $number - UNARY code
--    exp   = $table  - EXPRESSION node
--    line  = $number - line number
--  }
--  Parameters:
--  Return:
function Class.NewUnaryNode (line, expression)
  if (_DEBUG) then print("AST :: NewUnaryNode") end
  local node = {
    id    = tree_nodes["UNARY"],
    exp   = expression,
    line  = line,
  }
  return node
end

--NewVarNode: Create a new node
--  {
--    id    = $number - VAR code
--    array = $table  - list of EXPRESSIONS, one for each dimension
--    line  = $number - line number
--    name  = $string - var name
--  }
--  Parameters:
--  Return:
function Class.NewVarNode (line, name, array)
  if (_DEBUG) then print("AST :: NewVarNode") end
  local node = {
    id    = tree_nodes["VAR"],
    line  = line,
    name  = name,
    array = array,
  }
  return node
end

--NewWhileNode: Create a new node
--  {
--    id    = $number - WHILE code
--    block = $table  - list of COMMANDS that will be executed if [cond] is true
--    cond  = $table  - EXPRESSION node, represents condition
--    line  = $number - line number
--  }
--  Parameters:
--  Return:
function Class.NewWhileNode (line, condition, block)
  if (_DEBUG) then print("AST :: NewWhileNode") end
  local node = {
    id    = tree_nodes["WHILE"],
    block = block,
    cond  = condition,
    line  = line,
  }
  return node
end

--Print: Print Abstract Syntax Tree with comprehensible format
--  Parameters:
--  Return:
function Class.Print ()
  if (_DEBUG) then print("AST :: Print") end
  UtilTree.Print(tree)
end


--==============================================================================
-- Return
--==============================================================================

return Class