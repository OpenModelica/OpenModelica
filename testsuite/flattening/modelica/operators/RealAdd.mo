// name: RealAdd
// keywords: real, addition
// status: correct
//
// tests Real addition
//

model RealAdd
  constant Real r = 4711.2 + 1138.3;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end RealAdd;

// Result:
// class RealAdd
//   constant Real r = 5849.5;
// end RealAdd;
// endResult
