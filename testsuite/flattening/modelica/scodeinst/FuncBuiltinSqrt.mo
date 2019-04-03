// name: FuncBuiltinSqrt
// keywords: sqrt
// status: correct
// cflags: -d=newInst
//
// Tests the builtin sqrt function.
//

model FuncBuiltinSqrt
  Real r1 = sqrt(25);
  Real r2 = sqrt(15.4);
  Real r3 = sqrt(r1 + r2); 
end FuncBuiltinSqrt;

// Result:
// class FuncBuiltinSqrt
//   Real r1 = 5.0;
//   Real r2 = 3.924283374069717;
//   Real r3 = sqrt(r1 + r2);
// end FuncBuiltinSqrt;
// endResult
