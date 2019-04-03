// name: CevalFuncArray3
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x[3];
  output Real y[3];
algorithm
  y := {x[1], x[2], x[3]};
end f;

model CevalFuncArray3
  constant Real x[:] = f({1, 2, 3});
end CevalFuncArray3;

// Result:
// class CevalFuncArray3
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
// end CevalFuncArray3;
// endResult
