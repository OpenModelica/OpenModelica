// name:     NotDependsRecursive
// keywords: scoping
// status:   correct
// cflags: -d=-newInst
//
// A recursive model can not be instantiated. But this one can.
//

model NotDependsRecursive
  type NotDependsRecursive = Real;
  Real head;
  NotDependsRecursive tail;
end NotDependsRecursive;
// Result:
// class NotDependsRecursive
//   Real head;
//   Real tail;
// end NotDependsRecursive;
// endResult
