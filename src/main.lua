--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = false
local printInput    = false
local printASTTree  = true


--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local Lexical     = require "src/lexical"
local Syntactic   = require "src/syntactic"
local Semantic    = require "src/semantic"


--==============================================================================
-- Return codes
--==============================================================================

-- Possible return codes for program
local ret_codes = {
  ok            = 0,
  err_input     = 1,
  err_open      = 2,
  err_lexical   = 3,
  err_syntactic = 4,
  err_semantic  = 5,
}


--==============================================================================
-- Running
--==============================================================================

print("\n== START TEST =======================================================")
local args = {...}
if (#args == 0) then
   print("Nenhum arquivo de entrada foi informado.")
   io.stderr:write(ret_codes.err_input)
   os.exit(ret_codes.err_input)
end
for k, v in ipairs(args) do
	print("\n== INPUT ============================================================")
  local f = io.open(args[k], "r")
  if (not f) then
    print(string.format("Arquivo %s nao pode ser aberto", args[k]))
    io.stderr:write(ret_codes.err_open)
    os.exit(ret_codes.err_open)
  end
	local str = f:read("*a")
  f:close()
  if (printInput) then
    print(str)
  else
    print("FILE: SUCCESS")
  end
  local ok, msg
  print("\n== LEXICAL ==========================================================")
  ok, msg = Lexical.Open(str)
  if (not ok) then
    print("LEX: FAILURE    ", msg)
    io.stderr:write(ret_codes.err_lexical)
    os.exit(ret_codes.err_lexical)
  else
    print("LEX: SUCCESS")
  end
  print("\n== SYNTACTIC ========================================================")
  ok, msg = Syntactic.Open(Lexical.GetTags())
  if (not ok) then
    print("SYN: FAILURE    ", msg)
    io.stderr:write(ret_codes.err_syntactic)
    os.exit(ret_codes.err_syntactic)
  else
    print("SYN: SUCCESS")
  end
  print("\n== SYNTACTIC AST TREE ===============================================")
  if (printASTTree) then
    Syntactic.PrintTree()
  end
  print("AST: SUCCESS")
  print("\n== SEMANTIC =========================================================")
  ok, msg = Semantic.Open(Syntactic.GetTree())
    if (not ok) then
    print("SEM: FAILURE    ", msg)
    io.stderr:write(ret_codes.err_semantic)
    os.exit(ret_codes.err_semantic)
  else
    print("SEM: SUCCESS")
  end
  print("\n== FINISH ===========================================================")
end

return ret_codes.ok