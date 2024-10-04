// name: ConstrainingClass3
// keywords:
// status: correct
//

model A
  replaceable Real x constrainedby Real(start = 1.0);
end A;

model ConstrainingClass3
  A a(redeclare replaceable Real x(min = 1.0) constrainedby Real(start = 2.0));
end ConstrainingClass3;

// Result:
// class ConstrainingClass3
//   Real a.x(min = 1.0, start = 2.0);
// end ConstrainingClass3;
// endResult
