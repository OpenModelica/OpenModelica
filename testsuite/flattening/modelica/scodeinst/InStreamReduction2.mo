// name: InStreamReduction2
// keywords: stream inStream reduction
// status: correct
//
// A sum reduction of an array-valued inStream is element-wise.
//

connector C
  Real r;
  flow Real f;
  stream Real s[2];
end C;

model InStreamReduction2
  parameter Integer n = 3;
  C c[n];
  Real as[2] = sum(inStream(c[i].s) for i in 1:n);
end InStreamReduction2;

// Result:
// class InStreamReduction2
//   final parameter Integer n = 3;
//   Real c[1].r;
//   Real c[1].f;
//   Real c[1].s[1];
//   Real c[1].s[2];
//   Real c[2].r;
//   Real c[2].f;
//   Real c[2].s[1];
//   Real c[2].s[2];
//   Real c[3].r;
//   Real c[3].f;
//   Real c[3].s[1];
//   Real c[3].s[2];
//   Real as[1];
//   Real as[2];
// equation
//   c[1].f = 0.0;
//   c[2].f = 0.0;
//   c[3].f = 0.0;
//   as = {c[1].s[1] + c[2].s[1] + c[3].s[1], c[1].s[2] + c[2].s[2] + c[3].s[2]};
// end InStreamReduction2;
// endResult
