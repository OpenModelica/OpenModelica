within DataReconciliationSimpleTests;
model SimpleCircuit_Q2

  Lib.SimpleCircuit_Q simpleCircuit_Q(
    pipePressureLoss1(Q(uncertain=Uncertainty.refine)),
    pipePressureLoss2(Q(uncertain=Uncertainty.refine)))
    annotation (Placement(transformation(extent={{-30,-20},{20,30}})));
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}},     preserveAspectRatio=true, initialScale=0.1, grid={1,1})),
      DymolaStoredErrors);
/*equation
  simpleCircuit_Q.pipePressureLoss1.Q = 0;
  simpleCircuit_Q.pipePressureLoss2.Q = 0*/
end SimpleCircuit_Q2;
