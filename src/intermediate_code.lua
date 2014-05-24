--==============================================================================
-- Debug
--==============================================================================

local printStruct = false
local _DEBUG = true


--==============================================================================
-- Dependency
--==============================================================================

local NodesClass = require "lib/node_codes"


--==============================================================================
-- Data Structure
--==============================================================================

local InterCodeGen = {}

--  store file path
local file

--  count number of generated labels
local label_counter = 0

--  count number of generated variables
local var_counter = 0

local function_counter = 0

--  list of nodes code
--  {
--    [name] = $number,
--  }
local nodes_codes = NodesClass.GetNodesList()

-- avaiable operator codes of intermediate language
local enum_opcodes = {
  ["LABEL"]         = 01,
  ["RETURN"]        = 02,
  ["ID=rval"]       = 03,
  ["ID=BYTErval"]   = 04,
  ["ID=unoprval"]   = 05,
  ["ID=rvalEQrval"] = 06,
  ["IFFALSEGOTO"]   = 07,
  ["GOTO"]          = 08,
}

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
--        [1 to N] = {    - list of instructions
--        }
--      }
--    }
--  }
local struct = {}


--==============================================================================
-- Private Methods
--==============================================================================

--AddInstruction:
--  Parameters:
--    [1] $table  - Table created by 'NewInstruction' function
--  Return:
function InterCodeGen.AddInstruction (inst)
  if (_DEBUG) then print("ICG :: AddInstruction") end
  assert (inst and type(inst) == "table")
  table.insert(struct.functions[function_counter], inst)
end

--Clear: Set Initial Condition
--  Parameters:
--  Return:
function InterCodeGen.Clear ()
  if (_DEBUG) then print("ICG :: Clear") end
  struct = {
    strings   = {},
    globals   = {},
    functions = {},
  }
  var_counter = 0
  label_counter = 0
  function_counter = 0
end

--Dump: Write struct to file
--  Parameters:
--    [1] $string   - complete file path
--  Return:
function InterCodeGen.Dump (output)
  util.TablePrint(struct)
  if (_DEBUG) then print("ICG :: Dump") end
  for _, str_node in ipairs(struct.strings) do
    output:write(string.format('%8s STRING  %s = "%s"\n', "", str_node.var, str_node.str))
  end
  for _, name in ipairs(struct.globals) do
    output:write(string.format('%8s GLOBAL %s\n', "", name))
  end
  for _, func in ipairs(struct.functions) do
    output:write(func.header)
    for _, inst in ipairs(func) do
      InterCodeGen.DumpInstruction(output, inst)
    end
  end
end

--DumpInstruction:
--  Parameters:
--    [1] $       - Desired output
--    [2] $table  - Table created by 'AddInstruction' function
--  Return:
function InterCodeGen.DumpInstruction (output, inst)
  if ((inst.code == enum_opcodes["LABEL"])) then
    output:write(string.format('%14s\n', inst.label and ("LABEL: " .. inst.label) or ""))
  elseif (inst.code == enum_opcodes["RETURN"]) then
    output:write(string.format('%14s   RET %s\n', inst.label and ("LABEL: " .. inst.label) or "", inst.op1 or ""))
  elseif (inst.code == enum_opcodes["ID=rval"]) then
    output:write(string.format('%14s   %s = %s\n', inst.label and ("LABEL: " .. inst.label) or "", inst.op1, inst.op2))
  elseif (inst.code == enum_opcodes["ID=BYTErval"]) then
    output:write(string.format('%14s   %s = BYTE %s\n', inst.label and ("LABEL: " .. inst.label) or "", inst.op1, inst.op2))
  elseif (inst.code == enum_opcodes["ID=unoprval"]) then
    output:write(string.format('%14s   %s = %s %s\n', inst.label and ("LABEL: " .. inst.label) or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == enum_opcodes["ID=rvalEQrval"]) then
    output:write(string.format('%14s   %s = %s == %s\n', inst.label and ("LABEL: " .. inst.label) or "", inst.op1, inst.op2, inst.op3))
  elseif (inst.code == enum_opcodes["IFFALSEGOTO"]) then
    output:write(string.format('%14s   IFFALSE %s GOTO %s\n', inst.label and ("LABEL: " .. inst.label) or "", inst.op1, inst.op2))
  elseif (inst.code == enum_opcodes["GOTO"]) then
    output:write(string.format('%14s   GOTO %s\n', inst.label and ("LABEL: " .. inst.label) or "", inst.op1))
  end
end

--Error:
--  Parameters:
--    [1] $string - 
--  Return:
function InterCodeGen.Error (msg)
  local str = string.format("intermediate code generator error: %s", msg or "")
  error(str, 0)
end

--GenAttribution:
--  Parameters:
--    [1] $table  - 
--  Return:
function InterCodeGen.GenAttribution (node)
  if (_DEBUG) then print("ICG :: GenAttribution") end
  assert(node.id == nodes_codes["ATTRIBUTION"])
  if ((node.var.sem_type == "char" or node.var.sem_type == "bool") and (node.var.sem_dimension == 0)) then
    InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "ID=BYTErval", node.var.name, InterCodeGen.GenExpression(node.exp)))
  else
    InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "ID=rval", node.var.name, InterCodeGen.GenExpression(node.exp)))
  end
