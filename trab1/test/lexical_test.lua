--==============================================================================
-- Dependency
--==============================================================================

local Lexical = require "src/lexical"

--==============================================================================
-- Running
--==============================================================================

local files = {
  "data/test1.txt",
  --"data/test2.txt",
}

for k, file_path in ipairs(files) do
  local f = io.open(file_path, "r")
  if (not f) then
  end
  local str = f:read("*a")
  f:close()
  local ok, msg = Lexical.Open(str)
  --print(string.format("(%2d de %2d) %s - %s", k, #files, (ok and "SUCCESS") or "FAILURE", msg))
  --if (not ok) then
  --  print("    ", msg)
  --end
end