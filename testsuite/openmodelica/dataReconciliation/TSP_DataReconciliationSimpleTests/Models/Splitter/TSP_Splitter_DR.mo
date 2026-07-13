within TSP_DataReconciliationSimpleTests.Models.Splitter;
model TSP_Splitter_DR
  TSP_Splitter splitter(
    volume(
      T(
        uncertain=Uncertainty.refine)),
    pipe1(
      Q(
        uncertain=Uncertainty.refine),
      Pm(
        uncertain=Uncertainty.refine),
      T(
        uncertain=Uncertainty.refine)),
    pipe2(
      Q(
        uncertain=Uncertainty.refine),
      Pm(
        uncertain=Uncertainty.refine),
      T(
        uncertain=Uncertainty.refine)),
    pipe3(
      Q(
        uncertain=Uncertainty.refine),
      Pm(
        uncertain=Uncertainty.refine),
      T(
        uncertain=Uncertainty.refine)))
    annotation (Placement(visible=true,transformation(origin={-1.77636e-15,3.55271e-15},extent={{-40,-40},{40,40}},rotation=0)));
equation
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Splitter_DR_Inputs.csv"));
end TSP_Splitter_DR;
