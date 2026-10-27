// name:     ArrayIndex2
// keywords: array indices bug1241
// status:   correct
//
// Checks that array indices are correct when using :.
//

model ArrayIndex2
  constant Integer N=2;
  Real A[N,N,N];
  Real B[N,N,N];
  Real C[N,N,N];
equation
  for a in 1:N loop
    A[a,:,:] = {{cos(time),sin(time)},
                {-sin(time),cos(time)}};
    B[:,a,:] = {{cos(time),sin(time)},
                {-sin(time),cos(time)}};
    C[:,:,a] = {{cos(time),sin(time)},
                {-sin(time),cos(time)}};
  end for;
end ArrayIndex2;

// Result:
// class ArrayIndex2
//   constant Integer N = 2;
//   Real A[1,1,1];
//   Real A[1,1,2];
//   Real A[1,2,1];
//   Real A[1,2,2];
//   Real A[2,1,1];
//   Real A[2,1,2];
//   Real A[2,2,1];
//   Real A[2,2,2];
//   Real B[1,1,1];
//   Real B[1,1,2];
//   Real B[1,2,1];
//   Real B[1,2,2];
//   Real B[2,1,1];
//   Real B[2,1,2];
//   Real B[2,2,1];
//   Real B[2,2,2];
//   Real C[1,1,1];
//   Real C[1,1,2];
//   Real C[1,2,1];
//   Real C[1,2,2];
//   Real C[2,1,1];
//   Real C[2,1,2];
//   Real C[2,2,1];
//   Real C[2,2,2];
// equation
//   A[1,1,1] = cos(time);
//   A[1,1,2] = sin(time);
//   A[1,2,1] = -sin(time);
//   A[1,2,2] = cos(time);
//   B[1,1,1] = cos(time);
//   B[1,1,2] = sin(time);
//   B[2,1,1] = -sin(time);
//   B[2,1,2] = cos(time);
//   C[1,1,1] = cos(time);
//   C[1,2,1] = sin(time);
//   C[2,1,1] = -sin(time);
//   C[2,2,1] = cos(time);
//   A[2,1,1] = cos(time);
//   A[2,1,2] = sin(time);
//   A[2,2,1] = -sin(time);
//   A[2,2,2] = cos(time);
//   B[1,2,1] = cos(time);
//   B[1,2,2] = sin(time);
//   B[2,2,1] = -sin(time);
//   B[2,2,2] = cos(time);
//   C[1,1,2] = cos(time);
//   C[1,2,2] = sin(time);
//   C[2,1,2] = -sin(time);
//   C[2,2,2] = cos(time);
// end ArrayIndex2;
// endResult
