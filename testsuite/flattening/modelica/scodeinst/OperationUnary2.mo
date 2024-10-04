// name: OperationUnary2
// keywords:
// status: correct
//

function f
  input Real x[:, :];
  output Real y[size(x, 2)];
algorithm
  y := -x[2, :];
end f;

model OperationUnary2
  Real x[:] = f({{1, 2, 3}, {3, 4, time}});
end OperationUnary2;

// Result:
// function f
//   input Real[:, :] x;
//   output Real[size(x, 2)] y;
// algorithm
//   y := -x[2,:];
// end f;
//
// class OperationUnary2
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = f({{1.0, 2.0, 3.0}, {3.0, 4.0, time}});
// end OperationUnary2;
// endResult
