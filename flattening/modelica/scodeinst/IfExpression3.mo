// name: IfExpression3
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfExpression3
  parameter Boolean b = true;
  Real x = if b then 1 else 2;
end IfExpression3;

// Result:
// class IfExpression3
//   parameter Boolean b = true;
//   Real x = /*Real*/(if b then 1 else 2);
// end IfExpression3;
// endResult
