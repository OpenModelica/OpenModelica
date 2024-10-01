// name: Sqrt
// keywords: sqrt
// status: correct
//
// Testing the built-in sqrt function
//

model Sqrt
  Real r;
equation
  r = sqrt(25);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Sqrt;

// Result:
// class Sqrt
//   Real r;
// equation
//   r = 5.0;
// end Sqrt;
// endResult
