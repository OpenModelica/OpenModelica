// name: ih1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  Real x;
  Real y;
equation
  y = 1.0;
end A;

model B
  A a;
end B;

model C
  B b;
equation
  b.a.x = 2.0;
end C;

// Result:
// class C
//   Real b.a.x;
//   Real b.a.y;
// equation
//   b.a.y = 1.0;
//   b.a.x = 2.0;
// end C;
// endResult
