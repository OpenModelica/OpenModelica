// name: FuncBuiltinIdentity
// keywords: identity
// status: correct
// cflags: -d=newInst
//
// Tests the builtin identity operator.
//

model FuncBuiltinIdentity
  Real x[3,3] = identity(3);
end FuncBuiltinIdentity;

// Result:
// class FuncBuiltinIdentity
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
// equation
//   x = {{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}};
// end FuncBuiltinIdentity;
// endResult
