-- PRECISO DE LINE DENTRO DA VAR ?

--==============================================================================
-- Debug
--==============================================================================

local printTree = false

--==============================================================================
-- Dependency
--==============================================================================

require "lib/util" -- TEMPORARY


--==============================================================================
-- Data Structure
--==============================================================================

local AbstractSyntaxTree = {}

local Print = {}

local list_ids = {
  CALL      = 003,
  CMDATRIB  = 021,
  CMDRETURN = 022,
  CMDWHILE  = 023,
  DECLARE   = 002,
  EXP_CALL  = 033,
  EXP_EXP   = 035,
  EXP_OP    = 031,
  EXP_VALUE = 034,
  EXP_VAR   = 032,
  FUNCTION  = 011,
  PARAMETER = 012,
  PROGRAM   = 001,
  VAR       = 004,
}

local tree = {}


--==============================================================================
-- Private Methods
--==============================================================================

function Print.Call (indent, t)
  print(indent .. "CALL [" .. t.name .. "] @" .. t.line .. "  {")
  for _, node in ipairs(t.exps) do
    print(Print.Expression(node))
  end
  print(indent .. "}")
end

function Print.CmdAtrib (indent, t)
  print(indent .. "ATRIB @" .. t.line .. " {")
  Print.Var(indent .. "  ", t.var)
  print(Print.Expression(t.exp))
  print(indent .. "}")
end

function Print.CmdReturn (indent, t)
  print(indent .. "RETURN @" .. t.line .. " {")
  print(Print.Expression(t.exp))
  print(indent .. "}")
end

function Print.CmdWhile (indent, t)
  print(indent .. "WHILE @" .. t.line .. " {")
  print(indent .. "}")
end

function Print.Declare (indent, t)
  print(indent .. "DECLARE @" .. t.line .. "{")
  print(indent .. "ID [" .. t.name .. "] " .. t.type .. " " .. t.size .. " @" .. t.line)
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
    if (node.id == list_ids.DECLARE) then
      Print.Declare(indent .. "  ", node)
    elseif (node.id == list_ids.CALL) then
      Print.Call(indent .. "  ", node)
    elseif (node.id == list_ids.CMDATRIB) then
      Print.CmdAtrib(indent .. "  ", node)
    elseif (node.id == list_ids.CMDRETURN) then
      Print.CmdReturn(indent .. "  ", node)
    elseif (node.id == list_ids.CMDWHILE) then
      Print.CmdWhile(indent .. "  ", node)
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
    if (node.id == list_ids.DECLARE) then
      Print.Declare(indent .. "  ", node)
    elseif (node.id == list_ids.FUNCTION) then
      Print.Function(indent .. "  ", node)
    end
  end
  print(indent .. "}")
end

function Print.Var (indent, t)
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

