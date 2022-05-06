// name: FuncBuiltinMax
// keywords: max
// status: correct
// cflags: -d=newInst
//
// Tests the builtin max operator.
//

model FuncBuiltinMax
  type E = enumeration(one, two, three);

  Real r1 = max(4.0, 2.0);
  Real r2 = max({3.0, 1.0, 2.0});
  Real r3 = max(r1, r2);
  Real r4 = max(1, r2);
  Real r5 = max(zeros(0));

  Integer i1 = max(5, 6);
  Integer i2 = max({4, 2, 1});
  Integer i3 = max(i2, i1);
  Integer i4 = max(zeros(0));

  Boolean b1 = max(true, false);
  Boolean b2 = max({false, true});
  Boolean b3 = max(b1, b2);
  Boolean b4 = max(fill(true, 0));

  E e1 = max(E.one, E.three);
  E e2 = max({E.one, E.two, E.three});
  E e3 = max(e1, e2);
  E e4 = max(fill(E.one, 0));
end FuncBuiltinMax;

// Result:
// class FuncBuiltinMax
//   Real r1 = 4.0;
//   Real r2 = 3.0;
//   Real r3 = max(r1, r2);
//   Real r4 = max(1.0, r2);
//   Real r5 = -4.611686018427388e+18;
//   Integer i1 = 6;
//   Integer i2 = 4;
//   Integer i3 = max(i2, i1);
//   Integer i4 = -4611686018427387903;
//   Boolean b1 = true;
//   Boolean b2 = true;
//   Boolean b3 = max(b1, b2);
//   Boolean b4 = false;
//   enumeration(one, two, three) e1 = E.three;
//   enumeration(one, two, three) e2 = E.three;
//   enumeration(one, two, three) e3 = max(e1, e2);
//   enumeration(one, two, three) e4 = E.one;
// end FuncBuiltinMax;
// endResult
