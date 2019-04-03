package Modelica
  extends Modelica.Icons.Package;

  package Math
    extends Modelica.Icons.Package;

    package Vectors
      extends Modelica.Icons.Package;

      package Utilities
        extends Modelica.Icons.UtilitiesPackage;

        encapsulated function roots
          extends .Modelica.Icons.Function;
          input Real[:] p;
          output Real[max(0, size(p, 1) - 1), 2] roots = fill(0, max(0, size(p, 1) - 1), 2);
        protected
          Integer np = size(p, 1);
          Integer n = size(p, 1) - 1;
          Real[max(size(p, 1) - 1, 0), max(size(p, 1) - 1, 0)] A;
          Real[max(size(p, 1) - 1, 0), 2] ev;
        algorithm
          if n > 0 then
            assert(abs(p[1]) > 0, "Computing the roots of a polynomial with function \"Modelica.Math.Vectors.Utilities.roots\"\n" + "failed because the first element of the coefficient vector is zero, but should not be.");
            A[1, :] := -p[2:np] / p[1];
            A[2:n, :] := [identity(n - 1), zeros(n - 1)];
            roots := .Modelica.Math.Matrices.Utilities.eigenvaluesHessenberg(A);
          else
          end if;
        end roots;
      end Utilities;
    end Vectors;

    package Matrices
      extends Modelica.Icons.Package;

      package LAPACK
        extends Modelica.Icons.Package;

        function dhseqr
          extends Modelica.Icons.Function;
          input Real[:, size(H, 1)] H;
          input Boolean eigenValuesOnly = true;
          input String compz = "N";
          input Real[:, :] Z = H;
          output Real[size(H, 1)] alphaReal;
          output Real[size(H, 1)] alphaImag;
          output Integer info;
          output Real[:, :] Ho = H;
          output Real[:, :] Zo = Z;
          output Real[3 * max(1, size(H, 1))] work;
        protected
          Integer n = size(H, 1);
          String job = if eigenValuesOnly then "E" else "S";
          Integer ilo = 1;
          Integer ihi = n;
          Integer ldh = max(n, 1);
          Integer lwork = 3 * max(1, size(H, 1));
          external "Fortran 77" dhseqr(job, compz, n, ilo, ihi, Ho, ldh, alphaReal, alphaImag, Zo, ldh, work, lwork, info) annotation(Library = {"lapack"});
        end dhseqr;
      end LAPACK;

      package Utilities
        extends Modelica.Icons.UtilitiesPackage;

        function eigenvaluesHessenberg
          extends Modelica.Icons.Function;
          input Real[:, size(H, 1)] H;
          output Real[size(H, 1), 2] ev;
          output Integer info = 0;
        protected
          Real[size(H, 1)] alphaReal;
          Real[size(H, 1)] alphaImag;
        algorithm
          if size(H, 1) > 0 then
            (alphaReal, alphaImag, info) := .Modelica.Math.Matrices.LAPACK.dhseqr(H);
          else
            alphaReal := fill(0, size(H, 1));
            alphaImag := fill(0, size(H, 1));
          end if;
          ev := [alphaReal, alphaImag];
        end eigenvaluesHessenberg;
      end Utilities;
    end Matrices;
  end Math;

  package Icons
    extends Icons.Package;

    partial package Package  end Package;

    partial package UtilitiesPackage
      extends Modelica.Icons.Package;
    end UtilitiesPackage;

    partial function Function  end Function;
  end Icons;
end Modelica;

model TestRoots
  Real a;
  parameter Real b = 2;
  parameter Real c = 3;
  parameter Real d = 4;
  parameter Real e = 5;
  Real[5] p;
  Real[4, 2] r;
initial equation
  a = 1;
equation
  p = {a, b, c, d, e};
  r = Modelica.Math.Vectors.Utilities.roots(p);
  der(a) = 1;
end TestRoots;
