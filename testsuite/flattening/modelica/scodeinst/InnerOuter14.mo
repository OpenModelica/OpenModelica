// name: InnerOuter14
// keywords:
// status: correct
//

model A
  inner outer Real x;
equation
  x = 0;
end A;

model InnerOuter14
  inner Real x = 1;
  A a;
end InnerOuter14;

// Result:
// class InnerOuter14
//   Real x = 1.0;
//   Real a.x;
// equation
//   x = 0.0;
// end InnerOuter14;
// endResult
