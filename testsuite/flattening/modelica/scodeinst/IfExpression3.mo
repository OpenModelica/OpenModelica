// name: IfExpression3
// keywords:
// status: correct
//

model IfExpression3
  parameter Boolean b = true;
  Real x = if b then 1 else 2;
end IfExpression3;

// Result:
// class IfExpression3
//   parameter Boolean b = true;
//   Real x = if b then 1.0 else 2.0;
// end IfExpression3;
// endResult
