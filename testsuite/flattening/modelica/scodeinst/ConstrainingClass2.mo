// name: ConstrainingClass2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable Real x constrainedby Real(start = 1.0);
end A;

model ConstrainingClass2
  A a(redeclare Real x(min = 1.0));
end ConstrainingClass2;

// Result:
// class ConstrainingClass2
//   Real a.x(min = 1.0, start = 1.0);
// end ConstrainingClass2;
// endResult
