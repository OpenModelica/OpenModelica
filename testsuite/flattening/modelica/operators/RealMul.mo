// name: RealMul
// keywords: real, multiplication
// status: correct
//
// tests Real multiplication
//

model RealMul
  constant Real r = 4711.2 * 1138.3;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end RealMul;

// Result:
// class RealMul
//   constant Real r = 5362758.96;
// end RealMul;
// endResult
