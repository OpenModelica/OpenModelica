// name: CevalArrayConstructor1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalArrayConstructor1
  constant Real x[:] = {i for i in 1:5};
end CevalArrayConstructor1;

// Result:
// class CevalArrayConstructor1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   constant Real x[4] = 4.0;
//   constant Real x[5] = 5.0;
// end CevalArrayConstructor1;
// endResult
