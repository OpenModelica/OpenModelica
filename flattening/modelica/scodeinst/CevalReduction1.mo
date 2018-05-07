// name: CevalReduction1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalReduction1
  constant Real x[:] = {i for i in 1:5};
end CevalReduction1;

// Result:
// class CevalReduction1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   constant Real x[4] = 4.0;
//   constant Real x[5] = 5.0;
// end CevalReduction1;
// endResult
