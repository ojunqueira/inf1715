--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = false
local printInput = false


--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local Lexical   = require "src/lexical"
local Syntactic = require "src/syntactic"
local ASTree    = require "lib/syntax_tree"


--==============================================================================
-- Return codes
--==============================================================================

local errors = {
  no_input  = 1,
  open_file = 2,
  lexical   = 3,
  syntactic = 4,
}


--==============================================================================
-- Running
--==============================================================================

print("== START TEST =======================================================")
local args = {...}
if (#args == 0) then
   print("Nenhum arquivo de entrada foi informado.")
   os.exit(errors.no_input)
end

for k, v in ipairs(args) do
	print("== INPUT ============================================================")
  local f = io.open(args[k], "r")
  if (not f) then
    print(string.format("Arquivo %s nao pode ser aberto", args[k]))
    os.exit(errors.open_file)
  end
	local str = f:read("*a")
  f:close()
  if (printInput) then
    print(str)
  end
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
  print("== AST TREE =========================================================")
  ASTree.Print()
  print("== FINISH ===========================================================")
end

return 0