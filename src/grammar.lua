--==============================================================================
-- Debug
--==============================================================================

local printTokensMatch = false


--==============================================================================
-- Dependency
--==============================================================================

local TokensCode  = require "lib/tokens_code"
local AST         = require "src/ast"


--==============================================================================
-- Data Structure
--==============================================================================

local Class = {}

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
local tokens = TokensCode.GetList()


--==============================================================================
-- Private Methods
--==============================================================================

--Error: Callback of errors that occurs during syntax analysis
--  Parameters:
--    [1] $number - line number of grammar syntax error
--  Return:
local function Error (line)
  error(string.format("@%d syntactic error.", line), 0)
end

--Match: Receives a token code number and compare with next avaiable token received from lexical
--  Parameters:
--    [1] $number - Next expected token code number
--  Return:
--    [1] $string - Token value/name
--    [2] $number - Token line number
local function Match (code)
  if (_DEBUG) then print("LAN :: Match") end
  local token = Parser.Peek()
  if (token and token.code == code) then
    if (_DEBUG or printTokensMatch) then
      print(string.format("    Match code '%10s' %s", TokensCode.GetName(code), token.token))
    end
    Parser.Advance()
    return token.token, token.line
  else
    if (token) then
      error(string.format("@%d syntactic error: expected token '%s' got token '%s'.", token.line, TokensCode.GetName(code), TokensCode.GetName(token.code)), 0)
    else
      error(string.format("@EOF syntactic error: expected token '%s' got 'END_OF_TOKENS'.", TokensCode.GetName(code)), 0)
    end
  end
end

--Block:
--  syntax:
--    bloco     → { declvar nl }
--                { comando nl }
--  parameters:
--  return:
--    [1] $table  - List of DECLARE, [...] nodes
function Grammar.Block ()
  if (_DEBUG) then print("LAN :: Grammar_bloco") end
  local list = {}
  while (true) do
    local token = Parser.Peek()
    local token2 = Parser.Peek2()
    if (token and token2 and token.code == tokens.ID and token2.code == tokens["OP_:"]) then
      table.insert(list, Grammar.DeclareVar())
      Grammar.LineEnd()
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
      table.insert(list, Grammar.Command() or {}) -- RETIRAR OPCAO {}
      Grammar.LineEnd()
    else
      break
    end
  end
  return list
end

--Call:
--  syntax:
--    chamada   → ID '(' listaexp ')'
--  parameters:
--  return:
--    [1] $table  - CALL node
function Grammar.Call ()
  if (_DEBUG) then print("LAN :: Grammar_chamada") end
  local name, line, exps
  name, line = Match(tokens.ID)
  Match(tokens["OP_("])
  exps = Grammar.ListExpressions()
  Match(tokens["OP_)"])
  return AST.NewCallNode(line, name, exps)
end

--CmdAttrib:
--  syntax:
--    cmdatrib  → var '=' exp
--  parameters:
--  return:
--    [1] $table  - ATTRIBUTION node
function Grammar.CmdAttrib ()
  if (_DEBUG) then print("LAN :: Grammar_cmdatrib") end
  local var, expression
  var = Grammar.Var()
  Match(tokens["OP_="])
  expression = Grammar.Expression()
  return AST.NewAttributionNode(var, expression)
end

--CmdIf:
--  syntax:
--    cmdif     → 'if' exp nl
--                    bloco
--                { 'else' 'if' exp nl
--                    bloco
--                }
--                [ 'else' nl
--                    bloco
--                ]
--                'end'
function Grammar.CmdIf ()
  if (_DEBUG) then print("LAN :: Grammar_cmdif") end
  local line, condition, block, else_block
  local elseif_nodes = {}
  _, line = Match(tokens.K_IF)
  condition = Grammar.Expression()
  Grammar.LineEnd()
  block = Grammar.Block()
  while (true) do
    local token = Parser.Peek()
    local token2 = Parser.Peek2()
    if (token and token2 and token.code == tokens.K_ELSE and token2.code == tokens.K_IF) then
      local line, condition, block
      _, line = Match(tokens.K_ELSE)
      Match(tokens.K_IF)
      condition = Grammar.Expression()
      Grammar.LineEnd()
      block = Grammar.Block()
      table.insert(elseif_nodes, AST.NewElseIfNode(line, condition, block))
    else
      break
    end
  end
  local token = Parser.Peek()
  if (token and token.code == tokens.K_ELSE) then
    Match(tokens.K_ELSE)
    Grammar.LineEnd()
    else_block = Grammar.Block()
  end
  Match(tokens.K_END)
  return AST.NewIfNode(line, condition, block, elseif_nodes, else_block)
