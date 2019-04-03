// name: InnerOuter1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model A
  outer Real x;
  Real y;
equation
  y = x;
end A;

model InnerOuter1
  inner Real x = 1.0;
  A a1, a2;
end InnerOuter1;

// Result:
// class InnerOuter1
//   Real x = 1.0;
//   Real a1.y;
//   Real a2.y;
// equation
//   a1.y = x;
//   a2.y = x;
// end InnerOuter1;
// endResult
