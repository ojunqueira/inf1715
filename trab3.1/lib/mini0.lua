--==============================================================================
-- Debug
--==============================================================================

local printTokensMatch = false


--==============================================================================
-- Dependency
--==============================================================================

local TokensClass = require "lib/tokens"
local ASTClass    = require "lib/syntax_tree"


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

--Error: Callback of errors that occurs during syntax analysis
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
--    [1] $string - Token value/name
--    [2] $number - Token line number
local function Match (code)
  if (_DEBUG) then print("LAN :: Match") end
  local token = Parser.Peek()
  if (token and token.code == code) then
    if (_DEBUG or printTokensMatch) then
      print(string.format("    Match code '%10s' %s", TokensClass.GetTokenName(code), token.token))
    end
    Parser.Advance()
    return token.token, token.line
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
  return ASTClass.NewCallNode(line, name, exps)
end

--CmdAtrib:
--  syntax:
--    cmdatrib  → var '=' exp
function Grammar.CmdAtrib ()
  if (_DEBUG) then print("LAN :: Grammar_cmdatrib") end
  local var, expression
  var = Grammar.Var()
  Match(tokens["OP_="])
  expression = Grammar.Expression()
  return ASTClass.NewCmdAtribNode(var, expression)
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
  Match(tokens.K_IF)
  Grammar.Expression()
  Grammar.LineEnd()
  Grammar.Block()
  while (true) do
    local token = Parser.Peek()
    local token2 = Parser.Peek2()
    if (token and token2 and token.code == tokens.K_ELSE and token2.code == tokens.K_IF) then
      Match(tokens.K_ELSE)
      Match(tokens.K_IF)
      Grammar.Expression()
      Grammar.LineEnd()
      Grammar.Block()
    else
      break
    end
  end
  local token = Parser.Peek()
  if (token and token.code == tokens.K_ELSE) then
    Match(tokens.K_ELSE)
    Grammar.LineEnd()
    Grammar.Block()
  end
  Match(tokens.K_END)
end

--CmdReturn:
--  syntax:
--    cmdreturn → 'return' exp | 'return'
function Grammar.CmdReturn ()
  if (_DEBUG) then print("LAN :: Grammar_cmdreturn") end
  local line, exp
  _, line = Match(tokens.K_RETURN)
  local token = Parser.Peek()
  if (token and token.code ~= tokens.LINE_END) then
    exp = Grammar.Expression()
  end
  return ASTClass.NewCmdReturnNode(line, exp)
end

--CmdWhile:
--  syntax:
--    cmdwhile  → 'while' exp nl
--                    bloco
--                'loop'
function Grammar.CmdWhile ()
  if (_DEBUG) then print("LAN :: Grammar_cmdwhile") end
  local line, exp, block
  _, line = Match(tokens.K_WHILE)
  exp = Grammar.Expression()
  Grammar.LineEnd()
  block = Grammar.Block()
  Match(tokens.K_LOOP)
  return ASTClass.NewCmdWhileNode(line, exp, block)
end

--Command:
--  syntax:
--    comando   → cmdif | cmdwhile | cmdatrib | cmdreturn | chamada
--  parameters:
--  return:
--    [1] $table - List of DECLARE, CMDATRIB, CMDRETURN, CMDWHILE, [...] nodes
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
    if (token2 and token2.code == tokens["OP_:"]) then
      return Grammar.DeclareVar()
    elseif (token2 and token2.code == tokens["OP_("]) then
      return Grammar.Call()
    elseif (token2 and 
            token2.code == tokens["OP_="] or
            token2.code == tokens["OP_["]) then
      return Grammar.CmdAtrib()
    else
      Error(token.line or nil)
    end
  else
    Error(token.line or nil)
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
    Error(token.line or nil)
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
  return ASTClass.NewDeclareNode(line, name, typebase, array)
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
  if exp then
    --util.TablePrint(exp)
    return {exp}
  end
  return {}
end

function Grammar.ExpressionLevel1 ()
  local left = Grammar.ExpressionLevel2()
  local token = Parser.Peek()
  if (token and token.code == tokens.K_OR) then
    Match(tokens.K_OR)
    return {left, Grammar.ExpressionLevel1(), op = "or"}
  end
  return left
end

function Grammar.ExpressionLevel2 ()
  local left = Grammar.ExpressionLevel3()
  local token = Parser.Peek()
  if (token and token.code == tokens.K_AND) then
    Match(tokens.K_AND)
    return {left, Grammar.ExpressionLevel2(), op = "and"}
  end
  return left
end

