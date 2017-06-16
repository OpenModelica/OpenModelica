// name: enum2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model M
  type E1 = enumeration(one, two, three);
  type E2 = E1(start = E1.two);
  E2 e;
end M;

// Result:
// class M
//   enumeration(one, two, three) e(start = E1.two);
// end M;
// endResult
