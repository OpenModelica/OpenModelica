// name:     ZeroDimUnconnectedFlow1
// keywords: connect
// status:   correct
//
// Checks that equations for unconnected flow variables in arrays with zero dims
// are not generated.
//

connector C
  Real e;
  flow Real f;
end C;

model ZeroDimUnconnectedFlow1
  C c[0];
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ZeroDimUnconnectedFlow1;

// Result:
// class ZeroDimUnconnectedFlow1
// end ZeroDimUnconnectedFlow1;
// endResult
