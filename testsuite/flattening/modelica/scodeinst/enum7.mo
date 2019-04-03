// name: enum7.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

model M
  type E = enumeration(one, two, three);

  type E2
    extends E;
  end E2;

  E2 e = E2.one;
end M;

// Result:
// class M
//   enumeration(one, two, three) e = E.one;
// end M;
// endResult
