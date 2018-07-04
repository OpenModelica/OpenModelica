// name: CevalArrayConstant2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalArrayConstant2
  constant Real x[:] = {1, 2, 3};
  Integer n = 2;
  Real y = x[n];
end CevalArrayConstant2;

// Result:
// class CevalArrayConstant2
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   Integer n = 2;
//   Real y = {1.0, 2.0, 3.0}[n];
// end CevalArrayConstant2;
// endResult
