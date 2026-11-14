// name: RecordBinding20
// keywords:
// status: correct
//
// Checks that a record parameter binding that depends on an Evaluate=false
// parameter is moved to an initial equation.
//

record R
  Real x;
  Real y;
end R;

function f
  input Real a;
  output R r;
algorithm
  r := R(cos(a), sin(a));
end f;

model RecordBinding20
  parameter Real p = 1 annotation(Evaluate = false);
  parameter R r = f(p);
  Real x = r.x;
end RecordBinding20;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   input Real y;
//   output R res;
// end R;
//
// function f
//   input Real a;
//   output R r;
// algorithm
//   r := R(cos(a), sin(a));
// end f;
//
// class RecordBinding20
//   parameter Real p = 1.0;
//   parameter Real r.x(fixed = false);
//   parameter Real r.y(fixed = false);
//   Real x = r.x;
// initial equation
//   r = f(p);
// end RecordBinding20;
// endResult
