// name:     Scalar
// keywords: array, scalar
// status:   correct
//
// Tests the scalar dimensionality conversion function.
//

model Scalar
  function f
    input Real[:] rs;
    output Integer i;
  algorithm
    i :=  scalar(size(rs));
  end f;

  Real r1 = scalar({3});
  Real r2 = scalar({{4}});
  Real r3 = scalar({{{5}}});
  Real r4 = scalar([6]);
  Real r5 = f(fill(1,3));
end Scalar;

// Result:
// function Scalar.f
//   input Real[:] rs;
//   output Integer i;
// algorithm
//   i := size(rs, 1);
// end Scalar.f;
//
// class Scalar
//   Real r1 = 3.0;
//   Real r2 = 4.0;
//   Real r3 = 5.0;
//   Real r4 = 6.0;
//   Real r5 = 3.0;
// end Scalar;
// endResult
