// name: enum2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model M
  type E1 = enumeration(one, two, three);
  type E2 = E1(start = two);
  E2 e;
end M;

// Result:
// class M
//   enumeration(one, two, three) e;
// end M;
// endResult
