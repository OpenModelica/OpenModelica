within TSP_DataReconciliationSimpleTests.Models.Pipe;
model TSP_Pipe3
  Components.BoundaryConditions.SourcePQ sourcePQ1
    annotation (Placement(visible=true,transformation(origin={-90,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.Sink sink1
    annotation (Placement(visible=true,transformation(origin={90,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa"),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa"),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      uncertain=Uncertainty.refine),
    flow_reversal=false,
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=false)
    annotation (Placement(visible=true,transformation(origin={2,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss3(
    Pm(
      displayUnit="Pa"),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={50,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(sourcePQ1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-80,0},{-60,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,singularPressureLoss2.C1)
    annotation (Line(points={{-40,0},{-8,0}},color={0,0,255}));
  connect(singularPressureLoss2.C2,singularPressureLoss3.C1)
    annotation (Line(points={{12,0},{40,0}},color={0,0,255}));
  connect(singularPressureLoss3.C2,sink1.C)
    annotation (Line(points={{60,0},{80,0},{80,0},{80,0},{80,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Pipe3_Inputs.csv"));
end TSP_Pipe3;
