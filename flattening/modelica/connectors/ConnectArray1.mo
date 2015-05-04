// name:     ConnectArray1
// keywords: connect
// status:   correct
//
// Basic connections
//

connector C
  flow Real f[3];
  Real e[3];
end C;

model M
  C c;
end M;

model ConnectArray1
  M m1[2], m2[2];
equation
  connect(m1.c, m2.c);
end ConnectArray1;

// Result:
// class ConnectArray1
//   Real m1[1].c.f[1];
//   Real m1[1].c.f[2];
//   Real m1[1].c.f[3];
//   Real m1[1].c.e[1];
//   Real m1[1].c.e[2];
//   Real m1[1].c.e[3];
//   Real m1[2].c.f[1];
//   Real m1[2].c.f[2];
//   Real m1[2].c.f[3];
//   Real m1[2].c.e[1];
//   Real m1[2].c.e[2];
//   Real m1[2].c.e[3];
//   Real m2[1].c.f[1];
//   Real m2[1].c.f[2];
//   Real m2[1].c.f[3];
//   Real m2[1].c.e[1];
//   Real m2[1].c.e[2];
//   Real m2[1].c.e[3];
//   Real m2[2].c.f[1];
//   Real m2[2].c.f[2];
//   Real m2[2].c.f[3];
//   Real m2[2].c.e[1];
//   Real m2[2].c.e[2];
//   Real m2[2].c.e[3];
// equation
//   m1[2].c.f[1] + m2[2].c.f[1] = 0.0;
//   m1[2].c.f[2] + m2[2].c.f[2] = 0.0;
//   m1[2].c.f[3] + m2[2].c.f[3] = 0.0;
//   m1[1].c.f[1] + m2[1].c.f[1] = 0.0;
//   m1[1].c.f[2] + m2[1].c.f[2] = 0.0;
//   m1[1].c.f[3] + m2[1].c.f[3] = 0.0;
//   m1[1].c.e[1] = m2[1].c.e[1];
//   m1[1].c.e[2] = m2[1].c.e[2];
//   m1[1].c.e[3] = m2[1].c.e[3];
//   m1[2].c.e[1] = m2[2].c.e[1];
//   m1[2].c.e[2] = m2[2].c.e[2];
//   m1[2].c.e[3] = m2[2].c.e[3];
// end ConnectArray1;
// endResult
