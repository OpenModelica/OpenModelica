// name: CevalFuncSubscript2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  output Real x[2, 2];
algorithm
  x[1, 1] := 1.0;
  x[1, 2] := 2.0;
  x[2, 1] := 3.0;
  x[2, 2] := 4.0;
end f;

model CevalFuncSubscript2
  constant Real x[:, :] = f();
end CevalFuncSubscript2;

// Result:
// class CevalFuncSubscript2
//   constant Real x[1,1] = 1.0;
//   constant Real x[1,2] = 2.0;
//   constant Real x[2,1] = 3.0;
//   constant Real x[2,2] = 4.0;
// end CevalFuncSubscript2;
// endResult
