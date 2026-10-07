// name:     Transpose3
// keywords: transpose #2743
// status:   correct
//
// Checks that transpose works for 3 dimensions.
//

model Transpose3
  Real x[:, :, :] = transpose({{{1}, {2}, {3}}, {{4}, {5}, {6}}});
end Transpose3;

// Result:
// class Transpose3
//   Real x[1,1,1];
//   Real x[1,2,1];
//   Real x[2,1,1];
//   Real x[2,2,1];
//   Real x[3,1,1];
//   Real x[3,2,1];
// equation
//   x = {{{1.0}, {4.0}}, {{2.0}, {5.0}}, {{3.0}, {6.0}}};
// end Transpose3;
// endResult
