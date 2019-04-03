// name: ExtendsMod1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  Real x;
end A;

model ExtendsMod1
  extends A(x = 1);
end ExtendsMod1;

// Result:
// class ExtendsMod1
//   Real x = 1.0;
// end ExtendsMod1;
// endResult
