// name: Asin
// keywords: asin
// status: correct
//
// Tests the built-in asin function
//

model Asin
  Real r;
equation
  r = asin(0.5);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Asin;

// Result:
// class Asin
//   Real r;
// equation
//   r = 0.5235987755982989;
// end Asin;
// endResult
