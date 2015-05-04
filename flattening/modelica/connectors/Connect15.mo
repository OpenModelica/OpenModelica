// name: Connect15
// keywords:  connector, arrays
// status: correct
//
// Test that it is possible to connect to array of connector.
//

connector Pin
 flow Real i;
 Real v;
end Pin;

model A
  Pin p[2];
end A;

model Connect15
  A t1,t2;
equation
connect(t1.p[1],t2.p[2]);
end Connect15;

// Result:
// class Connect15
//   Real t1.p[1].i;
//   Real t1.p[1].v;
//   Real t1.p[2].i;
//   Real t1.p[2].v;
//   Real t2.p[1].i;
//   Real t2.p[1].v;
//   Real t2.p[2].i;
//   Real t2.p[2].v;
// equation
//   t1.p[2].i = 0.0;
//   t1.p[1].i + t2.p[2].i = 0.0;
//   t2.p[1].i = 0.0;
//   t1.p[1].v = t2.p[2].v;
// end Connect15;
// endResult
