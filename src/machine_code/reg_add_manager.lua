--==============================================================================
-- Debug
--==============================================================================

local _DEBUG = false
local printStruct     = false
local printAppearance = false


--==============================================================================
-- Dependency
--==============================================================================

local OperationsCode  = require "operations_code"


--==============================================================================
-- Data Structure
--==============================================================================

local Class = {}

--  list of registers
--  {
--    [1 to N] = $string  - register name
--  }
local registers = {
  "%eax",
  "%ebx",
  "%ecx",
  "%edx",
  "%edi",
  "%esi",
}

--  table with registers and variables allocation
--  {
--    regs = {
--      [1 to N] = {          -- list of registers
--        [1 to N] = "name"   -- variables with values inside this registers
--      }
--    }
--    vars = {
--      "name" = {
--        [1 to N] = "name"   -- places where this variable is kept
--      }
--    }
--  }
local struct = {}

--  table with list of instruction number where they appear
--  {
--    [1 to N] = {          --  enum of instructions. 'N' will have one line more
--                              than number of instructions in basic block, where
--                              the last line has all variables 'alive'.
--      "name" = {
--        alive     = $boolean
--        next_inst = $number
--      }
--    }
--  }
local var_appear = {}


--==============================================================================
-- Private Methods
--==============================================================================

--Build: Initialize 'struct' and 'var_appear' with desired values. In 'struct',
--    'regs' are started empty and 'vars' with their own position only. In
--    'var_appear', all instructions number wher variable appear will be placed
--    inside list.
--  Parameters:
--    [1] $table  - table containing one basic block
--  Return:
function Class.Build (basic_block)
  if (_DEBUG) then print("RAM :: Build") end
  assert(type(basic_block) == "table")
  Class.BuildTableRegsVars(basic_block)
  Class.BuildTableVarsNextUse(basic_block)
end

function Class.BuildTableRegsVars (basic_block)
  if (_DEBUG) then print("RAM :: BuildTableRegsVars") end
  struct = {
    regs = {},
    vars = {},
  }
  for num, _ in ipairs(registers) do
    struct.regs[num] = {}
  end
  for num, block in ipairs(basic_block) do
    if (Class.OperatorIsVariable(block.op1)) then
      struct.vars[block.op1] = struct.vars[block.op1] or {block.op1}
    end
    if (Class.OperatorIsVariable(block.op2)) then
      struct.vars[block.op2] = struct.vars[block.op2] or {block.op2}
    end
    if (Class.OperatorIsVariable(block.op3)) then
      struct.vars[block.op3] = struct.vars[block.op3] or {block.op3}
    end
  end
end

function Class.BuildTableVarsNextUse (basic_block)
  if (_DEBUG) then print("RAM :: BuildTableVarsNextUse") end
  var_appear = {}
  var_appear[#basic_block + 1] = {}
  for var_name, _ in pairs(struct.vars) do
    var_appear[#basic_block + 1][var_name] = {
      alive     = true,
      next_inst = #basic_block + 1,
    }
  end
  for i = #basic_block, 1, -1 do
    var_appear[i] = util.TableCopy(var_appear[i + 1])
    local group = Class.GetOperationGroup(basic_block[i].code)
    if (group == "0in0out") then
      -- nothing to do
    elseif (group == "1in0out") then
      if (Class.OperatorIsVariable(basic_block[i].op1)) then
        var_appear[i][basic_block[i].op1].alive = true
        var_appear[i][basic_block[i].op1].next_inst = i
      end
    elseif (group == "1in1out") then
      if (Class.OperatorIsVariable(basic_block[i].op1)) then
        var_appear[i][basic_block[i].op1].alive = false
        var_appear[i][basic_block[i].op1].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op2)) then
        var_appear[i][basic_block[i].op2].alive = true
        var_appear[i][basic_block[i].op2].next_inst = i
      end
    elseif (group == "2in1out") then
      if (Class.OperatorIsVariable(basic_block[i].op1)) then
        var_appear[i][basic_block[i].op1].alive = false
        var_appear[i][basic_block[i].op1].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op2)) then
        var_appear[i][basic_block[i].op2].alive = true
        var_appear[i][basic_block[i].op2].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op3)) then
        var_appear[i][basic_block[i].op3].alive = true
        var_appear[i][basic_block[i].op3].next_inst = i
      end
    elseif (group == "3in0out") then
      if (Class.OperatorIsVariable(basic_block[i].op1)) then
        var_appear[i][basic_block[i].op1].alive = true
        var_appear[i][basic_block[i].op1].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op2)) then
        var_appear[i][basic_block[i].op2].alive = true
        var_appear[i][basic_block[i].op2].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op3)) then
        var_appear[i][basic_block[i].op3].alive = true
        var_appear[i][basic_block[i].op3].next_inst = i
      end
    end
  end
