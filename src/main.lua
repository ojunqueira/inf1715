--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = false
local printInput = false


--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local Lexical     = require "src/lexical"
local Syntactic   = require "src/syntactic"
local ASTree      = require "src/syntax_tree"
local Semantic    = require "src/semantic"


--==============================================================================
-- Return codes
--==============================================================================

local errors = {
  no_input  = 1,
  open_file = 2,
  lexical   = 3,
  syntactic = 4,
  semantic  = 5,
}


--==============================================================================
-- Running
--==============================================================================

print("== START TEST =======================================================")
local args = {...}
if (#args == 0) then
   print("Nenhum arquivo de entrada foi informado.")
   io.stderr:write(errors.no_input)
   --os.exit(errors.no_input)
end

for k, v in ipairs(args) do
	print("== INPUT ============================================================")
  local f = io.open(args[k], "r")
  if (not f) then
    print(string.format("Arquivo %s nao pode ser aberto", args[k]))
    io.stderr:write(errors.open_file)
    --os.exit(errors.open_file)
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
    io.stderr:write(errors.lexical)
    --os.exit(errors.lexical)
  else
    print("LEX: SUCCESS")
  end
  print("== SYNTACTIC ========================================================")
  ok, msg = Syntactic.Open(Lexical.GetTags())
  if (not ok) then
    print("SYN: FAILURE    ", msg)
    io.stderr:write(errors.syntactic)
    --os.exit(errors.syntactic)
  else
    print("SYN: SUCCESS")
  end
  print("== AST TREE =========================================================")
  ASTree.Print()
  local tree = ASTree.GetTree()
  print("== SEMANTIC =========================================================")
  ok, msg = Semantic.Open(tree)
    if (not ok) then
    print("SEM: FAILURE    ", msg)
    io.stderr:write(errors.semantic)
    --os.exit(errors.semantic)
  else
    print("SEM: SUCCESS")
  end
  print("== FINISH ===========================================================")
end

return 0