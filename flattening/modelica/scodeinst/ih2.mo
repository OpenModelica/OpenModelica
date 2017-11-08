// name: ih2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//


package P
  package P
    constant Integer i;
  end P;

  model A
    package P1 = P(i = 2);
    package P2 = P(i = 3);
    Integer i1 = P1.i;
    Integer i2 = P2.i;
  end A;
end P;

model A
  extends P.A;
end A;

// Result:
// class A
//   constant Integer P2.i = 3;
//   constant Integer P1.i = 2;
//   Integer i1 = P1.i;
//   Integer i2 = P2.i;
// end A;
// endResult
