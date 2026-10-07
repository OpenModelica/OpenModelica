// name: HoldTest
// keywords: synchronous features
// status: correct

model HoldTest
  output Real x;
  output Real y[2];
  Real z[2];
equation
  x = hold(3);
  y = hold(z);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end HoldTest;

// Result:
// class HoldTest
//   output Real x;
//   output Real y[1];
//   output Real y[2];
//   Real z[1];
//   Real z[2];
// equation
//   x = /*Real*/(hold(3));
//   y[1] = hold(z[1]);
//   y[2] = hold(z[2]);
// end HoldTest;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
