--==============================================================================
-- Class Dependency
--==============================================================================

require "lib/class"


--==============================================================================
-- Data Structure
--==============================================================================

local Lexical = Class{}

function Lexical:Constructor ()
  if (_DEBUG) then print("Lex :: Constructor") end
  self.cursor   = 0
  self.line_str = ""
end


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
  self.line_str = f:read()
  while (self.line_str) do
    -- COMPLETE
    local char = self:_GetChar()
    while (char ~= "\n") do
      -- COMPLETE
      char = self:_GetChar()
    end
    self.line_str = f:read()
    self.cursor = 0
  end
  f:close()
  return true, "Leitura realizada com sucesso."
end


--==============================================================================
-- Private Methods
--==============================================================================

function Lexical:_GetChar ()
  if (_DEBUG) then print("Lex :: GetChar") end
  local line_end
  _, line_end = string.find(self.line_str, ".$")
  if (line_end == self.cursor) then
    return "\n"
  end
  self.cursor = self.cursor + 1
  return string.sub(self.line_str, self.cursor, self.cursor)
end

function Lexical:_PeekChar ()
  if (_DEBUG) then print("Lex :: PeekChar") end
  return string.sub(self.line_str, self.cursor + 1, self.cursor + 1)
end

function Lexical:_PutChar ()
  if (_DEBUG) then print("Lex :: PutChar") end
  if (self.cursor > 0) then
    self.cursor = self.cursor - 1
  end
end


--==============================================================================
-- Return
--==============================================================================

return Lexical