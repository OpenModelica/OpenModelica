// name: CevalFuncRecord4
// keywords:
// status: correct
//
//

record R
  Real x;
  Real y;
end R;

function f
  input R inR;
  output R outR;
algorithm
  outR := inR;
end f;

model CevalFuncRecord4
  constant R r1(x = 1.0, y = 2.0);
  constant R r2 = f(r1);
end CevalFuncRecord4;

// Result:
// class CevalFuncRecord4
//   constant Real r1.x = 1.0;
//   constant Real r1.y = 2.0;
//   constant Real r2.x = 1.0;
//   constant Real r2.y = 2.0;
// end CevalFuncRecord4;
// endResult
