within DataReconciliationSimpleTests;
model RedundancyTestCase2
  Real x1(uncertain=Uncertainty.refine)=1;
  Real x2(uncertain=Uncertainty.refine)=2;
  Real x3;
  Real x4;
  Real x5;
  Real x6                               annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
equation
  x1-x2-x3 = 0;
  x2-x4 = 0;
  x3-x5 = 0;
  x4+x5-x6 = 0;
end RedundancyTestCase2;
