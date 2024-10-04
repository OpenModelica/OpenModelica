// name: ImplicitRangeEq1
// keywords:
// status: correct
//
//

model ImplicitRangeEq1
  Real x[5];
equation
  for i loop
    x[i] = i;
  end for;
end ImplicitRangeEq1;

// Result:
// class ImplicitRangeEq1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
// equation
//   x[1] = 1.0;
//   x[2] = 2.0;
//   x[3] = 3.0;
//   x[4] = 4.0;
//   x[5] = 5.0;
// end ImplicitRangeEq1;
// endResult
