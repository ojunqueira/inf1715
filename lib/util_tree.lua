--==============================================================================
-- Debug
--==============================================================================


--==============================================================================
-- Dependency
--==============================================================================

local TreeNodesCode = require "tree_nodes_code"


--==============================================================================
-- Data Structure
--==============================================================================

local Class = {}

--  list of nodes code
--  {
--    [name] = $number,
--  }
local tree_nodes = TreeNodesCode.GetList()


--==============================================================================
-- Private Methods
--==============================================================================

function Class.Block (indent, t)
  if (t) then
    for _, node in ipairs(t) do
      if (node.id == tree_nodes["ATTRIBUTION"]) then
        Class.ComandAttribution(indent, node)
      elseif (node.id == tree_nodes["IF"]) then
        Class.ComandIf(indent, node)
      elseif (node.id == tree_nodes["RETURN"]) then
        Class.ComandReturn(indent, node)
      elseif (node.id == tree_nodes["WHILE"]) then
        Class.ComandWhile(indent, node)
      elseif (node.id == tree_nodes["DECLARE"]) then
        Class.Declare(indent, node)
      elseif (node.id == tree_nodes["CALL"]) then
        Class.Call(indent, node)
      else
        error("block node error")
      end
    end
  end
end

function Class.Call (indent, t)
  print(indent .. "CALL [" .. t.name .. "] @" .. t.line .. "  {")
  for _, node in ipairs(t.exps) do
    print(indent .. "  PARAM " .. Class.Expression(node))
  end
  local str = indent .. "}"
  if (t.sem_type and t.sem_dimension) then
    str = str .. string.format(" #%s:%d", t.sem_type, t.sem_dimension)
  end
  print(str)
end

function Class.ComandAttribution (indent, t)
  print(indent .. "ATRIB @" .. t.line .. " {")
  local str = ""
  str = str .. t.var.name
  if (t.var.array) then
    for _, exp in ipairs(t.var.array) do
      str = str .. "[" .. Class.Expression(exp) .. "]"
    end
  end
  Class.Variable(indent .. "  ", t.var)

  print(indent .. "  =" .. Class.Expression(t.exp))
  print(indent .. "}")
end

function Class.ComandElseIf (indent, t)
  print(indent .. "ELSEIF [" .. Class.Expression(t.cond) .. "] @" .. t.line)
  Class.Block(indent .. "  ", t.block)
end

function Class.ComandIf (indent, t)
  print(indent .. "IF [" .. Class.Expression(t.cond) .. "] @" .. t.line .. " {")
  Class.Block(indent .. "  ", t.block)
  if (t["elseif"]) then
    for _, elseif_node in ipairs(t["elseif"]) do
      Class.ComandElseIf(indent, elseif_node)
    end
  end
  if (t["else"]) then
    print(indent .. "ELSE ")
    Class.Block(indent .. "  ", t["else"])
  end
  print(indent .. "}")
end

function Class.ComandReturn (indent, t)
  print(indent .. "RETURN @" .. t.line .. " {")
  print(indent .. "  " .. Class.Expression(t.exp))
  print(indent .. "}")
  -- print(indent .. "RETURN [" .. Class.Expression(t.exp) .. "] @" .. t.line)
end

function Class.ComandWhile (indent, t)
  print(indent .. "WHILE [" .. Class.Expression(t.cond) .. "] @" .. t.line .. " {")
  Class.Block(indent .. "  ", t.block)
  print(indent .. "}")
end

function Class.Declare (indent, t)
  print(indent .. "DECLARE @" .. t.line .. "{")
  print(indent .. "  ID [" .. t.name .. "] " .. t.type .. string.rep("[]", t.dimension) .. " @" .. t.line)
  print(indent .. "}")
  -- print(indent .. "DECLARE [" .. t.name .. "] " .. t.type .. string.rep("[]", t.dimension) .. " @" .. t.line)
end

