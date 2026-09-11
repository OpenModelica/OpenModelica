// name: RecordBinding19
// keywords:
// status: correct
//

record R
  Real x;
  Real y;
  Real z;
end R;

function f
  input Real x;
  input Real y;
  output R r;
algorithm
  r.x := x;
  r.y := y;
end f;

function f2
  input R r;
  output Real x = r.x;
end f2;

model RecordBinding19
  parameter R r = f(1.0, 2.0) annotation(Evaluate=true);
end RecordBinding19;

// Result:
// class RecordBinding19
//   parameter Real r.x = 1.0;
//   parameter Real r.y = 2.0;
//   parameter Real r.z = 0.0;
// end RecordBinding19;
// [flattening/modelica/scodeinst/RecordBinding19.mo:15:3-15:13:writable] Warning: Output parameter r.z was not assigned a value
//
// endResult
