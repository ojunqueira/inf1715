--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = true


--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
require "lib/tokencodes"
local Lexical   = require "src/lexical"
local Syntactic = require "src/syntactic"


--==============================================================================
-- Return codes
--==============================================================================

local errors = {
  open_file = 1,
  lexical   = 2,
  syntactic = 3,
}


--==============================================================================
-- Testing
--==============================================================================

--local lexical_test = require "test/lexical_test"

--==============================================================================
-- Running
--==============================================================================

local args = {...}
if (#args == 0) then
   print("Nenhum arquivo de entrada foi informado.")
   os.exit(errors.open_file)
end

for k, v in ipairs(args) do
	print("== INPUT ============================================================")
  local f = io.open(args[k], "r")
	local str = f:read("*a")
  f:close()
  print(str)
  local ok, msg
  print("== LEXICAL ==========================================================")
  ok, msg = Lexical.Open(str)
  if (not ok) then
    print("LEX: FAILURE    ", msg)
    os.exit(errors.lexical)
  else
    print("LEX: SUCCESS")
  end
  print("== SYNTACTIC ========================================================")
  ok, msg = Syntactic.Open(Lexical.GetTags())
  if (not ok) then
    print("SYN: FAILURE    ", msg)
    os.exit(errors.syntactic)
  else
    print("SYN: SUCCESS")
  end
  print("== FINISH ===========================================================")
end