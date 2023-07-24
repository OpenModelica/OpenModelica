package Parse

import Absyn;

function parse
  output Absyn.Prog outProg;

  external "C" annotation(Library = {"lexerPetrol.o","parsutil_omc.o","parser.o"});
end parse;
end Parse;

