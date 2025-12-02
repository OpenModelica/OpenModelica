// name: OperationLogicalUnary2
// keywords:
// status: correct
//

function f
  input Boolean x[:, :];
  output Boolean y[size(x, 2)];
algorithm
  y := not x[2, :];
end f;

model OperationLogicalUnary2
  Boolean b[:] = f({{time > 0}});
end OperationLogicalUnary2;

// Result:
// function f
//   input Boolean[:, :] x;
//   output Boolean[size(x, 2)] y;
// algorithm
//   y := not x[2,:];
// end f;
//
// class OperationLogicalUnary2
//   Boolean b[1];
// equation
//   b = f({{time > 0.0}});
// end OperationLogicalUnary2;
// endResult
