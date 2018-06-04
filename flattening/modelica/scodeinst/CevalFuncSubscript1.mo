// name: CevalFuncSubscript1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  output Real x[3];
algorithm
  x[1] := 1.0;
  x[2] := 2.0;
  x[3] := 3.0;
end f;

model CevalFuncSubscript1
  constant Real x[:] = f();
end CevalFuncSubscript1;

// Result:
// class CevalFuncSubscript1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
// end CevalFuncSubscript1;
// endResult
