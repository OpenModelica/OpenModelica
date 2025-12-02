// name: ArrayConnect5
// keywords:
// status: correct
//

connector C
  Real e[2];
  flow Real f[2];
end C;

model ArrayConnect5
  C c1[2], c2[2];
equation
  connect(c1, c2);
  annotation(__OpenModelica_commandLineOptions="-d=-nfScalarize");
end ArrayConnect5;

// Result:
// class ArrayConnect5
//   Real[2, 2] c1.e;
//   Real[2, 2] c1.f;
//   Real[2, 2] c2.e;
//   Real[2, 2] c2.f;
// equation
//   c1.e = c2.e;
//   for $i4 in 1:2 loop
//     for $i5 in 1:2 loop
//       -(c1[$i4].f[$i5] + c2[$i4].f[$i5]) = 0.0;
//     end for;
//   end for;
//   for $i2 in 1:2 loop
//     for $i3 in 1:2 loop
//       c1[$i2].f[$i3] = 0.0;
//     end for;
//   end for;
//   for $i0 in 1:2 loop
//     for $i1 in 1:2 loop
//       c2[$i0].f[$i1] = 0.0;
//     end for;
//   end for;
// end ArrayConnect5;
// endResult
