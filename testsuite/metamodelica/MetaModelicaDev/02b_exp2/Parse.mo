package Parse

import Exp2;

function yyparse
  output Integer i;
external "C" annotation(Library = {"lexer.o","parser.o"});
end yyparse;

function getAST
  output Exp2.Exp exp;
external "C" annotation(Library = {"lexer.o","parser.o"});
end getAST;

function parse
  output Exp2.Exp exp;
algorithm
  0 := yyparse();
  exp := getAST();
end parse;

end Parse;

