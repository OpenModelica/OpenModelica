// name: Concatenation2
// status: correct
// cflags: -d=newInst

model Concatenation2
  parameter Real x[:] = {1, 2};
  parameter Real y[:] = {3, 4};
  parameter Real z[:, :] = [x, y];
end Concatenation2;

// Result:
// class Concatenation2
//   parameter Real x[1] = 1.0;
//   parameter Real x[2] = 2.0;
//   parameter Real y[1] = 3.0;
//   parameter Real y[2] = 4.0;
//   parameter Real z[1,1] = x[1];
//   parameter Real z[1,2] = y[1];
//   parameter Real z[2,1] = x[2];
//   parameter Real z[2,2] = y[2];
// end Concatenation2;
// endResult
