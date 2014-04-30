--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = false


--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local Lexical   = require "src/lexical"
local Syntactic = require "src/syntactic"
local Semantic  = require "src/semantic"


--==============================================================================
-- Data Structure
--==============================================================================

local files = {
  --[[
  ["nilfile.txt"] = {
    open      = false,
  },
  ["data/lexical_01.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["data/lexical_02.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["data/lexical_03.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["data/lexical_04.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["data/without_last_line_end.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["data/fun_01.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  ["data/global_01.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  ["data/program_01.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  --]]
  ["data/sem_fail_func_same_name.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true, --false
  },
  ["data/sem_fail_func_same_name_var.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true, --false
  },
  ["data/sem_fail_func_ret_type.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true, --false
  },
  ["data/sem_fail_var_same_name_func.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true, --false
  },
  ["data/sem_fail_if_exp_bool.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true, --false
  },
  --[[
  ["testes_gabarito/00-fail-empty.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/01-global.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/02-fun.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/03-nls.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/04-funglobal.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/05-params.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/06-declvar.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/07-if.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/08-fail-else.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/09-fail-elseif.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/10-fail-if.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/11-ifdecl.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/12-while.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/13-fail-while.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/14-ifwhile.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/15-fail-ifwhile.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/16-atrib.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/17-call.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/18-fail-call.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/19-callargs.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/19-fail-callargs.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/20-return.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/21-arrays.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/21-return-noargs.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/22-exp.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/22-fail-exp.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/23-fail-fun.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/24-fail-fun2.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/25-fail-fun3.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/26-fail-fun4.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/27-fail-global.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/28-fail-block.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/29-fail-params.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/30-fail-param.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/31-fail-type.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/32-fail-declvar.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/33-fail-missingexp.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/34-fail-invalidexp.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  ["testes_gabarito/35-expprio.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["testes_gabarito/36-fail-roottoken.m0"] = {
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  --]]
}


--==============================================================================
-- Private Methods
--==============================================================================

local function Run ()
  local num_files = 0
  local num_files_read = 1
  for _, _ in pairs (files) do
    num_files = num_files + 1
  end
  for file, valid in pairs (files) do
    local file_str                  --  keeps the convertion of file to string
    local unexpected_error = false  --  inform that an unexpected error occurs (if true stop further tests)
    local expected_error = false    --  inform that an expected error occurs (if true stop further tests)
    -- TEST OPENING
    ------------------------------------------------
    if (not unexpected_error and not expected_error) then
      local f = io.open(file, "r")
      if (not f and valid.open) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to open.', num_files_read, num_files, file))
      elseif (f and not valid.open) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" not expected to open.', num_files_read, num_files, file))
      elseif (not f and not valid.open) then
        expected_error = true
      else
        file_str = f:read("*a")
        f:close()
      end
    end
    -- TEST LEXICAL
    ------------------------------------------------
    if (not unexpected_error and not expected_error) then
      local ok, msg = Lexical.Open(file_str)
      if (not ok and valid.lexical) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to PASS on lexical. \n\t %s', num_files_read, num_files, file, msg or ""))
      elseif (ok and not valid.lexical) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to FAIL on lexical. \n\t %s', num_files_read, num_files, file, msg or ""))
      elseif (not ok and not valid.lexical) then
        expected_error = true
      end
    end
    -- TEST SYNTAX
    ------------------------------------------------
    if (not unexpected_error and not expected_error) then
      local ok, msg = Syntactic.Open(Lexical.GetTags())
      if (not ok and valid.syntactic) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to PASS on syntactic. \n\t %s', num_files_read, num_files, file, msg or ""))
      elseif (ok and not valid.syntactic) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to FAIL on syntactic. \n\t %s', num_files_read, num_files, file, msg or ""))
      elseif (not ok and not valid.syntactic) then
        expected_error = true
      end
    end
    -- TEST SEMANTIC
    ------------------------------------------------
    if (not unexpected_error and not expected_error) then
      local ok, msg = Semantic.Open(Syntactic.GetTree())
      if (not ok and valid.semantic) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to PASS on semantic. \n\t %s', num_files_read, num_files, file, msg or ""))
      elseif (ok and not valid.semantic) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to FAIL on semantic. \n\t %s', num_files_read, num_files, file, msg or ""))
      elseif (not ok and not valid.semantic) then
        expected_error = true
      end
    end
    -- PASSED ALL TESTS
    ------------------------------------------------
    if (not unexpected_error or expected_error) then
      print(string.format('(%2s de %2s) SUCCESS - File "%s".', num_files_read, num_files, file))
    end
    num_files_read = num_files_read + 1
  end
end


--==============================================================================
-- Running
--==============================================================================

local ok, msg = pcall(function () Run() end)
if (not ok) then
  print("Erro inesperado no teste automático. " .. msg)
end