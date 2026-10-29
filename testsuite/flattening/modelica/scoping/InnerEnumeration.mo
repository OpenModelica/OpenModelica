// name:     InnerEnumeration
// keywords: inner outer variables
// status:   correct
//
// makes sure that outer variables are replaced with the correct inner ones on the top scope
//

model InnerEnumeration

  package P
    type E = enumeration(
        four,
        one,
        two,
        three,
        five);

    model A
      outer E T0;
    end A;

    model C
      outer E T0;
    end C;

    model B
      inner E T0 = E.five;
      A a1, a2; // B.T0, B.a1.T0 and B.a2.T0 is the same variable
      C c;
    end B;
  end P;

  P.B b;

equation
  assert(b.a1.T0 == P.E.five, "b.a1.T0 was not set to the correct value");
  assert(b.a2.T0 == P.E.five, "b.a2.T0 was not set to the correct value");
  assert(b.T0 == P.E.five, "b.T0 was not set to the correct value");
  assert(b.c.T0 == P.E.five, "b.c.T0 was not set to the correct value");
end InnerEnumeration;

// Result:
// class InnerEnumeration
//   enumeration(four, one, two, three, five) b.T0 = P.E.five;
// equation
//   assert(b.T0 == P.E.five, "b.a1.T0 was not set to the correct value");
//   assert(b.T0 == P.E.five, "b.a2.T0 was not set to the correct value");
//   assert(b.T0 == P.E.five, "b.T0 was not set to the correct value");
//   assert(b.T0 == P.E.five, "b.c.T0 was not set to the correct value");
// end InnerEnumeration;
// endResult
