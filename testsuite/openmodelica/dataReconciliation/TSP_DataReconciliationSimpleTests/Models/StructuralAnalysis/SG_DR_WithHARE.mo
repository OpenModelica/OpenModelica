within TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis;
model SG_DR_WithHARE
  extends TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis.SG_DR(
    GV(
      singularPressureLoss_ARE(
        C1(
          h(
            uncertain=Uncertainty.refine)))));
equation
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_STDOUT,LOG_ASSERT,LOG_STATS",
      reconcileState="()",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/SG_DR_WithHARE_OS.csv",
      variableFilter=".*"));
end SG_DR_WithHARE;
