// name: FunctionRecordArg1
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON:
//  * Weird syntax on record constructor R output.
//  * Input r of f shouldn't be expanded.
//  * Binding of M.r is lost.
//

record R
  Real x;
  Real y;
end R;

function f
  input R r;
  output Real x;
algorithm
  x := r.x;
end f;

model M
  R r = R(2.0, 4.0);
  Real x = f(r);
end M;

// Result:
// function R
//   input Real x;
//   input Real y;
//   output R res;
// end R;
//
// function f
//   input R r;
//   output Real x;
// algorithm
//   x := r.x;
// end f;
//
// class M
//   Real r.x = 2.0;
//   Real r.y = 4.0;
//   Real x = f(r);
// end M;
// endResult
