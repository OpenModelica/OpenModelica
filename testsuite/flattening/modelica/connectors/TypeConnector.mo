// status: correct
// See ticket:4471

model TypeConnector
  type T
    extends String;
  end T;
  connector C = output T;
  C c;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end TypeConnector;

// Result:
// class TypeConnector
//   output String c;
// end TypeConnector;
// endResult
