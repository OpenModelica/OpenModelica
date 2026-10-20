within TSP_DataReconciliationSimpleTests.Models.Splitter;
model TSP_Splitter_p2
  "Article example"
  Components.BoundaryConditions.SinkQ sinkQ1(
    Q0=1)
    annotation (Placement(visible=true,transformation(origin={72,-30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceP sourceP(
    option_temperature=2)
    annotation (Placement(visible=true,transformation(origin={-70,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ(
    Q0=1)
    annotation (Placement(visible=true,transformation(origin={70,28},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSource heatSource(
    W0={1e6},
    option_temperature=2)
    annotation (Placement(visible=true,transformation(origin={-4,50},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.VolumeBTh volume(
    P(
      displayUnit="Pa"),
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={1,0},extent={{-11,-10},{11,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss pipe1(
    K=1000,
    Pm(
      displayUnit="Pa"),
    T(
      displayUnit="K"),
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-38,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss pipe2(
    K=1000,
    Pm(
      displayUnit="Pa"),
    T(
      displayUnit="K"),
    flow_reversal=false,
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={28,28},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss pipe3(
    K=1000,
    Pm(
      displayUnit="Pa"),
    T(
      displayUnit="K"),
    flow_reversal=false,
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={32,-30},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(heatSource.C[1],volume.Cth)
    annotation (Line(points={{-4,40},{-4,6}}));
  connect(pipe1.C2,volume.Ce1)
    annotation (Line(points={{-28,0},{-10,0}},color={0,0,255}));
  connect(volume.Cs1,pipe2.C1)
    annotation (Line(points={{2,10},{0,10},{0,28},{18,28}},color={0,0,255}));
  connect(volume.Cs2,pipe3.C1)
    annotation (Line(points={{2,-10},{0,-10},{0,-30},{22,-30}},color={0,0,255}));
  connect(pipe2.C2,sinkQ.C)
    annotation (Line(points={{38,28},{60,28}},color={0,0,255}));
  connect(pipe3.C2,sinkQ1.C)
    annotation (Line(points={{42,-30},{62,-30}},color={0,0,255}));
  connect(pipe1.C2,volume.Ce1)
    annotation (Line(points={{-28,0},{-10,0}},color={0,0,255}));
  connect(sourceP.C,pipe1.C1)
    annotation (Line(points={{-60,0},{-48,0}},color={0,0,255}));
end TSP_Splitter_p2;
