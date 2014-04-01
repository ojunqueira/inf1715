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


--==============================================================================
-- Dependency
--==============================================================================

assert(token_codes)


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
  if (token.code == code) then
    print("    Match code ", code)
    Parser.Advance()
  else
    error("Expected " .. code .. " got " .. token.code .. " at line " .. token.line, 0)
  end
end


--==============================================================================
-- Initialize
--==============================================================================

function Grammar.bloco ()
  if (_DEBUG) then print("LAN :: Grammar_bloco") end
  while (true) do
    local token = Parser.Peek()
    local token2 = Parser.Peek2()
    if (token.code == token_codes.ID and token2.code == token_codes["OP_:"]) then
      Grammar.declvar()
      Grammar.nl()
    else
      break
    end
  end
  while (true) do
    local token = Parser.Peek()
    if (token.code == token_codes.K_ID or
        token.code == token_codes.K_IF or
        token.code == token_codes.K_WHILE or
        token.code == token_codes.K_RETURN) then
      Grammar.comando()
      Grammar.nl()
    else
      break
    end
  end
end

function Grammar.chamada ()
  if (_DEBUG) then print("LAN :: Grammar_chamada") end
  Match(token_codes.ID)
  Match(token_codes["OP_("])
  Grammar.listaexp()
  Match(token_codes["OP_)"])
end

function Grammar.cmdatrib ()
  if (_DEBUG) then print("LAN :: Grammar_cmdatrib") end
end

function Grammar.cmdif ()
  if (_DEBUG) then print("LAN :: Grammar_cmdif") end
  Match(token_codes.K_IF)
  Grammar.exp()
  Grammar.nl()
  Grammar.bloco()
  while (true) do
    local token = Parser.Peek()
    local token2 = Parser.Peek()
    if (token.code == token_codes.K_ELSE and token2.code == token_codes.K_IF) then
      Match(token_codes.K_ELSE)
      Match(token_codes.K_IF)
      Grammar.exp()
      Grammar.nl()
      Grammar.bloco()
    else
      break
    end
  end
  local token = Parser.Peek()
  if (token.code == token_codes.K_ELSE) then
    Match(token_codes.K_ELSE)
    Grammar.nl()
    Grammar.bloco()
  end
  Match(token_codes.K_END)
end

function Grammar.cmdreturn ()
  if (_DEBUG) then print("LAN :: Grammar_cmdreturn") end
  Match(token_codes.K_RETURN)
  local token = Parser.Peek()
  -- Valido isso abaixo? ou devemos enumerar todas as condicoes de EXP ?
  if (token.code ~= token_codes.LINE_END) then
    Grammar.exp()
  end
end

function Grammar.cmdwhile ()
  if (_DEBUG) then print("LAN :: Grammar_cmdwhile") end
  Match(token_codes.K_WHILE)
  Grammar.exp()
  Grammar.nl()
  Grammar.bloco()
  Match(token_codes.K_LOOP)
end

function Grammar.comando ()
  if (_DEBUG) then print("LAN :: Grammar_comando") end
  local token = Parser.Peek()
  if (token.code == token_codes.K_IF) then
    Grammar.cmdif()
  elseif (token.code == token_codes.K_WHILE) then
    Grammar.cmdwhile()
  elseif (token.code == token_codes.K_RETURN) then
    Grammar.cmdreturn()
  elseif (token.code == token_codes.ID) then
    local token2 = Parser.Peek2()
    if (token2.code == token_codes["OP_:"]) then
      Grammar.declvar()
    elseif (token2.code == token_codes["OP_("]) then
      Grammar.chamada()
    elseif (token2.code == token_codes["OP_="] or
            token2.code == token_codes["OP_["]) then
      Grammar.cmdatrib()
    else
      Error(token.line)
    end
  else
    Error(token.line)
  end
end

function Grammar.decl ()
  if (_DEBUG) then print("LAN :: Grammar_decl") end
  local token = Parser.Peek()
  if (token.code == token_codes.K_FUN) then
    Grammar.funcao()
  elseif (token.code == token_codes.ID) then
    Grammar.global()
  else
    Error(token.line)
  end
