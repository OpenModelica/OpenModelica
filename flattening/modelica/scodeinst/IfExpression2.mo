// name: IfExpression2
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfExpression2
  Real x = if time > 1 then 1 else 2;
end IfExpression2;

// Result:
// class IfExpression2
//   Real x = /*Real*/(if time > 1.0 then 1 else 2);
// end IfExpression2;
// endResult
