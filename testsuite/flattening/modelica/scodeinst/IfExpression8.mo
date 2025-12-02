// name: IfExpression8
// keywords:
// status: correct
//

model IfExpression8
  parameter Integer n = 3;
  parameter Integer m = 2;
  Real x[:, :] = if n == 3 then ones(n, m) else ones(n, n);
end IfExpression8;

// Result:
// class IfExpression8
//   final parameter Integer n = 3;
//   final parameter Integer m = 2;
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[3,1];
//   Real x[3,2];
// equation
//   x = {{1.0, 1.0}, {1.0, 1.0}, {1.0, 1.0}};
// end IfExpression8;
// endResult
