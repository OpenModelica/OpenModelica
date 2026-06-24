within TSP_DataReconciliationSimpleTests.Models.Splitter;
model TSP_Splitter
  "Article example"
  Components.BoundaryConditions.SinkQ sinkQ1(
    Q0=1)
    annotation (Placement(visible=true,transformation(origin={72,-30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI pipe1(
    Pm(
      displayUnit="Pa"),
    Qnom=1,
    T(
      displayUnit="K"),
    deltaPnom(
      displayUnit="Pa")=99999.99999999999,
    flow_reversal=false)
    annotation (Placement(visible=true,transformation(origin={-30,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI pipe2(
    Pm(
      displayUnit="Pa"),
    Qnom=1,
    T(
      displayUnit="K"),
    deltaPnom=99999.99999999999,
    flow_reversal=false)
    annotation (Placement(visible=true,transformation(origin={30,28},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI pipe3(
    Pm(
      displayUnit="Pa"),
    Qnom=1,
    T(
      displayUnit="K"),
    deltaPnom=99999.99999999999,
    flow_reversal=false)
    annotation (Placement(visible=true,transformation(origin={30,-30},extent={{-10,-10},{10,10}},rotation=0)));
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
equation
  connect(pipe3.C2,sinkQ1.C)
    annotation (Line(points={{40,-30},{62,-30}},color={0,0,255}));
  connect(sourceP.C,pipe1.C1)
    annotation (Line(points={{-60,0},{-40,0}},color={0,0,255}));
  connect(pipe2.C2,sinkQ.C)
    annotation (Line(points={{40,28},{60,28}},color={0,0,255}));
  connect(pipe1.C2,volume.Ce1)
    annotation (Line(points={{-20,0},{-10,0}},color={0,0,255}));
  connect(volume.Cs2,pipe3.C1)
    annotation (Line(points={{1,-10},{1,-30},{20,-30}},color={0,0,255}));
  connect(volume.Cs1,pipe2.C1)
    annotation (Line(points={{1,10},{1,28},{20,28}},color={0,0,255}));
  connect(heatSource.C[1],volume.Cth)
    annotation (Line(points={{-4,40},{-4,6}}));
end TSP_Splitter;