function Grammar.ExpressionLevel3 ()
  local left = Grammar.ExpressionLevel4()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_="]) then
    Match(tokens["OP_="])
    return {left, Grammar.ExpressionLevel3(), op = "="}
  elseif (token and token.code == tokens["OP_<>"]) then
    Match(tokens["OP_<>"])
    return {left, Grammar.ExpressionLevel3(), op = "<>"}
  end
  return left
end

function Grammar.ExpressionLevel4 ()
  local left = Grammar.ExpressionLevel5()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_>"]) then
    Match(tokens["OP_>"])
    return {left, Grammar.ExpressionLevel4(), op = ">"}
  elseif (token and token.code == tokens["OP_<"]) then
    Match(tokens["OP_<"])
    return {left, Grammar.ExpressionLevel4(), op = "<"}
  elseif (token and token.code == tokens["OP_>="]) then
    Match(tokens["OP_>="])
    return {left, Grammar.ExpressionLevel4(), op = ">="}
  elseif (token and token.code == tokens["OP_<="]) then
    Match(tokens["OP_<="])
    return {left, Grammar.ExpressionLevel4(), op = "<="}
  end
  return left
end

function Grammar.ExpressionLevel5 ()
  local left = Grammar.ExpressionLevel6()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_+"]) then
    Match(tokens["OP_+"])
    return {left, Grammar.ExpressionLevel5(), op = "+"}
  elseif (token and token.code == tokens["OP_-"]) then
    Match(tokens["OP_-"])
    return {left, Grammar.ExpressionLevel5(), op = "-"}
  end
  return left
end

function Grammar.ExpressionLevel6 ()
  local left = Grammar.ExpressionLevel7()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_*"]) then
    Match(tokens["OP_*"])
    return {left, Grammar.ExpressionLevel6(), op = "*"}
  elseif (token and token.code == tokens["OP_/"]) then
    Match(tokens["OP_/"])
    return {left, Grammar.ExpressionLevel6(), op = "/"}
  end
  return left
end

function Grammar.ExpressionLevel7 ()
  local left = Grammar.ExpressionLevel8()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_-"]) then
    Match(tokens["OP_-"])
    -- PROBLEM WITH -exp
    return {left, Grammar.ExpressionLevel7(), op = "-"}
  end
  return left
end

function Grammar.ExpressionLevel8 ()
  local left = Grammar.ExpressionLevel9()
  local token = Parser.Peek()
  if (token and token.code == tokens["OP_("]) then
    Match(tokens["OP_("])
    local exp = Grammar.Expression()
    Match(tokens["OP_)"])
    return {unpack(exp), type = "expression"}
  end
  return left
end

function Grammar.ExpressionLevel9 ()
  local token = Parser.Peek()
  if (token and token.code == tokens.NUMBER) then
    return {value = Match(tokens.NUMBER), type = "number"}
  elseif (token and token.code == tokens.STRING) then
    return {value = Match(tokens.STRING), type = "string"}
  elseif (token and token.code == tokens.K_TRUE) then
    return {value = Match(tokens.K_TRUE), type = "boolean"}
  elseif (token and token.code == tokens.K_FALSE) then
    return {value = Match(tokens.K_FALSE), type = "boolean"}
  elseif (token and token.code == tokens.K_NEW) then
    -- NEED TO DEFINE WHAT TO DO HERE
    Match(tokens.K_NEW)
    Match(tokens["OP_["])
    Grammar.Expression()
    Match(tokens["OP_]"])
    Grammar.Type()
  elseif (token and token.code == tokens.K_NOT) then
    -- NEED TO DEFINE WHAT TO DO HERE
    Match(tokens.K_NOT)
    Grammar.Expression()
  elseif (token and token.code == tokens.ID) then
    -- NEED TO DEFINE WHAT TO DO HERE
    local node
    local token2 = Parser.Peek2()
    if (token2 and token2.code == tokens["OP_("]) then
      return {value = Grammar.Call(), type = "function"}
    else
      return {value = Grammar.Var(), type = "var"}
    end
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
  return ASTClass.NewFunctionNode(line, name, params, ret_type, array_size, block)
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
  local name, typebase, array_size
  name, _ = Match(tokens.ID)
  Match(tokens["OP_:"])
  typebase, array_size = Grammar.Type()
  return ASTClass.NewParameterNode(name, typebase, array_size)
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
  if (token and 
      token.code == tokens.K_FUN or
      token.code == tokens.ID) then
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
    Error(token.line or nil)
  end
  ASTClass.NewProgramNode(node)
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
    Error(token.line or nil)
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
    Error(token.line or nil)
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
  return ASTClass.NewVarNode(line, name, array)
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
  local ok, msg = pcall(function () Grammar.Program() end)
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