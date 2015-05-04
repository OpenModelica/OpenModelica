// name: Symmetric2
// keywords: symmetric builtin bug2126
// status: correct
//
// Testing the built-in symmetric function.
//

model Symmetric2
  parameter Integer n =3;
  Real A[:,:] = symmetric(2*identity(n)-[[0,time,0];[0,0,time];zeros(1,n)]);
end Symmetric2;

// Result:
// class Symmetric2
//   parameter Integer n = 3;
//   Real A[1,1];
//   Real A[1,2];
//   Real A[1,3];
//   Real A[2,1];
//   Real A[2,2];
//   Real A[2,3];
//   Real A[3,1];
//   Real A[3,2];
//   Real A[3,3];
// equation
//   A = {{2.0, -time, 0.0}, {-time, 2.0, -time}, {0.0, -time, 2.0}};
// end Symmetric2;
// endResult
