within DataReconciliationSimpleTests;
model SimpleCircuit_QP1
  Lib.SimpleCircuit_QP simpleCircuit_QP(
    pipePressureLoss1(Q(uncertain=Uncertainty.refine)),
    pipePressureLoss2(Q(uncertain=Uncertainty.refine)),
    pipePressureLoss3(Q(uncertain=Uncertainty.refine)),
    pipePressureLoss4(Q(uncertain=Uncertainty.refine)))
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end SimpleCircuit_QP1;
