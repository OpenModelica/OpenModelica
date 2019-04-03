// name: IfExpression1
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfExpression1
  Real x = if true then 1 else 2;
end IfExpression1;

// Result:
// class IfExpression1
//   Real x = 1.0;
// end IfExpression1;
// endResult
