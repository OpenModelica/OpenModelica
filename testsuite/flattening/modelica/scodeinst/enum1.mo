// name: enum1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//


model M
  type E = enumeration(one, two, three);
  E e = E.one;
end M;

// Result:
// class M
//   enumeration(one, two, three) e = E.one;
// end M;
// endResult
