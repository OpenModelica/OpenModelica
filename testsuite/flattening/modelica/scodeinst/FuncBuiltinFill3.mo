// name: FuncBuiltinFill3
// keywords: fill
// status: correct
//
// Tests the builtin fill operator.
//

model FuncBuiltinFill3
  parameter Integer a[:, :] = {{1}, {2}, {3}};
  Real x[3, 3];
equation
  for i in 1:3 loop
    x[:, 1:i] = zeros(3, a[i, 1]+0);
  end for;
end FuncBuiltinFill3;

// Result:
// class FuncBuiltinFill3
//   parameter Integer a[1,1] = 1;
//   parameter Integer a[2,1] = 2;
//   parameter Integer a[3,1] = 3;
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
//   x[:,1:1] = fill(0.0, 3, a[1,1]);
//   x[:,1:2] = fill(0.0, 3, a[2,1]);
//   x[:,:] = fill(0.0, 3, a[3,1]);
// end FuncBuiltinFill3;
// endResult
