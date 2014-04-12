--==============================================================================
-- Debug
--==============================================================================



--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"


--==============================================================================
-- Data Structure
--==============================================================================

local AbstractSyntaxTree = {}

local list_ids = {
  PROGRAM   = 999,
  DECLARE   = 100,
  FUNCTION  = 200,
  PARAMETER = 210,
  CMDATRIB  = 301,
  CMDRETURN = 302,
  CMDWHILE  = 303,
  CALL      = 310,
  VAR       = 800,
}

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

--NewCallNode:
--  parameters:
--  return:
function AbstractSyntaxTree.NewCallNode (line, name, expressions)
  local node = {
    id   = list_ids.CALL,
    line = line,
    name = name,
    exps = expressions,
  }
  return node
end

--NewCmdAtribNode:
--  parameters:
--  return:
function AbstractSyntaxTree.NewCmdAtribNode (var, expression)
  local node = {
    id = list_ids.CMDATRIB,
    var = var,
    exp = expression,
  }
  return node
end

--NewCmdReturnNode:
--  parameters:
--  return:
function AbstractSyntaxTree.NewCmdReturnNode (line, expression)
  local node = {
    id = list_ids.CMDRETURN,
    exp = expression,
    line = line,
  }
  return node
end

--NewCmdWhileNode:
--  parameters:
--  return:
function AbstractSyntaxTree.NewCmdWhileNode (line, condition, block)
  local node = {
    id = list_ids.CMDWHILE,
    block = block,
    condition = condition,
    line = line,
  }
  return node
end

--NewDeclareNode:
--  parameters:
--  return:
function AbstractSyntaxTree.NewDeclareNode (line, name, typebase, size)
  local node = {
    id    = list_ids.DECLARE,
    line  = line,
    name  = name,
    size  = size,
    type  = typebase,
  }
  return node
end

--NewFunctionNode:
--  parameters:
--  return:
function AbstractSyntaxTree.NewFunctionNode (line, name, params, ret_type, ret_size, block)
  if (_DEBUG) then print("AST :: AddFunctionNode") end
  local node = {
    id                = list_ids.FUNCTION,
    line              = line,
    name              = name,
    parameters        = params,
    return_type       = ret_type,
    return_arraysize  = ret_size,
    block             = block,
  }
  return node
end

--NewParameterNode:
--  parameters:
--  return:
function AbstractSyntaxTree.NewParameterNode (name, typebase, size)
  local node = {
    id    = list_ids.PARAMETER,
    name  = name,
    size  = size,
    type  = typebase,
  }
  return node
end

--NewProgramNode:
--  parameters:
--  return:
function AbstractSyntaxTree.NewProgramNode (ast_tree)
  if (_DEBUG) then print("AST :: NewProgramNode") end
  tree = ast_tree
end

--NewVarNode:
--  parameters:
--  return:
function AbstractSyntaxTree.NewVarNode (line, name, array)
  local node = {
    id    = list_ids.VAR,
    line  = line,
    name  = name,
    array = array,
  }
  return node
end

--Print:
--  parameters:
--  return:
function AbstractSyntaxTree.Print ()
  util.TablePrint(tree)
end


--==============================================================================
-- Return
--==============================================================================

return AbstractSyntaxTree