within TSP_DataReconciliationSimpleTests.Components.PressureLoss;
model SingularPressureLoss_KDR
  "Singular pressure loss"
  parameter Real K=1.e-4
    "Pressure loss coefficient"
    annotation (__OpenModelica_BoundaryCondition=true);
  parameter ThermoSysPro.Units.SI.Density p_rho=0
    "If > 0, fixed fluid density";
protected
  parameter Real eps=1.e-3
    "Small number for pressure loss equation";
public
  ThermoSysPro.Units.SI.PressureDifference deltaP
    "Singular pressure loss";
  ThermoSysPro.Units.SI.MassFlowRate Q(
    start=100)
    "Mass flow rate";
  ThermoSysPro.Units.SI.Density rho(
    start=998)
    "Fluid density";
  ThermoSysPro.Units.SI.Temperature T(
    start=290)
    "Fluid temperature";
  ThermoSysPro.Units.SI.AbsolutePressure Pm(
    start=1.e5)
    "Average fluid pressure";
  ThermoSysPro.Units.SI.SpecificEnthalpy h(
    start=100000)
    "Fluid specific enthalpy";
  ThermoSysPro.WaterSteam.Connectors.FluidInlet C1
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet C2
    annotation (Placement(transformation(extent={{90,-10},{110,10}},rotation=0)));
equation
  C1.P-C2.P=deltaP;
  C2.Q=C1.Q;
  C2.h=C1.h;
  h=C1.h;
  Q=C1.Q;

  /* Flow reversal */
  0=C1.h-C1.h_vol;

  /* Pressure loss */

  //  deltaP = K*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho;
  deltaP=K*Q^2/rho;

  /* Fluid thermodynamic properties */
  Pm=(C1.P+C2.P)/2;
  T=Modelica.Media.Water.WaterIF97_ph.temperature_ph(
    Pm,
    h,
    0);

  //  h = Modelica.Media.Water.WaterIF97_ph.specificEnthalpy_pT(Pm, T, 0,0);
  if(p_rho > 0) then
    rho=p_rho;
  else

    //   rho = Modelica.Media.Water.WaterIF97_ph.density_ph(Pm, Modelica.Media.Water.WaterIF97_ph.specificEnthalpy_pT(Pm,T,0), 0);

    //    rho = Modelica.Media.Water.WaterIF97_ph.density_ph(Pm,0.98e6,0);

    //    rho=800 +1e-6*Pm;
    rho=Modelica.Media.Water.WaterIF97_ph.density_ph(
      Pm,
      h,
      0);
  end if;
  annotation (
    Diagram(
      coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}),
      graphics={
        Polygon(
          points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,40}},
          lineColor={0,0,255},
          fillColor={128,255,0},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}},
          lineColor={0,0,255},
          fillColor={128,255,0},
          fillPattern=FillPattern.Solid)}),
    Icon(
      coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}),
      graphics={
        Polygon(
          points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,40}},
          lineColor={0,0,255},
          fillColor={128,255,0},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}},
          lineColor={0,0,255},
          fillColor={128,255,0},
          fillPattern=FillPattern.Solid)}),
    Window(
      x=0.09,
      y=0.2,
      width=0.66,
      height=0.69),
    Documentation(
      info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
<p><b>ThermoSysPro Version 2.0</b></p>
<p>This component model is documented in Sect. 13.4 of the <a href=\"https://www.springer.com/us/book/9783030051044\">ThermoSysPro book</a>. </h4>
</HTML>
    ",
      revisions="<html>
<p><u><b>Authors</b></u></p>
<ul>
<li>Baligh El Hefni</li>
<li>Daniel Bouskela </li>
</ul>
</html>"));
end SingularPressureLoss_KDR;
