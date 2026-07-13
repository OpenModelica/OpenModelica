within TSP_DataReconciliationSimpleTests.Models.FourFlows;
model TSP_FourFlows5
  Components.BoundaryConditions.Sink sink1
    annotation (Placement(visible=true,transformation(origin={148,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa",
      start=15e5,
      uncertain=Uncertainty.refine),
    Q(
      start=2.10,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=470,
      uncertain=Uncertainty.refine),
    deltaP(
      start=1.e5),
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa",
      start=4e5,
      uncertain=Uncertainty.refine),
    Q(
      start=1.10,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=465,
      uncertain=Uncertainty.refine),
    deltaP(
      start=1.e5),
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={0,20},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss3(
    Pm(
      displayUnit="Pa",
      start=4e5,
      uncertain=Uncertainty.refine),
    Q(
      start=0.95,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=473,
      uncertain=Uncertainty.refine),
    deltaP(
      start=1.e5),
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={0,-20},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss4(
    Pm(
      displayUnit="Pa",
      start=4e5,
      uncertain=Uncertainty.refine),
    Q(
      start=2.00,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=462,
      uncertain=Uncertainty.refine),
    deltaP(
      start=1.e5),
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={110,-2},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Junctions.StaticDrum staticDrum1(
    P(
      displayUnit="Pa",
      start=4e5,
      uncertain=Uncertainty.refine),
    T(
      start=470,
      uncertain=Uncertainty.refine),
    x=0.95)
    annotation (Placement(visible=true,transformation(origin={-22,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Junctions.Mixer2 mixer21(
    P(
      displayUnit="Pa",
      start=4e5,
      uncertain=Uncertainty.refine),
    T(
      start=470,
      uncertain=Uncertainty.refine),
    specific_enthalpy_as_state_variable=false)
    annotation (Placement(visible=true,transformation(origin={64,-2},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceQ sourceQ1(
    Q0=2,
    h0=1e6)
    annotation (Placement(visible=true,transformation(origin={-90,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.Sink sink
    annotation (Placement(visible=true,transformation(origin={72,56},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser simpleStaticCondenser(
    DPc(
      displayUnit="Pa"),
    DPf(
      displayUnit="Pa"),
    DPfc(
      displayUnit="Pa"),
    DPff(
      displayUnit="Pa"),
    DPgc(
      displayUnit="Pa"),
    DPgf(
      displayUnit="Pa"),
    Tec(
      displayUnit="K"),
    Tef(
      displayUnit="K"),
    Tsc(
      displayUnit="K"),
    Tsf(
      displayUnit="K"),
    rhoc(
      displayUnit="kg/m3"),
    rhof(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={34,56},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourcePQ sourcePQ
    annotation (Placement(visible=true,transformation(origin={-12,56},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(singularPressureLoss4.C2,sink1.C)
    annotation (Line(points={{120,-2},{127,-2},{127,0},{138,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,staticDrum1.Ce_sup)
    annotation (Line(points={{-40,0},{-40,4},{-31,4}},color={0,0,255}));
  connect(staticDrum1.Cs_eva,singularPressureLoss3.C1)
    annotation (Line(points={{-18,-9},{-18,-20},{-10,-20}},color={0,0,255}));
  connect(singularPressureLoss3.C2,mixer21.Ce2)
    annotation (Line(points={{10,-20},{60,-20},{60,-12}},color={0,0,255}));
  connect(mixer21.Cs,singularPressureLoss4.C1)
    annotation (Line(points={{74,-2},{100,-2}},color={0,0,255}));
  connect(sourceQ1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-80,0},{-60,0},{-60,0},{-60,0}},color={0,0,255}));
  connect(simpleStaticCondenser.Sc,mixer21.Ce1)
    annotation (Line(points={{40,46},{38,46},{38,20},{60,20},{60,8}},color={0,0,255}));
  connect(singularPressureLoss2.C2,simpleStaticCondenser.Ec)
    annotation (Line(points={{10,20},{28,20},{28,46}},color={0,0,255}));
  connect(staticDrum1.Cs_sur,singularPressureLoss2.C1)
    annotation (Line(points={{-18,9},{-18,20},{-10,20}},color={0,0,255}));
  connect(simpleStaticCondenser.Sf,sink.C)
    annotation (Line(points={{44,56},{62,56}},color={0,0,255}));
  connect(sourcePQ.C,simpleStaticCondenser.Ef)
    annotation (Line(points={{-2,56},{24,56}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_FourFlows5_Inputs.csv"));
end TSP_FourFlows5;
