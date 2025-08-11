// name: NoScalarizeConnect2
// keywords:
// status: correct
//

connector C
  Real e;
  flow Real f;
  stream Real s;
end C;

model NoScalarizeConnect2
  C c[3];
  Real x;
equation
  for i in 1:3 loop
    x = actualStream(c[i].s);
  end for;
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end NoScalarizeConnect2;

// Result:
// class NoScalarizeConnect2
//   Real[3] c.e;
//   Real[3] c.f;
//   Real[3] c.s;
//   Real x;
// equation
//   for $i0 in 1:3 loop
//     c[$i0].f = 0.0;
//   end for;
//   x = c[1].s;
//   x = c[2].s;
//   x = c[3].s;
// end NoScalarizeConnect2;
// endResult
