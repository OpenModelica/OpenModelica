within TSP_DataReconciliationSimpleTests.Models;
model Rankine
  ThermoSysPro.WaterSteam.HeatExchangers.StaticCondenser staticCondenser(
    Pcond(
      displayUnit="Pa"),
    Pee(
      displayUnit="Pa"),
    Pex(
      displayUnit="Pa"),
    Pse(
      displayUnit="Pa"),
    Tee(
      displayUnit="K"),
    Tsat(
      displayUnit="K"),
    Tse(
      displayUnit="K"),
    rho_ee(
      displayUnit="kg/m3"),
    rho_ex(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={50,-10},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Machines.StaticCentrifugalPump staticCentrifugalPump
    annotation (Placement(visible=true,transformation(origin={2,-88},extent={{10,-10},{-10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Boilers.ElectricBoiler electricBoiler(
    Te(
      displayUnit="K"),
    Ts(
      displayUnit="K"),
    W=2e6)
    annotation (Placement(visible=true,transformation(origin={-50,-50},extent={{10,-10},{-10,10}},rotation=-90)));
  ThermoSysPro.WaterSteam.Machines.StodolaTurbine stodolaTurbine(
    Pe(
      displayUnit="Pa"),
    Ps(
      displayUnit="Pa"),
    rhos(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-2,88},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.RefP refP(
    P0=700000)
    annotation (Placement(visible=true,transformation(origin={-50,10},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceQ sourceQ
    annotation (Placement(visible=true,transformation(origin={10,-16},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP
    annotation (Placement(visible=true,transformation(origin={88,-16},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.LoopBreakers.LoopBreakerQ loopBreakerQ
    annotation (Placement(visible=true,transformation(origin={-50,48},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.WaterSteam.LoopBreakers.LoopBreakerP loopBreakerP
    annotation (Placement(visible=true,transformation(origin={-50,-20},extent={{-10,-10},{10,10}},rotation=90)));
equation
  connect(staticCondenser.Cex,staticCentrifugalPump.C1)
    annotation (Line(points={{50.1,-20.2},{50.1,-88},{12,-88}},color={0,0,255}));
  connect(stodolaTurbine.Cs,staticCondenser.Cvt)
    annotation (Line(points={{8,88},{50,88},{50,0}},color={0,0,255}));
  connect(sourceQ.C,staticCondenser.Cee)
    annotation (Line(points={{20,-16},{40,-16}},color={0,0,255}));
  connect(staticCondenser.Cse,sinkP.C)
    annotation (Line(points={{60,-16},{78,-16}},color={0,0,255}));
  connect(staticCentrifugalPump.C2,electricBoiler.Ce)
    annotation (Line(points={{-8,-88},{-50,-88},{-50,-60}},color={0,0,255}));
  connect(loopBreakerQ.C1,refP.C2)
    annotation (Line(points={{-50,38},{-50,20}},color={0,0,255}));
  connect(loopBreakerQ.C2,stodolaTurbine.Ce)
    annotation (Line(points={{-50,58},{-50,88},{-12,88}},color={0,0,255}));
  connect(refP.C1,loopBreakerP.C2)
    annotation (Line(points={{-50,0},{-50,-10}},color={0,0,255}));
  connect(loopBreakerP.C1,electricBoiler.Cs)
    annotation (Line(points={{-50,-30},{-50,-40}},color={0,0,255}));
end Rankine;
