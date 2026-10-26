// name: Acos
// keywords: acos
// status: correct
//
// Tests the built-in acos function
//

model Acos
  Real r;
equation
  r = acos(0.5);
end Acos;

// Result:
// class Acos
//   Real r;
// equation
//   r = 1.0471975511965979;
// end Acos;
// endResult
