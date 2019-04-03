// name: Condition1
// keywords:
// status: correct
// cflags: -d=newInst
//

model Condition1
  Real x if true;
end Condition1;

// Result:
// class Condition1
//   Real x;
// end Condition1;
// endResult
