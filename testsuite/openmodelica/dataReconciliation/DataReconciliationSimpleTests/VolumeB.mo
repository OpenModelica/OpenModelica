within DataReconciliationSimpleTests;
model VolumeB "Mixing volume with 2 inlets and 2 outlets"
  parameter Modelica.SIunits.Volume V=1 "Volume";
  parameter Modelica.SIunits.AbsolutePressure P0=1e5
    "Initial fluid pressure (active if dynamic_mass_balance=true and steady_state=false)";
  parameter Modelica.SIunits.SpecificEnthalpy h0=1e5
    "Initial fluid specific enthalpy (active if steady_state=false)";
  parameter Boolean dynamic_mass_balance=false
    "true: dynamic mass balance equation - false: static mass balance equation";
  parameter Boolean steady_state=true
    "true: start from steady state - false: start from (P0, h0)";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0
    "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";

public
  Modelica.SIunits.Temperature T "Fluid temperature";
  Modelica.SIunits.AbsolutePressure P(start=1.e5) "Fluid pressure";
  Modelica.SIunits.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  Modelica.SIunits.MassFlowRate BQ
    "Right hand side of the mass balance equation";
  Modelica.SIunits.Power BH "Right hand side of the energybalance equation";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
    "Propri�t�s de l'eau"
    annotation (Placement(transformation(extent={{-100,80},{-80,100}}, rotation=
           0)));
public
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce1
                           annotation (Placement(transformation(extent={{-110,
            -10},{-90,10}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce2
                           annotation (Placement(transformation(extent={{90,-10},
            {110,10}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs1
                           annotation (Placement(transformation(extent={{-10,80},
            {10,100}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs2
                           annotation (Placement(transformation(extent={{-10,
            -108},{10,-88}}, rotation=0)));
equation
  assert(V > 0, "Volume non-positive");

  /* Unconnected connectors */
  if (cardinality(Ce1) == 0) then
    Ce1.Q = 0 annotation( __OpenModelica_ExactConstantEquation = true);
    Ce1.h = 1.e5;
    Ce1.b = true;
  end if;

  if (cardinality(Ce2) == 0) then
    Ce2.Q = 0 annotation( __OpenModelica_ExactConstantEquation = true);
    Ce2.h = 1.e5;
    Ce2.b = true;
  end if;

  if (cardinality(Cs1) == 0) then
    Cs1.Q = 0 annotation( __OpenModelica_ExactConstantEquation = true);
    Cs1.h = 1.e5;
    Cs1.a = true;
  end if;

  if (cardinality(Cs2) == 0) then
    Cs2.Q = 0 annotation( __OpenModelica_ExactConstantEquation = true);
    Cs2.h = 1.e5;
    Cs2.a = true;
  end if;

  /* Mass balance equation */
  BQ = Ce1.Q + Ce2.Q - Cs1.Q - Cs2.Q;
  0 = BQ annotation( __OpenModelica_ExactConstantEquation = true);

  P = Ce1.P;
  P = Ce2.P;
  P = Cs1.P;
  P = Cs2.P;

  /* Energy balance equation */
  BH = Ce1.Q*Ce1.h + Ce2.Q*Ce2.h - Cs1.Q*Cs1.h - Cs2.Q*Cs2.h;
  0 = BH annotation( __OpenModelica_ExactConstantEquation = true);

  Ce1.h_vol = h;
  Ce2.h_vol = h;
  Cs1.h_vol = h;
  Cs2.h_vol = h;

  /* Fluid thermodynamic properties */
  pro = ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);

  T = pro.T;

  if (p_rho > 0) then
    rho = p_rho;
  else
    rho = pro.d;
  end if;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{-90,0},{90,0}}),
        Line(points={{0,90},{0,-100}}),
        Ellipse(
          extent={{-60,60},{60,-60}},
          lineColor={0,0,255},
          fillColor={85,170,255},
          fillPattern=FillPattern.Solid)}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{0,90},{0,-100}}),
        Line(points={{-90,0},{90,0}}),
        Ellipse(
          extent={{-60,60},{60,-60}},
          lineColor={0,0,255},
          fillColor={85,170,255},
          fillPattern=FillPattern.Solid)}),
    Window(
      x=0.07,
      y=0.22,
      width=0.66,
      height=0.69),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
<p><b>ThermoSysPro Version 2.0</b></p>
<p>This component model is documented in Sect. 14.1 of the <a href=\"https://www.springer.com/us/book/9783030051044\">ThermoSysPro book</a>. </h4>
</HTML>
", revisions="<html>
<p><u><b>Author</b></u></p>
<ul>
<li>Daniel Bouskela </li>
</ul>
</html>"));
end VolumeB;
