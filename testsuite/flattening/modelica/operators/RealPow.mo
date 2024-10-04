// name: RealPow
// keywords: real, power
// status: correct
//
// tests Real powers
//

model RealPow
  constant Real r = 2.3 ^ 9.5;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end RealPow;

// Result:
// class RealPow
//   constant Real r = 2731.5832575191735;
// end RealPow;
// endResult