end

--CmdReturn:
--  syntax:
--    cmdreturn → 'return' exp | 'return'
--  parameters:
--  return:
--    [1] $table  - RETURN node
function Grammar.CmdReturn ()
  if (_DEBUG) then print("LAN :: Grammar_cmdreturn") end
  local line, exp
  _, line = Match(tokens.K_RETURN)
  local token = Parser.Peek()
  if (token and token.code ~= tokens.LINE_END) then
    exp = Grammar.Expression()
  end
  return AST.NewReturnNode(line, exp)
end

--CmdWhile:
--  syntax:
--    cmdwhile  → 'while' exp nl
--                    bloco
--                'loop'
--  parameters:
--  return:
--    [1] $table  - WHILE node
function Grammar.CmdWhile ()
  if (_DEBUG) then print("LAN :: Grammar_cmdwhile") end
  local line, exp, block
  _, line = Match(tokens.K_WHILE)
  exp = Grammar.Expression()
  Grammar.LineEnd()
  block = Grammar.Block()
  Match(tokens.K_LOOP)
  return AST.NewWhileNode(line, exp, block)
end

--Command:
--  syntax:
--    comando   → cmdif | cmdwhile | cmdatrib | cmdreturn | chamada
--  parameters:
--  return:
--    [1] $table - List of DECLARE, CMDATRIB, CMDIF, CMDRETURN, CMDWHILE, [...] nodes
function Grammar.Command ()
  if (_DEBUG) then print("LAN :: Grammar_comando") end
  local token = Parser.Peek()
  if (token and token.code == tokens.K_IF) then
    return Grammar.CmdIf()
  elseif (token and token.code == tokens.K_WHILE) then
    return Grammar.CmdWhile()
  elseif (token and token.code == tokens.K_RETURN) then
    return Grammar.CmdReturn()
  elseif (token and token.code == tokens.ID) then
    local token2 = Parser.Peek2()
    if (token2 and token2.code == tokens["OP_("]) then
      return Grammar.Call()
    elseif (token2 and 
            token2.code == tokens["OP_="] or
            token2.code == tokens["OP_["]) then
      return Grammar.CmdAttrib()
    else
      Error(token and token.line or 0)
    end
  else
    Error(token and token.line or 0)
  end
end

--Declare:
--  syntax:
--    decl      → funcao | global
--  parameters:
--  return:
--    [1] $table  - DECLARE or FUNCTION node
function Grammar.Declare ()
  if (_DEBUG) then print("LAN :: Grammar_decl") end
  local decl
  local token = Parser.Peek()
  if (token and token.code == tokens.K_FUN) then
    decl = Grammar.Function(parent_node)
  elseif (token and token.code == tokens.ID) then
    decl = Grammar.Global(parent_node)
  else
    Error(token and token.line or 0)
  end
  return decl
end

--DeclareVar:
--  syntax:
--    declvar   → ID ':' tipo
--  parameters:
--  return:
--    [1] $table  - DECLARE node
function Grammar.DeclareVar ()
  if (_DEBUG) then print("LAN :: Grammar_declvar") end
  local name, line, typebase, array
  name, line = Match(tokens.ID)
  Match(tokens["OP_:"])
  typebase, array = Grammar.Type()
  return AST.NewDeclVarNode(line, name, typebase, array)
end

