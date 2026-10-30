// name:     ConstantReductions
// keywords: declaration
// status:   correct
//
// Constant evaluation of reductions.
//

model ConstantReductions
  Real x1, x2, x3, x4;
  constant Real v[5] = {product(j for j in 1:i) for i in 0:4};
  constant Integer arr[5] = {i for i in 1:5};
equation
  x1 = sum(i * 3 for i in {1,3,4,5});
  x2 = min(i for i in 1:5);
  x3 = max(i - 3 for i in 1:4);
  x4 = product(i for i in 1:5);
end ConstantReductions;

// Result:
// class ConstantReductions
//   Real x1;
//   Real x2;
//   Real x3;
//   Real x4;
//   constant Real v[1] = 1.0;
//   constant Real v[2] = 1.0;
//   constant Real v[3] = 2.0;
//   constant Real v[4] = 6.0;
//   constant Real v[5] = 24.0;
//   constant Integer arr[1] = 1;
//   constant Integer arr[2] = 2;
//   constant Integer arr[3] = 3;
//   constant Integer arr[4] = 4;
//   constant Integer arr[5] = 5;
// equation
//   x1 = 39.0;
//   x2 = 1.0;
//   x3 = 1.0;
//   x4 = 120.0;
// end ConstantReductions;
// endResult