end

function Grammar.declvar ()
  if (_DEBUG) then print("LAN :: Grammar_declvar") end
  Match(token_codes.ID)
  Match(token_codes["OP_:"])
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
  local token = Parser.Peek()
  local token2 = Parser.Peek2()
  -- TO IMPLEMENT
end

function Grammar.funcao ()
  if (_DEBUG) then print("LAN :: Grammar_funcao") end
  Match(token_codes.K_FUN)
  Match(token_codes.ID)
  Match(token_codes["OP_("])
  Grammar.params()
  Match(token_codes["OP_)"])
  local token = Parser.Peek()
  if (token.code == token_codes["OP_:"]) then
    Match(token_codes["OP_:"])
    Grammar.tipo()
  end
  Grammar.nl()
  Grammar.bloco()
  Match(token_codes.K_END)
  Grammar.nl()
end

function Grammar.global ()
  if (_DEBUG) then print("LAN :: Grammar_global") end
  Grammar.declvar()
  Grammar.nl()
end

function Grammar.listaexp ()
  if (_DEBUG) then print("LAN :: Grammar_listaexp") end
end

function Grammar.nl()
  if (_DEBUG) then print("LAN :: Grammar_nl") end
  Match(token_codes.LINE_END)
  while (true) do
    local token = Parser.Peek()
    if (token.code == token_codes.LINE_END) then
      Match(token_codes.LINE_END)
    else
      break
    end
  end
end

function Grammar.parametro ()
  if (_DEBUG) then print("LAN :: Grammar_parametro") end
  Match(token_codes.ID)
  Match(token_codes["OP_:"])
  Grammar.tipo()
end

function Grammar.params ()
  if (_DEBUG) then print("LAN :: Grammar_params") end
  local token
  token = Parser.Peek()
  if (token.code == token_codes["OP_)"]) then
  elseif (token.code == token_codes.ID) then
    Grammar.parametro()
    while (true) do
      token = Parser.Peek()
      if (token.code == token_codes["OP_,"]) then
        Match(token_codes["OP_,"])
        Grammar.parametro()
      else
        break
      end
    end
  else
    Error(token.line)
  end
end

function Grammar.programa ()
  if (_DEBUG) then print("LAN :: Grammar_programa") end
  local token = Parser.Peek()
  if (token.code == token_codes.LINE_END) then
    Grammar.nl()
  elseif (token.code == token_codes.K_FUN or
          token.code == token_codes.ID) then
    Grammar.decl()
  else
    Error(token.line)
  end
end

function Grammar.tipo ()
  if (_DEBUG) then print("LAN :: Grammar_tipo") end
  local token
  token = Parser.Peek()
  if (token.code == token_codes.K_INT or
      token.code == token_codes.K_BOOL or
      token.code == token_codes.K_CHAR or
      token.code == token_codes.K_STRING) then
    Grammar.tipobase()
  elseif (token.code == token_codes["OP_["]) then
    Match(token_codes["OP_["])
    Match(token_codes["OP_]"])
    Grammar.tipo()
  else
    Error(token.line)
  end
end

function Grammar.tipobase ()
  if (_DEBUG) then print("LAN :: Grammar_tipobase") end
  local token
  token = Parser.Peek()
  if (token.code == token_codes.K_INT) then
    Match(token_codes.K_INT)
  elseif (token.code == token_codes.K_BOOL) then
    Match(token_codes.K_BOOL)
  elseif (token.code == token_codes.K_CHAR) then
    Match(token_codes.K_CHAR)
  elseif (token.code == token_codes.K_STRING) then
    Match(token_codes.K_STRING)
  else
    Error(token.line)
  end
end

function Grammar.var ()
  if (_DEBUG) then print("LAN :: Grammar_var") end
  -- TO IMPLEMENT
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
  Grammar.programa()
  return true
end


--==============================================================================
-- Return
--==============================================================================

return Language