--Expression:
--  syntax:
--    exp       → LITNUMERAL
--              | LITSTRING
--              | TRUE
--              | FALSE
--              | var
--              | 'new' '[' exp ']' tipo
--              | '(' exp ')'
--              | chamada
--              | exp '+' exp
--              | exp '-' exp
--              | exp '*' exp
--              | exp '/' exp
--              | exp '>' exp
--              | exp '<' exp
--              | exp '>=' exp
--              | exp '<=' exp
--              | exp '=' exp
--              | exp '<>' exp
--              | exp 'and' exp
--              | exp 'or' exp
--              | 'not' exp
--              | '-' exp
function Grammar.Expression ()
  if (_DEBUG) then print("LAN :: Grammar_exp") end
  local exp = Grammar.ExpressionLevel1()
  if (not exp) then
    Error(0)
  end
  return exp
end

function Grammar.ExpressionLevel1 ()
  local left = Grammar.ExpressionLevel2()
  local token = Parser.Peek()
  if (token and token.code == tokens.K_OR) then
    Match(tokens.K_OR)
    return AST.NewOperatorNode(token.line, left, "or", Grammar.ExpressionLevel1())
  end
  return left
end

function Grammar.ExpressionLevel2 ()
  local left = Grammar.ExpressionLevel3()
  local token = Parser.Peek()
  if (token and token.code == tokens.K_AND) then
    Match(tokens.K_AND)
    return AST.NewOperatorNode(token.line, left, "and", Grammar.ExpressionLevel2())
  end
  return left
end

function Grammar.ExpressionLevel3 ()
  local left = Grammar.ExpressionLevel4()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_="]) then
    Match(tokens["OP_="])
    return AST.NewOperatorNode(token.line, left, "=", Grammar.ExpressionLevel3())
  elseif (token and token.code == tokens["OP_<>"]) then
    Match(tokens["OP_<>"])
    return AST.NewOperatorNode(token.line, left, "<>", Grammar.ExpressionLevel3())
  end
  return left
end

function Grammar.ExpressionLevel4 ()
  local left = Grammar.ExpressionLevel5()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_>"]) then
    Match(tokens["OP_>"])
    return AST.NewOperatorNode(token.line, left, ">", Grammar.ExpressionLevel4())
  elseif (token and token.code == tokens["OP_<"]) then
    Match(tokens["OP_<"])
    return AST.NewOperatorNode(token.line, left, "<", Grammar.ExpressionLevel4())
  elseif (token and token.code == tokens["OP_>="]) then
    Match(tokens["OP_>="])
    return AST.NewOperatorNode(token.line, left, ">=", Grammar.ExpressionLevel4())
  elseif (token and token.code == tokens["OP_<="]) then
    Match(tokens["OP_<="])
    return AST.NewOperatorNode(token.line, left, "<=", Grammar.ExpressionLevel4())
  end
  return left
end

function Grammar.ExpressionLevel5 ()
  local left = Grammar.ExpressionLevel6()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_+"]) then
    Match(tokens["OP_+"])
    return AST.NewOperatorNode(token.line, left, "+", Grammar.ExpressionLevel5())
  elseif (token and token.code == tokens["OP_-"]) then
    Match(tokens["OP_-"])
    return AST.NewOperatorNode(token.line, left, "-", Grammar.ExpressionLevel5())
  end
  return left
end

function Grammar.ExpressionLevel6 ()
  local left = Grammar.ExpressionLevel7()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_*"]) then
    Match(tokens["OP_*"])
    return AST.NewOperatorNode(token.line, left, "*", Grammar.ExpressionLevel6())
  elseif (token and token.code == tokens["OP_/"]) then
    Match(tokens["OP_/"])
    return AST.NewOperatorNode(token.line, left, "/", Grammar.ExpressionLevel6())
  end
  return left
end

