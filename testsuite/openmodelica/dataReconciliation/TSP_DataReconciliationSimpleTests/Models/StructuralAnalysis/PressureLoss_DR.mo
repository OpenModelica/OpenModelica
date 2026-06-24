within TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis;
model PressureLoss_DR
  Models.StructuralAnalysis.SG GV(
    Source_ARE(
      Q(
        start=550,
        displayUnit="kg/s",
        uncertain=Uncertainty.refine),
      C(
        P(
          start=70e5,
          displayUnit="Pa",
          uncertain=Uncertainty.refine))),
    singularPressureLoss_ARE(
      K(
        start=650,
        uncertain=Uncertainty.refine),
      T(
        start=500,
        displayUnit="K",
        uncertain=Uncertainty.refine)))
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
equation
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_STDOUT,LOG_ASSERT,LOG_STATS",
      reconcileState="()",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/PressureLoss_DR_OS.csv",
      variableFilter=".*"));
end PressureLoss_DR;
