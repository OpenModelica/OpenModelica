// name:     MatrixRowIndexing
// keywords: Row indexing of matrix
// status:   correct
//
// Make sure row indexing of matrix works fine!
// Also constant evaluation via Cevalfunc.mo module.
//

function callMe
  input Real[:] a;
  output Real[size(a,1)] b;
algorithm
  b := a;
end callMe;

model MatrixRowIndexing
  constant Real a[7,5]= {{01.0, 02.0, 03.0, 04.0, 05.0},
                         {06.0, 07.0, 08.0, 09.0, 10.0},
                         {11.0, 12.0, 13.0, 14.0, 15.0},
                         {16.0, 17.0, 18.0, 19.0, 20.0},
                         {21.0, 22.0, 23.0, 24.0, 25.0},
                         {26.0, 27.0, 28.0, 29.0, 30.0},
                         {31.0, 32.0, 33.0, 34.0, 35.0}};
  Real b[size(a,2)];
  Real c[size(a,2)];
  Real d[size(a,2)];
equation
  b = a[1, :];
  c = callMe(a[3, :]);
algorithm
  d := a[4, :];
end MatrixRowIndexing;

// Result:
// function callMe
//   input Real[:] a;
//   output Real[size(a, 1)] b;
// algorithm
//   b := a;
// end callMe;
//
// class MatrixRowIndexing
//   constant Real a[1,1] = 1.0;
//   constant Real a[1,2] = 2.0;
//   constant Real a[1,3] = 3.0;
//   constant Real a[1,4] = 4.0;
//   constant Real a[1,5] = 5.0;
//   constant Real a[2,1] = 6.0;
//   constant Real a[2,2] = 7.0;
//   constant Real a[2,3] = 8.0;
//   constant Real a[2,4] = 9.0;
//   constant Real a[2,5] = 10.0;
//   constant Real a[3,1] = 11.0;
//   constant Real a[3,2] = 12.0;
//   constant Real a[3,3] = 13.0;
//   constant Real a[3,4] = 14.0;
//   constant Real a[3,5] = 15.0;
//   constant Real a[4,1] = 16.0;
//   constant Real a[4,2] = 17.0;
//   constant Real a[4,3] = 18.0;
//   constant Real a[4,4] = 19.0;
//   constant Real a[4,5] = 20.0;
//   constant Real a[5,1] = 21.0;
//   constant Real a[5,2] = 22.0;
//   constant Real a[5,3] = 23.0;
//   constant Real a[5,4] = 24.0;
//   constant Real a[5,5] = 25.0;
//   constant Real a[6,1] = 26.0;
//   constant Real a[6,2] = 27.0;
//   constant Real a[6,3] = 28.0;
//   constant Real a[6,4] = 29.0;
//   constant Real a[6,5] = 30.0;
//   constant Real a[7,1] = 31.0;
//   constant Real a[7,2] = 32.0;
//   constant Real a[7,3] = 33.0;
//   constant Real a[7,4] = 34.0;
//   constant Real a[7,5] = 35.0;
//   Real b[1];
//   Real b[2];
//   Real b[3];
//   Real b[4];
//   Real b[5];
//   Real c[1];
//   Real c[2];
//   Real c[3];
//   Real c[4];
//   Real c[5];
//   Real d[1];
//   Real d[2];
//   Real d[3];
//   Real d[4];
//   Real d[5];
// equation
//   b[1] = 1.0;
//   b[2] = 2.0;
//   b[3] = 3.0;
//   b[4] = 4.0;
//   b[5] = 5.0;
//   c[1] = 11.0;
//   c[2] = 12.0;
//   c[3] = 13.0;
//   c[4] = 14.0;
//   c[5] = 15.0;
// algorithm
//   d := {16.0, 17.0, 18.0, 19.0, 20.0};
// end MatrixRowIndexing;
// endResult
