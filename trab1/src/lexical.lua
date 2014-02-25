--==============================================================================
-- Dependency
--==============================================================================

local lulex = require "lib/lulex"


--==============================================================================
-- Private Methods
--==============================================================================

local function StoreToken(code, token, line)
  if (_DEBUG) then
    print(string.format("codigo: %s linha: %s token: %s", tostring(code), tostring(line), tostring(token)))
  end
end


--==============================================================================
-- Data Structure
--==============================================================================

local Lexical = {}

-- number of current line
local line_number = 1

-- code of each tag
local code = {
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

-- lexer instructions and callbacks 
local lexer = lulex.New{
  { ' ',
    function (token)
    end
  },
  { '//[^\n]+',
    function (token)
      StoreToken(code.COMMENT_LINE, token, line_number)
    end
  },
  { '/%*[^%*]+%*/',
    function (token)
      StoreToken(code.COMMENT_BLOCK, token, line_number)
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
      StoreToken(code.K_IF, token, line_number) end
  },
  { 'then',
    function (token)
      StoreToken(code.K_THEN, token, line_number) end
  },
  { 'else',
    function (token)
      StoreToken(code.K_ELSE, token, line_number) end
  },
  { 'while',
    function (token)
      StoreToken(code.K_WHILE, token, line_number) end
  },
  { 'loop',
    function (token)
      StoreToken(code.K_LOOP, token, line_number) end
  },
  { 'fun',
    function (token)
      StoreToken(code.K_FUN, token, line_number) end
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
  { '"[^"]*"', -- nao considera \" -- leitura sendo feita ate o proximo ". Como diferenciar quebra de linha de \n dentro da string?
    function (token)
      StoreToken(code.STRING, token, line_number)
    end
  },
  { '[%d]+',
    function (token)
      StoreToken(code.NUMBER, token, line_number)
    end
  },
  { '0x[%d]+',
    function (token)
      StoreToken(code.NUMBER, token, line_number)
    end
  },
  { '%(',
    function (token)
      StoreToken(code["OP_("], token, line_number)
    end
  },
  { '%)',
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
  { '%[',
    function (token)
      StoreToken(code["OP_["], token, line_number)
    end
  },
  { '%]',
    function (token)
      StoreToken(code["OP_]"], token, line_number)
    end
  },
  { '%+',
    function (token)
      StoreToken(code["OP_+"], token, line_number)
    end
  },
  { '%-',
    function (token)
      StoreToken(code["OP_-"], token, line_number)
    end
  },
  { '%*',
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
  { '[%a_][%w%d_]*',
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
  if (_DEBUG) then print("Lex :: Open") end
  assert(txt and type(txt) == "string")
  lexer:run(txt, true)
  --return true, "Leitura realizada com sucesso."
end


--==============================================================================
-- Return
--==============================================================================

return Lexical