// name: CevalArrayConstant3
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalArrayConstant3
  constant Real x[:] = {1, 2, 3};
  Real y;
equation
  for i in 1:3 loop
    y = x[i];
  end for;
end CevalArrayConstant3;

// Result:
// class CevalArrayConstant3
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   Real y;
// equation
//   y = 1.0;
//   y = 2.0;
//   y = 3.0;
// end CevalArrayConstant3;
// endResult
