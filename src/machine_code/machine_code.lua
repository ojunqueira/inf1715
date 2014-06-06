--==============================================================================
-- Debug
--==============================================================================

local _DEBUG = false
local printStruct     = false
local printAppearance = false
local printBasicBlocks = false


--==============================================================================
-- Dependency
--==============================================================================

local OperationsCode  = require "operations_code"


--==============================================================================
-- Data Structure
--==============================================================================

local Class = {}

local indent = "    "

--  list of operations code
--  {
--    [name] = $number,
--  }
local operations_code = OperationsCode.GetList()

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
local regs_vars = {}

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
local vars_appear = {}


--==============================================================================
-- Private Methods
--==============================================================================

--BuildTableRegistersVariables: Initialize 'regs_vars' with desired values. In
--    'regs_vars', 'regs' are started empty and 'vars' with their own position
--    only.
--  Parameters:
--    [1] $table  - table containing one basic block
--  Return:
function Class.BuildTableRegistersVariables (basic_block)
  if (_DEBUG) then print("RAM :: BuildTableRegistersVariables") end
  regs_vars = {
    regs = {},
    vars = {},
  }
  for num, _ in ipairs(registers) do
    regs_vars.regs[num] = {}
  end
  for num, block in ipairs(basic_block) do
    if (Class.OperatorIsVariable(block.op1)) then
      regs_vars.vars[block.op1] = regs_vars.vars[block.op1] or {block.op1}
    end
    if (Class.OperatorIsVariable(block.op2)) then
      regs_vars.vars[block.op2] = regs_vars.vars[block.op2] or {block.op2}
    end
    if (Class.OperatorIsVariable(block.op3)) then
      regs_vars.vars[block.op3] = regs_vars.vars[block.op3] or {block.op3}
    end
  end
end

--BuildTableVariablesNextUse: Initialize 'vars_appear' with desired values. In
--    'vars_appear', all instructions number wher variable appear will be placed
--    inside list.
--  Parameters:
--    [1] $table  - table containing one basic block
--  Return:
function Class.BuildTableVariablesNextUse (basic_block)
  if (_DEBUG) then print("RAM :: BuildTableVariablesNextUse") end
  vars_appear = {}
  vars_appear[#basic_block + 1] = {}
  for var_name, _ in pairs(regs_vars.vars) do
    vars_appear[#basic_block + 1][var_name] = {
      alive     = true,
      next_inst = #basic_block + 1,
    }
  end
  for i = #basic_block, 1, -1 do
    vars_appear[i] = util.TableCopy(vars_appear[i + 1])
    local group = Class.GetOperationGroup(basic_block[i].code)
    if (group == "0in0out") then
      -- nothing to do
    elseif (group == "1in0out") then
      if (Class.OperatorIsVariable(basic_block[i].op1)) then
        vars_appear[i][basic_block[i].op1].alive = true
        vars_appear[i][basic_block[i].op1].next_inst = i
      end
    elseif (group == "1in1out") then
      if (Class.OperatorIsVariable(basic_block[i].op1)) then
        vars_appear[i][basic_block[i].op1].alive = false
        vars_appear[i][basic_block[i].op1].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op2)) then
        vars_appear[i][basic_block[i].op2].alive = true
        vars_appear[i][basic_block[i].op2].next_inst = i
      end
    elseif (group == "2in1out") then
      if (Class.OperatorIsVariable(basic_block[i].op1)) then
        vars_appear[i][basic_block[i].op1].alive = false
        vars_appear[i][basic_block[i].op1].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op2)) then
        vars_appear[i][basic_block[i].op2].alive = true
        vars_appear[i][basic_block[i].op2].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op3)) then
        vars_appear[i][basic_block[i].op3].alive = true
        vars_appear[i][basic_block[i].op3].next_inst = i
      end
    elseif (group == "3in0out") then
      if (Class.OperatorIsVariable(basic_block[i].op1)) then
        vars_appear[i][basic_block[i].op1].alive = true
        vars_appear[i][basic_block[i].op1].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op2)) then
        vars_appear[i][basic_block[i].op2].alive = true
        vars_appear[i][basic_block[i].op2].next_inst = i
      end
      if (Class.OperatorIsVariable(basic_block[i].op3)) then
        vars_appear[i][basic_block[i].op3].alive = true
        vars_appear[i][basic_block[i].op3].next_inst = i
      end
    end
  end
