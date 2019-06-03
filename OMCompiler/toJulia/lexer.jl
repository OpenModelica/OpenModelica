# Generate a Lexer for (Meta)Modelica
# =====================================================================

import Automa
import Automa.RegExp: @re_str
import MacroTools
const re = Automa.RegExp

include("tokens.jl")

keywordWithAction = [
  Automa.RegExp.parse(word) => :(emit($(Symbol(uppercase(word[1]) * word[2:end]))())) for word in keywords
]
# Describe patterns in regular expression.
string   = re"\"([^\"\\x5c]|(\\x5c['\"?\\x5cabfnrtv]))*\""
ident    = re"[_A-Za-z][_A-Za-z0-9]*|'([^'\\x5c]|(\\x5c.))+'"
int      = re"[0-9]+"
prefloat = re"[0-9]+\.[0-9]*|[0-9]*\.[0-9]+"
float    = prefloat | re.cat(prefloat | re"[-+]?[0-9]+", re"[eE][-+]?[0-9]+")
operator = re"[{}(),]|end"
number   = int | float
ws       = re"[ ]+"
omtoken  = number | string | ident | operator
omtokens = re.opt(ws) * re.rep(omtoken * re.opt(ws))

# Compile a finite-state machine.
res = vcat(keywordWithAction, [
    re"=" => :(emit(Equality())),
    re":=" => :(emit(Assign())),
    re";" => :(emit(Semicolon())),
    re"," => :(emit(Comma())),
    re"\[" => :(emit(LeftBracket())),
    re"\]" => :(emit(RightBracket())),
    re"[(]" => :(emit(LeftPar())),
    re"[)]" => :(emit(RightPar())),
    re"{" => :(emit(LeftCurly())),
    re"}" => :(emit(RightCurly())),
    re"^" => :(emit(Exponent())),
    re"[.]" => :(emit(Dot())),
    re"[*]" => :(emit(Product())),
    re"/" => :(emit(Division())),
    re"[.][*]" => :(emit(Product_EW())),
    re"[.]/" => :(emit(Division_EW())),
    re"[+]" => :(emit(Plus())),
    re"[-]" => :(emit(Minus())),
    re"[.][+]" => :(emit(Plus_EW())),
    re"[.][-]" => :(emit(Minus_EW())),
    re"<" => :(emit(Less())),
    re"<=" => :(emit(LessEq())),
    re">" => :(emit(Greater())),
    re">=" => :(emit(GreaterEq())),
    re"==" => :(emit(Equals())),
    re"<>" => :(emit(NotEquals())),
    re":" => :(emit(Colon())),
    string => :(emit(StringToken(unescape_string(String(data[ts+1:te-1]))))),
    ident => :(emit(Identifier(unescape_string(String(data[ts:te]))))), # Should this be a symbol instead?
    int => :(emit(IntToken(parse(Int, String(data[ts:te]))))),
    float => :(emit(RealToken(String(data[ts:te]), parse(Float64, String(data[ts:te]))))),
    re"[\n\t ]" => :(),
    re"//[^\n]*[\n]" => :(emit(LineComment(String(data[ts+1:te-1])))),
    re"/[*]([^*]|[*][^/])*[*][/]" => :(emit(BlockComment(String(data[ts+1:te-1])))),
    re"." => :(for tok = tokens println(tok) end; throw(LexerError(filename,positions[ts][1],positions[ts][2],"Error lexing near: “$(data[ts:p + min(p_eof-p, 20)])”"))),
    ])
tokenizer = Automa.compile(res...)

# Generate a tokenizing function from the machine.
ctx = Automa.CodeGenContext()
init_code = MacroTools.prettify(Automa.generate_init_code(ctx, tokenizer))
exec_code = MacroTools.prettify(Automa.generate_exec_code(ctx, tokenizer))

write(open("toJulia/generated_lexer.jl","w"), """
function tokenize(filename)
  $(init_code)
  data = read(open(filename), String)
  data_raw = Vector{UInt8}(data)
  p_end = p_eof = sizeof(data)
  positions = bytesToPositions(data)
  failed = false
  tokens = Token[]
  makeInfo(p) = FileInfo(0, p)
  emit(tok::Token) = push!(tokens, tok)
  emit(tok::Any) = throw(LexerError("Error while lexing. Got non-token \$(tok)"))
  while p ≤ p_eof && cs > 0
    $(exec_code)
  end
  if cs < 0 || failed
    throw(LexerError("Error while lexing"))
  end
  if p < p_eof
    throw(LexerError("Did not scan until end of file. Remaining: \$(data[p:p_eof])"))
  end
  return tokens
end
""")
