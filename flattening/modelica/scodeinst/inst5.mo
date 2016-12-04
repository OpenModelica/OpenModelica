// name: inst5.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
// Check that instances are cloned properly, so that modifiers don't "stick" to
// a class.
//

model A
  Real x;
end A;

model B
  A a1(x = 3);
  A a2;
  A a3(x = 5);
end B;

// Result:
// class B
//   Real a1.x = 3;
//   Real a2.x;
//   Real a3.x = 5;
// end B;
// endResult
