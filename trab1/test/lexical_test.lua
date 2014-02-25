--==============================================================================
-- Dependency
--==============================================================================

local Lexical = require "src/lexical"

--==============================================================================
-- Running
--==============================================================================

local files = {
  "data/test_general_1.txt",
  "data/test_keyword_1.txt",
  "data/test_operator_1.txt",
  "data/test_string_1.txt",
}

for k, file_path in ipairs(files) do
  local f = io.open(file_path, "r")
  if (not f) then
    print(string.format("(%2d de %2d) %s - %s", k, #files, "FAILURE", file_path))
    print("Arquivo nao pode ser aberto")
  else
    local str = f:read("*a")
    f:close()
    local ok, msg = Lexical.Open(str)
    if (not ok) then
      print(string.format("(%2d de %2d) %s - %s", k, #files, "FAILURE", file_path))
      print(msg)
    else
      print(string.format("(%2d de %2d) %s - %s", k, #files, "SUCCESS", file_path))
    end
  end
end