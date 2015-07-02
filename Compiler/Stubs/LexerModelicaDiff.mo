encapsulated package LexerModelicaDiff

type Token=Integer;
type TokenId=Integer;

function scanString
  input String fileSource;
  output list<Token> tokens;
algorithm
  assert(false, getInstanceName());
end scanString;

function tokenContent<A>
  input A token;
  output String contents;
algorithm
  assert(false, getInstanceName());
end tokenContent;

function modelicaDiffTokenEq<T>
  input T a,b;
  output Boolean o;
algorithm
  assert(false, getInstanceName());
end modelicaDiffTokenEq;

function filterModelicaDiff<A>
  input A diffs;
  input Boolean removeWhitespace=true;
  output A odiffs;
algorithm
  assert(false, getInstanceName());
end filterModelicaDiff;

annotation(__OpenModelica_Interface="backend");
end LexerModelicaDiff;
