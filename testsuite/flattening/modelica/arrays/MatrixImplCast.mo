// name: MatrixImplCast
// keywords: matrix typecasting #3409
// status: correct
//
// Checks that expressions in matrix constructor are typecast to Real properly
// if there's a mix of Real and Integer expressions.
//

model MatrixImplCast
  function f
    input Real v[:];
    output Real m[size(v, 1), 2];
  algorithm
    m := [zeros(size(v, 1)), v];
  end f;

  Real m[:, :] = f({0.1, 0.2, 0.3});
end MatrixImplCast;

// Result:
// function MatrixImplCast.f
//   input Real[:] v;
//   output Real[size(v, 1), 2] m;
// algorithm
//   m := cat(2, promote(fill(0.0, size(v, 1)), 2), promote(v, 2));
// end MatrixImplCast.f;
//
// class MatrixImplCast
//   Real m[1,1];
//   Real m[1,2];
//   Real m[2,1];
//   Real m[2,2];
//   Real m[3,1];
//   Real m[3,2];
// equation
//   m = {{0.0, 0.1}, {0.0, 0.2}, {0.0, 0.3}};
// end MatrixImplCast;
// endResult
