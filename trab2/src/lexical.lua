--==============================================================================
-- Dependency
--==============================================================================

local lulex = require "lib/lulex"
assert(token_codes)


--==============================================================================
-- Data Structure
--==============================================================================

local Lexical = {}

-- number of current line
local line_number

-- lexer instructions and callbacks
--  {
--    [#] = {
--      [1] = pattern,
--      [2] = function,
--    }
--  }
local lexer = {}

-- tags read in input
--  {
--    [#] = {
--      code  = $number,
--      line  = $number,
--      token = $string,
--    }
--  }
local tags = {}


--==============================================================================
-- Private Methods
--==============================================================================

local function StoreToken (code, token, line)
  assert(code and type(code) == "number")
  assert(token)
  assert(line and type(line) == "number")
  if (_DEBUG) then
    print(string.format("codigo: %3d linha: %4d token: %s", code, line, tostring(token)))
  end
  local t = {
    code = code,
    line = line,
    token = token,
  }
  table.insert(tags, t)
end


--==============================================================================
-- Initialize
--==============================================================================

lexer = lulex.New{
  { '[ \t]+',
    function (token)
    end
  },
  { '//[^\n]+',
    function (token)
      --StoreToken(token_codes.COMMENT_LINE, token, line_number)
    end
  },
  { '/\\*([^\\*]|\\*[^/])*\\*/',
    function (token)
      --StoreToken(token_codes.COMMENT_BLOCK, token, line_number)
      local init = 0
      while (string.find(token, "\n", init)) do
        _, init = string.find(token, "\n", init)
        init = init + 1
        line_number = line_number + 1
      end
    end
  },
  { 'if',
    function (token)
      StoreToken(token_codes.K_IF, token, line_number)
    end
  },
  { 'then',
    function (token)
      StoreToken(token_codes.K_THEN, token, line_number)
    end
  },
  { 'else',
    function (token)
      StoreToken(token_codes.K_ELSE, token, line_number)
    end
  },
  { 'while',
    function (token)
      StoreToken(token_codes.K_WHILE, token, line_number)
    end
  },
  { 'loop',
    function (token)
      StoreToken(token_codes.K_LOOP, token, line_number)
    end
  },
  { 'fun',
    function (token)
      StoreToken(token_codes.K_FUN, token, line_number)
    end
  },
  { 'return',
    function (token)
      StoreToken(token_codes.K_RETURN, token, line_number)
    end
  },
  { 'new',
    function (token)
      StoreToken(token_codes.K_NEW, token, line_number)
    end
  },
  { 'string',
    function (token)
      StoreToken(token_codes.K_STRING, token, line_number)
    end
  },
  { 'int',
    function (token)
      StoreToken(token_codes.K_INT, token, line_number)
    end
  },
  { 'char',
    function (token)
      StoreToken(token_codes.K_CHAR, token, line_number)
    end
  },
  { 'bool',
    function (token)
      StoreToken(token_codes.K_BOOL, token, line_number)
    end
  },
  { 'true',
    function (token)
      StoreToken(token_codes.K_TRUE, token, line_number)
    end
  },
  { 'false',
    function (token)
      StoreToken(token_codes.K_FALSE, token, line_number)
    end
  },
  { 'and',
    function (token)
      StoreToken(token_codes.K_AND, token, line_number)
    end
  },
  { 'or',
    function (token)
      StoreToken(token_codes.K_OR, token, line_number)
    end
  },
  { 'not',
    function (token)
      StoreToken(token_codes.K_NOT, token, line_number)
    end
  },
  { 'end',
    function (token)
      StoreToken(token_codes.K_END, token, line_number)
    end
  },
  { '\\"([^\\"\\\\]|\\\\[nt\\\\"])*\\"',
    function (token)
      local str = token
      str = string.gsub(str, '^"', '')
      str = string.gsub(str, '"$', '')
      str = string.gsub(str, '\\"', '"')
      str = string.gsub(str, '\\n', '\n')
      str = string.gsub(str, '\\t', '\t')
      str = string.gsub(str, '\\\\', '\\')
      StoreToken(token_codes.STRING, str, line_number)
    end
  },
  { '[0-9]+',
    function (token)
      StoreToken(token_codes.NUMBER, token, line_number)
    end
  },
  { '0x[0-9]+',
    function (token)
      StoreToken(token_codes.NUMBER, tonumber(token), line_number)
    end
  },
  { '\\(',
    function (token)
      StoreToken(token_codes["OP_("], token, line_number)
    end
  },
  { '\\)',
    function (token)
      StoreToken(token_codes["OP_)"], token, line_number)
    end
  },
  { ',',
    function (token)
      StoreToken(token_codes["OP_,"], token, line_number)
    end
  },
  { ':',
    function (token)
      StoreToken(token_codes["OP_:"], token, line_number)
    end
  },
  { '>',
    function (token)
      StoreToken(token_codes["OP_>"], token, line_number)
    end
  },
  { '<',
    function (token)
      StoreToken(token_codes["OP_<"], token, line_number)
    end
  },
  { '>=',
    function (token)
      StoreToken(token_codes["OP_>="], token, line_number)
    end
  },
  { '<=',
    function (token)
      StoreToken(token_codes["OP_<="], token, line_number)
    end
  },
  { '=',
    function (token)
      StoreToken(token_codes["OP_="], token, line_number)
    end
  },
  { '<>',
    function (token)
      StoreToken(token_codes["OP_<>"], token, line_number)
    end
  },
  { '\\[',
    function (token)
      StoreToken(token_codes["OP_["], token, line_number)
    end
  },
  { '\\]',
    function (token)
      StoreToken(token_codes["OP_]"], token, line_number)
    end
  },
  { '\\+',
    function (token)
      StoreToken(token_codes["OP_+"], token, line_number)
    end
  },
  { '-',
    function (token)
      StoreToken(token_codes["OP_-"], token, line_number)
    end
  },
  { '\\*',
    function (token)
      StoreToken(token_codes["OP_*"], token, line_number)
    end
  },
  { '/',
    function (token)
      StoreToken(token_codes["OP_/"], token, line_number)
    end
  },
  { '[ \n]+',
    function (token)
      StoreToken(token_codes.LINE_END, token, line_number)
      local init = 0
      while (string.find(token, "\n", init)) do
        _, init = string.find(token, "\n", init)
        init = init + 1
        line_number = line_number + 1
      end
    end
  },
  { '[a-zA-Z_][a-zA-Z0-9]*',
    function (token)
      StoreToken(token_codes.ID, token, line_number)
    end
  },
  { '.',
    function (token)
      StoreToken(token_codes.ERROR, token, line_number)
    end
  },
}


--==============================================================================
-- Public Methods
--==============================================================================

--Open:
--  parameters:
--    [1] $string  - path of file to be analysed
--  return:
--    [1] $boolean - false if found any problem, true otherwise
--    [2] $string  - only when [1] is false, informing which error occurs
function Lexical.Open (txt)
  if (_DEBUG) then print("LEX :: Open") end
  assert(txt and type(txt) == "string")
  tags = {}
  line_number = 1
  lexer:run(txt, true)
  for _, tab in ipairs(tags) do
    if (tab.code == token_codes.ERROR) then
      return false, "Erro na identificação das tags"
    end
  end
  return true
end

function Lexical.GetTags()
  if (_DEBUG) then print("LEX :: GetTags") end
  return tags
end


--==============================================================================
-- Return
--==============================================================================

return Lexical