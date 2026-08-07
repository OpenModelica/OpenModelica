model TestExtLapack "external FORTRAN 77 (LAPACK) with protected work variables"
  // Deliberately not symmetric: a transposed A would still solve, so only an
  // asymmetric one catches a missing row-major/column-major conversion.
  parameter Real A[3, 3] = {{2, 1, 5}, {7, 3, 1}, {0, 4, 6}};
  parameter Real b[3] = {1, 2, 3};
  Real xs[3];
  Integer infos;
  Real LU[3, 3];
  Integer pivots[3];
  Integer inff;
  Real y(start = 0, fixed = true);
equation
  (xs, infos) = Modelica.Math.Matrices.LAPACK.dgesv_vec(A, b);
  (LU, pivots, inff) = Modelica.Math.Matrices.LAPACK.dgetrf(A);
  der(y) = xs[1] + LU[2, 2];
end TestExtLapack;
