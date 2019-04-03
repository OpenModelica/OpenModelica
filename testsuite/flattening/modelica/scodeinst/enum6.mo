// name: enum6.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model M
  model P
    replaceable type E = enumeration(one, two, three);
    constant Real e[E];
  end P;

  type E = enumeration(a, b, c);

  P p(redeclare type E = E);
  Real e[P.E];
end M;

// Result:
// class M
//   constant Real p.e[E.one];
//   constant Real p.e[E.two];
//   constant Real p.e[E.three];
//   Real e[P.E.one];
//   Real e[P.E.two];
//   Real e[P.E.three];
// end M;
// endResult
