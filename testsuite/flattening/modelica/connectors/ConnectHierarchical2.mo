// name:     ConnectHierarchical2
// keywords: connect
// status:   correct
//
// Compared to ConnectHiearchical1 we have established
// the same connections but at different places.
// Thus a.c2.f will thus be default connected, and set to zero.
// Thus we cannot have a modifier for it.
// The unknown flow 'a.b.c.f' evaluates to 1.

connector Connector
  flow Real f;
  Real e;
end Connector;

class B
  Connector c;
end B;

class A
  B b;
  Connector c1, c2;
equation
  connect(c1, b.c);
  connect(c1, c2);
end A;

class ConnectHierarchical2
  A a;
  Connector c(e = 1.0, f=1.0);
equation
  connect(c, a.c1);
end ConnectHierarchical2;

// Result:
// class ConnectHierarchical2
//   Real a.b.c.f;
//   Real a.b.c.e;
//   Real a.c1.f;
//   Real a.c1.e;
//   Real a.c2.f;
//   Real a.c2.e;
//   Real c.f = 1.0;
//   Real c.e = 1.0;
// equation
//   a.c1.e = a.c2.e;
//   a.c1.e = a.b.c.e;
//   c.e = a.c1.e;
//   a.c1.f - c.f = 0.0;
//   a.b.c.f - a.c1.f - a.c2.f = 0.0;
//   a.c2.f = 0.0;
//   c.f = 0.0;
// end ConnectHierarchical2;
// [flattening/modelica/connectors/ConnectHierarchical2.mo:17:3-17:14:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/ConnectHierarchical2.mo:21:3-21:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/ConnectHierarchical2.mo:22:3-22:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/ConnectHierarchical2.mo:24:3-24:19:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/connectors/ConnectHierarchical2.mo:29:3-29:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/ConnectHierarchical2.mo:30:3-30:30:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/ConnectHierarchical2.mo:32:3-32:19:writable] Warning: Equation sections are deprecated in class.
//
// endResult
