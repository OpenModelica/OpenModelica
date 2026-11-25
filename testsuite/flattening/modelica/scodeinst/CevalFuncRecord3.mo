// name: CevalFuncRecord3
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
  outR.x := inR.x;
  outR.y := inR.y;
end f;

model CevalFuncRecord3
  constant R r1(x = 1.0, y = 2.0);
  constant R r2 = f(r1);
end CevalFuncRecord3;

// Result:
// class CevalFuncRecord3
//   constant Real r1.x = 1.0;
//   constant Real r1.y = 2.0;
//   constant Real r2.x = 1.0;
//   constant Real r2.y = 2.0;
// end CevalFuncRecord3;
// endResult
