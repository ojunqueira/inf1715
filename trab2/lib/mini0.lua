--==============================================================================
-- Debug
--==============================================================================

local printTokensMatch = false


--==============================================================================
-- Dependency
--==============================================================================

local TokensClass = require "lib/tokens"


--==============================================================================
-- Data Structure
--==============================================================================

local Language = {}

-- Stores Parser Functions
--  {
--    $name = $function
--  }
local Parser = {}

-- Stores Grammar Functions
--  {
--    $name = $function
--  }
local Grammar = {}

--  list of tokens
--  {
--    [name] = $number,
--  }
local tokens = TokensClass.GetTokensList()


--==============================================================================
-- Private Methods
--==============================================================================

--Error: 
--  Parameters:
--    [1] $number - line number of grammar syntax error
--  Return:
local function Error (line)
  error("Syntax error at line " .. line .. ".", 0)
end

--Match: Receives a token code number and compare with next avaiable token received from lexical
--  Parameters:
--    [1] $number - Next expected token code number
--  Return:
local function Match (code)
  if (_DEBUG) then print("LAN :: Match") end
  local token = Parser.Peek()
  if (token and token.code == code) then
    if (_DEBUG or printTokensMatch) then
      print(string.format("    Match code '%10s' %s", TokensClass.GetTokenName(code), token.token))
    end
    Parser.Advance()
  else
    if (token) then
      error("Expected " .. TokensClass.GetTokenName(code) .. " got " .. TokensClass.GetTokenName(token.code) .. " at line " .. token.line, 0)
    else
      error("Expected " .. TokensClass.GetTokenName(code) .. " got end of tokens.", 0)
    end
  end
end


--==============================================================================
-- Initialize
--==============================================================================

-- bloco     → { declvar nl }
--             { comando nl }
function Grammar.bloco ()
  if (_DEBUG) then print("LAN :: Grammar_bloco") end
  while (true) do
    local token = Parser.Peek()
    local token2 = Parser.Peek2()
    if (token and token2 and token.code == tokens.ID and token2.code == tokens["OP_:"]) then
      Grammar.declvar()
      Grammar.nl()
    else
      break
    end
  end
  while (true) do
    local token = Parser.Peek()
    if (token and
        token.code == tokens.ID or
        token.code == tokens.K_IF or
        token.code == tokens.K_WHILE or
        token.code == tokens.K_RETURN) then
      Grammar.comando()
      Grammar.nl()
    else
      break
    end
  end
end

-- chamada   → ID '(' listaexp ')'
function Grammar.chamada ()
  if (_DEBUG) then print("LAN :: Grammar_chamada") end
  Match(tokens.ID)
  Match(tokens["OP_("])
  Grammar.listaexp()
  Match(tokens["OP_)"])
end

-- cmdatrib  → var '=' exp
function Grammar.cmdatrib ()
  if (_DEBUG) then print("LAN :: Grammar_cmdatrib") end
  Grammar.var()
  Match(tokens["OP_="])
  Grammar.exp()
end

-- cmdif     → 'if' exp nl
--                bloco
--             { 'else' 'if' exp nl
--                bloco
--             }
--             [ 'else' nl
--                bloco
--             ]
--             'end'
function Grammar.cmdif ()
  if (_DEBUG) then print("LAN :: Grammar_cmdif") end
  Match(tokens.K_IF)
  Grammar.exp()
  Grammar.nl()
  Grammar.bloco()
  while (true) do
    local token = Parser.Peek()
    local token2 = Parser.Peek2()
    if (token and token2 and token.code == tokens.K_ELSE and token2.code == tokens.K_IF) then
      Match(tokens.K_ELSE)
      Match(tokens.K_IF)
      Grammar.exp()
      Grammar.nl()
      Grammar.bloco()
    else
      break
    end
  end
  local token = Parser.Peek()
  if (token and token.code == tokens.K_ELSE) then
    Match(tokens.K_ELSE)
    Grammar.nl()
    Grammar.bloco()
  end
  Match(tokens.K_END)
end

-- cmdreturn → 'return' exp | 'return'
function Grammar.cmdreturn ()
  if (_DEBUG) then print("LAN :: Grammar_cmdreturn") end
  Match(tokens.K_RETURN)
  local token = Parser.Peek()
  if (token and token.code ~= tokens.LINE_END) then
    Grammar.exp()
  end
end

