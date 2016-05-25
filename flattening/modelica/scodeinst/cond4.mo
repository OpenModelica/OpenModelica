// name: cond4.mo
// keywords:
// status: correct
// cflags:   +d=newInst
//
// FAILREASON: Seems like conditional components are a bit broken.
//

model A
  parameter Boolean b;
  Real x if b;
end A;

model B
  parameter Boolean b = true;
  A a(b = b);
end B;

// Result:
//
// EXPANDED FORM:
//
// class B
//   parameter Boolean b = true;
//   parameter Boolean a.b = true;
//   Real a.x;
// end B;
//
//
// Found 1 components and 2 parameters.
// class B
//   parameter Boolean b = true;
//   parameter Boolean a.b = b;
//   Real a.x;
// end B;
// endResult
