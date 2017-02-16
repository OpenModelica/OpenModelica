// name: enum5.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model M
  type E = enumeration(one, two, three);
  E e = E.one;

  type ME = E;
  ME me = ME.two;

  package P
    type PE = E;
  end P;
  P.PE pe = P.PE.three;

  model M2
    replaceable type M2E = E;
    M2E m2e = M2E.one;
    M2E m2e2 = M2E.two;
    E e = m2e;
  end M2;

  M2 m2(redeclare type M2E = E(start = E.two));
end M;

// Result:
// class M
//   enumeration(one, two, three) e = E.one;
//   enumeration(one, two, three) me = ME.two;
//   enumeration(one, two, three) pe = P.PE.three;
//   enumeration(one, two, three) m2.m2e(start = E.two) = m2.M2E.one;
//   enumeration(one, two, three) m2.m2e2(start = E.two) = m2.M2E.two;
//   enumeration(one, two, three) m2.e(start = E.two) = m2.m2e;
// end M;
// endResult
