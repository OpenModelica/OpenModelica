package Parse

import Exp1;

function yyparse
  output Integer i;
external "C" annotation(Library = {"lexer.o","parser.o"});
end yyparse;

function getAST
  output Exp1.Exp exp;
external "C" annotation(Library = {"lexer.o","parser.o"});
end getAST;

function parse
  output Exp1.Exp exp;
algorithm
  0 := yyparse();
  exp := getAST();
end parse;

end Parse;
