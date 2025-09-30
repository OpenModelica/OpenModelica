// name: InStreamArray2
// keywords: stream instream connector
// status: correct
//

connector C
  Real p;
  flow Real f;
  stream Real s;
end C;

partial model A
  C c;
end A;

model M
  A1 a1;
  A2 a2;
  input Real s;
equation
  connect(a1.c, a2.c);
end M;

model A1
  extends A;
equation
  c.p = sin(time);
  c.s = cos(time);
end A1;

model A2
  extends A;
equation
  c.f = sin(time);
  c.s = cos(time);
end A2;

model InStreamArray2
  M[2] m(s={inStream(m[i].a1.c.s) + inStream(m[i].a2.c.s) for i in 1:2});
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end InStreamArray2;

// Result:
// class InStreamArray2
//   Real[2] m.a1.c.p;
//   Real[2] m.a1.c.f;
//   Real[2] m.a1.c.s;
//   Real[2] m.a2.c.p;
//   Real[2] m.a2.c.f;
//   Real[2] m.a2.c.s;
//   Real[2] m.s = {m[1].a1.c.s + m[1].a2.c.s, m[2].a1.c.s + m[2].a2.c.s};
// equation
//   m[2].a1.c.p = m[2].a2.c.p;
//   m[1].a1.c.p = m[1].a2.c.p;
//   m[1].a2.c.f + m[1].a1.c.f = 0.0;
//   m[2].a2.c.f + m[2].a1.c.f = 0.0;
//   for $i4 in 1:2 loop
//     m[$i4].a1.c.p = sin(time);
//   end for;
//   for $i3 in 1:2 loop
//     m[$i3].a1.c.s = cos(time);
//   end for;
//   for $i2 in 1:2 loop
//     m[$i2].a2.c.f = sin(time);
//   end for;
//   for $i1 in 1:2 loop
//     m[$i1].a2.c.s = cos(time);
//   end for;
// end InStreamArray2;
// endResult