function Grammar.ExpressionLevel7 ()
  local token = Parser.Peek()
  if (token and token.code == tokens.NUMBER) then
    return AST.NewLiteralNode(token.line, "int", Match(tokens.NUMBER))
  elseif (token and token.code == tokens.STRING) then
    return AST.NewLiteralNode(token.line, "string", Match(tokens.STRING))
  elseif (token and token.code == tokens.K_TRUE) then
    return AST.NewLiteralNode(token.line, "bool", Match(tokens.K_TRUE))
  elseif (token and token.code == tokens.K_FALSE) then
    return AST.NewLiteralNode(token.line, "bool", Match(tokens.K_FALSE))
  elseif (token and token.code == tokens.K_NEW) then
    Match(tokens.K_NEW)
    Match(tokens["OP_["])
    local exp = Grammar.Expression()
    Match(tokens["OP_]"])
    local typebase, dimension = Grammar.Type()
    return AST.NewNewVarNode(token.line, exp, typebase, dimension)
  elseif (token and token.code == tokens.K_NOT) then
    Match(tokens.K_NOT)
    local exp = Grammar.ExpressionLevel7()
    return AST.NewNegateNode(token.line, exp)
  elseif (token and token.code == tokens.ID) then
    local node
    local token2 = Parser.Peek2()
    if (token2 and token2.code == tokens["OP_("]) then
      return Grammar.Call()
    else
      return Grammar.Var()
    end
  elseif (token and token.code == tokens["OP_("]) then
    Match(tokens["OP_("])
    local exp = Grammar.Expression()
    Match(tokens["OP_)"])
    return exp
  elseif (token and token.code == tokens["OP_-"]) then
    Match(tokens["OP_-"])
    return AST.NewUnaryNode(token.line, Grammar.ExpressionLevel7())
  else
    Error(token and token.line or 0)
  end
end

--Function:
--  syntax:
--    funcao    → 'fun' ID '(' params ')' [ ':' tipo ] nl
--                    bloco
--                'end' nl
--  parameters:
--  return:
--    [1] $table  - FUNCTION node
function Grammar.Function ()
  if (_DEBUG) then print("LAN :: Grammar_funcao") end
  local name, line, params, ret_type, array_size, block
  Match(tokens.K_FUN)
  name, line = Match(tokens.ID)
  Match(tokens["OP_("])
  params = Grammar.Parameters()
  Match(tokens["OP_)"])
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_:"]) then
    Match(tokens["OP_:"])
    ret_type, array_size = Grammar.Type()
  end
  Grammar.LineEnd()
  block = Grammar.Block()
  Match(tokens.K_END)
  Grammar.LineEnd()
  return AST.NewFunctionNode(line, name, params, ret_type, array_size, block)
end

--Global:
--  syntax:
--    global    → declvar nl
--  parameters:
--  return:
--    [1] $table  - DECLARE node
function Grammar.Global ()
  if (_DEBUG) then print("LAN :: Grammar_global") end
  local node = Grammar.DeclareVar()
  Grammar.LineEnd()
  return node
end

--ListExpressions:
--  syntax:
--    listaexp  → /*vazio*/ | exp { ',' exp }
--  parameters:
--  return:
--    [1] $table  - List of EXPRESSION nodes
function Grammar.ListExpressions ()
  if (_DEBUG) then print("LAN :: Grammar_listaexp") end
  local list = {}
  local token = Parser.Peek()
  if (token and token.code ~= tokens["OP_)"]) then
    table.insert(list, Grammar.Expression())
    while (true) do
      token = Parser.Peek()
      if (token and token.code == tokens["OP_,"]) then
        Match(tokens["OP_,"])
        table.insert(list, Grammar.Expression())
      else
        break
      end
    end
  end
  return list
end

--LineEnd:
--  syntax:
--    nl        → NL { NL }
function Grammar.LineEnd()
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

--Parameter:
--  syntax:
--    parametro → ID ':' tipo
--  parameters:
--  return:
--    [1] $table  - PARAMETER node
function Grammar.Parameter ()
  if (_DEBUG) then print("LAN :: Grammar_parametro") end
  local name, line, typebase, array_size
  name, line = Match(tokens.ID)
  Match(tokens["OP_:"])
  typebase, array_size = Grammar.Type()
  return AST.NewParameterNode(line, name, typebase, array_size)
end

