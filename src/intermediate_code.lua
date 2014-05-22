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

local IntermediateCodeGen = {}

--  store file path
local file

--  count number of generated labels
local label_counter = 0

--  count number of generated variables
local var_counter = 0

--  list of nodes code
--  {
--    [name] = $number,
--  }
local nodes_codes = NodesClass.GetNodesList()

-- avaiable operator codes of intermediate language
local opcode = {
  ["RETURN"]  = "RET",
  ["ID=rval"] = "="
}

--  three address codes
--  {
--    strings   = {}
--    globals   = {
--      [1 to N] = "name"
--    }
--    functions = {}
--  }
local struct = {}


--==============================================================================
-- Private Methods
--==============================================================================

--Clear: Set Initial Condition
--  Parameters:
--  Return:
function IntermediateCodeGen.Clear ()
  struct = {
    strings   = {},
    globals   = {},
    functions = {},
  }
  var_counter = 0
  label_counter = 0
end

--Dump: Write struct to file
--  Parameters:
--    [1] $string   - complete file path
--  Return:
function IntermediateCodeGen.Dump (path)
  if (_DEBUG) then print("ICG :: Dump") end
  local f = io.open(path, "w")
  if (not f) then
    Error(string.format("output file '%s' could not be opened"), path)
  end
  for _, string in ipairs(struct.strings) do
    -- WRITE STRINGS
  end
  for _, name in ipairs(struct.globals) do
    f:write(string.format("%8s DECLARE %s\n", "", name))
  end
  for _, line in ipairs(struct.functions) do
    f:write(line)
  end
  f:close()
end

--Error:
--  Parameters:
--  Return:
function IntermediateCodeGen.Error (msg)
  local str = string.format("intermediate code generator error: %s", msg or "")
  error(str, 0)
end

--GenAttribution:
--  Parameters:
--  Return:
function IntermediateCodeGen.GenAttribution (node)
  if (_DEBUG) then print("ICG :: GenAttribution") end
  assert(node.id == nodes_codes["ATTRIBUTION"])
  local label = IntermediateCodeGen.GetLabel()
  -- COMPLETE write expression
  -- WHICH OP CODE?
  --local str = IntermediateCodeGen.NewInstruction(nil, )
  --table.insert(struct.functions, str)
end

--GenBlock:
--  Parameters:
--  Return:
function IntermediateCodeGen.GenBlock (block)
  if (_DEBUG) then print("ICG :: GenBlock") end
  for _, node in ipairs(block) do
    if (node.id == nodes_codes["ATTRIBUTION"]) then
      IntermediateCodeGen.GenAttribution(node)
    elseif (node.id == nodes_codes["CALL"]) then
      -- COMPLETE
    elseif (node.id == nodes_codes["DECLARE"]) then
      -- COMPLETE
    elseif (node.id == nodes_codes["IF"]) then
      -- COMPLETE
    elseif (node.id == nodes_codes["RETURN"]) then
      IntermediateCodeGen.GenReturn(node)
    elseif (node.id == nodes_codes["WHILE"]) then
      -- COMPLETE
    end
  end
end

--GenExpression:
--  Parameters:
--  Return:
function IntermediateCodeGen.GenExpression (var, node)
  local str = "expression here return at " .. var .. "\n"
  print(node.id)
  if (node.id == nodes_codes["CALL"]) then
    
  elseif (node.id == nodes_codes["NEGATE"]) then
    
  elseif (node.id == nodes_codes["NEWVAR"]) then
    
  elseif (node.id == nodes_codes["OPERATOR"]) then
    
  elseif (node.id == nodes_codes["UNARY"]) then
    
  elseif (node.id == nodes_codes["VALUE"]) then
    local str = IntermediateCodeGen.NewInstruction(nil, "ID=rval", var, node.value)
    table.insert(struct.functions, str)
  elseif (node.id == nodes_codes["VAR"]) then
    
  end
  
end

--GenFunction:
--  Parameters:
--  Return:
function IntermediateCodeGen.GenFunction (node)
  if (_DEBUG) then print("ICG :: GenFunction") end
  assert(node.id == nodes_codes["FUNCTION"])
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
  table.insert(struct.functions, header)
  IntermediateCodeGen.GenBlock(node.block)
end

--GenGlobal:
--  Parameters:
--  Return:
function IntermediateCodeGen.GenGlobal (node)
  if (_DEBUG) then print("ICG :: GenGlobal") end
  assert(node.id == nodes_codes["DECLARE"])
  table.insert(struct.globals, node.name)
end

--GenLiteralString:
--  Parameters:
--  Return:
function IntermediateCodeGen.GenLiteralString (node)
  if (_DEBUG) then print("ICG :: GenLiteralString") end
  -- COMPLETE
end

--GenReturn:
--  Parameters:
--  Return:
function IntermediateCodeGen.GenReturn (node)
  if (_DEBUG) then print("ICG :: GenReturn") end
  assert(node.id == nodes_codes["RETURN"])
  local str, var
  if (node.exp) then
    var = IntermediateCodeGen.GetVariable()
    IntermediateCodeGen.GenExpression(var, node.exp)
  end
  str = IntermediateCodeGen.NewInstruction(nil, "RETURN", var)
  table.insert(struct.functions, str)
end

--GetLabel: Get a new string to use as a label
--  Parameters:
--  Return:
--    [1] $string   - New unique label
function IntermediateCodeGen.GetLabel ()
  if (_DEBUG) then print("ICG :: GetLabel") end
  label_counter = label_counter + 1
  return "$L" .. label_counter
end

--GetVariable: Get a new string to use as a variable
--  Parameters:
--  Return:
--    [1] $string   - New unique label
function IntermediateCodeGen.GetVariable ()
  if (_DEBUG) then print("ICG :: GetVariable") end
  var_counter = var_counter + 1
  return "$t" .. var_counter
end

--NewInstruction:
--  Parameters:
--  Return:
function IntermediateCodeGen.NewInstruction (label, code, op1, op2, op3)
  if (_DEBUG) then print("ICG :: NewInstruction") end
  assert (opcode) -- opcode[opcode]
  local str
  if (code == "RETURN") then
    str = string.format("%14s   %s %s\n", label and ("LABEL: " .. label) or "", opcode[code], op1 or "")
  elseif (code == "ID=rval") then
    str = string.format("%14s   %s %s %s\n", label and ("LABEL: " .. label) or "", op1, opcode[code], op2)
  end
  return str
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
function IntermediateCodeGen.Open (path, tree)
  if (_DEBUG) then print("ICG :: Open") end
  assert(path)
  assert(tree and type(tree) == "table")
  IntermediateCodeGen.Clear()
  local ok, msg = pcall(function ()
    for _, node in ipairs(tree) do
      if (node.id == nodes_codes["DECLARE"]) then
        IntermediateCodeGen.GenGlobal(node)
      elseif (node.id == nodes_codes["FUNCTION"]) then
        IntermediateCodeGen.GenFunction(node)
      else
        IntermediateCodeGen.Error("unknown program node.")
      end
    end
    IntermediateCodeGen.Dump(util.FileRemoveExtension(path) .. ".icg")
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

return IntermediateCodeGen


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