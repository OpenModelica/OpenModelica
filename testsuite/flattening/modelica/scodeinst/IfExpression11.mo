// name: IfExpression11
// keywords:
// status: correct
//

function f
  input Integer n;
  output Real x[2];
algorithm
  x := if n <> 2 then {1.0, 2.0, 3.0} else {1.0, 2.0};
end f;

model IfExpression11
  Integer n;
  Real x[2] = f(n);
end IfExpression11;

// Result:
// function f
//   input Integer n;
//   output Real[2] x;
// algorithm
//   x := if n <> 2 then {1.0, 2.0, 3.0} else {1.0, 2.0};
// end f;
//
// class IfExpression11
//   Integer n;
//   Real x[1];
//   Real x[2];
// equation
//   x = f(n);
// end IfExpression11;
// endResult