end

--Error: Stop class execution and generate error message
--  Parameters:
--    [1] $string - 
--  Return:
function Class.Error (msg)
  if (_DEBUG) then print("RAM :: Error") end
  local str = string.format("machine code generator error: %s", msg or "")
  error(str, 0)
end

--GetRegisterEmpty:
--  Parameters:
--    [1] $number         - Start counting from this number
--  Return:
--    [1] $number or $nil - Number of register who is empty
function Class.GetRegisterEmpty ()
  if (_DEBUG) then print("RAM :: GetRegisterEmpty") end
  for regnum, regtable in ipairs(struct.regs) do
    if (util.TableIsEmpty(regtable)) then
      return regnum
    end
  end
  return nil
end

--GetOperationGroup:
--  Parameters:
--    [1] $number - Operation code;
--  Return:
--    [1] $string - Group code [0in0out, 1in0out, 1in1out, 2in1out, 3in0out];
function Class.GetOperationGroup (code)
  if (_DEBUG) then print("RAM :: GetOperationGroup") end
  assert(code and type(code) == "number")
  local group = {
    ["CALLID"]            = "0in0out",
    ["GOTO"]              = "0in0out",
    ["LABEL"]             = "0in0out",
    ["RET_NIL"]           = "0in0out",
    ["IFFALSEGOTO"]       = "1in0out",
    ["IFGOTO"]            = "1in0out",
    ["PARAM"]             = "1in0out",
    ["RET_OP"]            = "1in0out",
    ["ID=rval"]           = "1in1out",
    ["ID=BYTErval"]       = "1in1out",
    ["ID=-rval"]          = "1in1out",
    ["ID=NEWrval"]        = "1in1out",
    ["ID=NEWBYTErval"]    = "1in1out",
    ["ID=ID[rval]"]       = "2in1out",
    ["ID=BYTEID[rval]"]   = "2in1out",
    ["ID=rvalEQrval"]     = "2in1out",
    ["ID=rvalNErval"]     = "2in1out",
    ["ID=rvalGErval"]     = "2in1out",
    ["ID=rvalLErval"]     = "2in1out",
    ["ID=rval<rval"]      = "2in1out",
    ["ID=rval>rval"]      = "2in1out",
    ["ID=rval+rval"]      = "2in1out",
    ["ID=rval-rval"]      = "2in1out",
    ["ID=rval*rval"]      = "2in1out",
    ["ID=rval/rval"]      = "2in1out",
    ["ID[rval]=rval"]     = "3in0out",
    ["ID[rval]=BYTErval"] = "3in0out",
  }
  local name = OperationsCode.GetName(code)
  return group[name]
end

