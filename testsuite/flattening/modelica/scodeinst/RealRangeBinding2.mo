// name: RealRangeBinding2
// keywords:
// status: correct
//
// Real ranges where stop is not part of the range, MLS 10.4.3.
//

model RealRangeBinding2
  constant Real x[:] = 2.7:6.8;
  constant Real y[:] = 0.5:2.0:7.9;
  constant Real z[:] = 1.0:-0.3:0.0;
  constant Real w[:] = 1e-4:1e-4:5e-4;
  constant Real s = sum(2.7:6.8);
end RealRangeBinding2;

// Result:
// class RealRangeBinding2
//   constant Real x[1] = 2.7;
//   constant Real x[2] = 3.7;
//   constant Real x[3] = 4.7;
//   constant Real x[4] = 5.7;
//   constant Real x[5] = 6.7;
//   constant Real y[1] = 0.5;
//   constant Real y[2] = 2.5;
//   constant Real y[3] = 4.5;
//   constant Real y[4] = 6.5;
//   constant Real z[1] = 1.0;
//   constant Real z[2] = 0.7;
//   constant Real z[3] = 0.4;
//   constant Real z[4] = 0.10000000000000009;
//   constant Real w[1] = 1e-4;
//   constant Real w[2] = 2e-4;
//   constant Real w[3] = 3.0000000000000003e-4;
//   constant Real w[4] = 4e-4;
//   constant Real w[5] = 5e-4;
//   constant Real s = 23.5;
// end RealRangeBinding2;
// endResult
