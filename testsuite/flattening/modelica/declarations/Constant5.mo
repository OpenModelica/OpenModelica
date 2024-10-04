// name:     Constant5
// keywords: declaration,array
// status:   correct
//
//
//

class Constant5
  Real x[integer(2.5)];
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Constant5;

// Result:
// class Constant5
//   Real x[1];
//   Real x[2];
// end Constant5;
// endResult
