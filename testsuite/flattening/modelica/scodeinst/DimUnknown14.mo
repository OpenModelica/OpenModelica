// name: DimUnknown14
// keywords:
// status: correct
// cflags: -d=newInst
//
//

record R
  Real x[:];
end R;

function f
  input Real x;
  output R r(x = {1, 2, 3});
end f;

model DimUnknown14
  parameter Real y(fixed = false);
  parameter R r = f(y);
  Real x[:] = r.x;
end DimUnknown14;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real[:] x;
//   output R res;
// end R;
//
// function f
//   input Real x;
//   output R r;
// end f;
//
// class DimUnknown14
//   parameter Real y(fixed = false);
//   parameter Real r.x[1](fixed = false);
//   parameter Real r.x[2](fixed = false);
//   parameter Real r.x[3](fixed = false);
//   Real x[1];
//   Real x[2];
//   Real x[3];
// initial equation
//   r = f(y);
// equation
//   x = r.x;
// end DimUnknown14;
// endResult
