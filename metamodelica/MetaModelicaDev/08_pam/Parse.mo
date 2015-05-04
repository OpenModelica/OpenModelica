package Parse

import Pam;

function parse
  output Pam.Stmt outStmt;
external "C" annotation(Library = {"lexer.o","parser.o"});
end parse;

end Parse;

