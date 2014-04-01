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
-- Running
--==============================================================================

local files = {
  --"data/test_general_1.txt",
  --"data/test_keyword_1.txt",
  --"data/test_operator_1.txt",
  --"data/test_string_1.txt",
  "data/program_01.txt",
}


for k, file_path in ipairs(files) do
  local f = io.open(file_path, "r")
  if (not f) then
    print(string.format("(%2d de %2d) %s - %s", k, #files, "FAILURE OPENING", file_path))
    print("Arquivo nao pode ser aberto")
  else
    local str = f:read("*a")
    f:close()
    local ok, msg
    -- LEXICAL
    ok, msg = Lexical.Open(str)
    if (not ok) then
      print(string.format("(%2d de %2d) %s - %s", k, #files, "FAILURE LEXICAL", file_path))
      print(msg)
      if (_DEBUG) then util.TablePrint(Lexical.GetTags()) end
    end
    -- SYNTACTIC
    ok = Syntactic.Open(Lexical.GetTags())
    if (not ok) then
      print(string.format("(%2d de %2d) %s - %s", k, #files, "FAILURE SYNTACTIC", file_path))
    end
    -- TEST END
    print(string.format("(%2d de %2d) %s - %s", k, #files, "SUCCESS", file_path))
  end
end