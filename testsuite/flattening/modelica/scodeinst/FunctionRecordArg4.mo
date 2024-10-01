// name: FunctionRecordArg4
// keywords:
// status: correct
//

record BaseR
  constant Integer n;
  final parameter Real x[n] = ones(n);
end BaseR;

function f
  input BaseR r;
  output Real x;
algorithm
  x := r.x * r.x;
end f;

record R = BaseR(final n = 2);

model FunctionRecordArg4
  R r;
  Real x = f(r);
end FunctionRecordArg4;

// Result:
// function BaseR "Automatically generated record constructor for BaseR"
//   input Integer n;
//   protected Real[n] x = fill(1.0, n);
//   output BaseR res;
// end BaseR;
//
// function R "Automatically generated record constructor for R"
//   protected Integer n = 2;
//   protected Real[2] x = {1.0, 1.0};
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
// class FunctionRecordArg4
//   final constant Integer r.n = 2;
//   final parameter Real r.x[1] = 1.0;
//   final parameter Real r.x[2] = 1.0;
//   Real x = f(r);
// end FunctionRecordArg4;
// endResult
