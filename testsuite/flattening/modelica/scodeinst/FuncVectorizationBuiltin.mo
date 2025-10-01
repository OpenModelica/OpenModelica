// name: FuncVectorizationBuiltin
// keywords: vectorization function map array reduction
// status: correct
//
// Checks vectorization of simple builtin functions.
//


model FuncVectorizationBuiltin
  Real[2,3,4] a, b;
equation
  a = array(time for i in 1:4, j in 1:3, k in 1:2);
  b = sin(a);
end FuncVectorizationBuiltin;


// Result:
// class FuncVectorizationBuiltin
//   Real a[1,1,1];
//   Real a[1,1,2];
//   Real a[1,1,3];
//   Real a[1,1,4];
//   Real a[1,2,1];
//   Real a[1,2,2];
//   Real a[1,2,3];
//   Real a[1,2,4];
//   Real a[1,3,1];
//   Real a[1,3,2];
//   Real a[1,3,3];
//   Real a[1,3,4];
//   Real a[2,1,1];
//   Real a[2,1,2];
//   Real a[2,1,3];
//   Real a[2,1,4];
//   Real a[2,2,1];
//   Real a[2,2,2];
//   Real a[2,2,3];
//   Real a[2,2,4];
//   Real a[2,3,1];
//   Real a[2,3,2];
//   Real a[2,3,3];
//   Real a[2,3,4];
//   Real b[1,1,1];
//   Real b[1,1,2];
//   Real b[1,1,3];
//   Real b[1,1,4];
//   Real b[1,2,1];
//   Real b[1,2,2];
//   Real b[1,2,3];
//   Real b[1,2,4];
//   Real b[1,3,1];
//   Real b[1,3,2];
//   Real b[1,3,3];
//   Real b[1,3,4];
//   Real b[2,1,1];
//   Real b[2,1,2];
//   Real b[2,1,3];
//   Real b[2,1,4];
//   Real b[2,2,1];
//   Real b[2,2,2];
//   Real b[2,2,3];
//   Real b[2,2,4];
//   Real b[2,3,1];
//   Real b[2,3,2];
//   Real b[2,3,3];
//   Real b[2,3,4];
// equation
//   a = array(array(array(time for i in 1:4) for j in 1:3) for k in 1:2);
//   b = array(array(array(sin(a[$i0,$i1,$i2]) for $i2 in 1:4) for $i1 in 1:3) for $i0 in 1:2);
// end FuncVectorizationBuiltin;
// endResult
