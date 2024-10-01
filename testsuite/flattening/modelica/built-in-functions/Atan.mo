// name: Atan
// keywords: atan
// status: correct
//
// Tests the built-in atan function
//

model Atan
  Real r;
equation
  r = atan(0.5);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Atan;

// Result:
// class Atan
//   Real r;
// equation
//   r = 0.4636476090008061;
// end Atan;
// endResult
