// name: IfExpression12
// keywords:
// status: correct
// cflags: -d=newInst
//

model IfExpression12
  parameter Integer n = 3;
  Real x[:] = if n == 1 then {1} else 2 .* fill(n, 2);
end IfExpression12;

// Result:
// class IfExpression12
//   parameter Integer n = 3;
//   Real x[1];
//   Real x[2];
// equation
//   x = {6, 6};
// end IfExpression12;
// endResult
