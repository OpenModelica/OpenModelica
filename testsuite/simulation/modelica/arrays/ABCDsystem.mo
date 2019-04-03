// name:     ABCDsystem
// keywords: array
// status:  correct
//
// Using empty arrays.
// Drmodelica: 7.9 Empty Arrays (p. 231)
//

model ABCDsystem
  parameter Integer n = 0;
  Real u[5] = {15, 4, 3, 9, 11};
  Real x[n];
  Real y[3];
  Real A[n, n], B[n, 5], C[3, n];
  Real D[3, 5] = fill(1, 3, 5);
equation
  der(x) = A*x + B*u;             // This will disappear since x is empty
  y = C*x + D*u;                  // Which is: y = D*u
end ABCDsystem;

// class ABCDsystem
// parameter Integer n = 0;
// Real u[1];
// Real u[2];
// Real u[3];
// Real u[4];
// Real u[5];
// Real y[1];
// Real y[2];
// Real y[3];
// Real D[1,1];
// Real D[1,2];
// Real D[1,3];
// Real D[1,4];
// Real D[1,5];
// Real D[2,1];
// Real D[2,2];
// Real D[2,3];
// Real D[2,4];
// Real D[2,5];
// Real D[3,1];
// Real D[3,2];
// Real D[3,3];
// Real D[3,4];
// Real D[3,5];
// equation
//   u[1] = 15.0;
//   u[2] = 4.0;
//   u[3] = 3.0;
//   u[4] = 9.0;
//   u[5] = 11.0;
//   D[1,1] = 1.0;
//   D[1,2] = 1.0;
//   D[1,3] = 1.0;
//   D[1,4] = 1.0;
//   D[1,5] = 1.0;
//   D[2,1] = 1.0;
//   D[2,2] = 1.0;
//   D[2,3] = 1.0;
//   D[2,4] = 1.0;
//   D[2,5] = 1.0;
//   D[3,1] = 1.0;
//   D[3,2] = 1.0;
//   D[3,3] = 1.0;
//   D[3,4] = 1.0;
//   D[3,5] = 1.0;
//   y[1] = ({{},{},{}} * {} + {D[1,1] * u[1] + D[1,2] * u[2] + D[1,3] * u[3] + D[1,4] * u[4] + D[1,5] * u[5],D[2,1] * u[1] + D[2,2] * u[2] + D[2,3] * u[3] + D[2,4] * u[4] + D[2,5] * u[5],D[3,1] * u[1] + D[3,2] * u[2] + D[3,3] * u[3] + D[3,4] * u[4] + D[3,5] * u[5]})[1];
//   y[2] = ({{},{},{}} * {} + {D[1,1] * u[1] + D[1,2] * u[2] + D[1,3] * u[3] + D[1,4] * u[4] + D[1,5] * u[5],D[2,1] * u[1] + D[2,2] * u[2] + D[2,3] * u[3] + D[2,4] * u[4] + D[2,5] * u[5],D[3,1] * u[1] + D[3,2] * u[2] + D[3,3] * u[3] + D[3,4] * u[4] + D[3,5] * u[5]})[2];
//   y[3] = ({{},{},{}} * {} + {D[1,1] * u[1] + D[1,2] * u[2] + D[1,3] * u[3] + D[1,4] * u[4] + D[1,5] * u[5],D[2,1] * u[1] + D[2,2] * u[2] + D[2,3] * u[3] + D[2,4] * u[4] + D[2,5] * u[5],D[3,1] * u[1] + D[3,2] * u[2] + D[3,3] * u[3] + D[3,4] * u[4] + D[3,5] * u[5]})[3];
// end ABCDsystem;
