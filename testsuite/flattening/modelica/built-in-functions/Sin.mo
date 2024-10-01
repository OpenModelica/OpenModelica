// name: Sin
// keywords: sin
// status: correct
//
// Tests the built-in sin function
//

model Sin
  Real r;
equation
  r = sin(45);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Sin;

// Result:
// class Sin
//   Real r;
// equation
//   r = 0.8509035245341184;
// end Sin;
// endResult