--NewCallNode:
--  {
--    id    = $number - one of list_ids values
--    line  = $number - line number
--    name  = $string - var name
--    exps  = $table  - list of EXPRESSIONS nodes
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewCallNode (line, name, expressions)
  if (_DEBUG) then print("AST :: NewCallNode") end
  local node = {
    id   = list_ids.CALL,
    line = line,
    name = name,
    exps = expressions,
  }
  return node
end

--NewCmdAtribNode:
--  {
--    id    = $number - one of list_ids values
--    var   = $table  - VAR node
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewCmdAtribNode (var, expression)
  if (_DEBUG) then print("AST :: NewCmdAtribNode") end
  local node = {
    id    = list_ids.CMDATRIB,
    exp   = expression,
    line  = var.line,
    var   = var,
  }
  return node
end

--NewCmdReturnNode:
--  {
--    id    = $number - one of list_ids values
--    line  = $number - line number
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewCmdReturnNode (line, expression)
  if (_DEBUG) then print("AST :: NewCmdReturnNode") end
  local node = {
    id    = list_ids.CMDRETURN,
    exp   = expression,
    line  = line,
  }
  return node
end

--NewCmdWhileNode:
--  {
--    id    = $number - one of list_ids values
--    block = $table  - list of COMMANDS that will be executed if [cond] is true
--    cond  = $table  - EXPRESSION NODE, represents condition
--    line  = $number - line number
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewCmdWhileNode (line, condition, block)
  if (_DEBUG) then print("AST :: NewCmdWhileNode") end
  local node = {
    id    = list_ids.CMDWHILE,
    block = block,
    cond  = condition,
    line  = line,
  }
  return node
end

--NewDeclareNode:
--  {
--    id    = $number - one of list_ids values
--    line  = $number - line number
--    name  = $string - var name
--    size  = $number - 
--    type  = $number - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewDeclareNode (line, name, typebase, size)
  if (_DEBUG) then print("AST :: NewDeclareNode") end
  local node = {
    id    = list_ids.DECLARE,
    line  = line,
    name  = name,
    size  = size,
    type  = typebase,
  }
  return node
end

--NewExpCallNode:
--  {
--    id    = $number - one of list_ids values
--    name  = $string - 
--    array = $table  - 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpCallNode (call)
  if (_DEBUG) then print("AST :: NewExpCallNode") end
  local node = {
    id    = list_ids.EXP_CALL,
    name  = call.name,
    exps  = call.exps,
  }
  return node
end

--NewExpOperatorNode:
--  {
--    id    = $number - one of list_ids values
--    op    = $string - 
--    [1]   = 
--    [2]   = 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpOperatorNode (left, operator, right)
  if (_DEBUG) then print("AST :: NewExpOperatorNode") end
  local node = {
    id    = list_ids.EXP_OP,
    op    = operator,
    left,
    right,
  }
  return node
end

--NewExpParenthesisNode:
--  {
--    id    = $number - one of list_ids values
--    exp   = $table  - EXPRESSION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpParenthesisNode (exp)
  if (_DEBUG) then print("AST :: NewExpParenthesisNode") end
  local node = {
    id  = list_ids.EXP_EXP,
    exp = unpack(exp)
  }
  return node
end

--NewExpValueNode:
--  {
--    id    = $number - one of list_ids values
--    type  = $string - 
--    value = $string or $number or $boolean - 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpValueNode (type, value)
  if (_DEBUG) then print("AST :: NewExpValueNode") end
  local node = {
    id    = list_ids.EXP_VALUE,
    type  = type,
    value = value,
  }
  return node
end

--NewExpVarNode:
--  {
--    id    = $number - one of list_ids values
--    name  = $string - 
--    array = $table  - 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewExpVarNode (var)
  if (_DEBUG) then print("AST :: NewExpVarNode") end
  local node = {
    id    = list_ids.EXP_VAR,
    name  = var.name,
    array = var.array,
  }
  return node
end

--NewFunctionNode:
--  {
--    id      = $number - one of list_ids values
--    block   = $table  - list of COMMANDS that will be executed if [cond] is true
--    line    = $number - line number
--    name    = $string - var name
--    params  = $table  - list of PARAMETER nodes
--    r_type  = $number - [bool, char, int, string], represents functino return type
--    r_size  = $number - 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewFunctionNode (line, name, parameters, return_type, return_size, block)
  if (_DEBUG) then print("AST :: NewFunctionNode") end
  local node = {
    id      = list_ids.FUNCTION,
    line    = line,
    name    = name,
    params  = parameters,
    r_type  = return_type,
    r_size  = return_size,
    block   = block,
  }
  return node
end

--NewParameterNode:
--  {
--    id    = $number - one of list_ids values
--    name  = $string - var name
--    size  = $number - 
--    type  = $number - [bool, char, int, string]
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewParameterNode (name, typebase, size)
  if (_DEBUG) then print("AST :: NewProgramNode") end
  local node = {
    id    = list_ids.PARAMETER,
    name  = name,
    size  = size,
    type  = typebase,
  }
  return node
end

--NewProgramNode:
--  {
--    [1 to N] = DECLARE or FUNCTION node
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewProgramNode (ast_tree)
  if (_DEBUG) then print("AST :: NewProgramNode") end
  tree = ast_tree
  if (printTree) then AbstractSyntaxTree.Print() end
end

--NewVarNode:
--  {
--    id    = $number - one of list_ids values
--    line  = $number - line number
--    name  = $string - var name
--    array = $table  - 
--  }
--  parameters:
--  return:
function AbstractSyntaxTree.NewVarNode (line, name, array)
  if (_DEBUG) then print("AST :: NewVarNode") end
  local node = {
    id    = list_ids.VAR,
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