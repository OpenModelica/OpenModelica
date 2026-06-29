within TSP_DataReconciliationSimpleTests.Components.Volumes;
model SGVALI
  "Steam Generator"
  parameter Real x_vvp=1.
    "Separation efficiency at the VVP outlet";
  parameter Modelica.Units.SI.MassFlowRate Qnom_vvp=535
    "Nominal mass flow rate for VVP outlet";
  parameter Modelica.Units.SI.Pressure DPnom_vvp=0.9e5
    "Nominal pressure loss between ARE and VVP";
  parameter Real CoeffDeltaP_are=1
    "Ponderation of the pressure loss equation between ARE and VVP";
  parameter Integer fluid=1
    "1: water/steam - 2: C3H3F5 - 3: Simple";
  ThermoSysPro.WaterSteam.Connectors.FluidInletI C1_are
    annotation (layer="icon",Placement(transformation(extent={{-10,-108},{10,-88}},rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI C2_pur
    annotation (layer="icon",Placement(transformation(extent={{20,-60},{40,-40}},rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI C3_vvp
    annotation (Placement(transformation(extent={{-10,90},{10,110}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Volumes.StaticDrum SG_volume(
    P(
      displayUnit="Pa"),
    fluid=fluid,
    x=x_vvp)
    annotation (Placement(transformation(extent={{-12,0},{8,20}},rotation=0)));
  PressureLoss.SingularPressureLossVALI DP_pur(
    deltaPnom=0)
    annotation (Placement(transformation(extent={{20,-10},{40,10}},rotation=0)));
  PressureLoss.SingularPressureLossVALI DP_vvp1(
    deltaPnom=DPnom_vvp,
    Qnom=Qnom_vvp,
    CoeffDeltaP=CoeffDeltaP_are)
    annotation (Placement(transformation(origin={0,50},extent={{-10,-10},{10,10}},rotation=90)));
  PressureLoss.SingularPressureLossVALI DP_are(
    deltaPnom=0)
    annotation (Placement(transformation(origin={0,-60},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.Thermal.Connectors.ThermalPort thermalPort
    annotation (Placement(transformation(extent={{-50,30},{-30,50}},rotation=0)));
equation
  connect(SG_volume.Cs_sur,DP_vvp1.C1)
    annotation (Line(points={{1.8,19.4},{1.8,20},{-6.12323e-016,20},{-6.12323e-016,40}},color={0,0,255}));
  connect(DP_vvp1.C2,C3_vvp)
    annotation (Line(points={{6.12323e-016,60},{6.12323e-016,76},{0,76},{0,100}},color={0,0,255}));
  connect(SG_volume.Cs_eva,DP_pur.C1)
    annotation (Line(points={{2,0.6},{2,0},{20,0}},color={0,0,255}));
  connect(DP_pur.C2,C2_pur)
    annotation (Line(points={{40,0},{45,0},{45,-50},{30,-50}},color={0,0,255}));
  connect(C1_are,DP_are.C1)
    annotation (Line(points={{0,-98},{0,-70},{-6.12323e-016,-70}}));
  connect(DP_are.C2,SG_volume.Ce_eco)
    annotation (Line(points={{6.12323e-016,-50},{6.12323e-016,-40},{-6,-40},{-6,0.6}},color={0,0,255}));
  connect(thermalPort,SG_volume.Cth)
    annotation (Line(points={{-40,40},{-20,40},{-20,10},{-2,10}},color={191,95,0}));
  annotation (
    structurallyIncomplete,
    Documentation(
      info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
    ",
      revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
    "),
    Diagram(
      coordinateSystem(
        preserveAspectRatio=true,
        extent={{-100,-100},{100,100}},
        grid={2,2}),
      graphics),
    Icon(
      coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}),
      graphics={
        Ellipse(
          extent={{-40,100},{40,60}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Ellipse(
          extent={{-30,-100},{30,-80}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-40,80},{-40,20},{-30,0},{-30,-90},{30,-90},{30,0},{40,20},{40,80},{-40,80}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-28,88},{28,32}},
          lineColor={0,0,255},
          textString="VALI")}),
    Icon,
    Window(
      x=0.09,
      y=0.11,
      width=0.7,
      height=0.66),
    Documentation(
      info="<html>
<p><b>Copyright &copy; EDF 2002 - 2003</b></p>
</HTML>
<html>
<p><b>Version 1.4</b></p>
</HTML>
    "),
    Diagram(
      Text(
        extent=[
          34,-4;
          68,-26],
        string="Valve 2")));
end SGVALI;