end

--GenBlock:
--  Parameters:
--    [1] $table  - 
--  Return:
function InterCodeGen.GenBlock (block)
  if (_DEBUG) then print("ICG :: GenBlock") end
  for _, node in ipairs(block) do
    if (node.id == nodes_codes["ATTRIBUTION"]) then
      InterCodeGen.GenAttribution(node)
    elseif (node.id == nodes_codes["CALL"]) then
      InterCodeGen.GenCall(node)
    elseif (node.id == nodes_codes["DECLARE"]) then
      InterCodeGen.GenDeclare(node)
    elseif (node.id == nodes_codes["IF"]) then
      InterCodeGen.GenIf(node)
    elseif (node.id == nodes_codes["RETURN"]) then
      InterCodeGen.GenReturn(node)
    elseif (node.id == nodes_codes["WHILE"]) then
      InterCodeGen.GenWhile(node)
    end
  end
end

--GenCall: 
--  Parameters:
--    [1] $table  - 
--  Return:
function InterCodeGen.GenCall (node)
  if (_DEBUG) then print("ICG :: GenCall") end
  assert(node.id == nodes_codes["CALL"])
  -- COMPLETE
end

--GenDeclare: Create a new instruction and add it to current function
--  Parameters:
--    [1] $table  - 
--  Return:
function InterCodeGen.GenDeclare (node)
  if (_DEBUG) then print("ICG :: GenDeclare") end
  assert(node.id == nodes_codes["DECLARE"])
  local op
  if ((node.type == "bool" or node.type == "char") and node.dimension == 0) then
    op = "ID=BYTErval"
  else
    op = "ID=rval"
  end
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, op, node.name, "0"))
end

--GenExpression:
--  Parameters:
--    [1] $table  - 
--  Return:
--    [1] $string - Variable or value of expression return
function InterCodeGen.GenExpression (node)
  if (node.id == nodes_codes["CALL"]) then
    return InterCodeGen.GenExpressionCall(node)
  elseif (node.id == nodes_codes["LITERAL"]) then
    return InterCodeGen.GenExpressionLiteral(node)
  elseif (node.id == nodes_codes["NEGATE"]) then
    return InterCodeGen.GenExpressionNegate(node)
  elseif (node.id == nodes_codes["NEWVAR"]) then
    return InterCodeGen.GenExpressionNewVar(node)
  elseif (node.id == nodes_codes["OPERATOR"]) then
    return InterCodeGen.GenExpressionOperator(node)
  elseif (node.id == nodes_codes["UNARY"]) then
    return InterCodeGen.GenExpressionUnary(node)
  elseif (node.id == nodes_codes["VAR"]) then
    return InterCodeGen.GenExpressionVar(node)
  end
end

function InterCodeGen.GenExpressionCall (node)
  -- COMPLETE
end

function InterCodeGen.GenExpressionLiteral (node)
  local op
  if (node.type == "char") then
    op = InterCodeGen.GetVariable()
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

function InterCodeGen.GenExpressionNegate (node)
  local op = InterCodeGen.GetVariable()
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "ID=rvalEQrval", op, InterCodeGen.GenExpression(node.exp), "0"))
  return op
end

function InterCodeGen.GenExpressionNewVar (node)
  -- COMPLETE
end

function InterCodeGen.GenExpressionOperator (node)
  --[and or + - * / > < >= <= = <>]
  -- COMPLETE
end

function InterCodeGen.GenExpressionUnary (node)
  local op = InterCodeGen.GetVariable()
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "ID=unoprval", op, "-", InterCodeGen.GenExpression(node.exp)))
  return op
end

function InterCodeGen.GenExpressionVar (node)
  -- COMPLETE
  -- verify dimension
end

--GenFunction: 
--  Parameters:
--    [1] $table  - 
--  Return:
function InterCodeGen.GenFunction (node)
  if (_DEBUG) then print("ICG :: GenFunction") end
  assert(node.id == nodes_codes["FUNCTION"])
  function_counter = function_counter + 1
  local header = string.format("%8s FUN %s (", "", node.name)
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
  }
  InterCodeGen.GenBlock(node.block)
end

--GenGlobal:
--  Parameters:
--    [1] $table  - 
--  Return:
function InterCodeGen.GenGlobal (node)
  if (_DEBUG) then print("ICG :: GenGlobal") end
  assert(node.id == nodes_codes["DECLARE"])
  table.insert(struct.globals, node.name)
end

