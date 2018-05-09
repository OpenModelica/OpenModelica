// name: CevalFuncArray1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x[3];
  output Real y[3];
algorithm
  y := x;
end f;

model CevalFuncArray1
  constant Real x[:] = f({1, 2, 3});
end CevalFuncArray1;

// Result:
// class CevalFuncArray1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
// end CevalFuncArray1;
// endResult
