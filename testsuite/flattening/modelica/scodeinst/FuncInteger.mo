// name: FuncInteger
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that the Integer function works.
//

model FuncInteger
  type E = enumeration(one, two, three);
  E e = E.two;

  Integer i = Integer(E.one);
  Integer j = Integer(e);
end FuncInteger;

// Result:
// class FuncInteger
//   enumeration(one, two, three) e = E.two;
//   Integer i = 1;
//   Integer j = Integer(e);
// end FuncInteger;
// endResult
