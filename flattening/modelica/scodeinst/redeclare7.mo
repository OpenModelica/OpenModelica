// name: redeclare7.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: ??
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
//   constant Real b.P.x = 2;
//   Real b.z = b.P.x;
// end D;
// endResult
