// name:     FillSize
// keywords: fill, ones, zeros, wholedim, size, bug1146
// status:   correct
//
// Tests the fill function with ones and zeros where the function argument is
// the size of an array of unknown size.
//
// Fix for bug #1146: http://openmodelica.ida.liu.se:8080/cb/issue/1146?navigation=true
//

function z
  input Real B[:];
  output Real A[size(B, 1)] = ones(size(B, 1));
end z;

function z2
  input Real B[:,:];
  output Real A[size(B, 1), size(B, 2)] = zeros(size(B, 1), size(B, 2));
end z2;

model FillSize
  constant Real r[:] = z(ones(3));
  constant Real r2[:,:] = z2(ones(4, 4));
end FillSize;

// Result:
// function z
//   input Real[:] B;
//   output Real[size(B, 1)] A = fill(1.0, size(B, 1));
// end z;
//
// function z2
//   input Real[:, :] B;
//   output Real[size(B, 1), size(B, 2)] A = fill(0.0, size(B, 1), size(B, 2));
// end z2;
//
// class FillSize
//   constant Real r[1] = 1.0;
//   constant Real r[2] = 1.0;
//   constant Real r[3] = 1.0;
//   constant Real r2[1,1] = 0.0;
//   constant Real r2[1,2] = 0.0;
//   constant Real r2[1,3] = 0.0;
//   constant Real r2[1,4] = 0.0;
//   constant Real r2[2,1] = 0.0;
//   constant Real r2[2,2] = 0.0;
//   constant Real r2[2,3] = 0.0;
//   constant Real r2[2,4] = 0.0;
//   constant Real r2[3,1] = 0.0;
//   constant Real r2[3,2] = 0.0;
//   constant Real r2[3,3] = 0.0;
//   constant Real r2[3,4] = 0.0;
//   constant Real r2[4,1] = 0.0;
//   constant Real r2[4,2] = 0.0;
//   constant Real r2[4,3] = 0.0;
//   constant Real r2[4,4] = 0.0;
// end FillSize;
// endResult
