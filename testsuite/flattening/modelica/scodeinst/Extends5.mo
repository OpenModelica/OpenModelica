// name: Extends5.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that the lookup finds the correct element when the component scope has
// the same name as the extended class.
//

model A
  Real x;
end A;

model B
  extends A;
end B;

model Extends5
  B A;
end Extends5;

// Result:
// class Extends5
//   Real A.x;
// end Extends5;
// endResult
