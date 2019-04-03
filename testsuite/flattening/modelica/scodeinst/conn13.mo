// name: conn13.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Overconstrained types are not recognized as such yet (need to add
//             equalityConstraint to their type).
//

type OC
  extends Real;

  function equalityConstraint
    input Real x;
    input Real y;
    output Real residue[0];
  algorithm
  end equalityConstraint;
end OC;

connector C
  OC oc;
  Real e[3];
  flow Real f[3];
end C;

model M
  C c1, c2;
equation
  Connections.branch(c1.oc, c2.oc);
  Connections.isRoot(c1.oc);
  connect(c1, c2);
end M;
