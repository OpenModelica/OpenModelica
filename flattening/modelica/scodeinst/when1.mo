// name: when1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Expand of when equations not implemented.
//

model A
  Real x, y;
  Boolean b, b2;
equation
  when {b, b2} then
    x = y;
  end when;
end A;

// Result:
// class A
//   Real x;
//   Real y;
//   Boolean b;
//   Boolean b2;
// equation
//   when {b, b2} then
//     x = y;
//   end when;
// end A;
// endResult
