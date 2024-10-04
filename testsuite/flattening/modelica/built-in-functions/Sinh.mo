// name: Sinh
// keywords: sinh
// status: correct
//
// Tests the built-in sinh function
//

model Sinh
  Real r;
equation
  r = sinh(45);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Sinh;

// Result:
// class Sinh
//   Real r;
// equation
//   r = 1.7467135528742547e+19;
// end Sinh;
// endResult
