// name: Cardinality1
// keywords: cardinality
// status: correct
// cflags: -d=newInst
//
// Tests the builtin cardinality operator.
//

model Cardinality1
  connector C
    Real e;
    flow Real f;
  end C;

  C c;
  Integer r1 = cardinality(c);
end Cardinality1;

// Result:
// class Cardinality1
//   Real c.e;
//   Real c.f;
//   Integer r1 = 0;
// equation
//   c.f = 0.0;
// end Cardinality1;
// endResult
