// name: FunctionRecordArg3
// keywords:
// status: correct
//

record BaseR
  constant Integer n;
  parameter Real x[n];
end BaseR;

function f
  input BaseR r;
  output Real x;
algorithm
  x := r.x * r.x;
end f;

record R = BaseR(n = 2);

model FunctionRecordArg3
  R r(x = {1, 2});
  Real x = f(r);
end FunctionRecordArg3;

// Result:
// function BaseR "Automatically generated record constructor for BaseR"
//   input Integer n;
//   input Real[n] x;
//   output BaseR res;
// end BaseR;
//
// function R "Automatically generated record constructor for R"
//   input Integer n = 2;
//   input Real[n] x;
//   output R res;
// end R;
//
// function f
//   input BaseR r;
//   output Real x;
// algorithm
//   x := r.x * r.x;
// end f;
//
// class FunctionRecordArg3
//   constant Integer r.n = 2;
//   parameter Real r.x[1] = 1.0;
//   parameter Real r.x[2] = 2.0;
//   Real x = f(r);
// end FunctionRecordArg3;
// endResult
