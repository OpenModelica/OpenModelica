within TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis;
model SG_DR
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
    Puit_VVP(
      C(
        P(
          start=68e5,
          displayUnit="Pa",
          uncertain=Uncertainty.refine))),
    Puit_purge(
      Q(
        start=5,
        displayUnit="kg/s",
        uncertain=Uncertainty.refine)),
    staticDrum(
      x(
        start=1,
        uncertain=Uncertainty.refine),
      Cth.W(
        start=1e9,
        displayUnit="W",
        uncertain=Uncertainty.refine)),
    singularPressureLoss_ARE(
      K(
        start=650,
        uncertain=Uncertainty.refine),
      T(
        start=500,
        displayUnit="K",
        uncertain=Uncertainty.refine)),
    singularPressureLoss_VVP(
      K(
        start=11,
        uncertain=Uncertainty.refine)))
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
equation
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/SG_DR_OS.csv",
      variableFilter=".*"));
end SG_DR;
