// name: InStreamReduction1
// keywords: stream actualStream connector
// status: correct
//

connector C
  Real r;
  flow Real f;
  stream Real s;
end C;

model InStreamReduction1
  parameter Integer n = 3;
  C c[n];
  Real as = sum(inStream(c[i].s) for i in 1:n);
end InStreamReduction1;

// Result:
// class InStreamReduction1
//   final parameter Integer n = 3;
//   Real c[1].r;
//   Real c[1].f;
//   Real c[1].s;
//   Real c[2].r;
//   Real c[2].f;
//   Real c[2].s;
//   Real c[3].r;
//   Real c[3].f;
//   Real c[3].s;
//   Real as = c[1].s + c[2].s + c[3].s;
// equation
//   c[1].f = 0.0;
//   c[2].f = 0.0;
//   c[3].f = 0.0;
// end InStreamReduction1;
// endResult
