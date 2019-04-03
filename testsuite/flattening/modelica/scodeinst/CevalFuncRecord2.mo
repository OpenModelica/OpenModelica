// name: CevalFuncRecord2
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
  output R r;
algorithm
  r.x := x;
  r.y := y;
end f;

model CevalFuncRecord2
  constant R r = f(1.0, 2.0);
end CevalFuncRecord2;

// Result:
// class CevalFuncRecord2
//   constant Real r.x = 1.0;
//   constant Real r.y = 2.0;
// end CevalFuncRecord2;
// endResult