--Parameters:
--  syntax:
--    params    → /*vazio*/ | parametro { ',' parametro }
--  parameters:
--  return:
--    [1] $table  - List of PARAMETER nodes
function Grammar.Parameters ()
  if (_DEBUG) then print("LAN :: Grammar_params") end
  local list = {}
  local token = Parser.Peek()
  if (token and token.code ~= tokens["OP_)"]) then
    table.insert(list, Grammar.Parameter())
    while (true) do
      token = Parser.Peek()
      if (token and token.code == tokens["OP_,"]) then
        Match(tokens["OP_,"])
        table.insert(list, Grammar.Parameter())
      else
        break
      end
    end
  end
  return list
end

--Program:
--  syntax:
--    programa  → { NL } decl { decl }
function Grammar.Program ()
  if (_DEBUG) then print("LAN :: Grammar_programa") end
  local node = {}
  local token = Parser.Peek()
  if (token and token.code == tokens.LINE_END) then
    Grammar.LineEnd()
  end
  token = Parser.Peek()
  if (token and (token.code == tokens.K_FUN or token.code == tokens.ID)) then
    table.insert(node, Grammar.Declare())
    while (true) do
      token = Parser.Peek()
      if (token) then
        table.insert(node, Grammar.Declare())
      else
        break
      end
    end
  else
    Error(token and token.line or 0)
  end
  AST.NewProgramNode(node)
end

--Type:
--  syntax:
--    tipo      → tipobase | '[' ']' tipo
--  parameters:
--  return:
--    [1] $typebase
--    [2] $array_size
function Grammar.Type (array_size)
  if (_DEBUG) then print("LAN :: Grammar_tipo") end
  array_size = array_size or 0
  local typebase
  local token = Parser.Peek()
  if (token and
      token.code == tokens.K_INT or
      token.code == tokens.K_BOOL or
      token.code == tokens.K_CHAR or
      token.code == tokens.K_STRING) then
    typebase = Grammar.Typebase()
  elseif (token and token.code == tokens["OP_["]) then
    Match(tokens["OP_["])
    Match(tokens["OP_]"])
    array_size = array_size + 1
    typebase, array_size = Grammar.Type(array_size)
  else
    Error(token and token.line or 0)
  end
  return typebase, array_size
end

--Typebase:
--  syntax:
--    tipobase  → 'int' | 'bool' | 'char' | 'string'
--  parameters:
--  return:
--    [1] $typebase
function Grammar.Typebase ()
  if (_DEBUG) then print("LAN :: Grammar_tipobase") end
  local token = Parser.Peek()
  if (token and token.code == tokens.K_INT) then
    Match(tokens.K_INT)
    return "int"
  elseif (token and token.code == tokens.K_BOOL) then
    Match(tokens.K_BOOL)
    return "bool"
  elseif (token and token.code == tokens.K_CHAR) then
    Match(tokens.K_CHAR)
    return "char"
  elseif (token and token.code == tokens.K_STRING) then
    Match(tokens.K_STRING)
    return "string"
  else
    Error(token and token.line or 0)
  end
end

--Var:
--  syntax:
--    var       → ID | var '[' exp ']'
--  parameters:
--  return:
--    [1] $table - VAR node
function Grammar.Var ()
  if (_DEBUG) then print("LAN :: Grammar_var") end
  local name, line
  local array = {}
  name, line = Match(tokens.ID)
  while (true) do
    local token = Parser.Peek()
    if (token and token.code == tokens["OP_["]) then
      Match(tokens["OP_["])
      table.insert(array, Grammar.Expression())
      Match(tokens["OP_]"])
    else
      break
    end
  end
  return AST.NewVarNode(line, name, array)
end


--==============================================================================
-- Public Methods
--==============================================================================

function Class.Start (func_advance, func_peek, func_peek2)
  if (_DEBUG) then print("LAN :: Start") end
  assert(type(func_advance) == "function")
  assert(type(func_peek) == "function")
  assert(type(func_peek2) == "function")
  Parser.Advance = func_advance
  Parser.Peek = func_peek
  Parser.Peek2 = func_peek2
  local ok, msg = pcall(function () Grammar.Program() end)
  if (not ok) then
    return false, msg
  end
  return true
end


--==============================================================================
-- Return
--==============================================================================

return Class


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