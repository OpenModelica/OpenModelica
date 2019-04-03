// name:     ConstantReductions
// keywords: declaration
// status:   correct
//
// Constant evaluation of reductions.
//

class ConstantReductions
  Real x1, x2, x3, x4;
  Real v[5];
  Real v2[2];
  String s;
  Integer arr[5];
equation
  x1 = sum(i * 3 for i in {1,3,4,5});
  x2 = min(i for i in 1:5);
  x3 = max(i - 3 for i in 1:4);
  x4 = product(i for i in 1:5);
  v = {product(j for j in 1:i) for i in 0:4};
  v2 = sum(j for j in {{1,2},{3,4}});
  s = sum(i for i in {"Hello", " ", "world", "!"});
  arr = {i for i in 1:5};
end ConstantReductions;

// Result:
// class ConstantReductions
//   Real x1;
//   Real x2;
//   Real x3;
//   Real x4;
//   Real v[1];
//   Real v[2];
//   Real v[3];
//   Real v[4];
//   Real v[5];
//   Real v2[1];
//   Real v2[2];
//   String s;
//   Integer arr[1];
//   Integer arr[2];
//   Integer arr[3];
//   Integer arr[4];
//   Integer arr[5];
// equation
//   x1 = 39.0;
//   x2 = 1.0;
//   x3 = 1.0;
//   x4 = 120.0;
//   v[1] = 1.0;
//   v[2] = 1.0;
//   v[3] = 2.0;
//   v[4] = 6.0;
//   v[5] = 24.0;
//   v2[1] = 4.0;
//   v2[2] = 6.0;
//   s = "Hello world!";
//   arr[1] = 1;
//   arr[2] = 2;
//   arr[3] = 3;
//   arr[4] = 4;
//   arr[5] = 5;
// end ConstantReductions;
// endResult
