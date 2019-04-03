// name: RealSubEw
// keywords: real, subtraction, element-wise
// status: correct
//
// Tests element-wise scalar-array subtraction.
//

function f
  input Real r1;
  input Real r2[:];
  output Real o[size(r2, 1)];
algorithm
  o := r1 .- r2;
end f;

model RealAddEw
  Real x[:] = f(3, {4, 5, 6});
end RealAddEw;

// Result:
// function f
//   input Real r1;
//   input Real[:] r2;
//   output Real[size(r2, 1)] o;
// algorithm
//   o := r1 .- r2;
// end f;
//
// class RealAddEw
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {-1.0, -2.0, -3.0};
// end RealAddEw;
// endResult
