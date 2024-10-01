// name: FuncDefaultArg5
// keywords:
// status: correct
//
//

function f
  input Integer dim;
  input Real x = f2(dim);
  output Integer n = dim;
end f;

function f2
  input Integer dim;
  output Integer n = dim;
end f2;

model FuncDefaultArg5
  parameter Real x = f(3);
end FuncDefaultArg5;

// Result:
// class FuncDefaultArg5
//   parameter Real x = 3.0;
// end FuncDefaultArg5;
// endResult
