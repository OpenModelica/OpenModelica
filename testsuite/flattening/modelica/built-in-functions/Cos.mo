// name: Cos
// keywords: cos
// status: correct
//
// Tests the built-in cos function
//

model Cos
  Real r;
equation
  r = cos(45);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Cos;

// Result:
// class Cos
//   Real r;
// equation
//   r = 0.5253219888177297;
// end Cos;
// endResult
