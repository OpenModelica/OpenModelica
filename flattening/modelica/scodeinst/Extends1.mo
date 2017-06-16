// name: Extends1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model Extends1
  extends A;
  Real y;
end Extends1;

// Result:
// class Extends1
//   Real x;
//   Real y;
// end Extends1;
// endResult
