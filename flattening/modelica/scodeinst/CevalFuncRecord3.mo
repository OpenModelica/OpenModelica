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
  parameter R r1;
  parameter R r2 = f(r1);
end CevalFuncRecord3;

// Result:
// class CevalFuncRecord3
//   parameter Real r1.x;
//   parameter Real r1.y;
//   parameter Real r2.x = r1.x;
//   parameter Real r2.y = r1.y;
// end CevalFuncRecord3;
// endResult
