// name: EnumArrayConnector
// keywords: connect enum array
// status: correct
//
// Tests that connectors containing arrays with enum dimensions work correctly.
//

model EnumArrayConnector
  type E = enumeration(a, b);

  connector C
    Real e;
    flow Real f;
    stream Real s[E];
  end C;

  model B
    C c;
  end B;

  B b;
end EnumArrayConnector;

// Result:
// class EnumArrayConnector
//   Real b.c.e;
//   Real b.c.f;
//   Real b.c.s[EnumArrayConnector.E.a];
//   Real b.c.s[EnumArrayConnector.E.b];
// equation
//   b.c.f = 0.0;
// end EnumArrayConnector;
// endResult
