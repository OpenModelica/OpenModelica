within DataReconciliationSimpleTests;
model SimpleCircuit_Q1

  Lib.SimpleCircuit_Q simpleCircuit_Q(
    pipePressureLoss1(Q(uncertain=Uncertainty.refine)),
    pipePressureLoss2(Q(uncertain=Uncertainty.refine)),
    pipePressureLoss3(Q(uncertain=Uncertainty.refine)),
    pipePressureLoss4(Q(uncertain=Uncertainty.refine)))
    annotation (Placement(transformation(extent={{-30,-20},{20,30}})));
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}},     preserveAspectRatio=true, initialScale=0.1, grid={1,1})),
      DymolaStoredErrors);
end SimpleCircuit_Q1;
