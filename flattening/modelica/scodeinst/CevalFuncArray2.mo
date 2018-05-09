// name: CevalFuncArray2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x[3];
  output Real y[3];
algorithm
  y[1] := x[1];
  y[2] := x[2];
  y[3] := x[3];
end f;

model CevalFuncArray2
  constant Real x[:] = f({1, 2, 3});
end CevalFuncArray2;

// Result:
// class CevalFuncArray2
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
// end CevalFuncArray2;
// endResult
