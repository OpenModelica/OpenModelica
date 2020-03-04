within DataReconciliationSimpleTests;
model HalfSimpleCircuit2
  Lib.HalfSimpleCircuit halfSimpleCircuit(
    x1(uncertain=Uncertainty.refine),
    x2(uncertain=Uncertainty.refine))
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end HalfSimpleCircuit2;
