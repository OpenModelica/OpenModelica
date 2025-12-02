// name:     Terminal1
// keywords: The terminal operator
// status:   correct
//
//  The terminal operator.
//

class Terminal1
  Boolean t;
equation
  t=terminal();
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Terminal1;

// Result:
// class Terminal1
//   Boolean t;
// equation
//   t = terminal();
// end Terminal1;
// endResult