-- cmdwhile  → 'while' exp nl
--                bloco
--             'loop'
function Grammar.cmdwhile ()
  if (_DEBUG) then print("LAN :: Grammar_cmdwhile") end
  Match(tokens.K_WHILE)
  Grammar.exp()
  Grammar.nl()
  Grammar.bloco()
  Match(tokens.K_LOOP)
end

-- comando   → cmdif | cmdwhile | cmdatrib | cmdreturn | chamada 
function Grammar.comando ()
  if (_DEBUG) then print("LAN :: Grammar_comando") end
  local token = Parser.Peek()
  if (token and token.code == tokens.K_IF) then
    Grammar.cmdif()
  elseif (token and token.code == tokens.K_WHILE) then
    Grammar.cmdwhile()
  elseif (token and token.code == tokens.K_RETURN) then
    Grammar.cmdreturn()
  elseif (token and token.code == tokens.ID) then
    local token2 = Parser.Peek2()
    if (token2 and token2.code == tokens["OP_("]) then
      Grammar.chamada()
    elseif (token2 and 
            token2.code == tokens["OP_="] or
            token2.code == tokens["OP_["]) then
      Grammar.cmdatrib()
    else
      Error(token.line or nil)
    end
  else
    Error(token.line or nil)
  end
end

-- decl      → funcao | global
function Grammar.decl ()
  if (_DEBUG) then print("LAN :: Grammar_decl") end
  local token = Parser.Peek()
  if (token and token.code == tokens.K_FUN) then
    Grammar.funcao()
  elseif (token and token.code == tokens.ID) then
    Grammar.global()
  else
    Error(token.line or nil)
  end
end

-- declvar   → ID ':' tipo
function Grammar.declvar ()
  if (_DEBUG) then print("LAN :: Grammar_declvar") end
  Match(tokens.ID)
  Match(tokens["OP_:"])
  Grammar.tipo()
end

-- exp       → LITNUMERAL
--           | LITSTRING
--           | TRUE
--           | FALSE
--           | var
--           | 'new' '[' exp ']' tipo
--           | '(' exp ')'
--           | chamada
--           | exp '+' exp
--           | exp '-' exp
--           | exp '*' exp
--           | exp '/' exp
--           | exp '>' exp
--           | exp '<' exp
--           | exp '>=' exp
--           | exp '<=' exp
--           | exp '=' exp
--           | exp '<>' exp
--           | exp 'and' exp
--           | exp 'or' exp
--           | 'not' exp
--           | '-' exp
function Grammar.exp ()
  if (_DEBUG) then print("LAN :: Grammar_exp") end
  Grammar.exp_preced_1()
end

function Grammar.exp_preced_1 ()
  Grammar.exp_preced_2()
  local token = Parser.Peek()
  if (token and token.code == tokens.K_OR) then
    Match(tokens.K_OR)
    Grammar.exp_preced_1()
  end
end

function Grammar.exp_preced_2 ()
  Grammar.exp_preced_3()
  local token = Parser.Peek()
  if (token and token.code == tokens.K_AND) then
    Match(tokens.K_AND)
    Grammar.exp_preced_2()
  end
end

function Grammar.exp_preced_3 ()
  Grammar.exp_preced_4()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_="]) then
    Match(tokens["OP_="])
    Grammar.exp_preced_3()
  elseif (token and token.code == tokens["OP_<>"]) then
    Match(tokens["OP_<>"])
    Grammar.exp_preced_3()
  end
end

function Grammar.exp_preced_4 ()
  Grammar.exp_preced_5()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_>"]) then
    Match(tokens["OP_>"])
    Grammar.exp_preced_4()
  elseif (token and token.code == tokens["OP_<"]) then
    Match(tokens["OP_<"])
    Grammar.exp_preced_4()
  elseif (token and token.code == tokens["OP_>="]) then
    Match(tokens["OP_>="])
    Grammar.exp_preced_4()
  elseif (token and token.code == tokens["OP_<="]) then
    Match(tokens["OP_<="])
    Grammar.exp_preced_4()
  end
end

function Grammar.exp_preced_5 ()
  Grammar.exp_preced_6()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_+"]) then
    Match(tokens["OP_+"])
    Grammar.exp_preced_5()
  elseif (token and token.code == tokens["OP_-"]) then
    Match(tokens["OP_-"])
    Grammar.exp_preced_5()
  end
end

