// name: IfExpression15
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfExpression15
  parameter Real o[3];
  parameter Boolean b;
equation
  o = if b then {i1 for i1 in 1:3} else {i1 for i1 in 1:3};
end IfExpression15;

// Result:
// class IfExpression15
//   parameter Real o[1];
//   parameter Real o[2];
//   parameter Real o[3];
//   parameter Boolean b;
// equation
//   o = /*Real[3]*/(array(i1 for i1 in 1:3));
// end IfExpression15;
// endResult
