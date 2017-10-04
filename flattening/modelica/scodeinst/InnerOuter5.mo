// name: InnerOuter5
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model B
  outer A a;
  Real y;
equation
  y = a.x;
end B;

model C
  B b;
end C;

model InnerOuter5
  inner A a(x = 1.0);
  C c;
end InnerOuter5;

// Result:
// class InnerOuter5
//   Real a.x = 1.0;
//   Real c.b.y;
// equation
//   c.b.y = a.x;
// end InnerOuter5;
// endResult
