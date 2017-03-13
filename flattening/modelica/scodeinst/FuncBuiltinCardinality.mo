// name: FuncBuiltinCardinality
// keywords: cardinality
// status: correct
// cflags: -d=newInst
//
// Tests the builtin cardinality operator.
//

model FuncBuiltinCardinality
  connector C
    Real e;
    flow Real f;
  end C;

  C c;
  Integer r1 = cardinality(c);
end FuncBuiltinCardinality;

// Result:
// class FuncBuiltinCardinality
//   Real c.e;
//   Real c.f;
//   Integer r1 = 0;
// equation
//   c.f = 0.0;
// end FuncBuiltinCardinality;
// endResult
