// name: enum1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model M
  type E = enumeration(one, two, three);
  E e = E.one;
  //E e2 = e.one "NOT VALID!";
  //E e2 = E;
end M;

// Result:
// class M
//   enumeration(one, two, three) e = E.one;
// end M;
// endResult
