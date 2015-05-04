function dgeev_eigenValues
  input Real A[:, size(A, 1)];
  output Real EigenReal[size(A, 1)];
  output Real EigenImag[size(A, 1)];
  output Integer info;
protected
  Integer lwork=8*size(A, 1);
  Real Awork[size(A, 1), size(A, 1)]=A;
  Real work[lwork];
  Real EigenvectorsL[size(A, 1), size(A, 1)]=zeros(size(A, 1), size(A, 1));
external "Fortran 77" dgeev("N", "N", size(A, 1), Awork, size(A, 1),
    EigenReal, EigenImag, EigenvectorsL, size(EigenvectorsL, 1),
    EigenvectorsL, size(EigenvectorsL, 1), work, size(work, 1), info)
    annotation (Library="Lapack");
end dgeev_eigenValues;

class TestLapack
  Real A[4,4] = [1.0, 0.0, 0.0, 0.0;
                 3.0, 2.0, 0.0, 0.0;
                 0.0, 0.0, 3.0, 1.5;
                 0.0, 0.0, -1.5, 3.0];
  Real rvalsA[4] "real part";
  Real ivalsA[4] "imaginary part";

  Real B[3,3] = [1,2,3;
                 3,4,5;
                 2,1,4];
  Real rvalsB[3] "real part";
  Real ivalsB[3] "imaginary part";
algorithm
  (rvalsA,ivalsA) := dgeev_eigenValues(A);
  (rvalsB,ivalsB) := dgeev_eigenValues(B);
end TestLapack;
