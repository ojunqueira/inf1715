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

local mini_rules = {}


--==============================================================================
-- Private Methods
--==============================================================================

function Program ()
end


--==============================================================================
-- Initialize
--==============================================================================



--==============================================================================
-- Public Methods
--==============================================================================

--GetRules:
--  parameters:
--  return:
--    [1] $table - table with mini-0 language rules
function Language.GetRules ()
  if (_DEBUG) then print("LAN :: GetRules") end
  table.insert(mini_rules, Program)
  return mini_rules
end


--==============================================================================
-- Return
--==============================================================================

return Language