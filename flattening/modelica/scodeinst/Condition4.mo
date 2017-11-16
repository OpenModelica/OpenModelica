// name: Condition4
// keywords:
// status: correct
// cflags:   -d=newInst
//
//


model A
  Real x if true;
  Real y if false;
end A;

model Condition4
  A a1 if true;
  A a2 if false;
end Condition4;

// Result:
// class Condition4
//   Real a1.x;
// end Condition4;
// endResult
