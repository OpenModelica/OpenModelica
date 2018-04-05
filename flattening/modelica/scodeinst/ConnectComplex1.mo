// name: ConnectComplex1
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real r1;
  Real r2;
end R;

connector C
  R e;
  flow R f;
end C;

model M
  C c;
end M;

model ConnectComplex1
  M m1, m2;
equation
  connect(m1.c, m2.c);
end ConnectComplex1;

// Result:
// class ConnectComplex1
//   Real m1.c.e.r1;
//   Real m1.c.e.r2;
//   Real m1.c.f.r1;
//   Real m1.c.f.r2;
//   Real m2.c.e.r1;
//   Real m2.c.e.r2;
//   Real m2.c.f.r1;
//   Real m2.c.f.r2;
// equation
//   m1.c.e.r1 = m2.c.e.r1;
//   m1.c.e.r2 = m2.c.e.r2;
//   m2.c.f.r1 + m1.c.f.r1 = 0.0;
//   m2.c.f.r2 + m1.c.f.r2 = 0.0;
// end ConnectComplex1;
// endResult
