// name: FuncBuiltinMin2
// keywords: min
// status: correct
//
// Tests the builtin min operator.
//

model FuncBuiltinMin2
  type E = enumeration(one, two, three);

  Real r1[0];
  Real r2 = min(r1);

  Integer i1[0];
  Integer i2 = min(i1);

  Boolean b1[0];
  Boolean b2 = min(b1);

  E e1[0];
  E e2 = min(e1);
end FuncBuiltinMin2;

// Result:
// class FuncBuiltinMin2
//   Real r2 = 8.777798510069901e304;
//   Integer i2 = 4611686018427387903;
//   Boolean b2 = true;
//   enumeration(one, two, three) e2 = E.three;
// end FuncBuiltinMin2;
// endResult
