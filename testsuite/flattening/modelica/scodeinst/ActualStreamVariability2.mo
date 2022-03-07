// name: ActualStreamVariability2
// keywords: stream actualStream connector
// status: correct
// cflags: -d=newInst
//

connector C
  Real r;
  flow Real f;
  stream Real s;
end C;

model ActualStreamVariability2
  C c[2];
  parameter Integer n = 1;
  Real as = actualStream(c[n].s);
end ActualStreamVariability2;

// Result:
// class ActualStreamVariability2
//   Real c[1].r;
//   Real c[1].f;
//   Real c[1].s;
//   Real c[2].r;
//   Real c[2].f;
//   Real c[2].s;
//   final parameter Integer n = 1;
//   Real as = c[1].s;
// equation
//   c[1].f = 0.0;
//   c[2].f = 0.0;
// end ActualStreamVariability2;
// endResult
