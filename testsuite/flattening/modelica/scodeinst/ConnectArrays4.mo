// name: ConnectArrays4
// keywords:
// status: correct
// cflags:   -d=newInst --allowNonStandardModelica=nonStdEnumerationAsIntegers
//
//

model ConnectArrays4
  connector C
    Real e;
    flow Real f;
  end C;

  type E = enumeration(a, b, c);
  C c[2], c2[2];
equation
  connect(c[E.a], c2[E.a]);
  connect(c[1], c2[2]);
end ConnectArrays4;

// Result:
// class ConnectArrays4
//   Real c[1].e;
//   Real c[1].f;
//   Real c[2].e;
//   Real c[2].f;
//   Real c2[1].e;
//   Real c2[1].f;
//   Real c2[2].e;
//   Real c2[2].f;
// equation
//   c[1].e = c2[2].e;
//   c[1].e = c2[1].e;
//   -(c[1].f + c2[2].f + c2[1].f) = 0.0;
//   c[1].f = 0.0;
//   c[2].f = 0.0;
//   c2[1].f = 0.0;
//   c2[2].f = 0.0;
// end ConnectArrays4;
// Warning: Allowing usage of enumeration expression: E.a as Integer: 1. This is non-standard Modelica, use Integer(E.a) instead!
//
// endResult
