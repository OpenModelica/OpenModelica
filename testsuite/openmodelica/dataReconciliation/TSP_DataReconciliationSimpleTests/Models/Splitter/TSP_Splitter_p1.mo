within TSP_DataReconciliationSimpleTests.Models.Splitter;
model TSP_Splitter_p1
  "Article example"
  Components.BoundaryConditions.SinkQ sinkQ1(
    Q0=1)
    annotation (Placement(visible=true,transformation(origin={72,-30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Junctions.Splitter22 volume(
    P(
      displayUnit="Pa"),
    W=1e6,
    fluid=3,
    h(
      displayUnit="Pa"))
    annotation (Placement(visible=true,transformation(origin={-10,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI pipe1(
    Pm(
      displayUnit="Pa"),
    Qnom=1,
    T(
      displayUnit="K"),
    deltaPnom(
      displayUnit="Pa")=1e5)
    annotation (Placement(visible=true,transformation(origin={-50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI pipe2(
    Pm(
      displayUnit="Pa"),
    Qnom=1,
    T(
      displayUnit="K"),
    deltaPnom=99999.99999999999)
    annotation (Placement(visible=true,transformation(origin={30,28},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI pipe3(
    Pm(
      displayUnit="Pa"),
    Qnom=1,
    T(
      displayUnit="K"),
    deltaPnom=99999.99999999999)
    annotation (Placement(visible=true,transformation(origin={30,-30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceP sourceP(
    option_temperature=2)
    annotation (Placement(visible=true,transformation(origin={-90,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ(
    Q0=1)
    annotation (Placement(visible=true,transformation(origin={70,28},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(pipe1.C2,volume.Ce)
    annotation (Line(points={{-40,0},{-20,0}},color={0,0,255}));
  connect(volume.Cs1,pipe2.C1)
    annotation (Line(points={{-6,10},{-6,28},{20,28}},color={0,0,255}));
  connect(volume.Cs2,pipe3.C1)
    annotation (Line(points={{-6,-10},{-6,-30},{20,-30}},color={0,0,255}));
  connect(pipe3.C2,sinkQ1.C)
    annotation (Line(points={{40,-30},{62,-30}},color={0,0,255}));
  connect(sourceP.C,pipe1.C1)
    annotation (Line(points={{-80,0},{-60,0}},color={0,0,255}));
  connect(pipe2.C2,sinkQ.C)
    annotation (Line(points={{40,28},{60,28}},color={0,0,255}));
end TSP_Splitter_p1;
