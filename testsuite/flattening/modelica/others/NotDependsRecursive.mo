// name:     NotDependsRecursive
// keywords: scoping
// status:   correct
//
// A recursive model can not be instantiated. But this one can.
//

model NotDependsRecursive
  type NotDependsRecursive = Real;
  Real head;
  NotDependsRecursive tail;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end NotDependsRecursive;
// Result:
// class NotDependsRecursive
//   Real head;
//   Real tail;
// end NotDependsRecursive;
// endResult
