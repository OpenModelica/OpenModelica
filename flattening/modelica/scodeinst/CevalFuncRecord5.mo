// name: CevalFuncRecord4
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
  parameter R r1;
  parameter R r2 = f(r1);
end CevalFuncRecord5;

// Result:
// class CevalFuncRecord5
//   parameter Real r1.x;
//   parameter Real r1.y;
//   parameter Real r2.x = 1.0;
//   parameter Real r2.y;
// end CevalFuncRecord5;
// endResult
