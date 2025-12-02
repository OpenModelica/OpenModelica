// name: conn9.mo
// keywords:
// status: correct
//

connector C
  Real e;
  Real f;
  Real s;
end C;

model A
  flow C c;
end A;

// Result:
// class A
//   Real c.e;
//   Real c.f;
//   Real c.s;
// equation
//   c.e = 0.0;
//   c.f = 0.0;
//   c.s = 0.0;
// end A;
// [flattening/modelica/scodeinst/conn9.mo:13:3-13:11:writable] Warning: Connector c is not balanced: The number of potential variables (0) is not equal to the number of flow variables (3).
//
// endResult
