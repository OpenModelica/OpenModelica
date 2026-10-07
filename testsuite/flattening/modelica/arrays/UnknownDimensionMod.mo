// name:     UnknownDimensionMod.mo
// keywords: deduce unknown dimensions from modifier
// status:   correct
//
// check that we can deduce dimensions from array/matrix modifiers
//

model UnknownDimensionMod "check that we can deduce unknown dimensions from array/matrix modifier"
  type T = Real[:, :];
  parameter T matrix = [ 1,  2;  3,  4;  5,  6;
                             7,  8;  9, 10; 11, 12;
                            13, 14; 15, 16; 17, 18;
                            19, 20; 21, 22; 23, 24;
                            25, 26];

  parameter Real arr[:] = zeros(10);

  model A
    parameter T b;
  end A;

  A a(b = matrix);

end UnknownDimensionMod;

// Result:
// class UnknownDimensionMod "check that we can deduce unknown dimensions from array/matrix modifier"
//   parameter Real matrix[1,1] = 1.0;
//   parameter Real matrix[1,2] = 2.0;
//   parameter Real matrix[2,1] = 3.0;
//   parameter Real matrix[2,2] = 4.0;
//   parameter Real matrix[3,1] = 5.0;
//   parameter Real matrix[3,2] = 6.0;
//   parameter Real matrix[4,1] = 7.0;
//   parameter Real matrix[4,2] = 8.0;
//   parameter Real matrix[5,1] = 9.0;
//   parameter Real matrix[5,2] = 10.0;
//   parameter Real matrix[6,1] = 11.0;
//   parameter Real matrix[6,2] = 12.0;
//   parameter Real matrix[7,1] = 13.0;
//   parameter Real matrix[7,2] = 14.0;
//   parameter Real matrix[8,1] = 15.0;
//   parameter Real matrix[8,2] = 16.0;
//   parameter Real matrix[9,1] = 17.0;
//   parameter Real matrix[9,2] = 18.0;
//   parameter Real matrix[10,1] = 19.0;
//   parameter Real matrix[10,2] = 20.0;
//   parameter Real matrix[11,1] = 21.0;
//   parameter Real matrix[11,2] = 22.0;
//   parameter Real matrix[12,1] = 23.0;
//   parameter Real matrix[12,2] = 24.0;
//   parameter Real matrix[13,1] = 25.0;
//   parameter Real matrix[13,2] = 26.0;
//   parameter Real arr[1] = 0.0;
//   parameter Real arr[2] = 0.0;
//   parameter Real arr[3] = 0.0;
//   parameter Real arr[4] = 0.0;
//   parameter Real arr[5] = 0.0;
//   parameter Real arr[6] = 0.0;
//   parameter Real arr[7] = 0.0;
//   parameter Real arr[8] = 0.0;
//   parameter Real arr[9] = 0.0;
//   parameter Real arr[10] = 0.0;
//   parameter Real a.b[1,1] = matrix[1,1];
//   parameter Real a.b[1,2] = matrix[1,2];
//   parameter Real a.b[2,1] = matrix[2,1];
//   parameter Real a.b[2,2] = matrix[2,2];
//   parameter Real a.b[3,1] = matrix[3,1];
//   parameter Real a.b[3,2] = matrix[3,2];
//   parameter Real a.b[4,1] = matrix[4,1];
//   parameter Real a.b[4,2] = matrix[4,2];
//   parameter Real a.b[5,1] = matrix[5,1];
//   parameter Real a.b[5,2] = matrix[5,2];
//   parameter Real a.b[6,1] = matrix[6,1];
//   parameter Real a.b[6,2] = matrix[6,2];
//   parameter Real a.b[7,1] = matrix[7,1];
//   parameter Real a.b[7,2] = matrix[7,2];
//   parameter Real a.b[8,1] = matrix[8,1];
//   parameter Real a.b[8,2] = matrix[8,2];
//   parameter Real a.b[9,1] = matrix[9,1];
//   parameter Real a.b[9,2] = matrix[9,2];
//   parameter Real a.b[10,1] = matrix[10,1];
//   parameter Real a.b[10,2] = matrix[10,2];
//   parameter Real a.b[11,1] = matrix[11,1];
//   parameter Real a.b[11,2] = matrix[11,2];
//   parameter Real a.b[12,1] = matrix[12,1];
//   parameter Real a.b[12,2] = matrix[12,2];
//   parameter Real a.b[13,1] = matrix[13,1];
//   parameter Real a.b[13,2] = matrix[13,2];
// end UnknownDimensionMod;
// endResult
