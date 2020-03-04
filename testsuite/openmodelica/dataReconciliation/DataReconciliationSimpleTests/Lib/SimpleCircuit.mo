within DataReconciliationSimpleTests.Lib;
model SimpleCircuit
  Real x1=250;
  Real x2=125;
  Real x3;
  Real x4 annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
equation
  x1-x2-x3 = 0;
  x4-x2-x3 = 0;
end SimpleCircuit;
