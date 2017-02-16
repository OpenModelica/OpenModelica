// name: enum3.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model M
  type E = enumeration(one, two, three);
  class A end A;
  E e[E];
end M;

// Result:
// class M
//   enumeration(one, two, three) e[E.one];
//   enumeration(one, two, three) e[E.two];
//   enumeration(one, two, three) e[E.three];
// end M;
// endResult
