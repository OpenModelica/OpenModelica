model MatrixTest
  Real Smatrix[3,3]=[1,2,3;3,4,5;3,4,5];
  Real Cmatrix[3,3]=[4,4,3;4,4,5;3,2,1];
  Real F[3];
  Real q[3]={1,2,3};
  Real qpp[3]={3,4,5};
equation
  F = Smatrix*q +Cmatrix*qpp +Cmatrix*qpp;
end MatrixTest;
