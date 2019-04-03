// name: CevalFuncRecord3
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
  input R inR;
  output R outR;
algorithm
  outR.x := inR.x;
  outR.y := inR.y;
end f;

model CevalFuncRecord3
  constant R r1;
  constant R r2 = f(r1);
end CevalFuncRecord3;

// Result:
// class CevalFuncRecord3
//   constant Real r1.x;
//   constant Real r1.y;
//   constant Real r2.x = r1.x;
//   constant Real r2.y = r1.y;
// end CevalFuncRecord3;
// endResult
