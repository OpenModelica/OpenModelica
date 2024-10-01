// name: FunctionCompOrder1
// keywords:
// status: correct
//

function f
  input Real x;
  output Real y;
protected
  Real x1 = x2;
  Real x2 = x;
algorithm
  y := x1;
end f;

model FunctionCompOrder1
  Real x = f(time);
end FunctionCompOrder1;

// Result:
// function f
//   input Real x;
//   output Real y;
//   protected Real x2 = x;
//   protected Real x1 = x2;
// algorithm
//   y := x1;
// end f;
//
// class FunctionCompOrder1
//   Real x = f(time);
// end FunctionCompOrder1;
// endResult
