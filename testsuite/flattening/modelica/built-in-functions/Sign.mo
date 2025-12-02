// name: Sign
// keywords: sign
// status: correct
//
// Testing the built-in sign function
//

model Sign
  Real r1, r2;
equation
  r1 = sign(65);
  r2 = sign(-4711);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Sign;

// Result:
// class Sign
//   Real r1;
//   Real r2;
// equation
//   r1 = 1.0;
//   r2 = -1.0;
// end Sign;
// endResult