function Class.Expression (t)
  local str = "("
  if (not t) then
    return ""
  end
  if (t.id == tree_nodes["PARENTHESIS"]) then
    str = str .. " (" .. Class.Expression(t.exp) .. ")"
  elseif (t.id == tree_nodes["NEWVAR"]) then
    str = str .. " new [" .. Class.Expression(t.exp) .. "] " .. t.type
  elseif (t.id == tree_nodes["NEGATE"]) then
    str = str .. " not " .. Class.Expression(t.exp)
  elseif (t.id == tree_nodes["UNARY"]) then
    str = str .. " - " .. Class.Expression(t.exp)
  elseif (t.id == tree_nodes["OPERATOR"]) then
    str = str .. Class.Expression(t[1]) .. " " .. t.op .. " " .. Class.Expression(t[2])
  elseif (t.id == tree_nodes["LITERAL"]) then
    str = str .. " " .. t.value
  elseif (t.id == tree_nodes["CALL"]) then
    str = str .. " " .. t.name .. "("
    if (t.exps) then
      str = str .. Class.Expression(t.exps[1])
      if (t.exps[2]) then
        for i = 2, #t.exps do
          str = str .. ", " .. Class.Expression(t.exps[i])
        end
      end
    end
    str = str .. ")"
  elseif (t.id == tree_nodes["VAR"]) then
    str = str .. " " .. t.name
    if (t.array) then
      for _, exp in ipairs(t.array) do
        str = str .. "["
        str = str .. Class.Expression(exp)
        str = str .. "]"
      end
    end
  else
    error("expression node error")
  end
  if (t.sem_type and t.sem_dimension) then
    str = str .. string.format(" #%s:%d", t.sem_type, t.sem_dimension)
  end
  return str .. ")"
end

function Class.Function (indent, t)
  print(indent .. "FUN [" .. t.name .. "] @" .. t.line .. " {")
  for _, node in ipairs(t.params) do
    print(indent .. "  FUNC_PARAMETER [" .. node.name .. "] " .. node.type .. string.rep("[]", node.dimension))
  end
  print(indent .. "  FUNC_RETURN " .. (t.ret_type or "VOID") .. string.rep("[]", t.ret_dimension or 0))
  for _, node in ipairs(t.block) do
    if (node.id == tree_nodes["DECLARE"]) then
      Class.Declare(indent .. "  ", node)
    elseif (node.id == tree_nodes["CALL"]) then
      Class.Call(indent .. "  ", node)
    elseif (node.id == tree_nodes["ATTRIBUTION"]) then
      Class.ComandAttribution(indent .. "  ", node)
    elseif (node.id == tree_nodes["IF"]) then
      Class.ComandIf(indent .. "  ", node)
    elseif (node.id == tree_nodes["RETURN"]) then
      Class.ComandReturn(indent .. "  ", node)
    elseif (node.id == tree_nodes["WHILE"]) then
      Class.ComandWhile(indent .. "  ", node)
    end
  end
  print(indent .. "}")
end

function Class.Program (indent, t)
  print(indent .. "PROGRAM {")
  for _, node in ipairs(t) do
    if (node.id == tree_nodes["DECLARE"]) then
      Class.Declare(indent .. "  ", node)
    elseif (node.id == tree_nodes["FUNCTION"]) then
      Class.Function(indent .. "  ", node)
    end
  end
  print(indent .. "}")
end

function Class.Variable (indent, t)
  local array_str = ""
  for _, exp in ipairs(t.array) do
    array_str = array_str .. "[" .. Class.Expression() .. "]"
  end
  print(indent .. "ID [" .. t.name .. "] " .. array_str .. " @" .. t.line)
end


--==============================================================================
-- Public Methods
--==============================================================================

--Class: Class Abstract Syntax or Semantic Tree with comprehensible format
--  parameters:
--  return:
function Class.Class (tree)
  if (_DEBUG) then print("PRT :: Class") end
  Class.Program("", tree)
end


--==============================================================================
-- Return
--==============================================================================

return Class