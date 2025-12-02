// name: CevalFuncRecord7
// keywords:
// status: correct
//
//

record R
  Real x;
  Real y = x;
end R;

function f
  input Real x;
  output Real y;
protected
  R r(x = x);
algorithm
  y := r.y;
end f;

model CevalFuncRecord7
  constant Real x = f(1);
end CevalFuncRecord7;

// Result:
// class CevalFuncRecord7
//   constant Real x = 1.0;
// end CevalFuncRecord7;
// endResult
