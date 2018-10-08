// name: Subscript5
// status: correct
// cflags: -d=newInst
//
// Checks that partially subscripted crefs are padded with :.
// 

function f
  input Real x[:, :];
  input Real y[:, :];
  output Real z;
algorithm
  z := x[1] * y[2];
end f;

model Subscript5
  Real x[3, 3] = {{time, 1, 2}, {3, 4, 5}, {6, 7, 8}};
  Real y = f(x, x);
end Subscript5;
  

// Result:
// function f
//   input Real[:, :] x;
//   input Real[:, :] y;
//   output Real z;
// algorithm
//   z := x[1] * y[2];
// end f;
//
// class Subscript5
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
//   Real y = f(x, x);
// equation
//   x = {{time, 1.0, 2.0}, {3.0, 4.0, 5.0}, {6.0, 7.0, 8.0}};
// end Subscript5;
// endResult
