
// name:     ConnectInner2
// keywords: connect,dynamic scoping
// status:   correct
//
// The inner connector must be declared 'inner'. Generate a warning.
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

model ConnectInner2
  C global;
  B b;
  A a;
equation
  global.e=10;
end ConnectInner2;


// Result:
// class ConnectInner2
//   Real global.e;
//   Real global.f;
//   Real b.a.global.e;
//   Real b.a.global.f;
//   Real b.a.my.e;
//   Real b.a.my.f;
//   Real a.global.e;
//   Real a.global.f;
//   Real a.my.e;
//   Real a.my.f;
// equation
//   b.a.my.f = 10.0 + b.a.my.e;
//   a.my.f = 10.0 + a.my.e;
//   global.e = 10.0;
//   global.f = 0.0;
//   b.a.my.f = 0.0;
//   a.my.f = 0.0;
//   a.global.e = a.my.e;
//   (-a.my.f) + (-a.global.f) = 0.0;
//   b.a.global.e = b.a.my.e;
//   (-b.a.my.f) + (-b.a.global.f) = 0.0;
// end ConnectInner2;
// [flattening/modelica/connectors/ConnectInner2.mo:13:3-13:17:writable] Warning: No corresponding 'inner' declaration found for component .C b.a.global declared as 'outer '.
//   The existing 'inner' components are:
//     There are no 'inner' components defined in the model in any of the parent scopes of 'outer' component's scope: A.
//   Check if you have not misspelled the 'outer' component name.
//   Please declare an 'inner' component with the same name in the top scope.
//   Continuing flattening by only considering the 'outer' component declaration.
// [flattening/modelica/connectors/ConnectInner2.mo:13:3-13:17:writable] Warning: No corresponding 'inner' declaration found for component .C a.global declared as 'outer '.
//   The existing 'inner' components are:
//     There are no 'inner' components defined in the model in any of the parent scopes of 'outer' component's scope: A.
//   Check if you have not misspelled the 'outer' component name.
//   Please declare an 'inner' component with the same name in the top scope.
//   Continuing flattening by only considering the 'outer' component declaration.
//
// endResult
