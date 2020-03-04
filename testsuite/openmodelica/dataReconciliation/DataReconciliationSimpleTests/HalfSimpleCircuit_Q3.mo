within DataReconciliationSimpleTests;
model HalfSimpleCircuit_Q3
  Lib.HalfSimpleCircuit_Q halfSimpleCircuit_Q(
    pipePressureLoss1(Q(uncertain=Uncertainty.refine)),
    pipePressureLoss3(Q(uncertain=Uncertainty.refine)))
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end HalfSimpleCircuit_Q3;
