// name:     ConnectTypes
// keywords: connect,type
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
  annotation(__OpenModelica_commandLineOptions="+std=2.x");
end ConnectTypes;

// Result
// Result:
// class ConnectTypes
//   Real a.c.e[1];
//   Integer a.c.d;
//   parameter Integer a.c.p = 4;
//   final parameter Integer a.c.n = 1;
//   constant Real a.c.c = 2.0;
//   Real c.e[1];
//   Integer c.d;
//   parameter Integer c.p = 4;
//   final parameter Integer c.n = 1;
//   constant Real c.c = 2.0;
// equation
//   c.d = a.c.d;
//   c.e[1] = a.c.e[1];
//   assert(c.p == a.c.p, "Connected constants/parameters must be equal");
//   c.e[1] = time;
//   c.d = 4;
// end ConnectTypes;
// [flattening/modelica/connectors/ConnectTypes.mo:18:3-18:14:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/ConnectTypes.mo:22:3-22:14:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/ConnectTypes.mo:23:3-23:19:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/ConnectTypes.mo:25:3-25:18:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/connectors/ConnectTypes.mo:18:3-18:14:writable] Warning: Connector c is not balanced: The number of potential variables (2) is not equal to the number of flow variables (0).
// [flattening/modelica/connectors/ConnectTypes.mo:23:3-23:19:writable] Warning: Connector c is not balanced: The number of potential variables (2) is not equal to the number of flow variables (0).
//
// endResult
