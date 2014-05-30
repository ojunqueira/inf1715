--==============================================================================
-- Debug
--==============================================================================



--==============================================================================
-- Dependency
--==============================================================================

local OperationsCode  = require "lib/operations_code"


--==============================================================================
-- Data Structure
--==============================================================================

local Class = {}

--  list of operations code
--  {
--    [name] = $number,
--  }
local operations_code = OperationsCode.GetList()

--
--  {
--    [1 to N] = {      - list of functions
--      [1 to N] = {    - list of basic blocks
--      }
--    }
--  }
local functions_blocks = {}


--==============================================================================
-- Private Methods
--==============================================================================

function Class.BasicBlocks (intermediate_code)
  if (_DEBUG) then print("MCG :: BasicBlocks") end
  for enum_func, func in ipairs(intermediate_code.functions) do
    functions_blocks[enum_func] = {}
    local enum_block = 0
    local next_is_block = false
    for enum_inst, inst in ipairs(func) do
      if (next_is_block) then
        next_is_block = false
        enum_block = enum_block + 1
        functions_blocks[enum_func][enum_block] = {}
        table.insert(functions_blocks[enum_func][enum_block], inst)
      elseif (enum_inst == 1) then
        enum_block = enum_block + 1
        functions_blocks[enum_func][enum_block] = {}
        table.insert(functions_blocks[enum_func][enum_block], inst)
      elseif (inst.code == operations_code["LABEL"]) then
        enum_block = enum_block + 1
        functions_blocks[enum_func][enum_block] = {}
        table.insert(functions_blocks[enum_func][enum_block], inst)
      elseif (inst.code == operations_code["GOTO"] or inst.code == operations_code["IFFALSEGOTO"] or inst.code == operations_code["IFGOTO"]) then
        next_is_block = true
        table.insert(functions_blocks[enum_func][enum_block], inst)
      else
        table.insert(functions_blocks[enum_func][enum_block], inst)
      end
    end
    util.TablePrint(functions_blocks[enum_func])
  end
end


--==============================================================================
-- Public Methods
--==============================================================================

function Class.Open (path, intermediate_code)
  if (_DEBUG) then print("MCG :: Open") end
  assert(path)
  assert(intermediate_code and type(intermediate_code) == "table")
  local ok, msg = pcall(function ()
    Class.BasicBlocks(intermediate_code)
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
