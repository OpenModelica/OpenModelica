// name: redeclare7.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//


model C
  replaceable package P = P1;
  Real z = P.x;
end C;

package P1
  constant Real x = 1;
end P1;

package P2
  constant Real x = 2;
end P2;

model D
  C b(redeclare package P = P2);
end D;

// Result:
// class D
//   Real b.z = 2.0;
// end D;
// endResult