function Grammar.exp_preced_6 ()
  Grammar.exp_preced_7()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_*"]) then
    Match(tokens["OP_*"])
    Grammar.exp_preced_6()
  elseif (token and token.code == tokens["OP_/"]) then
    Match(tokens["OP_/"])
    Grammar.exp_preced_6()
  end
end

function Grammar.exp_preced_7 ()
  Grammar.exp_preced_8()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_-"]) then
    Match(tokens["OP_-"])
    Grammar.exp_preced_6()
  end
end

function Grammar.exp_preced_8 ()
  Grammar.exp_preced_9()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_("]) then
    Match(tokens["OP_("])
    Grammar.exp()
    Match(tokens["OP_)"])
  end
end

function Grammar.exp_preced_9 ()
  local token = Parser.Peek()
  if (token and token.code == tokens.NUMBER) then
    Match(tokens.NUMBER)
  elseif (token and token.code == tokens.STRING) then
    Match(tokens.STRING)
  elseif (token and token.code == tokens.K_TRUE) then
    Match(tokens.K_TRUE)
  elseif (token and token.code == tokens.K_FALSE) then
    Match(tokens.K_FALSE)
  elseif (token and token.code == tokens.K_NEW) then
    Match(tokens.K_NEW)
    Match(tokens["OP_["])
    Grammar.exp()
    Match(tokens["OP_]"])
    Grammar.tipo()
  elseif (token and token.code == tokens.K_NOT) then
    Match(tokens.K_NOT)
    Grammar.exp()
  elseif (token and token.code == tokens.ID) then
    local token2 = Parser.Peek2()
    if (token2 and token2.code == tokens["OP_("]) then
      Grammar.chamada()
    else
      Grammar.var()
    end
  else
    Error(token.line or nil)
  end
end

-- funcao    → 'fun' ID '(' params ')' [ ':' tipo ] nl
--                bloco
--             'end' nl
function Grammar.funcao ()
  if (_DEBUG) then print("LAN :: Grammar_funcao") end
  Match(tokens.K_FUN)
  Match(tokens.ID)
  Match(tokens["OP_("])
  Grammar.params()
  Match(tokens["OP_)"])
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_:"]) then
    Match(tokens["OP_:"])
    Grammar.tipo()
  end
  Grammar.nl()
  Grammar.bloco()
  Match(tokens.K_END)
  Grammar.nl()
end

-- global    → declvar nl
function Grammar.global ()
  if (_DEBUG) then print("LAN :: Grammar_global") end
  Grammar.declvar()
  Grammar.nl()
end

-- listaexp  → /*vazio*/ | exp { ',' exp }
function Grammar.listaexp ()
  if (_DEBUG) then print("LAN :: Grammar_listaexp") end
  local token = Parser.Peek()
  if (token and token.code ~= tokens["OP_)"]) then
    Grammar.exp()
    while (true) do
      token = Parser.Peek()
      if (token and token.code == tokens["OP_,"]) then
        Match(tokens["OP_,"])
        Grammar.exp()
      else
        break
      end
    end
  end
end

-- nl        → NL { NL }
function Grammar.nl()
  if (_DEBUG) then print("LAN :: Grammar_nl") end
  Match(tokens.LINE_END)
  while (true) do
    local token = Parser.Peek()
    if (token and token.code == tokens.LINE_END) then
      Match(tokens.LINE_END)
    else
      break
    end
  end
end

-- parametro → ID ':' tipo
function Grammar.parametro ()
  if (_DEBUG) then print("LAN :: Grammar_parametro") end
  Match(tokens.ID)
  Match(tokens["OP_:"])
  Grammar.tipo()
end

-- params    → /*vazio*/ | parametro { ',' parametro }
function Grammar.params ()
  if (_DEBUG) then print("LAN :: Grammar_params") end
  local token = Parser.Peek()
  if (token and token.code ~= tokens["OP_)"]) then
    Grammar.parametro()
    while (true) do
      token = Parser.Peek()
      if (token and token.code == tokens["OP_,"]) then
        Match(tokens["OP_,"])
        Grammar.parametro()
      else
        break
      end
    end
  end
end

-- programa  → { NL } decl { decl }
function Grammar.programa ()
  if (_DEBUG) then print("LAN :: Grammar_programa") end
  local token = Parser.Peek()
  if (token and token.code == tokens.LINE_END) then
    Grammar.nl()
  end
  token = Parser.Peek()
  if (token and 
      token.code == tokens.K_FUN or
      token.code == tokens.ID) then
    Grammar.decl()
    while (true) do
      token = Parser.Peek()
      if (token) then
        Grammar.decl()
      else
        break
      end
    end
  else
    Error(token.line or nil)
  end
end

-- tipo      → tipobase | '[' ']' tipo
function Grammar.tipo ()
  if (_DEBUG) then print("LAN :: Grammar_tipo") end
  local token = Parser.Peek()
  if (token and
      token.code == tokens.K_INT or
      token.code == tokens.K_BOOL or
      token.code == tokens.K_CHAR or
      token.code == tokens.K_STRING) then
    Grammar.tipobase()
  elseif (token and token.code == tokens["OP_["]) then
    Match(tokens["OP_["])
    Match(tokens["OP_]"])
    Grammar.tipo()
  else
    Error(token.line or nil)
  end
end

-- tipobase  → 'int' | 'bool' | 'char' | 'string'
function Grammar.tipobase ()
  if (_DEBUG) then print("LAN :: Grammar_tipobase") end
  local token = Parser.Peek()
  if (token and token.code == tokens.K_INT) then
    Match(tokens.K_INT)
  elseif (token and token.code == tokens.K_BOOL) then
    Match(tokens.K_BOOL)
  elseif (token and token.code == tokens.K_CHAR) then
    Match(tokens.K_CHAR)
  elseif (token and token.code == tokens.K_STRING) then
    Match(tokens.K_STRING)
  else
    Error(token.line or nil)
  end
end

-- var       → ID | var '[' exp ']'
function Grammar.var ()
  if (_DEBUG) then print("LAN :: Grammar_var") end
  Match(tokens.ID)
  while (true) do
    local token = Parser.Peek()
    if (token and token.code == tokens["OP_["]) then
      Match(tokens["OP_["])
      Grammar.exp()
      Match(tokens["OP_]"])
    else
      break
    end
  end
end


--==============================================================================
-- Public Methods
--==============================================================================

function Language.Start (func_advance, func_peek, func_peek2)
  if (_DEBUG) then print("LAN :: Start") end
  assert(type(func_advance) == "function")
  assert(type(func_peek) == "function")
  assert(type(func_peek2) == "function")
  Parser.Advance = func_advance
  Parser.Peek = func_peek
  Parser.Peek2 = func_peek2
  local ok, msg = pcall(function () Grammar.programa() end)
  if (not ok) then
    return false, msg
  end
  return true
end


--==============================================================================
-- Return
--==============================================================================

return Language


--==============================================================================
-- Grammar
--==============================================================================

-- programa  → { NL } decl { decl }
--
-- decl      → funcao | global
--
-- nl        → NL { NL }
--
-- global    → declvar nl
--
-- funcao    → 'fun' ID '(' params ')' [ ':' tipo ] nl
--                bloco
--             'end' nl
--
-- bloco     → { declvar nl }
--             { comando nl }
--
-- params    → /*vazio*/ | parametro { ',' parametro }
--
-- parametro → ID ':' tipo
--
-- tipo      → tipobase | '[' ']' tipo
--
-- tipobase  → 'int' | 'bool' | 'char' | 'string'
--
-- declvar   → ID ':' tipo
--
-- comando   → cmdif | cmdwhile | cmdatrib | cmdreturn | chamada 
--
-- cmdif     → 'if' exp nl
--                bloco
--             { 'else' 'if' exp nl
--                bloco
--             }
--             [ 'else' nl
--                bloco
--             ]
--             'end'
--
-- cmdwhile  → 'while' exp nl
--                bloco
--             'loop'
--
-- cmdatrib  → var '=' exp
--
-- chamada   → ID '(' listaexp ')'
--
-- listaexp  → /*vazio*/ | exp { ',' exp }
--
-- cmdreturn → 'return' exp | 'return'
--
-- var       → ID | var '[' exp ']'
--
-- exp       → LITNUMERAL
--           | LITSTRING
--           | TRUE
--           | FALSE
--           | var
--           | 'new' '[' exp ']' tipo
--           | '(' exp ')'
--           | chamada
--           | exp '+' exp
--           | exp '-' exp
--           | exp '*' exp
--           | exp '/' exp
--           | exp '>' exp
--           | exp '<' exp
--           | exp '>=' exp
--           | exp '<=' exp
--           | exp '=' exp
--           | exp '<>' exp
--           | exp 'and' exp
--           | exp 'or' exp
--           | 'not' exp
--           | '-' exp