// name: Connect4
// keywords:
// status: correct
// cflags: -d=newInst
//

connector C
  Real e[2];
  flow Real f[2];
end C;

model Connect4
  C c1[2], c2[2];
equation
  connect(c1, c2);
end Connect4;

// Result:
// class Connect4
//   Real c1[1].e[1];
//   Real c1[1].e[2];
//   Real c1[1].f[1];
//   Real c1[1].f[2];
//   Real c1[2].e[1];
//   Real c1[2].e[2];
//   Real c1[2].f[1];
//   Real c1[2].f[2];
//   Real c2[1].e[1];
//   Real c2[1].e[2];
//   Real c2[1].f[1];
//   Real c2[1].f[2];
//   Real c2[2].e[1];
//   Real c2[2].e[2];
//   Real c2[2].f[1];
//   Real c2[2].f[2];
// equation
//   c1[1].e[1] = c2[1].e[1];
//   c1[1].e[2] = c2[1].e[2];
//   (-c1[1].f[1]) + (-c2[1].f[1]) = 0.0;
//   (-c1[1].f[2]) + (-c2[1].f[2]) = 0.0;
//   c1[2].e[1] = c2[2].e[1];
//   c1[2].e[2] = c2[2].e[2];
//   (-c1[2].f[1]) + (-c2[2].f[1]) = 0.0;
//   (-c1[2].f[2]) + (-c2[2].f[2]) = 0.0;
//   c1[1].f[1] = 0.0;
//   c1[1].f[2] = 0.0;
//   c1[2].f[1] = 0.0;
//   c1[2].f[2] = 0.0;
//   c2[1].f[1] = 0.0;
//   c2[1].f[2] = 0.0;
//   c2[2].f[1] = 0.0;
//   c2[2].f[2] = 0.0;
// end Connect4;
// endResult
