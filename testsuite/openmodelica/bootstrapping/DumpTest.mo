package DumpTest

public function getAstAsCorbaString
  input Absyn.Program program;
  output String str;
algorithm
  Dump.getAstAsCorbaString(program);
  str := Print.getString();
end getAstAsCorbaString;

end DumpTest;
