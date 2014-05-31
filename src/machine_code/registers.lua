--==============================================================================
-- Debug
--==============================================================================

local _DEBUG = true


--==============================================================================
-- Dependency
--==============================================================================



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
--    "name" = {
--      [1 to N] = number     --  number of instruction where it is used
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
--    [1] $table  - Table containing one basic block
--  Return:
function Class.Build (basic_block)
  if (_DEBUG) then print("MCG :: Build") end
  assert(type(basic_block) == "table")
  struct = {
    regs = {},
    vars = {},
  }
  var_appear = {}
  for num, _ in ipairs(registers) do
    struct.regs[num] = {}
  end
  for num, block in ipairs(basic_block) do
    if (block.op1 and not tonumber(block.op1)) then
      struct.vars[block.op1] = struct.vars[block.op1] or {block.op1}
      var_appear[block.op1] = var_appear[block.op1] or {}
      table.insert(var_appear[block.op1], num)
    end
    if (block.op2 and not tonumber(block.op2)) then
      struct.vars[block.op2] = struct.vars[block.op2] or {block.op2}
      var_appear[block.op2] = var_appear[block.op2] or {}
      table.insert(var_appear[block.op2], num)
    end
    if (block.op3 and not tonumber(block.op3)) then
      struct.vars[block.op3] = struct.vars[block.op3] or {block.op3}
      var_appear[block.op3] = var_appear[block.op3] or {}
      table.insert(var_appear[block.op3], num)
    end
  end
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

--GetVariableNextAppearance:
--  Parameters:
--    [1] $string - Variable name
--    [2] $number - Number of current instruction
--  Return:
--    [1] $number or $nil - Nil if variable is not used anymore, number of next
--                          instruction use otherwise
function Class.GetVariableNextAppearance (var, inst_num)
  if (_DEBUG) then print("MCG :: GetVariableNextAppearance") end
  assert(type(var) == "string")
  assert(type(inst_num) == "number")
  for _, num in ipairs(var_appear[var]) do
    if (num > inst_num) then
      return num
    end
  end
  return nil
end


--==============================================================================
-- Public Methods
--==============================================================================

--GetRegisters: Receive a instruction node created by intermediate code
--    and return registers that should be used for operation
--  Parameters:
--    [1] $table  - Table containing a instruction
--  Return:
--    [1] $string - Register for first operator
--    [2] $string - Register for second operator
--    [3] $string - Register for third operator
function Class.GetRegisters (instruction)
  if (_DEBUG) then print("MCG :: GetRegisters") end
end

--New: 
--  Parameters:
--    [1] $table    - List of basic blocks containing intermediate code instructions
--  Return:
--    [1] $boolean  - false if found any problem, true otherwise
--    [2] $string   - only when [1] is false, informing which error occurs
function Class.New (basic_block)
  if (_DEBUG) then print("MCG :: Open") end
  assert(type(basic_block) == "table")
  local ok, msg = pcall(function ()
    Class.Build(basic_block)
    util.TablePrint(struct)
    util.TablePrint(var_appear)
    print(Class.GetVariableNextAppearance("$t3", 8))
  end)
  if (not ok) then
    print("ERRO REGISTERS")
    return false, msg
  end
  return true
end


--==============================================================================
-- Return
--==============================================================================

return Class
