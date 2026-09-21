// name: IfExpression21
// keywords:
// status: correct
//

function linspaceExt
  input Real x1;
  input Real x2;
  input Integer N;
  output Real vec[N];
algorithm
  vec := if N == 1 then {x1} else linspace(x1, x2, N);
end linspaceExt;

model IfExpression21
  Real x, y;
  parameter Integer N = 3;
  Real z[N];
equation
  z = linspaceExt(x, y, N);
end IfExpression21;

// Result:
// function linspaceExt
//   input Real x1;
//   input Real x2;
//   input Integer N;
//   output Real[N] vec;
// algorithm
//   vec := if N == 1 then {x1} else array(x1 + (x2 - x1) * /*Real*/(i - 1) / /*Real*/(N - 1) for i in 1:N);
// end linspaceExt;
//
// class IfExpression21
//   Real x;
//   Real y;
//   final parameter Integer N = 3;
//   Real z[1];
//   Real z[2];
//   Real z[3];
// equation
//   z = linspaceExt(x, y, 3);
// end IfExpression21;
// endResult
