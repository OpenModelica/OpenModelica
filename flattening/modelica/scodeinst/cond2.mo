// name: cond2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Seems like conditional components are a bit broken.
//


model A
  Real x if true;
  Real y if false;
end A;

model B
  A a1 if true;
  A a2 if false;
end B;

// Result:
//
// EXPANDED FORM:
//
// class B
//   Real a1.x;
// end B;
//
//
// Found 1 components and 0 parameters.
// class B
//   Real a1.x;
// end B;
// endResult
