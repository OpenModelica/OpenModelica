// name: CevalFuncArray5
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that the function evaluation can handle non-literal bindings.
//

function f
  output Real[10] v = linspace(0, 9, 10);
algorithm
  for i in 1:10 loop
    v[i] := max(0, v[i]);
  end for;
end f;

model CevalFuncArray5
  constant Real x[:] = f();
end CevalFuncArray5;

// Result:
// class CevalFuncArray5
//   constant Real x[1] = 0.0;
//   constant Real x[2] = 1.0;
//   constant Real x[3] = 2.0;
//   constant Real x[4] = 3.0;
//   constant Real x[5] = 4.0;
//   constant Real x[6] = 5.0;
//   constant Real x[7] = 6.0;
//   constant Real x[8] = 7.0;
//   constant Real x[9] = 8.0;
//   constant Real x[10] = 9.0;
// end CevalFuncArray5;
// endResult
