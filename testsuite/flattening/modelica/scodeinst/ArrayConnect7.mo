// name: ArrayConnect7
// keywords:
// status: correct
//
// A slice of known size, 2:end, is evaluated to an index array before the
// array connection handler sees it.
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C p, n;
equation
  p.f + n.f = 0;
  p.e - n.e = p.f;
end A;

model ArrayConnect7
  A a[4];
equation
  connect(a[2:end].p, a[1:end-1].n);
  annotation(__OpenModelica_commandLineOptions="-d=arrayConnect,-nfScalarize");
end ArrayConnect7;

// Result:
// class ArrayConnect7
//   Real[4] a.p.e;
//   Real[4] a.p.f;
//   Real[4] a.n.e;
//   Real[4] a.n.f;
// equation
//   for $i1 in 1:4 loop
//     a[$i1].p.f + a[$i1].n.f = 0.0;
//   end for;
//   for $i0 in 1:4 loop
//     a[$i0].p.e - a[$i0].n.e = a[$i0].p.f;
//   end for;
//   for $i2 in 1:3 loop
//     a[$i2].n.e = a[$i2 + 1].p.e;
//   end for;
//   for $i2 in 2:4 loop
//     a[$i2].p.f + a[$i2 - 1].n.f = 0.0;
//   end for;
//   a[1].p.f = 0.0;
//   a[4].n.f = 0.0;
// end ArrayConnect7;
// endResult
