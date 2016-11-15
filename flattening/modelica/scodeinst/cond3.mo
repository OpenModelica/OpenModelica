// name: cond3.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Arrays of conditional components not handled.
//

model A
  parameter Boolean b1;
  parameter Boolean b2;
  Real x if b1;
  Real y if b2;
end A;

model B
  A a2[2](b1 = {true, false}, b2 = {false, true});
end B;