--GenIf:
--  Parameters:
--    [1] $table  - 
--  Return:
function InterCodeGen.GenIf(node)
  if (_DEBUG) then print("ICG :: GenIf") end
  assert(node.id == nodes_codes["IF"])
  local lbl_end       = InterCodeGen.GetLabel()
  local var_condition = InterCodeGen.GetVariable()
  local op = InterCodeGen.GenExpression(node.cond)
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "ID=BYTErval", var_condition, op))
  if (node["elseif"] or node["else"]) then
    local lbl_next = InterCodeGen.GetLabel()
    InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_next))
    InterCodeGen.GenBlock(node.block)
    InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "GOTO", lbl_end))
    if (node["elseif"]) then
      for i = 1, #node["elseif"] do
        InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(lbl_next, "LABEL"))
        var_condition = InterCodeGen.GetVariable()
        op = InterCodeGen.GenExpression(node["elseif"][i].cond)
        InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "ID=BYTErval", var_condition, op))
        if ((#node["elseif"] - i) > 0) then
          lbl_next = InterCodeGen.GetLabel()
          InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_next))
          InterCodeGen.GenBlock(node["elseif"][i].block)
          InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "GOTO", lbl_end))
        else
          if (node["else"]) then
            lbl_next = InterCodeGen.GetLabel()
            InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_next))
            InterCodeGen.GenBlock(node["elseif"][i].block)
            InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "GOTO", lbl_end))
          else
            InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_end))
            InterCodeGen.GenBlock(node["elseif"][i].block)
          end
        end
      end
    end
    if (node["else"]) then
      InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(lbl_next, "LABEL"))
      InterCodeGen.GenBlock(node["else"])
    end
  else
    InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_end))
    InterCodeGen.GenBlock(node.block)
  end
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(lbl_end, "LABEL"))
end

--GenReturn:
--  Parameters:
--    [1] $table  - 
--  Return:
function InterCodeGen.GenReturn (node)
  if (_DEBUG) then print("ICG :: GenReturn") end
  assert(node.id == nodes_codes["RETURN"])
  local op
  if (node.exp) then
    op = InterCodeGen.GenExpression(node.exp)
  end
  local t = InterCodeGen.NewInstruction(nil, "RETURN", op)
  InterCodeGen.AddInstruction(t)
end

--GenWhile:
--  Parameters:
--    [1] $table  - 
--  Return:
function InterCodeGen.GenWhile (node)
  if (_DEBUG) then print("ICG :: GenWhile") end
  assert(node.id == nodes_codes["WHILE"])
  local lbl_before    = InterCodeGen.GetLabel()
  local lbl_after     = InterCodeGen.GetLabel()
  local var_condition = InterCodeGen.GetVariable()
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(lbl_before, "LABEL"))
  local op = InterCodeGen.GenExpression(node.cond)
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "ID=BYTErval", var_condition, op))
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "IFFALSEGOTO", var_condition, lbl_after))
  InterCodeGen.GenBlock(node.block)
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(nil, "GOTO", lbl_before))
  InterCodeGen.AddInstruction(InterCodeGen.NewInstruction(lbl_after, "LABEL"))
end

--GetLabel: Get a new string to use as a label
--  Parameters:
--  Return:
--    [1] $string   - New unique label
function InterCodeGen.GetLabel ()
  if (_DEBUG) then print("ICG :: GetLabel") end
  label_counter = label_counter + 1
  return ".L" .. label_counter
end

--GetVariable: Get a new string to use as a variable
--  Parameters:
--  Return:
--    [1] $string   - New unique variable
function InterCodeGen.GetVariable ()
  if (_DEBUG) then print("ICG :: GetVariable") end
  var_counter = var_counter + 1
  return "$t" .. var_counter
end

--NewInstruction:
--  Parameters:
--    [1] $string - 
--    [2] $string - 
--    [3] $string - 
--    [4] $string - 
--    [5] $string - 
--  Return:
function InterCodeGen.NewInstruction (label, code, operator1, operator2, operator3)
  if (_DEBUG) then print("ICG :: NewInstruction") end
  assert (enum_opcodes[code])
  local t = {
    label = label,
    code  = enum_opcodes[code],
    op1   = operator1,
    op2   = operator2,
    op3   = operator3,
  }
  return t
end


--==============================================================================
-- Public Methods
--==============================================================================

--Open:
--  parameters:
--    [1] $string   - 
--    [2] $table    - 
--  return:
--    [1] $boolean  - false if found any problem, true otherwise
--    [2] $string   - only when [1] is false, informing which error occurs
function InterCodeGen.Open (path, tree)
  if (_DEBUG) then print("ICG :: Open") end
  assert(path)
  assert(tree and type(tree) == "table")
  InterCodeGen.Clear()
  local ok, msg = pcall(function ()
    for _, node in ipairs(tree) do
      if (node.id == nodes_codes["DECLARE"]) then
        InterCodeGen.GenGlobal(node)
      elseif (node.id == nodes_codes["FUNCTION"]) then
        InterCodeGen.GenFunction(node)
      else
        InterCodeGen.Error("unknown program node.")
      end
    end
    local f = io.open(util.FileRemoveExtension(path) .. ".icg", "w")
    if (not f) then
      Error(string.format("output file '%s' could not be opened"), path)
    end
    InterCodeGen.Dump(f)
    f:close()
    if (printStruct) then
      util.TablePrint(struct)
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

return InterCodeGen


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
          | ID '[' rval ']' '=' rval
          | ID '=' BYTE ID '[' rval ']'
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