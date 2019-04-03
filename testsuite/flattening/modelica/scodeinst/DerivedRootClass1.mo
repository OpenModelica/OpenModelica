// name: DerivedRootClass1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model DerivedRootClass1 = A;

// Result:
// class DerivedRootClass1
//   Real x;
// end DerivedRootClass1;
// endResult
