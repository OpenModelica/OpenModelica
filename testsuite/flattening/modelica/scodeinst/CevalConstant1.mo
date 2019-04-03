// name: CevalConstant1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalConstant1
  constant Integer n = 3;
  Real x = n;
end CevalConstant1;

// Result:
// class CevalConstant1
//   constant Integer n = 3;
//   Real x = 3.0;
// end CevalConstant1;
// endResult
