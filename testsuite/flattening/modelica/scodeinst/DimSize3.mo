// name: DimSize3
// keywords:
// status: correct
// cflags: -d=newInst,-nfEvalConstArgFuncs
//

function f
  input Real x[:, size(x, 1)];
end f;

model DimSize3
algorithm
  f({{1, 2}, {3, 4}});
end DimSize3;

// Result:
// function f
//   input Real[:, size(x, 1)] x;
// end f;
//
// class DimSize3
// algorithm
//   f({{1.0, 2.0}, {3.0, 4.0}});
// end DimSize3;
// endResult
