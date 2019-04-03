// name: FuncBuiltinFloor
// keywords: floor
// status: correct
// cflags: -d=newInst
//
// Tests the builtin floor function.
//

model FuncBuiltinFloor
  Real r1 = floor(4.25);
  Real r2 = floor(-7.9);
  Real r3 = floor(r1 / r2);
end FuncBuiltinFloor;

// Result:
// class FuncBuiltinFloor
//   Real r1 = 4.0;
//   Real r2 = -8.0;
//   Real r3 = floor(r1 / r2);
// end FuncBuiltinFloor;
// endResult
