--==============================================================================
-- Dependency
--==============================================================================

local lulex = require "lib/lulex"


--==============================================================================
-- Data Structure
--==============================================================================

local Lexical = {}

-- number of current line
local line_number

-- code of each tag
--  {
--    ["code id"] = $number,
--  }
local code = {}

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

local function StoreToken(code, token, line)
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

code = {
  COMMENT_LINE  = 610,
  COMMENT_BLOCK = 620,
  K_IF          = 101,
  K_THEN        = 102,
  K_ELSE        = 103,
  K_WHILE       = 104,
  K_LOOP        = 105,
  K_FUN         = 106,
  K_RETURN      = 107,
  K_NEW         = 108,
  K_STRING      = 109,
  K_INT         = 110,
  K_CHAR        = 111,
  K_BOOL        = 112,
  K_TRUE        = 113,
  K_FALSE       = 114,
  K_AND         = 115,
  K_OR          = 116,
  K_NOT         = 117,
  K_END         = 118,
  STRING        = 200,
  NUMBER        = 300,
  ["OP_("]      = 401,
  ["OP_)"]      = 402,
  ["OP_,"]      = 403,
  ["OP_:"]      = 404,
  ["OP_>"]      = 405,
  ["OP_<"]      = 406,
  ["OP_>="]     = 407,
  ["OP_<="]     = 408,
  ["OP_="]      = 409,
  ["OP_<>"]     = 410,
  ["OP_["]      = 411,
  ["OP_]"]      = 412,
  ["OP_+"]      = 413,
  ["OP_-"]      = 414,
  ["OP_*"]      = 415,
  ["OP_/"]      = 416,
  LINE_END      = 500,
  ID            = 800,
  ERROR         = 000,
}

lexer = lulex.New{
  { ' ',
    function (token)
    end
  },
  { '//[^\n]+',
    function (token)
      --StoreToken(code.COMMENT_LINE, token, line_number)
    end
  },
  { '/\\*([^\\*]|\\*[^/])*\\*/',
    function (token)
      --StoreToken(code.COMMENT_BLOCK, token, line_number)
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
      StoreToken(code.K_IF, token, line_number)
    end
  },
  { 'then',
    function (token)
      StoreToken(code.K_THEN, token, line_number)
    end
  },
  { 'else',
    function (token)
      StoreToken(code.K_ELSE, token, line_number)
    end
  },
  { 'while',
    function (token)
      StoreToken(code.K_WHILE, token, line_number)
    end
  },
  { 'loop',
    function (token)
      StoreToken(code.K_LOOP, token, line_number)
    end
  },
  { 'fun',
    function (token)
      StoreToken(code.K_FUN, token, line_number)
    end
  },
  { 'return',
    function (token)
      StoreToken(code.K_RETURN, token, line_number)
    end
  },
  { 'new',
    function (token)
      StoreToken(code.K_NEW, token, line_number)
    end
  },
  { 'string',
    function (token)
      StoreToken(code.K_STRING, token, line_number)
    end
  },
  { 'int',
    function (token)
      StoreToken(code.K_INT, token, line_number)
    end
  },
  { 'char',
    function (token)
      StoreToken(code.K_CHAR, token, line_number)
    end
  },
  { 'bool',
    function (token)
      StoreToken(code.K_BOOL, token, line_number)
    end
  },
  { 'true',
    function (token)
      StoreToken(code.K_TRUE, token, line_number)
    end
  },
  { 'false',
    function (token)
      StoreToken(code.K_FALSE, token, line_number)
    end
  },
  { 'and',
    function (token)
      StoreToken(code.K_AND, token, line_number)
    end
  },
  { 'or',
    function (token)
      StoreToken(code.K_OR, token, line_number)
    end
  },
  { 'not',
    function (token)
      StoreToken(code.K_NOT, token, line_number)
    end
  },
  { 'end',
    function (token)
      StoreToken(code.K_END, token, line_number)
    end
  },
  --{ '"([^"]|\\[nt])*"', -- nao aceita \"
  { '"([^"]|\\[nt]|\\")*"', -- para corrigir
    function (token)
      StoreToken(code.STRING, token, line_number)
    end
  },
  { '[0-9]+',
    function (token)
      StoreToken(code.NUMBER, token, line_number)
    end
  },
  { '0x[0-9]+',
    function (token)
      StoreToken(code.NUMBER, tonumber(token), line_number)
    end
  },
  { '\\(',
    function (token)
      StoreToken(code["OP_("], token, line_number)
    end
  },
  { '\\)',
    function (token)
      StoreToken(code["OP_)"], token, line_number)
    end
  },
  { ',',
    function (token)
      StoreToken(code["OP_,"], token, line_number)
    end
  },
  { ':',
    function (token)
      StoreToken(code["OP_:"], token, line_number)
    end
  },
  { '>',
    function (token)
      StoreToken(code["OP_>"], token, line_number)
    end
  },
  { '<',
    function (token)
      StoreToken(code["OP_<"], token, line_number)
    end
  },
  { '>=',
    function (token)
      StoreToken(code["OP_>="], token, line_number)
    end
  },
  { '<=',
    function (token)
      StoreToken(code["OP_<="], token, line_number)
    end
  },
  { '=',
    function (token)
      StoreToken(code["OP_="], token, line_number)
    end
  },
  { '<>',
    function (token)
      StoreToken(code["OP_<>"], token, line_number)
    end
  },
  { '\\[',
    function (token)
      StoreToken(code["OP_["], token, line_number)
    end
  },
  { '\\]',
    function (token)
      StoreToken(code["OP_]"], token, line_number)
    end
  },
  { '\\+',
    function (token)
      StoreToken(code["OP_+"], token, line_number)
    end
  },
  { '-',
    function (token)
      StoreToken(code["OP_-"], token, line_number)
    end
  },
  { '\\*',
    function (token)
      StoreToken(code["OP_*"], token, line_number)
    end
  },
  { '/',
    function (token)
      StoreToken(code["OP_/"], token, line_number)
    end
  },
  { '[ \n]+',
    function (token)
      StoreToken(code.LINE_END, token, line_number)
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
      StoreToken(code.ID, token, line_number)
    end
  },
  { '.',
    function (token)
      StoreToken(code.ERROR, token, line_number)
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
    if (tab.code == code.ERROR) then
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