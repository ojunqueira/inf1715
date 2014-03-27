--[[
programa  → { NL } decl { decl }
decl      → funcao | global
nl        → NL { NL }
global    → declvar nl
funcao    → 'fun' ID '(' params ')' [ ':' tipo ] nl
               bloco
            'end' nl
bloco     → { declvar nl }
            { comando nl }
params    → /*vazio*/ | parametro { ',' parametro }
parametro → ID ':' tipo
tipo      → tipobase | '[' ']' tipo
tipobase  → 'int' | 'bool' | 'char' | 'string'
declvar   → ID ':' tipo
comando   → cmdif | cmdwhile | cmdatrib | cmdreturn | chamada 
cmdif     → 'if' exp nl
               bloco
            { 'else' 'if' exp nl
               bloco
            }
            [ 'else' nl
               bloco
            ]
            'end'
cmdwhile  → 'while' exp nl
               bloco
            'loop'
cmdatrib  → var '=' exp
chamada   → ID '(' listaexp ')'
listaexp  → /*vazio*/ | exp { ',' exp }
cmdreturn → 'return' exp | 'return'
var       → ID | var '[' exp ']'
exp       → LITNUMERAL
          | LITSTRING
          | TRUE
          | FALSE
          | var
          | 'new' '[' exp ']' tipo
          | '(' exp ')'
          | chamada
          | exp '+' exp
          | exp '-' exp
          | exp '*' exp
          | exp '/' exp
          | exp '>' exp
          | exp '<' exp
          | exp '>=' exp
          | exp '<=' exp
          | exp '=' exp
          | exp '<>' exp
          | exp 'and' exp
          | exp 'or' exp
          | 'not' exp
          | '-' exp
]]

--==============================================================================
-- Dependency
--==============================================================================

assert(token_codes)



--==============================================================================
-- Data Structure
--==============================================================================

local Language = {}

local Advance

local Peek

local function Error (line)
  error("Syntax error at line " .. line .. ".", 0)
end

local function Match (token, code)
  if (token.code ~= code) then

  else
    error("Expected " .. code .. " got " .. token.code .. " at line " .. token.line, 0)
  end
end


--==============================================================================
-- Private Methods
--==============================================================================

local function Grammar_decl ()
  if (_DEBUG) then print("LAN :: Grammar_decl") end
end

local function Grammar_nl()
  if (_DEBUG) then print("LAN :: Grammar_nl") end
  local token = Peek()
  if (token.code == token_codes.LINE_END) then
    Advance()
    token = Peek()
    while (token.code == token_codes.LINE_END) do
      Advance()
      token = Peek()
    end
  else
    Error(token.line)
  end
end

local function Grammar_programa ()
  if (_DEBUG) then print("LAN :: Grammar_programa") end
  local token = Peek()
  if (token.code == token_codes.LINE_END) then
    Grammar_nl()
  end
  Grammar_decl()

end


--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

function Language.Start (func_advance, func_peek)
  if (_DEBUG) then print("LAN :: Start") end
  assert(type(func_advance) == "function")
  assert(type(func_peek) == "function")
  Advance = func_advance
  Peek = func_peek
  Grammar_programa()
  return true
end


--==============================================================================
-- Return
--==============================================================================

return Language