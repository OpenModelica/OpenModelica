// name: CevalVectorProduct1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalVectorProduct1
  constant Real x = {1, 2, 3} * {4, 5, 6};
  constant Real y = ones(0) * ones(0);
end CevalVectorProduct1;

// Result:
// class CevalVectorProduct1
//   constant Real x = 32.0;
//   constant Real y = 0.0;
// end CevalVectorProduct1;
// endResult
