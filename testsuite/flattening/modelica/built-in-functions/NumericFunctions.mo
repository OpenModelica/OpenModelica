// name: NumericFunctions
// keywords: builtin, function, numeric
// status: correct
//
// Testing the built-in numeric functions abs, sign, and sqrt
//

model NumericFunctions
  constant Real r1 = abs(-2.5);
  constant Real r2 = sign(-72);
  constant Real r3 = sqrt(49);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end NumericFunctions;

// Result:
// class NumericFunctions
//   constant Real r1 = 2.5;
//   constant Real r2 = -1.0;
//   constant Real r3 = 7.0;
// end NumericFunctions;
// endResult
