// name: ConstrainingClass1
// keywords:
// status: correct
// cflags: -d=newInst
//

model ConstrainingClass1
  replaceable Real x constrainedby Real(start = 1.0);
end ConstrainingClass1;

// Result:
// class ConstrainingClass1
//   Real x(start = 1.0);
// end ConstrainingClass1;
// endResult
