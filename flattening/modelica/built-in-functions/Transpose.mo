// name:     Transpose
// keywords: transpose flatening
// status:   correct
//
// Fixed bug http://openmodelica.ida.liu.se/bugzilla/show_bug.cgi?id=170
//

model Transpose
    Real[3,5] M = [1,2,3,5,6; 1,2,3,5,6; 1,2,3,5,6];
    Real[5,3] TM;
    Real[5,3] M1 = [1,2,3; 5,6,1; 2,3,5; 6,1,2; 3,5,6];
    Real[3,5] TM1;
equation
  TM = transpose(M);
  TM1 = transpose(M1);
end Transpose;

// Result:
// class Transpose
//   Real M[1,1];
//   Real M[1,2];
//   Real M[1,3];
//   Real M[1,4];
//   Real M[1,5];
//   Real M[2,1];
//   Real M[2,2];
//   Real M[2,3];
//   Real M[2,4];
//   Real M[2,5];
//   Real M[3,1];
//   Real M[3,2];
//   Real M[3,3];
//   Real M[3,4];
//   Real M[3,5];
//   Real TM[1,1];
//   Real TM[1,2];
//   Real TM[1,3];
//   Real TM[2,1];
//   Real TM[2,2];
//   Real TM[2,3];
//   Real TM[3,1];
//   Real TM[3,2];
//   Real TM[3,3];
//   Real TM[4,1];
//   Real TM[4,2];
//   Real TM[4,3];
//   Real TM[5,1];
//   Real TM[5,2];
//   Real TM[5,3];
//   Real M1[1,1];
//   Real M1[1,2];
//   Real M1[1,3];
//   Real M1[2,1];
//   Real M1[2,2];
//   Real M1[2,3];
//   Real M1[3,1];
//   Real M1[3,2];
//   Real M1[3,3];
//   Real M1[4,1];
//   Real M1[4,2];
//   Real M1[4,3];
//   Real M1[5,1];
//   Real M1[5,2];
//   Real M1[5,3];
//   Real TM1[1,1];
//   Real TM1[1,2];
//   Real TM1[1,3];
//   Real TM1[1,4];
//   Real TM1[1,5];
//   Real TM1[2,1];
//   Real TM1[2,2];
//   Real TM1[2,3];
//   Real TM1[2,4];
//   Real TM1[2,5];
//   Real TM1[3,1];
//   Real TM1[3,2];
//   Real TM1[3,3];
//   Real TM1[3,4];
//   Real TM1[3,5];
// equation
//   M = {{1.0, 2.0, 3.0, 5.0, 6.0}, {1.0, 2.0, 3.0, 5.0, 6.0}, {1.0, 2.0, 3.0, 5.0, 6.0}};
//   M1 = {{1.0, 2.0, 3.0}, {5.0, 6.0, 1.0}, {2.0, 3.0, 5.0}, {6.0, 1.0, 2.0}, {3.0, 5.0, 6.0}};
//   TM[1,1] = M[1,1];
//   TM[1,2] = M[2,1];
//   TM[1,3] = M[3,1];
//   TM[2,1] = M[1,2];
//   TM[2,2] = M[2,2];
//   TM[2,3] = M[3,2];
//   TM[3,1] = M[1,3];
//   TM[3,2] = M[2,3];
//   TM[3,3] = M[3,3];
//   TM[4,1] = M[1,4];
//   TM[4,2] = M[2,4];
//   TM[4,3] = M[3,4];
//   TM[5,1] = M[1,5];
//   TM[5,2] = M[2,5];
//   TM[5,3] = M[3,5];
//   TM1[1,1] = M1[1,1];
//   TM1[1,2] = M1[2,1];
//   TM1[1,3] = M1[3,1];
//   TM1[1,4] = M1[4,1];
//   TM1[1,5] = M1[5,1];
//   TM1[2,1] = M1[1,2];
//   TM1[2,2] = M1[2,2];
//   TM1[2,3] = M1[3,2];
//   TM1[2,4] = M1[4,2];
//   TM1[2,5] = M1[5,2];
//   TM1[3,1] = M1[1,3];
//   TM1[3,2] = M1[2,3];
//   TM1[3,3] = M1[3,3];
//   TM1[3,4] = M1[4,3];
//   TM1[3,5] = M1[5,3];
// end Transpose;
// endResult
