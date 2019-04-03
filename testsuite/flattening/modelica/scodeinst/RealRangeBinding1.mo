// name: RealRangeBinding1
// keywords:
// status: correct
// cflags: -d=newInst
//

model RealRangeBinding1
  constant Real x[:] = 1.0:3.0;
  constant Real y[:] = 3.0:0.5:5.0;
end RealRangeBinding1;

// Result:
// class RealRangeBinding1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   constant Real y[1] = 3.0;
//   constant Real y[2] = 3.5;
//   constant Real y[3] = 4.0;
//   constant Real y[4] = 4.5;
//   constant Real y[5] = 5.0;
// end RealRangeBinding1;
// endResult
