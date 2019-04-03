// name: ExtendSelf1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that a class can extend a local class via itself.
//

model ExtendSelf1
  encapsulated model A
    Real x = 1;
  end A;

  extends ExtendSelf1.A;
end ExtendSelf1;

// Result:
// class ExtendSelf1
//   Real x = 1;
// end ExtendSelf1;
// endResult
