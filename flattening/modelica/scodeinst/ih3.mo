// name: ih3.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

package P
  package P
    constant Integer i;
  end P;

  package P1 = P(i = 2);
  package P2 = P(i = 3);

  model A
    Integer i1 = P1.i;
    Integer i2 = P2.i;
  end A;
end P;

model A
  extends P.A;
end A;

// Result:
// class A
//   Integer i1 = 2;
//   Integer i2 = 3;
// end A;
// endResult
