--==============================================================================
-- Debug
--==============================================================================

local printStruct = false


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

--  list of nodes code
--  {
--    [name] = $number,
--  }
local nodes_codes = NodesClass.GetNodesList()

-- avaiable operator codes of intermediate language
local opcode = {
  NOP       = 01, -- NO OPERATOR (EMPTY)
  
  DECLARE   = 03,


  --LITSTRING = 02,
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
    f:write(string.format("%8s DECLARE %s", "", name))
  end
  for _, var in ipairs(struct.functions) do
    -- WRITE FUNCTIONS
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

--GenFunction:
--  Parameters:
--  Return:
function IntermediateCodeGen.GenFunction (node)
  if (_DEBUG) then print("ICG :: GenFunction") end
  assert(node.id == nodes_codes["FUNCTION"])
  -- COMPLETE
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

--GetLabel: Get a new string to use as a label
--  Parameters:
--  Return:
--    [1] $string   - New unique label
function IntermediateCodeGen.GetLabel ()
  if (_DEBUG) then print("ICG :: GetLabel") end
  label_counter = label_counter + 1
  return "$L" .. label_counter
end

--NewInstruction:
--  Parameters:
--  Return:
function IntermediateCodeGen.NewInstruction (label, opcode, op1, op2, op3)
  if (_DEBUG) then print("ICG :: NewInstruction") end
  assert (opcode) -- opcode[opcode]
  local t = {
    label   = label or "",
    opcode  = opcode,
    op1     = op1,
    op2     = op2,
    op3     = op3,
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