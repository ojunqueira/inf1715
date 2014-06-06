--==============================================================================
-- Debug
--==============================================================================

local printStruct = false
local test_cte    = false


--==============================================================================
-- Dependency
--==============================================================================

require "util"
local TreeNodesCode   = require "tree_nodes_code"
local OperationsCode  = require "operations_code"


--==============================================================================
-- Data Structure
--==============================================================================

local Class = {}

--  list of operations code
--  {
--    [name] = $number,
--  }
local operations_code = OperationsCode.GetList()

--  list of nodes code
--  {
--    [name] = $number,
--  }
local tree_nodes = TreeNodesCode.GetList()

--  store file path
local file

--  count number of generated labels
local label_counter = 0

--  count number of generated variables
local var_counter = 0

--  count number of functions
local function_counter = 0

--  three address codes
--  {
--    strings   = {
--      [1 to N] = {
--        var = $string   - variable name
--        str = $string   - literal string
--      }
--    }
--    globals   = {
--      [1 to N] = "name"
--    }
--    functions = {
--      [1 to N] = {      - list of functions
--        header          - function header
--        name            - function name
--        [1 to N] = {    - list of instructions
--          label = 
--          code  = 
--          op1   = 
--          op2   = 
--          op3   = 
--        }
--      }
--    }
--  }
local struct = {}


--==============================================================================
-- Private Methods
--==============================================================================

--AddInstruction: Add a new instruction node to current function
--  Parameters:
--    [1] $table  - Table created by 'NewInstruction' function
--  Return:
function Class.AddInstruction (inst)
  if (_DEBUG) then print("ICG :: AddInstruction") end
  assert (inst and type(inst) == "table")
  table.insert(struct.functions[function_counter], inst)
end

--Clear: Set class condition to it's initial state
--  Parameters:
--  Return:
function Class.Clear ()
  if (_DEBUG) then print("ICG :: Clear") end
  struct = {
    strings   = {},
    globals   = {},
    functions = {},
  }
  function_counter  = 0
  label_counter     = 0
  var_counter       = 0
end

--Dump: Write class struct to file
--  Parameters:
--    [1] $string   - complete file path
--  Return:
function Class.Dump (output)
  if (_DEBUG) then print("ICG :: Dump") end
  for _, str_node in ipairs(struct.strings) do
    output:write(string.format('%8s string  %s = "%s"\n', "", str_node.var, str_node.str))
  end
  for _, name in ipairs(struct.globals) do
    output:write(string.format('%8s global %s\n', "", name))
  end
  for _, func in ipairs(struct.functions) do
    output:write(func.header)
    for _, inst in ipairs(func) do
      Class.DumpInstruction(output, inst)
    end
  end
end

