// name: CevalFuncRecord5
// keywords:
// status: correct
//
//

record R
  parameter Real x;
  parameter Real y(fixed = false);
end R;

function f
  input R inR;
  output R outR;
algorithm
  outR.x := inR.x;
end f;

model CevalFuncRecord5
  parameter R r1(x = 2.0);
  parameter R r2 = f(r1) annotation(Evaluate=true);
end CevalFuncRecord5;

// Result:
// class CevalFuncRecord5
//   parameter Real r1.x = 2.0;
//   parameter Real r1.y(fixed = false);
//   parameter Real r2.x = 2.0;
//   parameter Real r2.y(fixed = false) = 0.0;
// end CevalFuncRecord5;
// [flattening/modelica/scodeinst/CevalFuncRecord5.mo:14:3-14:16:writable] Warning: Output parameter outR.y was not assigned a value
//
// endResult
