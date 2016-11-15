// name: enum3.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Enumeration array dimensions not supported.
//


model M
  type E = enumeration(one, two, three);
  E e[E] = E;
end M;

// Result:
// class M
//   enumeration(one, two, three) e[E.one] = E.one;
//   enumeration(one, two, three) e[E.two] = E.two;
//   enumeration(one, two, three) e[E.three] = E.three;
// end M;
// endResult
