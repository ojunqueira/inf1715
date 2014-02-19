--==============================================================================
-- Global Defines
--==============================================================================

_DEBUG = false

--==============================================================================
-- Dependency
--==============================================================================

local LexicalClass = require "src/lexical"

--==============================================================================
-- Running
--==============================================================================

local files = {
	"test1.txt",
	"test2.txt",
}

for k, file_path in ipairs(files) do
	local ok, msg = LexicalClass:Open(file_path)
	print(string.format("(%2d de %2d) %s - %s", k, #files, (ok and "SUCCESS") or "FAILURE", msg))
	if (not ok) then
		print("    ", msg)
	end
end