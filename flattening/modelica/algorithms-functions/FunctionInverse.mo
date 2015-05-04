// name:     FunctionInverse
// keywords: function bug2056
// status:   correct
//
// This test checks that output parameters with dimensions given by the input
// arguments works.

function inv
  input Real[:, size(A, 1)] A;
  output Real[size(A, 1), size(A, 2)] invA;
protected
  Integer info;
  Integer[size(A, 1)] pivots;
  Real[size(A, 1), size(A, 2)] LU;
algorithm
  (LU, pivots, info) := LAPACK.dgetrf(A);
  assert(info == 0, "Calculating an inverse matrix with function
  \"Matrices.inv\" is not possible, since matrix A is singular.");
  invA := LAPACK.dgetri(LU, pivots);
end inv;

package LAPACK
  function dgetrf
    input Real[:, :] A;
    output Real[size(A, 1), size(A, 2)] LU = A;
    output Integer[min(size(A, 1), size(A, 2))] pivots;
    output Integer info;
  protected
    Integer lda = max(1, size(A, 1));
    external "FORTRAN 77" dgetrf(size(A, 1), size(A, 2), LU, lda, pivots, info);
  end dgetrf;

  function dgetri
    input Real[:, size(LU, 1)] LU;
    input Integer[size(LU, 1)] pivots;
    output Real[size(LU, 1), size(LU, 2)] inv = LU;
    output Integer info;
  protected
    Integer lda = max(1, size(LU, 1));
    Integer lwork = max(1, min(10, size(LU, 1)) * size(LU, 1));
    Real[max(1, min(10, size(LU, 1)) * size(LU, 1))] work;
    external "FORTRAN 77" dgetri(size(LU, 1), inv, lda, pivots, work, lwork, info);
  end dgetri;
end LAPACK;

model FunctionInverse
  parameter Integer N = 3;
  Real[N, N] A = identity(N);
  Real[N, N] B = identity(N);
  Real[N, N] C;
equation
  C = inv(A) * B;
end FunctionInverse;

// Result:
// function LAPACK.dgetrf
//   input Real[:, :] A;
//   output Real[size(A, 1), size(A, 2)] LU = A;
//   output Integer[min(size(A, 1), size(A, 2))] pivots;
//   output Integer info;
//   protected Integer lda = max(1, size(A, 1));
//
//   external "FORTRAN 77" dgetrf(size(A, 1), size(A, 2), LU, lda, pivots, info);
// end LAPACK.dgetrf;
//
// function LAPACK.dgetri
//   input Real[:, size(LU, 1)] LU;
//   input Integer[size(LU, 1)] pivots;
//   output Real[size(LU, 1), size(LU, 2)] inv = LU;
//   output Integer info;
//   protected Integer lda = max(1, size(LU, 1));
//   protected Integer lwork = max(1, min(10, size(LU, 1)) * size(LU, 1));
//   protected Real[max(1, min(10, size(LU, 1)) * size(LU, 1))] work;
//
//   external "FORTRAN 77" dgetri(size(LU, 1), inv, lda, pivots, work, lwork, info);
// end LAPACK.dgetri;
//
// function inv
//   input Real[:, size(A, 1)] A;
//   output Real[size(A, 1), size(A, 2)] invA;
//   protected Integer info;
//   protected Integer[size(A, 1)] pivots;
//   protected Real[size(A, 1), size(A, 2)] LU;
// algorithm
//   (LU, pivots, info) := LAPACK.dgetrf(A);
//   assert(info == 0, "Calculating an inverse matrix with function
//     \"Matrices.inv\" is not possible, since matrix A is singular.");
//   invA := LAPACK.dgetri(LU, pivots)[1];
// end inv;
//
// class FunctionInverse
//   parameter Integer N = 3;
//   Real A[1,1];
//   Real A[1,2];
//   Real A[1,3];
//   Real A[2,1];
//   Real A[2,2];
//   Real A[2,3];
//   Real A[3,1];
//   Real A[3,2];
//   Real A[3,3];
//   Real B[1,1];
//   Real B[1,2];
//   Real B[1,3];
//   Real B[2,1];
//   Real B[2,2];
//   Real B[2,3];
//   Real B[3,1];
//   Real B[3,2];
//   Real B[3,3];
//   Real C[1,1];
//   Real C[1,2];
//   Real C[1,3];
//   Real C[2,1];
//   Real C[2,2];
//   Real C[2,3];
//   Real C[3,1];
//   Real C[3,2];
//   Real C[3,3];
// equation
//   A = {{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}};
//   B = {{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}};
//   C = inv({{A[1,1], A[1,2], A[1,3]}, {A[2,1], A[2,2], A[2,3]}, {A[3,1], A[3,2], A[3,3]}}) * B;
// end FunctionInverse;
// endResult
