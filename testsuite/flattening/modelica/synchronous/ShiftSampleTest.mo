// name: ShiftSampleTest
// keywords: synchronous features
// status: correct

model ShiftSampleTest
  output Real x;
  output Real y[2];
  Real z[2];
equation
  x = shiftSample(1.0, 2, 4);
  y = shiftSample(z, 3);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ShiftSampleTest;

// Result:
// class ShiftSampleTest
//   output Real x;
//   output Real y[1];
//   output Real y[2];
//   Real z[1];
//   Real z[2];
// equation
//   x = shiftSample(1.0, 2, 4);
//   y[1] = shiftSample(z[1], 3, 1);
//   y[2] = shiftSample(z[2], 3, 1);
// end ShiftSampleTest;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
