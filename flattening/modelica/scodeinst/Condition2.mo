// name: Condition2
// keywords:
// status: correct
// cflags: -d=newInst
//

model Condition2
  Real x if false;
end Condition2;

// Result:
// class Condition2
// end Condition2;
// endResult
