// name:     ConnectTypes
// keywords: connect,type
// cflags: +std=2.x
// status:   correct
//
// Check generation of connection equations.
// Parameters and constants should generate assertions
// (used for size-parameters in Modelica.Blocks).

connector Connector
  Real e[n];
  Integer d;
  parameter Integer p;
  parameter Integer n=1;
  constant Real c=2;
end Connector;

class A
  Connector c;
end A;

class ConnectTypes
  A a(c(p=4));
  Connector c(p=4);
equation
  connect(c, a.c);
  c.e={time};
  c.d=4;
end ConnectTypes;

// Result
// Result:
// class ConnectTypes
//   Real a.c.e[1];
//   Integer a.c.d;
//   parameter Integer a.c.p = 4;
//   parameter Integer a.c.n = 1;
//   constant Real a.c.c = 2.0;
//   Real c.e[1];
//   Integer c.d;
//   parameter Integer c.p = 4;
//   parameter Integer c.n = 1;
//   constant Real c.c = 2.0;
// equation
//   assert(true, "automatically generated from connect");
//   assert(c.n == a.c.n, "automatically generated from connect");
//   assert(c.p == a.c.p, "automatically generated from connect");
//   c.e[1] = time;
//   c.d = 4;
//   a.c.d = c.d;
//   a.c.e[1] = c.e[1];
// end ConnectTypes;
// endResult
