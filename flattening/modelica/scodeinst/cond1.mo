// name: cond1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Seems like conditional components are a bit broken.
//


model M
  parameter Boolean b1 = true;
  parameter Boolean b2 = false;

  Real x if b1;
  Real y if b2;
end M;

model M2
  extends M(x = 2, y = 3);
end M2;

// Result:
// class M2
//   parameter Boolean b1 = true;
//   parameter Boolean b2 = false;
//   Real x = 2.0;
// end M2;
// endResult
