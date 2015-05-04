// name: MathematicalFunctions
// keywords: builtin, function, math
// status: correct
//
// Testing built-in mathematical functions
//

model MathematicalFunctions
  Real r1 = sin(45);
  Real r2 = cos(45);
  Real r3 = tan(45);
  Real r4 = asin(0.5);
  Real r5 = acos(0.5);
  Real r6 = atan(0.5);
  Real r7 = atan2(0.5,0.5);
  Real r8 = sinh(45);
  Real r9 = cosh(45);
  Real r10 = tanh(45);
  Real r11 = exp(5);
  Real r12 = log(5);
  Real r13 = log10(5);
end MathematicalFunctions;

// Results:
// endResult
// Result:
// class MathematicalFunctions
//   Real r1 = 0.8509035245341184;
//   Real r2 = 0.5253219888177297;
//   Real r3 = 1.6197751905438615;
//   Real r4 = 0.5235987755982989;
//   Real r5 = 1.0471975511965979;
//   Real r6 = 0.4636476090008061;
//   Real r7 = 0.7853981633974483;
//   Real r8 = 1.7467135528742547e+19;
//   Real r9 = 1.7467135528742547e+19;
//   Real r10 = 1.0;
//   Real r11 = 148.4131591025766;
//   Real r12 = 1.6094379124341003;
//   Real r13 = 0.6989700043360189;
// end MathematicalFunctions;
// endResult
