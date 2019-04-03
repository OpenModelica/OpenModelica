// name:     ConnectConst1
// keywords: connect,constant
// status:   correct
//
// The specification does not forbid you to connectors as constant.

connector C
  flow Real f;
  Real e;
end C;

model ConnectConst1
  C c1;
  constant C c2(e=1,f=2);
equation
  connect(c1,c2);
end ConnectConst1;

// Result:
// class ConnectConst1
//   Real c1.f;
//   Real c1.e;
//   constant Real c2.f = 2.0;
//   constant Real c2.e = 1.0;
// equation
//   c1.e = c2.e;
//   (-c1.f) + (-c2.f) = 0.0;
//   c2.f = 0.0;
//   c1.f = 0.0;
// end ConnectConst1;
// endResult
