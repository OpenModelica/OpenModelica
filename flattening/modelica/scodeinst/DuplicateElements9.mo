// name: DuplicateElements9
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  Real x;
end A;

model DuplicateElements9
  extends A;
  Real x;
  Real y;
equation
  y = x;
end DuplicateElements9;

// Result:
// class DuplicateElements9
//   Real x;
//   Real y;
// equation
//   y = x;
// end DuplicateElements9;
// endResult
