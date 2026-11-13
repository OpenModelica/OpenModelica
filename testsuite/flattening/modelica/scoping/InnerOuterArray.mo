// name:     InnerOuterArray
// keywords: dynamic scope, inner outer, lookup, array
// status:   correct
//
// Tests that inner/outer arrays are handled correctly.
//

model A
  outer Real x[3];
  Real y;
equation
  y = x * x;
end A;

model InnerOuterArray
  A a;
  inner Real x[3];
end InnerOuterArray;

// Result:
// class InnerOuterArray
//   Real a.y;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   a.y = x[1] * x[1] + x[2] * x[2] + x[3] * x[3];
// end InnerOuterArray;
// endResult
