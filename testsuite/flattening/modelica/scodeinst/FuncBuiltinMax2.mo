// name: FuncBuiltinMax2
// keywords: max
// status: correct
//
// Tests the builtin max operator.
//

model FuncBuiltinMax2
  type E = enumeration(one, two, three);

  Real r1[0];
  Real r2 = max(r1);

  Integer i1[0];
  Integer i2 = max(i1);

  Boolean b1[0];
  Boolean b2 = max(b1);

  E e1[0];
  E e2 = max(e1);
end FuncBuiltinMax2;

// Result:
// class FuncBuiltinMax2
//   Real r2 = -8.777798510069901e304;
//   Integer i2 = -4611686018427387903;
//   Boolean b2 = false;
//   enumeration(one, two, three) e2 = E.one;
// end FuncBuiltinMax2;
// endResult
