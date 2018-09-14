// name: FuncBuiltinMin
// keywords: min
// status: correct
// cflags: -d=newInst
//
// Tests the builtin min operator.
//

model FuncBuiltinMin
  type E = enumeration(one, two, three);

  Real r1 = min(4.0, 2.0);
  Real r2 = min({3.0, 1.0, 2.0});
  Real r3 = min(r1, r2);
  Real r4 = min(r1, 100);

  Integer i1 = min(5, 6);
  Integer i2 = min({4, 2, 1});
  Integer i3 = min(i2, i1);

  Boolean b1 = min(true, false);
  Boolean b2 = min({false, true});
  Boolean b3 = min(b1, b2);

  E e1 = min(E.one, E.three);
  E e2 = min({E.one, E.two, E.three});
  E e3 = min(e1, e2);
end FuncBuiltinMin;

// Result:
// class FuncBuiltinMin
//   Real r1 = 2.0;
//   Real r2 = 1.0;
//   Real r3 = min(r1, r2);
//   Real r4 = min(r1, 100.0);
//   Integer i1 = 5;
//   Integer i2 = 1;
//   Integer i3 = min(i2, i1);
//   Boolean b1 = false;
//   Boolean b2 = false;
//   Boolean b3 = min(b1, b2);
//   enumeration(one, two, three) e1 = E.one;
//   enumeration(one, two, three) e2 = E.one;
//   enumeration(one, two, three) e3 = min(e1, e2);
// end FuncBuiltinMin;
// endResult
