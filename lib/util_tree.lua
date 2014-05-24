--==============================================================================
-- Debug
--==============================================================================


--==============================================================================
-- Dependency
--==============================================================================

local NodesClass  = require "lib/node_codes"


--==============================================================================
-- Data Structure
--==============================================================================

local Print = {}

--  list of nodes code
--  {
--    [name] = $number,
--  }
local nodes_codes = NodesClass.GetNodesList()


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
      --elseif (node.id == nodes_codes["VAR"]) then
        --Print.Variable(indent, node)
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
  local str = indent .. "}"
  if (t.sem_type and t.sem_dimension) then
    str = str .. string.format(" #%s:%d", t.sem_type, t.sem_dimension)
  end
  print(str)
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

function Print.Expression (t)
  local str = "("
  if (not t) then
    return ""
  end
  if (t.id == nodes_codes["PARENTHESIS"]) then
    str = str .. " (" .. Print.Expression(t.exp) .. ")"
  elseif (t.id == nodes_codes["NEWVAR"]) then
    str = str .. " new [" .. Print.Expression(t.exp) .. "] " .. t.type
  elseif (t.id == nodes_codes["NEGATE"]) then
    str = str .. " not " .. Print.Expression(t.exp)
  elseif (t.id == nodes_codes["UNARY"]) then
    str = str .. " - " .. Print.Expression(t.exp)
  elseif (t.id == nodes_codes["OPERATOR"]) then
    str = str .. Print.Expression(t[1]) .. " " .. t.op .. " " .. Print.Expression(t[2])
  elseif (t.id == nodes_codes["LITERAL"]) then
    str = str .. " " .. t.value
  elseif (t.id == nodes_codes["CALL"]) then
    str = str .. " " .. t.name .. "("
    if (t.exps) then
      str = str .. Print.Expression(t.exps[1])
      if (t.exps[2]) then
        for i = 2, #t.exps do
          str = str .. ", " .. Print.Expression(t.exps[i])
        end
      end
    end
    str = str .. ")"
  elseif (t.id == nodes_codes["VAR"]) then
    str = str .. " " .. t.name
    if (t.array) then
      for _, exp in ipairs(t.array) do
        str = str .. "["
        str = str .. Print.Expression(exp)
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

function Print.Function (indent, t)
  print(indent .. "FUN [" .. t.name .. "] @" .. t.line .. " {")
  for _, node in ipairs(t.params) do
    print(indent .. "  FUNC_PARAMETER [" .. node.name .. "] " .. node.type .. string.rep("[]", node.dimension))
  end
  print(indent .. "  FUNC_RETURN " .. (t.ret_type or "VOID") .. string.rep("[]", t.ret_dimension or 0))
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

--Print: Print Abstract Syntax or Semantic Tree with comprehensible format
--  parameters:
--  return:
function Print.Print (tree)
  if (_DEBUG) then print("PRT :: Print") end
  Print.Program("", tree)
end


--==============================================================================
-- Return
--==============================================================================

return Print