// name: NoScalarizeConnect1
// keywords:
// status: correct
//

connector C
  Real e;
  flow Real f;
end C;

model M
  C c1, c2;
equation
  connect(c1, c2);
end M;

model NoScalarizeConnect1
  M m[3];
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end NoScalarizeConnect1;

// Result:
// class NoScalarizeConnect1
//   Real[3] m.c1.e;
//   Real[3] m.c1.f;
//   Real[3] m.c2.e;
//   Real[3] m.c2.f;
// equation
//   m[3].c1.e = m[3].c2.e;
//   -(m[3].c1.f + m[3].c2.f) = 0.0;
//   m[2].c1.e = m[2].c2.e;
//   -(m[2].c1.f + m[2].c2.f) = 0.0;
//   m[1].c1.e = m[1].c2.e;
//   -(m[1].c1.f + m[1].c2.f) = 0.0;
//   for $i1 in 1:3 loop
//     m[$i1].c1.f = 0.0;
//   end for;
//   for $i1 in 1:3 loop
//     m[$i1].c2.f = 0.0;
//   end for;
// end NoScalarizeConnect1;
// endResult
