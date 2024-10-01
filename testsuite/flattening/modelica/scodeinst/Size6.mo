// name: Size6
// keywords: size
// status: correct
//
// Tests the builtin size operator.
//

type T = Real[4];

model A
  T x;
end A;

model Size6
  Real x[n];
  A a;
  parameter Integer n = size(a.x, 1);
end Size6;

// Result:
// class Size6
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real a.x[1];
//   Real a.x[2];
//   Real a.x[3];
//   Real a.x[4];
//   final parameter Integer n = 4;
// end Size6;
// endResult
