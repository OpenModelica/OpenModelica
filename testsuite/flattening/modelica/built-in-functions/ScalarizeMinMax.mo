// name:     ScalarizeMinMax
// keywords: scalarize min max
// status:   correct
//
// Tests that min/max reductions are scalarized when +scalarizeMinMax is used.
//

model ScalarizeMinMax
  Real x[5];
  Real r1, r2;
equation
  r1 = min(x);
  r2 = max(x);
  annotation(__OpenModelica_commandLineOptions="+scalarizeMinMax");
end ScalarizeMinMax;

// Result:
// class ScalarizeMinMax
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real r1;
//   Real r2;
// equation
//   r1 = min(x);
//   r2 = max(x);
// end ScalarizeMinMax;
// endResult
