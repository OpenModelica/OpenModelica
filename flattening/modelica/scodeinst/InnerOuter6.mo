// name: InnerOuter6
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model B
  outer A a;
end B;

model C
  B b;
  inner A a(x = 1.0);
end C;

model D
  C c;
  Real y;
equation
  y = c.b.a.x;
end D;

model InnerOuter6
  D d;
  Real z;
equation
  z = d.c.b.a.x;
end InnerOuter6;

// Result:
// class InnerOuter6
//   Real d.c.a.x = 1.0;
//   Real d.y;
//   Real z;
// equation
//   d.y = d.c.a.x;
//   z = d.c.a.x;
// end InnerOuter6;
// endResult
