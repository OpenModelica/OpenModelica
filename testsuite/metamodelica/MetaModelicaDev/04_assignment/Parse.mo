package Parse

import Assignment;

function yyparse
  output Integer i;
external "C" annotation(Library = {"lexer.o","parser.o"});
end yyparse;

function getAST
  output Assignment.Program program;
external "C" annotation(Library = {"lexer.o","parser.o"});
end getAST;

function parse
  output Assignment.Program program;
algorithm
  0 := yyparse();
  program := getAST();
end parse;

end Parse;
