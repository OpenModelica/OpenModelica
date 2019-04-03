// name: CevalArrayConstructor2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalArrayConstructor2
  constant Real x[:,:] = {i-j for i in 1:5, j in 1:3};
end CevalArrayConstructor2;

// Result:
// class CevalArrayConstructor2
//   constant Real x[1,1] = 0.0;
//   constant Real x[1,2] = 1.0;
//   constant Real x[1,3] = 2.0;
//   constant Real x[1,4] = 3.0;
//   constant Real x[1,5] = 4.0;
//   constant Real x[2,1] = -1.0;
//   constant Real x[2,2] = 0.0;
//   constant Real x[2,3] = 1.0;
//   constant Real x[2,4] = 2.0;
//   constant Real x[2,5] = 3.0;
//   constant Real x[3,1] = -2.0;
//   constant Real x[3,2] = -1.0;
//   constant Real x[3,3] = 0.0;
//   constant Real x[3,4] = 1.0;
//   constant Real x[3,5] = 2.0;
// end CevalArrayConstructor2;
// endResult
