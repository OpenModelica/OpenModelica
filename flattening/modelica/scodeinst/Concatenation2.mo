// name: Concatenation2
// status: correct
// cflags: -d=newInst

model Concatenation2
  Real x[:] = {1, 2};
  Real y[:] = {3, 4};
  parameter Real z[:, :] = [x, y];
end Concatenation2;

// Result:
// class Concatenation2
//   Real x[1];
//   Real x[2];
//   Real y[1];
//   Real y[2];
//   parameter Real z[1,1] = x[1];
//   parameter Real z[1,2] = y[1];
//   parameter Real z[2,1] = x[2];
//   parameter Real z[2,2] = y[2];
// equation
//   x = {1.0, 2.0};
//   y = {3.0, 4.0};
// end Concatenation2;
// endResult
