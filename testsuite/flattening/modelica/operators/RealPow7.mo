// name: RealPow7
// keywords: real, power
// status: correct
//
//

model RealPow7
  constant Real x[:] = (-1).^{1, 2, 3};
end RealPow7;

// Result:
// class RealPow7
//   constant Real x[1] = -1.0;
//   constant Real x[2] = 1.0;
//   constant Real x[3] = -1.0;
// end RealPow7;
// endResult
