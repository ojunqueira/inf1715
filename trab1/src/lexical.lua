--==============================================================================
-- Class Dependency
--==============================================================================

require "lib/class"


--==============================================================================
-- Data Structure
--==============================================================================

local Lexical = Class{}


--==============================================================================
-- Public Methods
--==============================================================================

--Open:
--  parameters:
--    [1] $string  - path of file to be analysed
--  return:
--    [1] $boolean - false if found any problem, true otherwise
--    [2] $string  - only when [1] is false, informing which error occurs
function Lexical:Open (file)
	if (_DEBUG) then print("Lex :: Open") end
	assert(file and type(file) == "string")
	local f = io.open(file, "r")
	if (not f) then
		return false, string.format('Arquivo "%s" nao pode ser aberto.', file)
	end
	local line_str = f:read()
	f:close()
end


--==============================================================================
-- Private Methods
--==============================================================================

function GetChar ()
	if (_DEBUG) then print("Lex :: GetChar") end
end

function PeekChar ()
	if (_DEBUG) then print("Lex :: PeekChar") end
end

function PutChar ()
	if (_DEBUG) then print("Lex :: PutChar") end
end


--==============================================================================
-- Return
--==============================================================================

return Lexical