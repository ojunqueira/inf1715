--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = false
local printFailMessage = false


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
  {
    name      = "nil_file",
    open      = false,
  },
  {
    name      = "lex_fail",
    open      = true,
    lexical   = false,
  },
  {
    name      = "lex_overload_01",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "lex_overload_02",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "lex_overload_03",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "lex_overload_04",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "sem_complete_program",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "sem_elseif_block",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "sem_fail_attrib_string_char",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_attrib_char_string",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_attrib_int_bool",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_call_not_function",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_call_wrong_param_number",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_declare_same_name_01",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_declare_same_name_02",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  }, 
  {
    name      = "sem_fail_elseif_condition",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_exp_negate_char",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_exp_sum_bool",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_exp_unary_bool",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_func_ret_dimension_different",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_func_ret_nil",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_func_ret_type_different",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_func_same_par_name",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_func_void_return",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_if_condition_int",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_var_array_bool",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_var_array_dimension_zero",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_var_array_larger",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_var_existent",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "sem_fail_var_undeclared",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },


  {
    name      = "00-fail-empty",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "01-global",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "02-fun",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "03-nls",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "04-funglobal",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "05-params",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "06-declvar",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "07-if",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "08-fail-else",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "09-fail-elseif",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "10-fail-if",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "11-ifdecl",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "12-while",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "13-fail-while",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "14-ifwhile",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "15-fail-ifwhile",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "16-atrib",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "17-call",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "18-fail-call",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "19-callargs",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "19-fail-callargs",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "20-return",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "21-arrays",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = true,
  },
  {
    name      = "21-return-noargs",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "22-exp",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "22-fail-exp",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "23-fail-fun",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "24-fail-fun2",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "25-fail-fun3",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "26-fail-fun4",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "27-fail-global",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "28-fail-block",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "29-fail-params",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "30-fail-param",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "31-fail-type",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "32-fail-declvar",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "33-fail-missingexp",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "34-fail-invalidexp",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "35-expprio",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
  {
    name      = "36-fail-roottoken",
    open      = true,
    lexical   = true,
    syntactic = false,
  },
  {
    name      = "37-invprio",
    open      = true,
    lexical   = true,
    syntactic = true,
    semantic  = false,
  },
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
  for _, valid in ipairs (files) do
    local file_str                  --  keeps the convertion of file to string
    local unexpected_error = false  --  inform that an unexpected error occurs (if true stop further tests)
    local expected_error = false    --  inform that an expected error occurs (if true stop further tests)
    local ok, msg

    -- TEST OPENING
    ------------------------------------------------
    if (not unexpected_error and not expected_error) then
      local f = io.open("data/" .. valid.name .. ".txt", "r")
      if (not f and valid.open) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to open.', num_files_read, num_files, valid.name))
      elseif (f and not valid.open) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" not expected to open.', num_files_read, num_files, valid.name))
      elseif (not f and not valid.open) then
        expected_error = true
        msg = "@0 file error: could not be opened."
      else
        file_str = f:read("*a")
        f:close()
      end
    end
    
    -- TEST LEXICAL
    ------------------------------------------------
    if (not unexpected_error and not expected_error) then
      ok, msg = Lexical.Open(file_str)
      if (not ok and valid.lexical) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to PASS on lexical. \n\t %s', num_files_read, num_files, valid.name, msg or ""))
      elseif (ok and not valid.lexical) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to FAIL on lexical. \n\t %s', num_files_read, num_files, valid.name, msg or ""))
      elseif (not ok and not valid.lexical) then
        expected_error = true
      end
    end
    
    -- TEST SYNTAX
    ------------------------------------------------
    if (not unexpected_error and not expected_error) then
      ok, msg = Syntactic.Open(Lexical.GetTags())
      if (not ok and valid.syntactic) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to PASS on syntactic. \n\t %s', num_files_read, num_files, valid.name, msg or ""))
      elseif (ok and not valid.syntactic) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to FAIL on syntactic. \n\t %s', num_files_read, num_files, valid.name, msg or ""))
      elseif (not ok and not valid.syntactic) then
        expected_error = true
      end
    end
    
    -- TEST SEMANTIC
    ------------------------------------------------
    if (not unexpected_error and not expected_error) then
      ok, msg = Semantic.Open(Syntactic.GetTree())
      if (not ok and valid.semantic) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to PASS on semantic. \n\t %s', num_files_read, num_files, valid.name, msg or ""))
      elseif (ok and not valid.semantic) then
        unexpected_error = true
        print(string.format('(%2s de %2s) FAILURE - File "%s" expected to FAIL on semantic. \n\t %s', num_files_read, num_files, valid.name, msg or ""))
      elseif (not ok and not valid.semantic) then
        expected_error = true
      end
    end
    
    -- PASSED ALL TESTS
    ------------------------------------------------
    if (not unexpected_error or expected_error) then
      print(string.format('(%2s de %2s) SUCCESS - File "%s".', num_files_read, num_files, valid.name))
      if (expected_error and printFailMessage) then
        print("        ", msg)
      end
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