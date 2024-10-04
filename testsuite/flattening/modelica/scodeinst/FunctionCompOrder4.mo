// name: FunctionCompOrder4
// keywords:
// status: correct
//

record R
  Real x;
end R;

function f
  input Real x;
  output Real y;
protected
  R r(x = lx);
  Real lx = x;
algorithm
  y := r.x;
end f;

model FunctionCompOrder4
  Real x = f(time);
end FunctionCompOrder4;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   output R res;
// end R;
//
// function f
//   input Real x;
//   output Real y;
//   protected Real lx = x;
//   protected R r;
// algorithm
//   y := r.x;
// end f;
//
// class FunctionCompOrder4
//   Real x = f(time);
// end FunctionCompOrder4;
// endResult
