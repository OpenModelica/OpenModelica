// name: CevalFuncRecord5
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
  outR.x := 1.0;
end f;

model CevalFuncRecord5
  constant R r1;
  constant R r2 = f(r1);
end CevalFuncRecord5;

// Result:
// class CevalFuncRecord5
//   constant Real r1.x;
//   constant Real r1.y;
//   constant Real r2.x = 1.0;
//   constant Real r2.y;
// end CevalFuncRecord5;
// endResult
