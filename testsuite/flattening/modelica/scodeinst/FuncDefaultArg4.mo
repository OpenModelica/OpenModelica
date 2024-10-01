// name: FuncDefaultArg4
// keywords:
// status: correct
//
//

record R
  Real x;
end R;

function f
  input R r;
  input Real x = r.x;
  output Real y = r.x * x;
end f;

model FuncDefaultArg4
  Real x = f(R(2));
end FuncDefaultArg4;

// Result:
// class FuncDefaultArg4
//   Real x = 4.0;
// end FuncDefaultArg4;
// endResult