end

--DumpFunction:
--  Parameters:
--    [1] $       - Desired output
--    [2] 
--    [3] $table
--  Return:
function Class.DumpFunction (output, name, instructions)
  if (_DEBUG) then print("MCG :: DumpFunction") end
  output:write(string.format("  %s:\n", name))
  for _, instruction in ipairs(instructions) do
    output:write(string.format("%s%s\n", indent, instruction))
  end
end

--DumpGlobal:
--  Parameters:
--    [1] $       - Desired output
--    [2] $string - Variable name
--  Return:
function Class.DumpGlobal (output, list_funcs, list_globals)
  if (_DEBUG) then print("MCG :: DumpGlobal") end
  assert(type(list_funcs) == "table")
  assert(type(list_globals) == "table")
  local t = {}
  if (not util.TableIsEmpty(list_funcs)) then
    for _, func in ipairs(list_funcs) do
      table.insert(t, func.name)
    end
  end
  if (not util.TableIsEmpty(list_globals)) then
    for _, glob in ipairs(list_globals) do
      table.insert(t, glob)
    end
  end
  local str = t[1]
  if (#t > 1) then
    for i = 2, #t do
      str = str .. ", " .. t[i]
    end
  end
  output:write(string.format('  .globl %s\n', str))
end

--DumpString:
--  Parameters:
--    [1] $       - Desired output
--    [2] $string - Variable name
--    [3] $string - Literal string
--  Return:
function Class.DumpString (output, var, str)
  if (_DEBUG) then print("MCG :: DumpString") end
  assert(var)
  assert(str)
  output:write(string.format('%s%s: .string "%s"\n', indent, var, str))
end

--Error: Stop class execution and generate error message
--  Parameters:
--    [1] $string - 
--  Return:
function Class.Error (msg)
  if (_DEBUG) then print("MCG :: Error") end
  local str = string.format("machine code generator error: %s", msg or "")
  error(str, 0)
end

--GenBasicBlock: Receives a list of instructions and split it into basic blocks
--  Parameters:
--    [1] $table  - list of function instructions generated by intermediate code
--  Return:
--    [1] $table = {
--          [1 to N] = {    - list of basic blocks
--        }
function Class.GenBasicBlock (func)
  if (_DEBUG) then print("MCG :: GenBasicBlock") end
  local t = {}
  local enum_block = 0
  local next_is_block = false
  for enum_inst, inst in ipairs(func) do
    if (next_is_block) then
      next_is_block = false
      enum_block = enum_block + 1
      t[enum_block] = {}
      table.insert(t[enum_block], inst)
    elseif (enum_inst == 1) then
      enum_block = enum_block + 1
      t[enum_block] = {}
      table.insert(t[enum_block], inst)
    elseif (inst.code == operations_code["LABEL"]) then
      enum_block = enum_block + 1
      t[enum_block] = {}
      table.insert(t[enum_block], inst)
    elseif (inst.code == operations_code["GOTO"] or inst.code == operations_code["IFFALSEGOTO"] or inst.code == operations_code["IFGOTO"]) then
      next_is_block = true
      table.insert(t[enum_block], inst)
    else
      table.insert(t[enum_block], inst)
    end
  end
  if (printBasicBlocks) then
    util.TablePrint(t)
  end
  return t
end

--GenMachineBlock:
--  Parameters:
--    [1] $table  - Table generated by 'GenBasicBlock' function
--  Return:
function Class.GenMachineBlock (basic_blocks)
  if (_DEBUG) then print("MCG :: GenMachineBlock") end
  assert(type(basic_blocks) == "table")
  local t = {}
  for _, block in ipairs(basic_blocks) do
    Class.BuildTableRegistersVariables(block)
    Class.BuildTableVariablesNextUse(block)
    for num, instruction in ipairs(block) do
      local op, reg1, reg2, reg3 = Class.GetRegs(num, instruction)
      if (op) then
        for _, inst in ipairs(op) do
          table.insert(t, inst)
        end
      end
      Class.GenMachineInstruction(t, instruction.code, reg1, reg2, reg3)
    end
  end
  return t
end

--GenMachineInstruction:
--  Parameters:
--  Return:
--    [1] $string   - Assembly instruction;
function Class.GenMachineInstruction (t, code, op1, op2, op3)
  if (_DEBUG) then print("MCG :: GenMachineInstruction") end
  if (code == operations_code["CALLID"]) then
    table.insert(t, string.format("  call   %s", op1))
  elseif (code == operations_code["GOTO"]) then
    table.insert(t, string.format("  jmp    %s", op1))
  elseif (code == operations_code["IFFALSEGOTO"]) then
    
  elseif (code == operations_code["IFGOTO"]) then
    table.insert(t, string.format("  jnz    %s", op1))
  elseif (code == operations_code["LABEL"]) then
    table.insert(t, string.format("%s", op1))
  elseif (code == operations_code["PARAM"]) then
    
  elseif (code == operations_code["RET_OP"]) then
    table.insert(t, string.format("  ret    %s", op1))
  elseif (code == operations_code["RET_NIL"]) then
    table.insert(t, string.format("  ret"))
  elseif (code == operations_code["ID=rval"]) then
    table.insert(t, string.format("  movl   %s, %s", op1, op2))
  elseif (code == operations_code["ID=BYTErval"]) then
    table.insert(t, string.format("  movb   %s, %s", op1, op2))
  elseif (code == operations_code["ID=ID[rval]"]) then
    
  elseif (code == operations_code["ID=BYTEID[rval]"]) then

  elseif (code == operations_code["ID=-rval"]) then
    table.insert(t, string.format("  movl   %s, %s", op1, op2))
    table.insert(t, string.format("  negl   %s", op1))
  elseif (code == operations_code["ID=NEWrval"]) then
    
  elseif (code == operations_code["ID=NEWBYTErval"]) then
    
  elseif (code == operations_code["ID=rvalEQrval"]) then
    
  elseif (code == operations_code["ID=rvalNErval"]) then
    
  elseif (code == operations_code["ID=rvalGErval"]) then
    
  elseif (code == operations_code["ID=rvalLErval"]) then
    
  elseif (code == operations_code["ID=rval<rval"]) then
    
  elseif (code == operations_code["ID=rval>rval"]) then
    
  elseif (code == operations_code["ID=rval+rval"]) then
    
  elseif (code == operations_code["ID=rval-rval"]) then
    
  elseif (code == operations_code["ID=rval*rval"]) then
    
  elseif (code == operations_code["ID=rval/rval"]) then
    
  elseif (code == operations_code["ID[rval]=rval"]) then
    
  elseif (code == operations_code["ID[rval]=BYTErval"]) then
    
  end
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

--GetRegs: Receive a instruction node created by intermediate code
--    and return registers that should be used for operation
--  Parameters:
--    [1] $number - number of instruction inside a basic block
--    [1] $table  - table containing a instruction
--  Return:
--    [1] $table or $nil  - table of operations to be done (spill registers)
--    [2] $string         - register for first operator
--    [3] $string         - register for second operator
--    [4] $string         - register for third operator
function Class.GetRegs (inst_num, inst)
  if (_DEBUG) then print("RAM :: GetRegs") end
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

--GetRegRead:
--  Parameters:
--    [1] $number         - Number of current instruction;
--    [2] $string         - Variable that should get a registrator;
--    [3] $string or $nil - Operator 1 already allocated by 'GetRegs';
--    [4] $number or $nil - Number of register used by Operator 1;
--    [5] $string or $nil - Operator 2 already allocated by 'GetRegs';
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
    for regnum, regtable in ipairs(regs_vars.regs) do
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
--    [3] $string or $nil - Operator 1 already allocated by 'GetRegs'
--    [4] $number or $nil - Number of register used by Operator 1
--    [5] $string or $nil - Operator 2 already allocated by 'GetRegs'
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
  for regnum, regtable in ipairs(regs_vars.regs) do
    if (#regtable == 1 and regtable[1] == op) then
      return nil, regnum
    end
  end
  if (reg1 and not Class.GetVariableNextUse(num, op1)) then
    if (#regs_vars.regs[reg1] == 1) then
      local reg = reg1
      Class.SetVariableInsideRegister(reg, op)
      return nil, reg
    end
  elseif (reg2 and not Class.GetVariableNextUse(num, op2)) then
    if (#regs_vars.regs[reg2] == 1) then
      local reg = reg2
      Class.SetVariableInsideRegister(reg, op)
      return nil, reg
    end
  else
    return Class.GetRegRead(num, op, op1, reg1, op2, reg2)
  end
end

--GetRegisterEmpty:
--  Parameters:
--    [1] $number         - Start counting from this number
--  Return:
--    [1] $number or $nil - Number of register who is empty
function Class.GetRegisterEmpty ()
  if (_DEBUG) then print("RAM :: GetRegisterEmpty") end
  for regnum, regtable in ipairs(regs_vars.regs) do
    if (util.TableIsEmpty(regtable)) then
      return regnum
    end
  end
  return nil
end

--GetVariableInsideMemory:
--  Parameters:
--    [1] $string   - Variable name
--  Return:
--    [1] $boolean  - TRUE if variable is saved in memory, FALSE otherwise
function Class.GetVariableInsideMemory (var)
  if (_DEBUG) then print("RAM :: GetReg") end
  assert(var and type(var) == "string")
  for _, place in ipairs(regs_vars.vars[var]) do
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
  for regnum, regtable in ipairs(regs_vars.regs) do
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
  return vars_appear[inst_num][var].alive, vars_appear[inst_num][var].next_inst
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
  for _, var_in_reg in ipairs(regs_vars.regs[reg]) do
    if (var == var_in_reg) then
      return
    end
  end
  table.insert(regs_vars.regs[reg], var)
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

--Open: Write a 'path'.o file with machine code.
--  Parameters:
--    [1] $string   - Path of exit file. Extension will be converted to '.o'
--    [2] $table    - Struct of program builded by intermediate code.
--  Return:
--    [1] $boolean  - false if found any problem, true otherwise
--    [2] $string   - only when [1] is false, informing which error occurs
function Class.Open (path, intermediate_code)
  if (_DEBUG) then print("MCG :: Open") end
  assert(path)
  assert(type(intermediate_code) == "table")
  local ok, msg = pcall(function ()
    local f = io.open(util.FileRemoveExtension(path) .. ".s", "w")
    if (not f) then
      Class.Error(string.format("output file '%s' could not be opened"), path)
    end
    f:write(string.format('.data\n'))
    for _, string in ipairs(intermediate_code.strings) do
      Class.DumpString(f, string.var, string.str)
    end
    f:write(string.format('.text\n'))
    Class.DumpGlobal(f, intermediate_code.functions, intermediate_code.globals)
    for _, func in ipairs(intermediate_code.functions) do
      local basic_blocks = Class.GenBasicBlock(func)
      local machine_block = Class.GenMachineBlock(basic_blocks)
      Class.DumpFunction(f, func.name, machine_block)
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
