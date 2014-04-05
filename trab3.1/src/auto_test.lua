--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = false


--==============================================================================
-- Dependency
--==============================================================================

require "lib/util"
local Lexical = require "src/lexical"
local Syntactic = require "src/syntactic"


--==============================================================================
-- Data Structure
--==============================================================================

local files = {
  -- ERROR CASES
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
  -- WORKING CASES
  ["data/fun_01.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,
  },
  ["data/global_01.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,     
  },
  ["data/program_01.txt"] = {
    open      = true,
    lexical   = true,
    syntactic = true,     
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