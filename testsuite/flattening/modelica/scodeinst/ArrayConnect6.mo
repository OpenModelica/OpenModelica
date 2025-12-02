// name: ArrayConnect6
// keywords:
// status: correct
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c1[2], c2;
end A;

model ArrayConnect6
  A a;
equation
  connect(a.c1[1], a.c2);
  annotation(__OpenModelica_commandLineOptions="-d=-nfScalarize");
end ArrayConnect6;

// Result:
// class ArrayConnect6
//   Real[2] a.c1.e;
//   Real[2] a.c1.f;
//   Real a.c2.e;
//   Real a.c2.f;
// equation
//   a.c1[1].e = a.c2.e;
//   a.c2.f + a.c1[1].f = 0.0;
//   a.c1[2].f = 0.0;
// end ArrayConnect6;
// endResult
