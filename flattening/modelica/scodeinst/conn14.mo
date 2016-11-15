// name: conn14.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Maybe no correct, see Modelica issue #768.
//

connector C
  Real e;
  flow Real f;
end C;

model A
  parameter C ri1, ri2;
equation
  connect(ri1, ri2);
end A;
