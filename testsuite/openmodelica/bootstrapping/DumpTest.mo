package DumpTest

public function dump
  input Absyn.Program program;
  output String str;
algorithm
  Print.clearBuf();
  Dump.dump(program);
  str := Print.getString();
end dump;

public function getAstAsCorbaString
  input Absyn.Program program;
  output String str;
algorithm
  Dump.getAstAsCorbaString(program);
  str := Print.getString();
end getAstAsCorbaString;

end DumpTest;
