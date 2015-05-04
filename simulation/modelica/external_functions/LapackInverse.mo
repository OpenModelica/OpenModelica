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

model LapackInverse
  parameter Integer N = 3;
  Real[N, N] A = identity(N);
  Real[N, N] B = identity(N);
  Real[N, N] C;
equation
  C = inv(A) * B;
end LapackInverse;
