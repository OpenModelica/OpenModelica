// name:     ConnectHierarchical1
// keywords: connect
// status:   correct
//
// All effort variables are equal to 1. The unknown flow 'a.b.c.f'
// evaluates to -1.
//

connector Connector
  flow Real f;
  Real e;
end Connector;

model B
  Connector c;
end B;

model A
  B b;
  Connector c1, c2(f = 2.0);
equation
  connect(c1, b.c);
end A;

model ConnectHierarchical1
  A a;
  Connector c(e = 1.0, f = 1.0);
equation
  connect(a.c1, a.c2);
  connect(c, a.c1);
end ConnectHierarchical1;

// Result:
// class ConnectHierarchical1
//   Real a.b.c.f;
//   Real a.b.c.e;
//   Real a.c1.f;
//   Real a.c1.e;
//   Real a.c2.f = 2.0;
//   Real a.c2.e;
//   Real c.f = 1.0;
//   Real c.e = 1.0;
// equation
//   a.c1.e = a.b.c.e;
//   a.b.c.f - a.c1.f = 0.0;
//   c.e = a.c1.e;
//   c.e = a.c2.e;
//   a.c2.f + a.c1.f - c.f = 0.0;
//   c.f = 0.0;
// end ConnectHierarchical1;
// endResult
