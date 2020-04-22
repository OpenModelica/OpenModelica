// name: IfExpression4
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfExpression4
  parameter Boolean b = true;
  Real x[2] = if b then {1, 2} else {3, 4, 5};
end IfExpression4;

// Result:
// class IfExpression4
//   parameter Boolean b = true;
//   Real x[1];
//   Real x[2];
// equation
//   x = if b then {1.0, 2.0} else {3.0, 4.0, 5.0};
// end IfExpression4;
// endResult
