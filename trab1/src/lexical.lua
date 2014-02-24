--==============================================================================
-- Dependency
--==============================================================================

local lulex = require "lib/lulex"


--==============================================================================
-- Private Methods
--==============================================================================

local function PrintToken(code, token)
  print(string.format("codigo: %s token: %s", tostring(code), tostring(token)))
end


--==============================================================================
-- Data Structure
--==============================================================================

local Lexical = {}

local code = {
  COMMENT_LINE  = 610,
  COMMENT_BLOCK = 620,
  --KEYWORD       = 100,
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




  LINE_END      = 500,
  NUMBER        = 300,
  OP            = 400,
  STRING        = 200,
  ID            = 900,
  ERROR         = 000,
}

local lexer = lulex.New{
  { ' ',
    function(token)
      -- do nothing
    end
  },
  { '//[^\n]+',
    function(token) PrintToken(code.COMMENT_LINE, token) end
  },
  { '/%*[^%*]+%*/',
    function(token) PrintToken(code.COMMENT_BLOCK, token) end
  },
  { '[Ii][Ff]',
    function(token) PrintToken(code.K_IF, token) end
  },
  { '[Tt][Hh][Ee][Nn]',
    function(token) PrintToken(code.K_THEN, token) end
  },
  { '[Ee][Ll][Ss][Ee]',
    function(token) PrintToken(code.K_ELSE, token) end
  },
  { '[Ww][Hh][Ii][Ll][Ee]',
    function(token) PrintToken(code.K_WHILE, token) end
  },
  { '[Ll][Oo][Oo][Pp]',
    function(token) PrintToken(code.K_LOOP, token) end
  },
  { '[Ff][Uu][Nn]',
    function(token) PrintToken(code.K_FUN, token) end
  },
  { '[Rr][Ee][Tt][Uu][Rr][Nn]',
    function(token) PrintToken(code.K_RETURN, token) end
  },
  { '[Nn][Ee][Ww]',
    function(token) PrintToken(code.K_NEW, token) end
  },
  { '[Ss][Tt][Rr][Ii][Nn][Gg]',
    function(token) PrintToken(code.K_STRING, token) end
  },
  { '[Ii][Nn][Tt]',
    function(token) PrintToken(code.K_INT, token) end
  },
  { '[Cc][Hh][Aa][Rr]',
    function(token) PrintToken(code.K_CHAR, token) end
  },
  { '[Bb][Oo][Oo][Ll]',
    function(token) PrintToken(code.K_BOOL, token) end
  },
  { '[Tt][Rr][Uu][Ee]',
    function(token) PrintToken(code.K_TRUE, token) end
  },
  { '[Ff][Aa][Ll][Ss][Ee]',
    function(token) PrintToken(code.K_FALSE, token) end
  },
  { '[Aa][Nn][Dd]',
    function(token) PrintToken(code.K_AND, token) end
  },
  { '[Oo][Rr]',
    function(token) PrintToken(code.K_OR, token) end
  },
  { '[Nn][Oo][Tt]',
    function(token) PrintToken(code.K_NOT, token) end
  },
  { '[Ee][Nn][Dd]',
    function(token) PrintToken(code.K_END, token) end
  },





  { '"[^"]+"', -- nao considera \"
    function(token) PrintToken(code.STRING, token) end
  },
  { '[ \n]+',
    function(token) PrintToken(code.LINE_END, token) end
  },


  { '',
    function(token) PrintToken(code.ID, token) end
  },
  { '.',
    function(token) PrintToken(code.ERROR, token) end
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