// name: ArrayConnect5
// keywords:
// status: correct
// cflags: -d=newInst,-nfScalarize
//

connector C
  Real e[2];
  flow Real f[2];
end C;

model ArrayConnect5
  C c1[2], c2[2];
equation
  connect(c1, c2);
end ArrayConnect5;

// Result:
// class ArrayConnect5
//   Real[2, 2] c1.f;
//   Real[2, 2] c1.e;
//   Real[2, 2] c2.f;
//   Real[2, 2] c2.e;
// equation
//   c1.e = c2.e;
//   for $i1 in 1:2 loop
//     for $i2 in 1:2 loop
//       -(c1[$i1].f[$i2] + c2[$i1].f[$i2]) = 0.0;
//     end for;
//   end for;
//   for $i1 in 1:2 loop
//     for $i2 in 1:2 loop
//       c1[$i1].f[$i2] = 0.0;
//     end for;
//   end for;
//   for $i1 in 1:2 loop
//     for $i2 in 1:2 loop
//       c2[$i1].f[$i2] = 0.0;
//     end for;
//   end for;
// end ArrayConnect5;
// endResult
