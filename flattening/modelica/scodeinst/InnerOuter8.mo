// name: InnerOuter8
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
equation
  a.x = a.y;
end B;

model C
  outer B b;
end C;

model D
  C c;
end D;

model E
  inner B b;
  D d;
end E;

model InnerOuter8
  inner Real x = 1.0;
  E e;
  Real y = e.d.c.b.a.x;
  Real z = e.d.c.b.a.y;
end InnerOuter8;

// Result:
// class InnerOuter8
//   Real x = 1.0;
//   Real e.b.a.y;
//   Real y = x;
//   Real z = e.b.a.y;
// equation
//   e.b.a.y = x;
//   x = e.b.a.y;
// end InnerOuter8;
// endResult
