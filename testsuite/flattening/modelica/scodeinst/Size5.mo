// name: Size5
// keywords: size
// status: correct
//
// Tests the builtin size operator.
//

model Size5
  Real x[3, 1, 2];
  parameter Integer y[:] = size(x);
end Size5;

// Result:
// class Size5
//   Real x[1,1,1];
//   Real x[1,1,2];
//   Real x[2,1,1];
//   Real x[2,1,2];
//   Real x[3,1,1];
//   Real x[3,1,2];
//   parameter Integer y[1] = 3;
//   parameter Integer y[2] = 1;
//   parameter Integer y[3] = 2;
// end Size5;
// endResult
