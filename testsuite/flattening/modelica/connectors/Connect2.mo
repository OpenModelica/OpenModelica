// name:     Connect2
// keywords: connect
// status:   correct
//
// Basic connections between three connectors.
//

connector C
  flow Real f;
  Real e;
end C;

model Connect2
  C c1,c2,c3;
equation
  connect(c1,c2);
  connect(c2,c3);
  c1.e = 1;
  c2.f = time;
  c3.f = 1;
end Connect2;

// Result:
// class Connect2
//   Real c1.f;
//   Real c1.e;
//   Real c2.f;
//   Real c2.e;
//   Real c3.f;
//   Real c3.e;
// equation
//   c1.e = 1.0;
//   c2.f = time;
//   c3.f = 1.0;
//   c1.f = 0.0;
//   c2.f = 0.0;
//   c3.f = 0.0;
//   c1.e = c2.e;
//   c1.e = c3.e;
//   (-c1.f) + (-c2.f) + (-c3.f) = 0.0;
// end Connect2;
// endResult
