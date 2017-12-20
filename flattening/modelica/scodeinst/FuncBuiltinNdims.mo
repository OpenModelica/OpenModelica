// name: FuncBuiltinNdims
// keywords: ndims
// status: correct
// cflags: -d=newInst
//
// Tests the builtin ndims operator.
//

model FuncBuiltinNdims
  Real x[1, 2, 3];
  Integer i = ndims(x);
  Integer j = ndims({{1},{2}});
  Real k = ndims(2);
end FuncBuiltinNdims;

// Result:
// class FuncBuiltinNdims
//   Real x[1,1,1];
//   Real x[1,1,2];
//   Real x[1,1,3];
//   Real x[1,2,1];
//   Real x[1,2,2];
//   Real x[1,2,3];
//   Integer i = 3;
//   Integer j = 2;
//   Real k = 0.0;
// end FuncBuiltinNdims;
// endResult
