// name:     Connect16
// keywords: connect
// status:   correct
//
// Checks that the correct connect equations are generated when components are
// connected at different levels in the hierarchy.
//

connector C
  Real v;
  flow Real i;
end C;

model A
  C c;
end A;

model B
  A a1;
  A a2;
equation
  connect(a1.c, a2.c);
end B;

model Connect16
  B b;
  C c;
equation
  connect(c, b.a1.c);
  connect(c, b.a2.c);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Connect16;

// Result:
// class Connect16
//   Real b.a1.c.v;
//   Real b.a1.c.i;
//   Real b.a2.c.v;
//   Real b.a2.c.i;
//   Real c.v;
//   Real c.i;
// equation
//   b.a1.c.i + b.a2.c.i + (-c.i) = 0.0;
//   b.a1.c.v = b.a2.c.v;
//   b.a1.c.v = c.v;
//   c.i = 0.0;
// end Connect16;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
