// name: OperationSubEW2
// keywords:
// status: correct
//

function f
  input Real x;
  input Real y[:];
  output Real z[:];
algorithm
  z := x .- y;
  z := y .- x;
end f;

model OperationSubEW2
  Real r1;
  Real r2[2];
equation
  f(r1, r2);
end OperationSubEW2;

// Result:
// function f
//   input Real x;
//   input Real[:] y;
//   output Real[:] z;
// algorithm
//   z := x .- y;
//   z := y .+ (-x);
// end f;
//
// class OperationSubEW2
//   Real r1;
//   Real r2[1];
//   Real r2[2];
// equation
//   f(r1, r2);
// end OperationSubEW2;
// endResult
