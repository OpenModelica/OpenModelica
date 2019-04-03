// name:     Connect1
// keywords: connect
// status:   correct
//
// Basic connections
//

connector C
  flow Real f;
  Real e;
end C;

model Connect1
  C c1,c2;
equation
  connect(c1,c2);
  c1.e = 1;
  c2.f = time;
end Connect1;

// Result:
// class Connect1
//   Real c1.f;
//   Real c1.e;
//   Real c2.f;
//   Real c2.e;
// equation
//   c1.e = 1.0;
//   c2.f = time;
//   c1.f = 0.0;
//   c2.f = 0.0;
//   c1.e = c2.e;
//   (-c1.f) + (-c2.f) = 0.0;
// end Connect1;
// endResult
