// name:     Connect16
// keywords: connect
// status:   correct
//
// Checks that the correct connect equations are generated when components are
// connected at different levels in the hierarchy.
//

connector C
  Real v;
  flow Real i;
end C;

model A
  C c;
end A;

model B
  A a1;
  A a2;
  C c1;
  C c2;
equation
  connect(a1.c, a2.c);
  connect(c1, a1.c);
  connect(c2, a2.c);
end B;

model Connect16
  B b;
  C c;
equation
  connect(c, b.c1);
  connect(c, b.c2);
end Connect16;

// Result:
// class Connect16
//   Real b.a1.c.v;
//   Real b.a1.c.i;
//   Real b.a2.c.v;
//   Real b.a2.c.i;
//   Real b.c1.v;
//   Real b.c1.i;
//   Real b.c2.v;
//   Real b.c2.i;
//   Real c.v;
//   Real c.i;
// equation
//   b.c2.v = b.a2.c.v;
//   b.c2.v = b.c1.v;
//   b.c2.v = b.a1.c.v;
//   b.a2.c.i + b.a1.c.i - b.c2.i - b.c1.i = 0.0;
//   c.v = b.c2.v;
//   c.v = b.c1.v;
//   b.c2.i + b.c1.i - c.i = 0.0;
//   c.i = 0.0;
// end Connect16;
// endResult
