// name: IfExpression9
// keywords:
// status: correct
//

model IfExpression9
  parameter Boolean b = true;
  Real x[2] = if b then {1, 2} + x else {3, 4, 5} + x;
end IfExpression9;

// Result:
// class IfExpression9
//   parameter Boolean b = true;
//   Real x[1];
//   Real x[2];
// equation
//   x = {1.0 + x[1], 2.0 + x[2]};
// end IfExpression9;
// endResult
