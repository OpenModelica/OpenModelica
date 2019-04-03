// name:     Connect5
// keywords: connect,type
// status:   correct
//
// Booleans are allowed in connectors
//

connector C
  Boolean b;
  flow Real f;
end C;

model Connect5
  C c1,c2;
equation
  connect(c1,c2);
  c1.b=time<0.5;
end Connect5;

// Result:
// class Connect5
//   Boolean c1.b;
//   Real c1.f;
//   Boolean c2.b;
//   Real c2.f;
// equation
//   c1.b = time < 0.5;
//   c1.f = 0.0;
//   c2.f = 0.0;
//   c1.b = c2.b;
//   (-c1.f) + (-c2.f) = 0.0;
// end Connect5;
// endResult
