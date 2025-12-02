// name: FuncBuiltinPromote
// keywords: sum
// status: correct
//
// Tests the builtin promote operator.
//

model FuncBuiltinPromote
  Real x;
  Real y[2, 2];
  Real r1 = promote(x, 0);
  Real r2[:] = promote(x, 1);
  Real r3[:, :] = promote(x, 2);
  Real r5[:, :] = promote(y, 2);
  Real r6[:, :, :] = promote(y, 3);
  annotation(__OpenModelica_commandLineOptions="--std=experimental");
end FuncBuiltinPromote;

// Result:
// class FuncBuiltinPromote
//   Real x;
//   Real y[1,1];
//   Real y[1,2];
//   Real y[2,1];
//   Real y[2,2];
//   Real r1 = x;
//   Real r2[1];
//   Real r3[1,1];
//   Real r5[1,1];
//   Real r5[1,2];
//   Real r5[2,1];
//   Real r5[2,2];
//   Real r6[1,1,1];
//   Real r6[1,2,1];
//   Real r6[2,1,1];
//   Real r6[2,2,1];
// equation
//   r2 = {x};
//   r3 = {{x}};
//   r5 = y;
//   r6 = {{{y[1,1]}, {y[1,2]}}, {{y[2,1]}, {y[2,2]}}};
// end FuncBuiltinPromote;
// endResult
