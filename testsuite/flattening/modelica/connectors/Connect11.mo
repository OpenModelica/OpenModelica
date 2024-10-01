// name:     Connect11
// keywords: connect
// status:   incorrect
//
// Testing of input/output flags
//

connector C1
  output Real x;
end C1;

connector C2
  output Real x;
end C2;

class Connect11
  C1 c1;
  C2 c2;
equation
  connect(c1,c2);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Connect11;
