// name: ExpandableConnector15
// keywords: expandable connector
// status: correct
//
// Checks that an array element added to an expandable connector during
// augmentation keeps its declared dimensions.
//

connector RealOutput = output Real;

expandable connector B
  Real x[2];
end B;

expandable connector E
end E;

model ExpandableConnector15
  B b[2];
  E e[2];
  RealOutput y[2] = {time, 2*time};
equation
  for i in 1:2 loop
    connect(y, b[i].x);
  end for;
  connect(b, e);
end ExpandableConnector15;

// Result:
// class ExpandableConnector15
//   Real e[2].x[1] "variable added to expandable connector";
//   Real e[2].x[2] "variable added to expandable connector";
//   Real e[1].x[1] "variable added to expandable connector";
//   Real e[1].x[2] "variable added to expandable connector";
//   Real b[1].x[1];
//   Real b[1].x[2];
//   Real b[2].x[1];
//   Real b[2].x[2];
//   output Real y[1];
//   output Real y[2];
// equation
//   b[2].x[1] = e[2].x[1];
//   b[2].x[1] = b[1].x[1];
//   b[2].x[1] = e[1].x[1];
//   b[2].x[1] = y[1];
//   b[2].x[2] = e[2].x[2];
//   b[2].x[2] = b[1].x[2];
//   b[2].x[2] = e[1].x[2];
//   b[2].x[2] = y[2];
//   y = {time, 2.0 * time};
// end ExpandableConnector15;
// endResult