--DumpInstruction: Write instruction to file
--  Parameters:
--    [1] $       - Desired output
--    [2] $table  - Table created by 'AddInstruction' function
--  Return:
function Class.DumpInstruction (output, inst)
  if (_DEBUG) then print("ICG :: DumpInstruction") end
  if (inst.code == operations_code["CALLID"]) then
    output:write(string.format('%14s   call %s\n', inst.label or "", inst.op1))
  elseif (inst.code == operations_code["GOTO"]) then
    output:write(string.format('%14s   goto %s\n', inst.label or "", inst.op1))
  elseif (inst.code == operations_code["IFFALSEGOTO"]) then
    output:write(string.format('%14s   ifFalse %s goto %s\n', inst.label or "", inst.op1, inst.op2))
  elseif (inst.code == operations_code["IFGOTO"]) then
    output:write(string.format('%14s   if %s goto %s\n', inst.label or "", inst.op1, inst.op2))
  elseif (inst.code == operations_code["LABEL"]) then
    output:write(string.format('%14s\n', inst.label .. ":" or ""))
  elseif (inst.code == operations_code["PARAM"]) then
    output:write(string.format('%14s   param %s\n', inst.label or "", inst.op1))
  elseif (inst.code == operations_code["RET_OP"]) then
    output:write(string.format('%14s   ret %s\n', inst.label or "", inst.op1))
  elseif (inst.code == operations_code["RET_NIL"]) then
    output:write(string.format('%14s   ret\n', inst.label or ""))
  elseif (inst.code == operations_code["ID=rval"]) then
    output:write(string.format('%14s   %s = %s\n', inst.label or "", inst.op1, inst.op2))
  elseif (inst.code == operations_code["ID=BYTErval"]) then
    output:write(string.format('%14s   %s = byte %s\n', inst.label or "", inst.op1, inst.op2))
  elseif (inst.code == operations_code["ID=ID[rval]"]) then
    output:write(string.format('%14s   %s = %s[%s]\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID=BYTEID[rval]"]) then
    output:write(string.format('%14s   %s = byte %s[%s]\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  -- UNARY OPERATORS
  elseif (inst.code == operations_code["ID=-rval"]) then
    output:write(string.format('%14s   %s = - %s\n', inst.label or "", inst.op1, inst.op2))
  elseif (inst.code == operations_code["ID=NEWrval"]) then
    output:write(string.format('%14s   %s = new %s\n', inst.label or "", inst.op1, inst.op2))
  elseif (inst.code == operations_code["ID=NEWBYTErval"]) then
    output:write(string.format('%14s   %s = new byte %s\n', inst.label or "", inst.op1, inst.op2))
  -- COMPARISON
  elseif (inst.code == operations_code["ID=rvalEQrval"]) then
    output:write(string.format('%14s   %s = %s == %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID=rvalNErval"]) then
    output:write(string.format('%14s   %s = %s != %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID=rvalGErval"]) then
    output:write(string.format('%14s   %s = %s >= %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID=rvalLErval"]) then
    output:write(string.format('%14s   %s = %s <= %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID=rval<rval"]) then
    output:write(string.format('%14s   %s = %s < %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID=rval>rval"]) then
    output:write(string.format('%14s   %s = %s > %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  --
  elseif (inst.code == operations_code["ID=rval+rval"]) then
    output:write(string.format('%14s   %s = %s + %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID=rval-rval"]) then
    output:write(string.format('%14s   %s = %s - %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID=rval*rval"]) then
    output:write(string.format('%14s   %s = %s * %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID=rval/rval"]) then
    output:write(string.format('%14s   %s = %s / %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  --
  elseif (inst.code == operations_code["ID[rval]=rval"]) then
    output:write(string.format('%14s   %s[%s] = %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == operations_code["ID[rval]=BYTErval"]) then
    output:write(string.format('%14s   %s[%s] = byte %s\n', inst.label or "", inst.op1, inst.op2, inst.op3))
  else
    Class.Error("unknown instruction node.")
  end
end

--Error: Stop class execution and generate error message
--  Parameters:
--    [1] $string - 
--  Return:
function Class.Error (msg)
  if (_DEBUG) then print("ICG :: Error") end
  local str = string.format("intermediate code generator error: %s", msg or "")
  error(str, 0)
end

--GenAttribution: Add instructions of node to it's function structure
--  Parameters:
--    [1] $table  - ATTRIBUTION node
--  Return:
function Class.GenAttribution (node)
  if (_DEBUG) then print("ICG :: GenAttribution") end
  assert(node.id == tree_nodes["ATTRIBUTION"])
  if (#node.var.array > 0) then
    local op
    for i = 1, #node.var.array do
      local last_op = op
      if (i == #node.var.array) then
        local op_inst
        if (node.var.sem_type == "bool" or node.var.sem_type == "char") then
          op_inst = "ID[rval]=BYTErval"
        else
          op_inst = "ID[rval]=rval"
        end
        local op_array  = Class.GenExpression(node.var.array[i])
        local op_exp    = Class.GenExpression(node.exp)
        Class.AddInstruction(Class.NewInstruction(nil, op_inst, op or node.var.name, op_array, op_exp))
      else
        local op_array = Class.GenExpression(node.var.array[i])
        op = Class.GetVariable()
        Class.AddInstruction(Class.NewInstruction(nil, "ID=ID[rval]", op, last_op or node.var.name, op_array))
      end
    end
  else
    local op
    if (node.var.sem_type == "char" or node.var.sem_type == "bool") then
      op = "ID=BYTErval"
    else
      op = "ID=rval"
    end
    local op_exp = Class.GenExpression(node.exp)
    Class.AddInstruction(Class.NewInstruction(nil, op, node.var.name, op_exp))
  end
end

--GenBlock: Add instructions of node to it's function structure
--  Parameters:
--    [1] $table  - List of ATTRIBUTION, CALL, DECLARE, IF, RETURN and WHILE nodes
--  Return:
function Class.GenBlock (block)
  if (_DEBUG) then print("ICG :: GenBlock") end
  for _, node in ipairs(block) do
    if (node.id == tree_nodes["ATTRIBUTION"]) then
      Class.GenAttribution(node)
    elseif (node.id == tree_nodes["CALL"]) then
      Class.GenCall(node)
    elseif (node.id == tree_nodes["DECLARE"]) then
      Class.GenDeclare(node)
    elseif (node.id == tree_nodes["IF"]) then
      Class.GenIf(node)
    elseif (node.id == tree_nodes["RETURN"]) then
      Class.GenReturn(node)
    elseif (node.id == tree_nodes["WHILE"]) then
      Class.GenWhile(node)
    end
  end
end

--GenCall: Add instructions of node to it's function structure
--  Parameters:
--    [1] $table  - CALL node
--  Return:
function Class.GenCall (node)
  if (_DEBUG) then print("ICG :: GenCall") end
  assert(node.id == tree_nodes["CALL"])
  if (node.exps) then
    local params_list = {}
    for i=#node.exps, 1, -1 do
      table.insert(params_list, Class.GenExpression(node.exps[i]))
    end
    for i=#node.exps, 1, -1 do
      Class.AddInstruction(Class.NewInstruction(nil, "PARAM", params_list[i]))
    end
  end
  Class.AddInstruction(Class.NewInstruction(nil, "CALLID", node.name))
end

--GenDeclare: Add instructions of node to it's function structure
--  Parameters:
--    [1] $table  - DECLARE node
--  Return:
function Class.GenDeclare (node)
  if (_DEBUG) then print("ICG :: GenDeclare") end
  assert(node.id == tree_nodes["DECLARE"])
  local op
  if ((node.type == "bool" or node.type == "char") and node.dimension == 0) then
    op = "ID=BYTErval"
  else
    op = "ID=rval"
  end
  Class.AddInstruction(Class.NewInstruction(nil, op, node.name, "0"))
end

--GenExpression:
--  Parameters:
--    [1] $table  - CALL, NEGATE, NEWVAR, OPERATOR, UNARY, VALUE or VAR node
--  Return:
--    [1] $string - Variable or value where expression return is saved
function Class.GenExpression (node)
  if (node.id == tree_nodes["CALL"]) then
    return Class.GenExpressionCall(node)
  elseif (node.id == tree_nodes["LITERAL"]) then
    return Class.GenExpressionLiteral(node)
  elseif (node.id == tree_nodes["NEGATE"]) then
    return Class.GenExpressionNegate(node)
  elseif (node.id == tree_nodes["NEWVAR"]) then
    return Class.GenExpressionNewVar(node)
  elseif (node.id == tree_nodes["OPERATOR"]) then
    return Class.GenExpressionOperator(node)
  elseif (node.id == tree_nodes["UNARY"]) then
    return Class.GenExpressionUnary(node)
  elseif (node.id == tree_nodes["VAR"]) then
    return Class.GenExpressionVar(node)
  end
end

function Class.GenExpressionCall (node)
  assert(node.id == tree_nodes["CALL"])
  Class.GenCall(node)
  local op = Class.GetVariable()
  local ret = "$ret"
  Class.AddInstruction(Class.NewInstruction(nil, "ID=rval", op, ret))
  return op
end

function Class.GenExpressionLiteral (node)
  assert(node.id == tree_nodes["LITERAL"])
  local op
  if (node.type == "char") then
    op = Class.GetVariable()
    local t = {
      var = op,
      str = node.value,
    }
    table.insert(struct.strings, t)
  elseif (node.type == "bool") then
    op = (node.value == "true" and "1") or "0"
  else
    op = node.value
  end
  return op
end

function Class.GenExpressionNegate (node)
  assert(node.id == tree_nodes["NEGATE"])
  local op = Class.GetVariable()
  Class.AddInstruction(Class.NewInstruction(nil, "ID=rvalEQrval", op, Class.GenExpression(node.exp), "0"))
  return op
end

function Class.GenExpressionNewVar (node)
  assert(node.id == tree_nodes["NEWVAR"])
  local op = Class.GetVariable()
  if ((node.sem_type == "bool" or node.sem_type == "char") and node.exp.sem_dimension == 0) then
    Class.AddInstruction(Class.NewInstruction(nil, "ID=NEWBYTErval", op, Class.GenExpression(node.exp)))
  else
    Class.AddInstruction(Class.NewInstruction(nil, "ID=NEWrval", op, Class.GenExpression(node.exp)))
  end
  return op
end

function Class.GenExpressionOperator (node)
  local op
  if (node.op == "and") then
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=BYTErval", op, 0))
    local lbl_end  = Class.GetLabel()
    local op_left  = Class.GenExpression(node[1])
    Class.AddInstruction(Class.NewInstruction(nil, "IFFALSEGOTO", op_left, lbl_end))
    local op_right = Class.GenExpression(node[2])
    Class.AddInstruction(Class.NewInstruction(nil, "IFFALSEGOTO", op_right, lbl_end))
    Class.AddInstruction(Class.NewInstruction(nil, "ID=BYTErval", op, 1))    
    Class.AddInstruction(Class.NewInstruction(lbl_end, "LABEL"))
  elseif (node.op == "or") then
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=BYTErval", op, 0))
    local lbl_true  = Class.GetLabel()
    local lbl_end   = Class.GetLabel()
    local op_left   = Class.GenExpression(node[1])
    Class.AddInstruction(Class.NewInstruction(nil, "IFGOTO", op_left, lbl_true))
    local op_right  = Class.GenExpression(node[2])  
    Class.AddInstruction(Class.NewInstruction(nil, "IFGOTO", op_right, lbl_true))
    Class.AddInstruction(Class.NewInstruction(nil, "GOTO", lbl_end))
    Class.AddInstruction(Class.NewInstruction(lbl_true, "LABEL"))
    Class.AddInstruction(Class.NewInstruction(nil, "ID=BYTErval", op, 1))
    Class.AddInstruction(Class.NewInstruction(lbl_end, "LABEL"))
  elseif (node.op == "=") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rvalEQrval", op, left, right))
  elseif (node.op == "<>") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rvalNErval", op, left, right))
  elseif (node.op == ">=") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rvalGErval", op, left, right))
  elseif (node.op == "<=") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rvalLErval", op, left, right))
  elseif (node.op == "+") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rval+rval", op, left, right))
  elseif (node.op == "-") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rval-rval", op, left, right))
  elseif (node.op == "*") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rval*rval", op, left, right))
  elseif (node.op == "/") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rval/rval", op, left, right))
  elseif (node.op == ">") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rval>rval", op, left, right))
  elseif (node.op == "<") then
    local left  = Class.GenExpression(node[1])
    local right = Class.GenExpression(node[2])
    op = Class.GetVariable()
    Class.AddInstruction(Class.NewInstruction(nil, "ID=rval<rval", op, left, right))
  end
  assert(op)
  return op
end

function Class.GenExpressionUnary (node)
  assert(node.id == tree_nodes["UNARY"])
  local op = Class.GetVariable()
  Class.AddInstruction(Class.NewInstruction(nil, "ID=-rval", op, Class.GenExpression(node.exp)))
  return op
end

function Class.GenExpressionVar (node)
  assert(node.id == tree_nodes["VAR"])
  if (#node.array > 0) then
    local op
    for i = 1, #node.array do
      local op_array = Class.GenExpression(node.array[i])
      local last_op = op
      op = Class.GetVariable()
      if (i == #node.array) then
        if (node.sem_type == "bool" or node.sem_type == "char") then
          Class.AddInstruction(Class.NewInstruction(nil, "ID=BYTEID[rval]", op, last_op or node.name, op_array))
        else
          Class.AddInstruction(Class.NewInstruction(nil, "ID=ID[rval]", op, last_op or node.name, op_array))
        end
      else
        Class.AddInstruction(Class.NewInstruction(nil, "ID=ID[rval]", op, last_op or node.name, op_array))
      end
    end
    return op
  else
    return node.name
  end
end

--GenFunction: 
--  Parameters:
--    [1] $table  - FUNCTION node
--  Return:
function Class.GenFunction (node)
  if (_DEBUG) then print("ICG :: GenFunction") end
  assert(node.id == tree_nodes["FUNCTION"])
  function_counter = function_counter + 1
  local header = string.format("%8s fun %s (", "", node.name)
  if (node.params and node.params[1]) then
    header = header .. node.params[1].name
  end
  if (node.params and #node.params > 1) then
    for i = 2, #node.params do
      header = header .. "," .. node.params[i].name
    end
  end
  header = header .. ")\n"
  struct.functions[function_counter] = {
    header = header,
    name   = node.name,
  }
  Class.GenBlock(node.block)
  Class.AddInstruction(Class.NewInstruction(nil, "RET_NIL"))
end

--GenGlobal: 
--  Parameters:
--    [1] $table  - DECLARE node
--  Return:
function Class.GenGlobal (node)
  if (_DEBUG) then print("ICG :: GenGlobal") end
  assert(node.id == tree_nodes["DECLARE"])
  table.insert(struct.globals, node.name)
end

--GenIf: Add instructions of node to it's function structure
--  Parameters:
--    [1] $table  - IF node
--  Return:
function Class.GenIf(node)
  if (_DEBUG) then print("ICG :: GenIf") end
  assert(node.id == tree_nodes["IF"])
  local lbl_end       = Class.GetLabel()
  local var_condition = Class.GetVariable()
  local op = Class.GenExpression(node.cond)
  Class.AddInstruction(Class.NewInstruction(nil, "ID=BYTErval", var_condition, op))
  if (node["elseif"] or node["else"]) then
    local lbl_next = Class.GetLabel()
    Class.AddInstruction(Class.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_next))
    Class.GenBlock(node.block)
    Class.AddInstruction(Class.NewInstruction(nil, "GOTO", lbl_end))
    if (node["elseif"]) then
      for i = 1, #node["elseif"] do
        Class.AddInstruction(Class.NewInstruction(lbl_next, "LABEL"))
        var_condition = Class.GetVariable()
        op = Class.GenExpression(node["elseif"][i].cond)
        Class.AddInstruction(Class.NewInstruction(nil, "ID=BYTErval", var_condition, op))
        if ((#node["elseif"] - i) > 0) then
          lbl_next = Class.GetLabel()
          Class.AddInstruction(Class.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_next))
          Class.GenBlock(node["elseif"][i].block)
          Class.AddInstruction(Class.NewInstruction(nil, "GOTO", lbl_end))
        else
          if (node["else"]) then
            lbl_next = Class.GetLabel()
            Class.AddInstruction(Class.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_next))
            Class.GenBlock(node["elseif"][i].block)
            Class.AddInstruction(Class.NewInstruction(nil, "GOTO", lbl_end))
          else
            Class.AddInstruction(Class.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_end))
            Class.GenBlock(node["elseif"][i].block)
          end
        end
      end
    end
    if (node["else"]) then
      Class.AddInstruction(Class.NewInstruction(lbl_next, "LABEL"))
      Class.GenBlock(node["else"])
    end
  else
    Class.AddInstruction(Class.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_end))
    Class.GenBlock(node.block)
  end
  Class.AddInstruction(Class.NewInstruction(lbl_end, "LABEL"))
end

--GenReturn: Add instructions of node to it's function structure
--  Parameters:
--    [1] $table  - RETURN node
--  Return:
function Class.GenReturn (node)
  if (_DEBUG) then print("ICG :: GenReturn") end
  assert(node.id == tree_nodes["RETURN"])
  local op
  if (node.exp) then
    op = Class.GenExpression(node.exp)
  end
  local t
  if (op) then
    t = Class.NewInstruction(nil, "RET_OP", op)
  else
    t = Class.NewInstruction(nil, "RET_NIL", op)
  end
  Class.AddInstruction(t)
end

--GenWhile: Add instructions of node to it's function structure
--  Parameters:
--    [1] $table  - WHILE node
--  Return:
function Class.GenWhile (node)
  if (_DEBUG) then print("ICG :: GenWhile") end
  assert(node.id == tree_nodes["WHILE"])
  local lbl_before    = Class.GetLabel()
  local lbl_after     = Class.GetLabel()
  local var_condition = Class.GetVariable()
  Class.AddInstruction(Class.NewInstruction(lbl_before, "LABEL"))
  local op = Class.GenExpression(node.cond)
  Class.AddInstruction(Class.NewInstruction(nil, "ID=BYTErval", var_condition, op))
  Class.AddInstruction(Class.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_after))
  Class.GenBlock(node.block)
  Class.AddInstruction(Class.NewInstruction(nil, "GOTO", lbl_before))
  Class.AddInstruction(Class.NewInstruction(lbl_after, "LABEL"))
end

--GetLabel: Get a new string to use as a label
--  Parameters:
--  Return:
--    [1] $string   - New unique label
function Class.GetLabel ()
  if (_DEBUG) then print("ICG :: GetLabel") end
  label_counter = label_counter + 1
  return ".L" .. label_counter
end

--GetVariable: Get a new string to use as a variable
--  Parameters:
--  Return:
--    [1] $string   - New unique variable
function Class.GetVariable ()
  if (_DEBUG) then print("ICG :: GetVariable") end
  var_counter = var_counter + 1
  return "$t" .. var_counter
end

--NewInstruction: Create a new instruction node
--  Parameters:
--    [1] $string - 
--    [2] $string - 
--    [3] $string - 
--    [4] $string - 
--    [5] $string - 
--  Return:
--    [1] $table  - Table containing a instruction node, of one 'operations_code'
function Class.NewInstruction (label, code, operator1, operator2, operator3)
  if (_DEBUG) then print("ICG :: NewInstruction") end
  assert (operations_code[code])
  local t = {
    label = label,
    code  = operations_code[code],
    op1   = operator1,
    op2   = operator2,
    op3   = operator3,
  }
  return t
end


--==============================================================================
-- Public Methods
--==============================================================================

--GetCode:
--  Parameters:
--  Return:
--    [1] $table
function Class.GetCode ()
  if (_DEBUG) then print("ICG :: GetIntermediateCode") end
  return util.TableCopy(struct)
end

--Open: Write a 'path'.icg file with intermediate code. After writing it, calls
--      a binary created by Hisham Muhammed to validate the created file.
--  Parameters:
--    [1] $string   - Path of exit file. Extension will be converted to '.icg'
--    [2] $table    - Struct of program builded by semantic.
--  Return:
--    [1] $boolean  - false if found any problem, true otherwise
--    [2] $string   - only when [1] is false, informing which error occurs
function Class.Open (path, tree)
  if (_DEBUG) then print("ICG :: Open") end
  assert(path)
  assert(tree and type(tree) == "table")
  Class.Clear()
  local ok, msg = pcall(function ()
    for _, node in ipairs(tree) do
      if (node.id == tree_nodes["DECLARE"]) then
        Class.GenGlobal(node)
      elseif (node.id == tree_nodes["FUNCTION"]) then
        Class.GenFunction(node)
      else
        Class.Error("unknown program node.")
      end
    end
    if (printStruct) then
      util.TablePrint(struct)
    end
    local f = io.open(util.FileRemoveExtension(path) .. ".icg", "w")
    if (not f) then
      Class.Error(string.format("output file '%s' could not be opened"), path)
    end
    Class.Dump(f)
    f:close()
    if (test_cte) then
      os.execute("./cte/cte " .. util.FileRemoveExtension(path) .. ".icg")
    end    
  end)
  if (not ok) then
    return false, msg
  end
  return true
end


--==============================================================================
-- Return
--==============================================================================

return Class


--[[
program   : strings globals functions
          ;

strings   : string strings
          |;

globals   : global globals
          |;              
    
functions : function functions
          |;  

nl        : NL opt_nl ;

opt_nl    : NL opt_nl
          |;

string    : STRING ID '=' LITSTRING nl

global    : GLOBAL ID nl

function  : FUN ID '(' args ')' nl
          commands
          ;

args      : arg more_args
          |;

more_args : ',' args
          |;

arg       : ID
          ;

commands  : label command nl commands
          |;

label     : LABEL ':' opt_nl label
          |;

rval      : LITNUM
          | ID
          ;

command   : ID '=' rval
          | ID '=' BYTE rval
          | ID '=' rval binop rval
          | ID '=' unop rval
          | ID '=' ID '[' rval ']'
          | ID '=' BYTE ID '[' rval ']'
          | ID '[' rval ']' '=' rval
          | ID '[' rval ']' '=' BYTE rval
          | IF ID GOTO LABEL
          | IFFALSE ID GOTO LABEL
          | GOTO LABEL
          | call
          | RET rval
          | RET
          ;

binop     : EQ
          | NE
          | '<'
          | '>'
          | GE
          | LE
          | '+'
          | '-'
          | '*'
          | '/'
          ;

unop      : '-'
          | NEW
          | NEW BYTE
          ;

call      : params
          CALL ID
          ;

params    : param nl params
          |;

param     : PARAM rval
          ;
--]]