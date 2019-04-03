// name: Size3
// keywords: size
// status: correct
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model Size3
  Real x[3, 2, 4];
  Integer n = size(x[1], 1);
end Size3;

// Result:
// class Size3
//   Real x[1,1,1];
//   Real x[1,1,2];
//   Real x[1,1,3];
//   Real x[1,1,4];
//   Real x[1,2,1];
//   Real x[1,2,2];
//   Real x[1,2,3];
//   Real x[1,2,4];
//   Real x[2,1,1];
//   Real x[2,1,2];
//   Real x[2,1,3];
//   Real x[2,1,4];
//   Real x[2,2,1];
//   Real x[2,2,2];
//   Real x[2,2,3];
//   Real x[2,2,4];
//   Real x[3,1,1];
//   Real x[3,1,2];
//   Real x[3,1,3];
//   Real x[3,1,4];
//   Real x[3,2,1];
//   Real x[3,2,2];
//   Real x[3,2,3];
//   Real x[3,2,4];
//   Integer n = 2;
// end Size3;
// endResult

