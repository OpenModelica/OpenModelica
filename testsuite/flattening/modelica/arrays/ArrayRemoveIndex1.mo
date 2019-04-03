// name:     ArrayRemoveIndex1
// keywords: subscript
// status:   correct
//
// Checks that array subscripts are removed even when preceeded with
// unary minus vector expression
//
//

model ArrayRemoveIndex1
  parameter Real A[2,2]={{-1,0},{0,-1}};
  parameter Real B[2,1]={{1},{1}};
  parameter Real Q[2,2]={{1,0},{1,0}};
  Real X[2,2];
  Real x[2,1](start={{10},{10}});
  Real u[1,1];
equation
  zeros(2, 2)=transpose(A)*transpose(X) + X*A - X*B*transpose(B)*X + Q "Algebraic Riccati Equation";
  der(x)=A*x + B*u "State equation";
  u=-transpose(B)*X*x "Control";
end ArrayRemoveIndex1;

// Result:
// class ArrayRemoveIndex1
//   parameter Real A[1,1] = -1.0;
//   parameter Real A[1,2] = 0.0;
//   parameter Real A[2,1] = 0.0;
//   parameter Real A[2,2] = -1.0;
//   parameter Real B[1,1] = 1.0;
//   parameter Real B[2,1] = 1.0;
//   parameter Real Q[1,1] = 1.0;
//   parameter Real Q[1,2] = 0.0;
//   parameter Real Q[2,1] = 1.0;
//   parameter Real Q[2,2] = 0.0;
//   Real X[1,1];
//   Real X[1,2];
//   Real X[2,1];
//   Real X[2,2];
//   Real x[1,1](start = 10.0);
//   Real x[2,1](start = 10.0);
//   Real u[1,1];
// equation
//   0.0 = A[1,1] * X[1,1] + A[2,1] * X[1,2] + X[1,1] * A[1,1] + X[1,2] * A[2,1] - ((X[1,1] * B[1,1] + X[1,2] * B[2,1]) * B[1,1] * X[1,1] + (X[1,1] * B[1,1] + X[1,2] * B[2,1]) * B[2,1] * X[2,1]) + Q[1,1] "Algebraic Riccati Equation";
//   0.0 = A[1,1] * X[2,1] + A[2,1] * X[2,2] + X[1,1] * A[1,2] + X[1,2] * A[2,2] - ((X[1,1] * B[1,1] + X[1,2] * B[2,1]) * B[1,1] * X[1,2] + (X[1,1] * B[1,1] + X[1,2] * B[2,1]) * B[2,1] * X[2,2]) + Q[1,2] "Algebraic Riccati Equation";
//   0.0 = A[1,2] * X[1,1] + A[2,2] * X[1,2] + X[2,1] * A[1,1] + X[2,2] * A[2,1] - ((X[2,1] * B[1,1] + X[2,2] * B[2,1]) * B[1,1] * X[1,1] + (X[2,1] * B[1,1] + X[2,2] * B[2,1]) * B[2,1] * X[2,1]) + Q[2,1] "Algebraic Riccati Equation";
//   0.0 = A[1,2] * X[2,1] + A[2,2] * X[2,2] + X[2,1] * A[1,2] + X[2,2] * A[2,2] - ((X[2,1] * B[1,1] + X[2,2] * B[2,1]) * B[1,1] * X[1,2] + (X[2,1] * B[1,1] + X[2,2] * B[2,1]) * B[2,1] * X[2,2]) + Q[2,2] "Algebraic Riccati Equation";
//   der(x[1,1]) = A[1,1] * x[1,1] + A[1,2] * x[2,1] + B[1,1] * u[1,1] "State equation";
//   der(x[2,1]) = A[2,1] * x[1,1] + A[2,2] * x[2,1] + B[2,1] * u[1,1] "State equation";
//   u[1,1] = ((-B[1,1]) * X[1,1] - B[2,1] * X[2,1]) * x[1,1] - (B[1,1] * X[1,2] + B[2,1] * X[2,2]) * x[2,1] "Control";
// end ArrayRemoveIndex1;
// endResult
