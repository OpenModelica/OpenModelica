// name: InnerOuter4
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

model B
  A a;
end B;

model InnerOuter4
  inner Real x = 1.0;
  B b;
end InnerOuter4;

// Result:
// class InnerOuter4
//   Real x = 1.0;
//   Real b.a.y;
// equation
//   b.a.y = x;
// end InnerOuter4;
// endResult
