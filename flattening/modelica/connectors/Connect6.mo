// name:     Connect6
// keywords: connect,type
// status:   correct
//
// Strings are allowed in connectors
//

connector C
  String s;
  flow Real f;
end C;

model Connect6
  C c1,c2;
  Boolean b;
equation
  connect(c1,c2);
  c1.s="h";
  b=c2.s=="h";
end Connect6;

// Result:
// class Connect6
//   String c1.s;
//   Real c1.f;
//   String c2.s;
//   Real c2.f;
//   Boolean b;
// equation
//   c1.s = "h";
//   b = c2.s == "h";
//   c1.f = 0.0;
//   c2.f = 0.0;
//   (-c1.f) + (-c2.f) = 0.0;
//   c1.s = c2.s;
// end Connect6;
// endResult
