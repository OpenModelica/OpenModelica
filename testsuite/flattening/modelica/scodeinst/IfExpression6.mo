// name: IfExpression6
// keywords:
// status: correct
// cflags: -d=newInst
//

model M
  parameter Boolean b;
  Real x[if b then 2 else 3] = if b then {1, 2} else {3, 4, 5};
end M;

model IfExpression6
  M m[2](b = {true, false});
end IfExpression6;

// Result:
// class IfExpression4
//   parameter Boolean b = true;
//   Real x[1];
//   Real x[2];
// equation
//   x = {1.0, 2.0};
// end IfExpression4;
// endResult
