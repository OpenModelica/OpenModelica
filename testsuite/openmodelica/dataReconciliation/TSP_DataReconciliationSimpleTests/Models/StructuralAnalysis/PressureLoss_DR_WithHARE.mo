within TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis;
model PressureLoss_DR_WithHARE
  extends TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.PressureLoss_DR(
    GV(
      singularPressureLoss_ARE(
        C1(
          h(
            uncertain=Uncertainty.refine)))));
equation
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/PressureLoss_DR_WithHARE_OS.csv",
      variableFilter=".*"));
end PressureLoss_DR_WithHARE;
