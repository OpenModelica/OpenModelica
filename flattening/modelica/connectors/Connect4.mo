// name:     Connect4
// keywords: connect,type,unknown
// status:   correct
//
// Integers are allowed in connectors
//

connector C
  Integer i;
  flow Real f;
end C;

model Connect4
  C c1,c2;
equation
  connect(c1,c2);
  c1.i=integer(time*10);
end Connect4;

// Result:
// class Connect4
//   Integer c1.i;
//   Real c1.f;
//   Integer c2.i;
//   Real c2.f;
// equation
//   c1.i = integer(10.0 * time);
//   c1.f = 0.0;
//   c2.f = 0.0;
//   (-c1.f) + (-c2.f) = 0.0;
//   c1.i = c2.i;
// end Connect4;
// endResult
