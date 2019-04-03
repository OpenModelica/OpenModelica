// name:     LeastSquares
// keywords: external function, array
// status:   correct
//
// Drmodelica: 9.2 External Functions (p. 311)
//


function ls "Solves a linear least squares problem"
  input Real A[:,:];
  input Real B[:,:];
  output Real Ares[size(A,1), size(A,2)] = A;
  output Real x[size(A,2), size(B,2)];

protected
  Integer lwork = min(size(A,1),size(A,2)) + max(max(size(A,1),size(A,2)),size(B,2))*32;
  Real work[lwork];
  Integer info;
  String transposed = "NNNN";  // Workaround for passing character data to Fortran routine
  external "FORTRAN 77"
   dgesl(transposed, 100, size(A,1), size(A,2), size(B,2), Ares, size(A,1), B, size(B,1), work, lwork, info, x);
end ls;

model LeastSquares
  Real in1[2,2]={{1,3}, {4,1}};
  Real in2[2,2]={{4,2}, {5,3}};
  Real x[2,2];

equation
  x = ls(in1, in2);
end LeastSquares;

// Result:
// function ls "Solves a linear least squares problem"
//   input Real[:, :] A;
//   input Real[:, :] B;
//   output Real[size(A, 1), size(A, 2)] Ares = A;
//   output Real[size(A, 2), size(B, 2)] x;
//   protected Integer info;
//   protected String transposed = "NNNN";
//   protected Integer lwork = min(size(A, 1), size(A, 2)) + 32 * max(max(size(A, 1), size(A, 2)), size(B, 2));
//   protected Real[lwork] work;
//
//   external "FORTRAN 77" dgesl(transposed, 100, size(A, 1), size(A, 2), size(B, 2), Ares, size(A, 1), B, size(B, 1), work, lwork, info, x);
// end ls;
//
// class LeastSquares
//   Real in1[1,1];
//   Real in1[1,2];
//   Real in1[2,1];
//   Real in1[2,2];
//   Real in2[1,1];
//   Real in2[1,2];
//   Real in2[2,1];
//   Real in2[2,2];
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
// equation
//   in1 = {{1.0, 3.0}, {4.0, 1.0}};
//   in2 = {{4.0, 2.0}, {5.0, 3.0}};
//   (x, _) = ls({{in1[1,1], in1[1,2]}, {in1[2,1], in1[2,2]}}, {{in2[1,1], in2[1,2]}, {in2[2,1], in2[2,2]}});
// end LeastSquares;
// endResult
