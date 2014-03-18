--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = false


--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local Lexical = require "src/lexical"


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
   os.exit(1)
end

for k, v in ipairs(args) do
	local f = io.open(args[k], "r")
	local str = f:read("*a")
  f:close()
  local ok, msg = Lexical.Open(str)
  if (not ok) then
    print("LEX: FAILURE    ", msg)
  else
    print("LEX: SUCCESS")
  end
end