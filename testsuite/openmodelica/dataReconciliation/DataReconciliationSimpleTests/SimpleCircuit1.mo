within DataReconciliationSimpleTests;
model SimpleCircuit1
  import DataReconciliationSimpleTests;
  DataReconciliationSimpleTests.Lib.SimpleCircuit simpleCircuit(
    x1(uncertain=Uncertainty.refine, start=2.1),
    x2(uncertain=Uncertainty.refine, start=1),
    x3(uncertain=Uncertainty.refine, start=0.95),
    x4(uncertain=Uncertainty.refine, start=2.0))
    annotation (Placement(transformation(extent={{-40,0},{0,40}})));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end SimpleCircuit1;
