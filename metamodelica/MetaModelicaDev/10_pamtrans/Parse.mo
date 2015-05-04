package Parse

import Absyn;

function parse
  output Absyn.Stmt outStmt;

  external "C" outStmt = parse() annotation(Library={"lexer.o","parser.o"});
end parse;
end Parse;

