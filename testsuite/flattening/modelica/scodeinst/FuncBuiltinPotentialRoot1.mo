// name: FuncBuiltinPotentialRoot1
// keywords:
// status: correct
//

type OC
  extends Real;

  function equalityConstraint
    input OC oc1;
    input OC oc2;
    output Real residue[0];
  end equalityConstraint;
end OC;

connector C
  Real e;
  flow Real f;
  OC oc;
end C;

model FuncBuiltinPotentialRoot1
  C c1, c2;
  parameter Integer p = 0;
equation
  Connections.potentialRoot(c1.oc, p);
  Connections.potentialRoot(c2.oc);
  c1.f = 0;
  c2.f = 0;
end FuncBuiltinPotentialRoot1;

// Result:
// class FuncBuiltinPotentialRoot1
//   Real c1.e;
//   Real c1.f;
//   Real c1.oc;
//   Real c2.e;
//   Real c2.f;
//   Real c2.oc;
//   final parameter Integer p = 0;
// equation
//   c1.f = 0.0;
//   c2.f = 0.0;
//   c1.f = 0.0;
//   c2.f = 0.0;
// end FuncBuiltinPotentialRoot1;
// endResult
