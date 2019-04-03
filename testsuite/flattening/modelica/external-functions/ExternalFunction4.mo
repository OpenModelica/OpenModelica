// name:     ExternalFunction4
// keywords: external function,code generation,constant propagation
// status:   correct
// teardown_command: rm -f ExternalFunction4_*
//
// Constant evaluation of function calls using Library annotation.
// The following example is from MSL and should propagate all constants.
//

model ExternalFunction4

function inv
  input Real A[2,2];
  output Real invA[2,2];
protected
  Integer info;
  Integer pivots[size(A,1)];
  Real LU[size(A,1),size(A,2)];
algorithm
  (LU,pivots,info) := dgetrf(A);
  assert(info == 0,"Calculating an inverse matrix with function \"Matrices.inv\" is not possible, since matrix A is singular.");
  invA := dgetri(LU,pivots);
end inv;

function dgetri
  input Real LU[:,size(LU,1)];
  input Integer pivots[size(LU,1)];
  output Real inv[size(LU,1),size(LU,2)]=LU;
protected
  Integer lwork=min(10,size(LU,1))*size(LU,1);
  Real work[lwork];
  Integer info;
  external "FORTRAN 77" dgetri(size(LU,1),inv,size(LU,1),pivots,work,lwork,info) annotation (Library="Lapack");
end dgetri;

function dgetrf
  input Real A[:,:];
  output Real LU[size(A,1),size(A,2)]=A;
  output Integer pivots[min(size(A,1),size(A,2))];
  output Integer info;
external "FORTRAN 77" dgetrf(size(A,1),size(A,2),LU,size(A,1),pivots,info) annotation (Library="Lapack");
end dgetrf;

  constant Real r[2,2] = {{1,2},{3,4}};
  Real r2[2,2] = r*inv(r);
end ExternalFunction4;

// Result:
// function ExternalFunction4.dgetrf
//   input Real[:, :] A;
//   output Real[size(A, 1), size(A, 2)] LU = A;
//   output Integer[min(size(A, 1), size(A, 2))] pivots;
//   output Integer info;
//
//   external "FORTRAN 77" dgetrf(size(A, 1), size(A, 2), LU, size(A, 1), pivots, info);
// end ExternalFunction4.dgetrf;
//
// function ExternalFunction4.dgetri
//   input Real[:, size(LU, 1)] LU;
//   input Integer[size(LU, 1)] pivots;
//   output Real[size(LU, 1), size(LU, 2)] inv = LU;
//   protected Integer info;
//   protected Integer lwork = min(10, size(LU, 1)) * size(LU, 1);
//   protected Real[lwork] work;
//
//   external "FORTRAN 77" dgetri(size(LU, 1), inv, size(LU, 1), pivots, work, lwork, info);
// end ExternalFunction4.dgetri;
//
// function ExternalFunction4.inv
//   input Real[2, 2] A;
//   output Real[2, 2] invA;
//   protected Integer info;
//   protected Integer[2] pivots;
//   protected Real[2, 2] LU;
// algorithm
//   (LU, pivots, info) := ExternalFunction4.dgetrf({{A[1,1], A[1,2]}, {A[2,1], A[2,2]}});
//   assert(info == 0, "Calculating an inverse matrix with function \"Matrices.inv\" is not possible, since matrix A is singular.");
//   invA := ExternalFunction4.dgetri({{LU[1,1], LU[1,2]}, {LU[2,1], LU[2,2]}}, {pivots[1], pivots[2]});
// end ExternalFunction4.inv;
//
// class ExternalFunction4
//   constant Real r[1,1] = 1.0;
//   constant Real r[1,2] = 2.0;
//   constant Real r[2,1] = 3.0;
//   constant Real r[2,2] = 4.0;
//   Real r2[1,1];
//   Real r2[1,2];
//   Real r2[2,1];
//   Real r2[2,2];
// equation
//   r2 = {{1.0, 0.0}, {8.881784197001252e-16, 0.9999999999999996}};
// end ExternalFunction4;
// endResult
