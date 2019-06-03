abstract type Token end
struct FileInfo
  line::Int
  column::Int
end

struct IntToken <: Token
  value::Int
end
struct RealToken <: Token
  original::String
  value::Real
end
struct StringToken <: Token
  value::String
end
struct Identifier <: Token
  value::String
end
# Operators
struct Comma <: Token end
struct Semicolon <: Token end
struct Assign <: Token end
struct Equality <: Token end
struct LeftBracket <: Token end
struct RightBracket <: Token end
struct LeftPar <: Token end
struct RightPar <: Token end
struct LeftCurly <: Token end
struct RightCurly <: Token end
struct Exponent <: Token end
struct Product <: Token end
struct Division <: Token end
struct Product_EW <: Token end
struct Division_EW <: Token end
struct Plus <: Token end
struct Minus <: Token end
struct Plus_EW <: Token end
struct Minus_EW <: Token end
struct Less <: Token end
struct LessEq <: Token end
struct Greater <: Token end
struct GreaterEq <: Token end
struct Equals <: Token end
struct NotEquals <: Token end
struct Dot <: Token end
struct Colon <: Token end
struct LineComment <: Token
  comment::String
end
struct BlockComment <: Token
  comment::String
end
struct LexerError <: Exception
  filename::String
  row::Int
  col::Int
  message::String
end

# Keywords
macro keywords(words...)
  res = quote
  begin
  end
  end
  for word in words
    res = quote
      $(res)
      struct $(Symbol(uppercase(word[1]) * word[2:end])) <: Token
      end
    end
  end
  res = quote
    $(res)
    $(esc(words))
  end
  res
end
keywords = @keywords(
  "algorithm", "and", "algorithm", "and", "annotation",
  "block", "break",
  "class", "connect", "connector", "constant", "constrainedby",
  "der", "discrete",
  "each", "else", "elseif", "elsewhen", "encapsulated", "end", "enumeration", "equation", "enumeration", "expandable", "extends", "external",
  "false", "final", "flow", "for", "function",
  "if", "import", "impure", "in", "initial", "inner", "input",
  "loop", "model", "not", "operator", "or", "outer", "output",
  "package", "parameter", "partial", "protected", "public", "pure",
  "record", "redeclare", "replaceable", "return",
  "stream", "then", "true", "type", "when", "while", "within"
)
