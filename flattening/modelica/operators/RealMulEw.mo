// name: RealMulEw
// keywords: real, multiplication, element-wise
// status: correct
//
// Tests element-wise array multiplication.
//

function f
  input Real r1[:];
  input Real r2[size(r1, 1)];
  output Real o[size(r1, 1)];
algorithm
  o := r1 .* r2;
end f;

model RealMulEw
  Real x[:] = f({1, 2, 3}, {4, 5, 6});
end RealMulEw;

// Result:
// function f
//   input Real[:] r1;
//   input Real[size(r1, 1)] r2;
//   output Real[size(r1, 1)] o;
// algorithm
//   o := r1 .* r2;
// end f;
//
// class RealMulEw
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {4.0, 10.0, 18.0};
// end RealMulEw;
// endResult
