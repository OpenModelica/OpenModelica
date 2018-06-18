// name: CevalFuncRecord1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

record R
  Real x;
  Real y;
end R;

function f
  input Real x;
  input Real y;
  output R r(x = x, y = y);
end f;

model CevalFuncRecord1
  constant R r = f(1.0, 2.0);
end CevalFuncRecord1;

// Result:
// class CevalFuncRecord1
//   constant Real r.x = 1.0;
//   constant Real r.y = 2.0;
// end CevalFuncRecord1;
// endResult
