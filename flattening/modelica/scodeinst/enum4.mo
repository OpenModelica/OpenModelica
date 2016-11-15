// name: enum4.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model M
  package P
    type E = enumeration(one, two, three);
  end P;

  P.E e = P.E.one;
end M;

// Result:
// class M
//   enumeration(one, two, three) e = P.E.one;
// end M;
// endResult