--GetRegRead:
--  Parameters:
--    [1] $number         - Number of current instruction;
--    [2] $string         - Variable that should get a registrator;
--    [3] $string or $nil - Operator 1 already allocated by 'GetRegisters';
--    [4] $number or $nil - Number of register used by Operator 1;
--    [5] $string or $nil - Operator 2 already allocated by 'GetRegisters';
--    [6] $number or $nil - Number of register used by Operator 2;
--  Return:
--    [1] $table          - Table of operations to be done (spill registers)
--                          already in assembly format;
--    [2] $number         - Number of register to use;
function Class.GetRegRead (num, op, op1, reg1, op2, reg2)
  if (_DEBUG) then print("RAM :: GetReg") end
  assert(type(num) == "number")
  assert(op and type(op) == "string")
  assert(not op1 or type(op1) == "string")
  assert(not reg1 or type(reg1) == "number")
  assert(not op2 or type(op2) == "string")
  assert(not reg2 or type(reg2) == "number")
  local operations = {}
  if (not Class.OperatorIsVariable(op)) then
    return nil, nil
  end
  local reg
  if (Class.GetVariableInsideRegister(op)) then
    reg = Class.GetVariableInsideRegister(op)
  elseif (Class.GetRegisterEmpty()) then
    reg = Class.GetRegisterEmpty()
  else
    for regnum, regtable in ipairs(struct.regs) do
      --print("All regs full")
      local avaiable = true
      for _, var in ipairs(regtable) do
        if (not Class.GetVariableInsideMemory(var)) then
          avaiable = false
          break
        end
      end
      if (avaiable) then
        reg = regnum
        break
      end
        print("Fail to find regs with variables in memory")
    end
  end
  Class.SetVariableInsideRegister(reg, op)
  return (util.TableIsEmpty(operations) and nil) or operations, reg
end

