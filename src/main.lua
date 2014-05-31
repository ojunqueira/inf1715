--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = false
local printInput    = false
local printASTTree  = false
package.path  = package.path .. ';' .. "src/" .. '?.lua'
package.path  = package.path .. ';' .. "lib/" .. '?.lua'


--==============================================================================
-- Dependency
--==============================================================================

require "util"
local Lexical           = require "lexical/lexical"
local Syntactic         = require "syntactic/syntactic"
local Semantic          = require "semantic/semantic"
local IntermediateCode  = require "intermediate_code/intermediate_code"
local MachineCode       = require "machine_code/machine_code"


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
  err_intercode = 6,
  err_machcode  = 7,
}


--==============================================================================
-- Running
--==============================================================================

print("\n== START TEST =======================================================")
local args = {...}
if (#args == 0) then
   print("@0 file error: no input file.")
   io.stderr:write(ret_codes.err_input)
   os.exit(ret_codes.err_input)
end
for k, v in ipairs(args) do
	print("\n== INPUT ==========================================================")
  local f = io.open(args[k], "r")
  if (not f) then
    print(string.format("file error: could not be opened.", args[k]))
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
  print("\n== LEXICAL ========================================================")
  ok, msg = Lexical.Open(str)
  if (not ok) then
    print("LEX: FAILURE    ", msg)
    io.stderr:write(ret_codes.err_lexical)
    os.exit(ret_codes.err_lexical)
  else
    print("LEX: SUCCESS")
  end
  print("\n== SYNTACTIC ======================================================")
  ok, msg = Syntactic.Open(Lexical.GetTags())
  if (not ok) then
    print("SYN: FAILURE    ", msg)
    io.stderr:write(ret_codes.err_syntactic)
    os.exit(ret_codes.err_syntactic)
  else
    print("SYN: SUCCESS")
  end
  print("\n== AST TREE =======================================================")
  if (printASTTree) then
    Syntactic.PrintTree()
  end
  print("AST: SUCCESS")
  print("\n== SEMANTIC =======================================================")
  ok, msg = Semantic.Open(Syntactic.GetTree())
    if (not ok) then
    print("SEM: FAILURE    ", msg)
    io.stderr:write(ret_codes.err_semantic)
    os.exit(ret_codes.err_semantic)
  else
    print("SEM: SUCCESS")
  end
  print("\n== INTERMEDIATE CODE ==============================================")
  ok, msg = IntermediateCode.Open(args[k], Semantic.GetTree())
  if (not ok) then
    print("ICG: FAILURE    ", msg)
    io.stderr:write(ret_codes.err_intercode)
    os.exit(ret_codes.err_intercode)
  else
    print("ICG: SUCCESS")
  end
  print("\n== MACHINE CODE ===================================================")
  ok, msg = MachineCode.Open(args[k], IntermediateCode.GetCode())
  if (not ok) then
    print("MCG: FAILURE    ", msg)
    io.stderr:write(ret_codes.err_machcode)
    os.exit(ret_codes.err_machcode)
  else
    print("MCG: SUCCESS")
  end
  print("\n== FINISH =========================================================")
end

return ret_codes.ok