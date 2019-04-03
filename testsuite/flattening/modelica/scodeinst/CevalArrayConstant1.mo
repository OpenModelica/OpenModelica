// name: CevalArrayConstant1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalArrayConstant1
  constant Real x[:] = {1, 2, 3};
  Real y = x[1];
  Real z = x[2];
  Real w = x[3];
end CevalArrayConstant1;

// Result:
// class CevalArrayConstant1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   Real y = 1.0;
//   Real z = 2.0;
//   Real w = 3.0;
// end CevalArrayConstant1;
// endResult
