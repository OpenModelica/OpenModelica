// name: Tan
// keywords: tan
// status: correct
//
// Tests the built-in tan function
//

model Tan
  Real r;
equation
  r = tan(45);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Tan;

// Result:
// class Tan
//   Real r;
// equation
//   r = 1.6197751905438615;
// end Tan;
// endResult
