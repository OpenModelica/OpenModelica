// name:     ConnectionOrder1
// keywords: connect
// status:   correct
// cflags: +orderConnections=false
//
// Makes sure that the connection order is preserved when
// +orderConnections=false is used.
//

connector C
  flow Real f;
  Real e;
end C;

model ConnectionOrder1
  C c1, c2, c3, c4;
equation
  connect(c1, c2);
  connect(c4, c3);
end ConnectionOrder1;

// Result:
// class ConnectionOrder1
//   Real c1.f;
//   Real c1.e;
//   Real c2.f;
//   Real c2.e;
//   Real c3.f;
//   Real c3.e;
//   Real c4.f;
//   Real c4.e;
// equation
//   c1.f = 0.0;
//   c2.f = 0.0;
//   c3.f = 0.0;
//   c4.f = 0.0;
//   c1.e = c2.e;
//   (-c1.f) + (-c2.f) = 0.0;
//   c4.e = c3.e;
//   (-c3.f) + (-c4.f) = 0.0;
// end ConnectionOrder1;
// endResult
