// name: IfExpression14
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfExpression14
  parameter Boolean cond = false;
  Real[3] a = if cond then {1.0} else {1.0, 2.0, 3.0};
  Real x[:] = cat(1, a, a);
end IfExpression14;

// Result:
// class IfExpression14
//   parameter Boolean cond = false;
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real x[6];
// equation
//   a = {1.0, 2.0, 3.0};
//   x = {a[1], a[2], a[3], a[1], a[2], a[3]};
// end IfExpression14;
// endResult
