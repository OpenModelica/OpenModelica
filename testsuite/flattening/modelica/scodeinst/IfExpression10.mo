// name: IfExpression10
// keywords:
// status: correct
//

model IfExpression10
  Real x[2] = if false then {1, 2} elseif false then {1} else {3, 4};
end IfExpression10;

// Result:
// class IfExpression10
//   Real x[1];
//   Real x[2];
// equation
//   x = {3.0, 4.0};
// end IfExpression10;
// endResult
