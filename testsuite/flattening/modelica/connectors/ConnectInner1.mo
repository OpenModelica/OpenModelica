
// name:     ConnectInner1
// keywords: connect,dynamic scoping
// status:   correct
//
// This demonstrates dynamic scoping for
// connector variables.
// Note the sign for the flow-variables.
//
connector C
  Real e;
  flow Real f;
end C;
model A
  outer C global;
  C my;
equation
  connect(global,my);
  my.f=10+my.e;
end A;
model B
  A a;
end B;

model ConnectInner1
  inner C global;
  B b;
  A a;
equation
  global.e=10;
end ConnectInner1;

// Result:
// class ConnectInner1
//   Real global.e;
//   Real global.f;
//   Real b.a.my.e;
//   Real b.a.my.f;
//   Real a.my.e;
//   Real a.my.f;
// equation
//   b.a.my.f = 10.0 + b.a.my.e;
//   a.my.f = 10.0 + a.my.e;
//   global.e = 10.0;
//   global.f = 0.0;
//   b.a.my.f = 0.0;
//   a.my.f = 0.0;
//   a.my.e = b.a.my.e;
//   a.my.e = global.e;
//   (-global.f) + (-b.a.my.f) + (-a.my.f) = 0.0;
// end ConnectInner1;
// endResult
