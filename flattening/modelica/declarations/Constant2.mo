// name:     Constant2
// keywords: declaration,type
// status:   correct
//
// Constants and their use in expressions. This tests that the
// translator checks that the equation modifications are constant.
//

model Constant2
  constant Real A = 5.0;
  constant Real B = A;
  constant Real C = B + 1.0;
  constant Real D = C - A;
  constant Integer E = 3;
  constant Integer F = E + 4;
end Constant2;

// Result:
// class Constant2
//   constant Real A = 5.0;
//   constant Real B = 5.0;
//   constant Real C = 6.0;
//   constant Real D = 1.0;
//   constant Integer E = 3;
//   constant Integer F = 7;
// end Constant2;
// endResult
