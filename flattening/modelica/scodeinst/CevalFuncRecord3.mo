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
  input R inR;
  output R outR;
algorithm
  outR.x := inR.x;
  outR.y := inR.y;
end f;

model CevalFuncRecord2
  parameter R r1;
  parameter R r2 = f(r1);
end CevalFuncRecord2;

// Result:
// class CevalFuncRecord2
//   parameter Real r1.x;
//   parameter Real r1.y;
//   parameter Real r2.x = r1.x;
//   parameter Real r2.y = r1.y;
// end CevalFuncRecord2;
// endResult
