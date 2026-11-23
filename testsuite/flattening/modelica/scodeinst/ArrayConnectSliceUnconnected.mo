// name: ArrayConnectSliceUnconnected
// keywords:
// status: correct
//
// The elements of a connector array outside of a connected slice are
// unconnected, their flow variables are zero.

connector C
  Real e;
  flow Real f;
end C;

model Cell
  C a, b;
  Real T(fixed = true);
equation
  der(T) = a.f + b.f;
  a.f = a.e - T;
  b.f = b.e - T;
end Cell;

model ArrayConnectSliceUnconnected
  Cell c[3](T(start = {1, 2, 3}));
equation
  connect(c[1:end - 1].b, c[2:end].a);
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end ArrayConnectSliceUnconnected;

// Result:
// class ArrayConnectSliceUnconnected
//   Real[3] c.a.e;
//   Real[3] c.a.f;
//   Real[3] c.b.e;
//   Real[3] c.b.f;
//   Real[3] c.T(start = {1.0, 2.0, 3.0}, fixed = array(true for $f1 in 1:3));
// equation
//   c[{1, 2}].b.e = c[{2, 3}].a.e;
//   for $i3 in 1:2 loop
//     c[{2, 3}[$i3]].a.f + c[{1, 2}[$i3]].b.f = 0.0;
//   end for;
//   c[1].a.f = 0.0;
//   c[3].b.f = 0.0;
//   for $i2 in 1:3 loop
//     der(c[$i2].T) = c[$i2].a.f + c[$i2].b.f;
//   end for;
//   for $i1 in 1:3 loop
//     c[$i1].a.f = c[$i1].a.e - c[$i1].T;
//   end for;
//   for $i0 in 1:3 loop
//     c[$i0].b.f = c[$i0].b.e - c[$i0].T;
//   end for;
// end ArrayConnectSliceUnconnected;
// endResult