--GetRegWrite:
--  Parameters:
--    [1] $number         - Number of current instruction
--    [2] $string         - Variable that should get a registrator
--    [3] $string or $nil - Operator 1 already allocated by 'GetRegisters'
--    [4] $number or $nil - Number of register used by Operator 1
--    [5] $string or $nil - Operator 2 already allocated by 'GetRegisters'
--    [6] $number or $nil - Number of register used by Operator 2
--  Return:
--    [1] $table          - table of operations to be done (spill registers)
--    [2] $number         - Number of register to use
function Class.GetRegWrite (num, op, op1, reg1, op2, reg2)
  if (_DEBUG) then print("RAM :: GetReg") end
  assert(type(num) == "number")
  assert(op and type(op) == "string")
  assert(not op1 or type(op1) == "string")
  assert(not reg1 or type(reg1) == "number")
  assert(not op2 or type(op2) == "string")
  assert(not reg2 or type(reg2) == "number")
  if (not Class.OperatorIsVariable(op)) then
    return nil, nil
  end
  for regnum, regtable in ipairs(struct.regs) do
    if (#regtable == 1 and regtable[1] == op) then
      return nil, regnum
    end
  end
  if (reg1 and not Class.GetVariableNextUse(num, op1)) then
    if (#struct.regs[reg1] == 1) then
      local reg = reg1
      Class.SetVariableInsideRegister(reg, op)
      return nil, reg
    end
  elseif (reg2 and not Class.GetVariableNextUse(num, op2)) then
    if (#struct.regs[reg2] == 1) then
      local reg = reg2
      Class.SetVariableInsideRegister(reg, op)
      return nil, reg
    end
  else
    return Class.GetRegRead(num, op, op1, reg1, op2, reg2)
  end
end

--GetVariableInsideMemory:
--  Parameters:
--    [1] $string   - Variable name
--  Return:
--    [1] $boolean  - TRUE if variable is saved in memory, FALSE otherwise
function Class.GetVariableInsideMemory (var)
  if (_DEBUG) then print("RAM :: GetReg") end
  assert(var and type(var) == "string")
  for _, place in ipairs(struct.vars[var]) do
    if (place == var) then
      return true
    end
  end
  return false
end

--GetVariableInsideRegister:
--  Parameters:
--    [1] $string         - Variable name
--  Return:
--    [1] $number or $nil - Number of register who has variable inside
function Class.GetVariableInsideRegister (variable)
  if (_DEBUG) then print("RAM :: GetVariableInsideRegister") end
  for regnum, regtable in ipairs(struct.regs) do
    for _, var in ipairs(regtable) do
      if (variable == var) then
        return regnum
      end
    end
  end
  return nil
end

--GetVariableNextUse:
--  Parameters:
--    [1] $string - variable name
--    [2] $number - number of current instruction
--  Return:
--    [1] $boolean  - TRUE if variable is going to be used, FALSE if value
--                    can be erased
--    [2] $number   - Return the next use of variable
function Class.GetVariableNextUse (inst_num, var)
  if (_DEBUG) then print("RAM :: GetVariableNextUse") end
  assert(type(inst_num) == "number")
  assert(type(var) == "string")
  return var_appear[inst_num][var].alive, var_appear[inst_num][var].next_inst
end

--OperatorIsVariable: Verify if a operator defined in intermediate code is a variable.
--    If it is $nil, or $number (LIT_NUM), or starts with '.' will return FALSE
--  Parameters:
--    [1] $string   - Operator defined in intermediate code
--  Return:
--    [1] $boolean  - TRUE if operator is a variable, FALSE otherwise
function Class.OperatorIsVariable (op)
  if (_DEBUG) then print("RAM :: OperatorIsVariable") end
  if (op and not tonumber(op) and not string.find(op, "^%.")) then
    return true
  end
  return false
end

--SetVariableInsideRegister:
--  Parameters:
--  Return:
function Class.SetVariableInsideRegister (reg, var)
  if (_DEBUG) then print("RAM :: SetVariableInsideRegister") end
  assert(reg and type(reg) == "number")
  assert(var and type(var) == "string")
  for _, var_in_reg in ipairs(struct.regs[reg]) do
    if (var == var_in_reg) then
      return
    end
  end
  table.insert(struct.regs[reg], var)
end

--SetRegisterInsideVariable:
--  Parameters:
--  Return:
function Class.SetRegisterInsideVariable (reg, var)
  if (_DEBUG) then print("RAM :: SetRegisterInsideVariable") end
end

--==============================================================================
-- Public Methods
--==============================================================================

--GetRegisters: Receive a instruction node created by intermediate code
--    and return registers that should be used for operation
--  Parameters:
--    [1] $number - number of instruction inside a basic block
--    [1] $table  - table containing a instruction
--  Return:
--    [1] $table or $nil  - table of operations to be done (spill registers)
--    [2] $string         - register for first operator
--    [3] $string         - register for second operator
--    [4] $string         - register for third operator
function Class.GetRegisters (inst_num, inst)
  if (_DEBUG) then print("RAM :: GetRegisters") end
  assert(inst_num and type(inst_num) == "number")
  local operations = {}
  local reg1, reg2, reg3

  local group = Class.GetOperationGroup(inst.code)
  if (group == "0in0out") then
  elseif (group == "1in0out") then
    _, reg1 = Class.GetRegRead(inst_num, inst.op1)
  elseif (group == "1in1out") then
    _, reg2 = Class.GetRegRead(inst_num, inst.op2)
    _, reg1 = Class.GetRegWrite(inst_num, inst.op1, inst.op2, reg2)
  elseif (group == "2in1out") then
    _, reg2 = Class.GetRegRead(inst_num, inst.op2)
    _, reg3 = Class.GetRegRead(inst_num, inst.op3, inst.op2, reg2)
    _, reg1 = Class.GetRegWrite(inst_num, inst.op1, inst.op2, reg2, inst.op3, reg3)
  elseif (group == "3in0out") then
    _, reg1 = Class.GetRegRead(inst_num, inst.op1)
    _, reg2 = Class.GetRegRead(inst_num, inst.op2)
    _, reg3 = Class.GetRegRead(inst_num, inst.op3)
  end
  reg1 = (registers[reg1]) or (tonumber(inst.op1) and "$" .. inst.op1) or inst.op1
  reg2 = (registers[reg2]) or (tonumber(inst.op2) and "$" .. inst.op2) or inst.op2
  reg3 = (registers[reg3]) or (tonumber(inst.op3) and "$" .. inst.op3) or inst.op3
  return (util.TableIsEmpty(operations) and nil) or operations, reg1, reg2, reg3
end

--New: 
--  Parameters:
--    [1] $table    - list of basic blocks containing intermediate code instructions
--  Return:
--    [1] $boolean  - false if found any problem, true otherwise
--    [2] $string   - only when [1] is false, informing which error occurs
function Class.New (basic_block)
  if (_DEBUG) then print("RAM :: New") end
  assert(type(basic_block) == "table")
  Class.Build(basic_block)
  if (printStruct) then
    print("RAM :: struct")
    util.TablePrint(struct)
  end
  if (printAppearance) then
    print("RAM :: appearance")
    util.TablePrint(var_appear)
  end
end


--==============================================================================
-- Return
--==============================================================================

return Class
