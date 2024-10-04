// name: FunctionCompOrder3
// keywords:
// status: correct
//

function f
  input Real x;
  output Real y;
protected
  Real z[n] = ones(3);
  parameter Integer n = 3;
algorithm
  y := z[1];
end f;

model FunctionCompOrder3
  Real x = f(time);
end FunctionCompOrder3;

// Result:
// function f
//   input Real x;
//   output Real y;
//   protected parameter Integer n = 3;
//   protected Real[n] z = {1.0, 1.0, 1.0};
// algorithm
//   y := z[1];
// end f;
//
// class FunctionCompOrder3
//   Real x = f(time);
// end FunctionCompOrder3;
// endResult
