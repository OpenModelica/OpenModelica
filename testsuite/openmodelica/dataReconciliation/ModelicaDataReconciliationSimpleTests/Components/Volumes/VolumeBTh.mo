within ModelicaDataReconciliationSimpleTests.Components.Volumes;
model VolumeBTh "Mixing volume with 2 inlets and 2 outlets and thermal input"
  parameter Boolean specific_enthalpy_as_state_variable=true "true: specific enthalpy is state variable for the state equation - false: temperature is state variable for the state equation";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5 - 3: Simple";
  parameter Modelica.Units.SI.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Modelica.Units.SI.SpecificHeatCapacity cp=4200 "Specific heat capacity";
  parameter Real b=190e-5;
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";

  Modelica.Units.SI.Temperature T "Fluid temperature";
  Modelica.Units.SI.AbsolutePressure P(start=1.e5) "Fluid pressure";
  Modelica.Units.SI.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  Modelica.Units.SI.Density rho(start=998) "Fluid density";
  Modelica.Units.SI.MassFlowRate BQ "Right hand side of the mass balance equation";
  Modelica.Units.SI.Power BH "Right hand side of the energybalance equation";
  ThermoSysPro.Thermal.Connectors.ThermalPort Cth annotation (Placement(
      visible=true,
      transformation(extent={{-50,40},{-30,60}}, rotation=0),
      iconTransformation(extent={{-50,40},{-30,60}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce1 annotation (Placement(transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce2 annotation (Placement(
      visible=true,
      transformation(extent={{90,-10},{110,10}}, rotation=0),
      iconTransformation(extent={{90,-10},{110,10}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs1 annotation (Placement(
      visible=true,
      transformation(extent={{-8,90},{12,110}}, rotation=0),
      iconTransformation(extent={{-8,90},{12,110}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs2 annotation (Placement(transformation(extent={{-10,-108},{10,-88}}, rotation=0)));
equation

  /* Unconnected connectors */
  if (cardinality(Ce1) == 0) then
    Ce1.Q = 0;
    Ce1.h = 1.e5;
    Ce1.b = true;
  end if;

  if (cardinality(Ce2) == 0) then
    Ce2.Q = 0;
    Ce2.h = 1.e5;
    Ce2.b = true;
  end if;

  if (cardinality(Cs1) == 0) then
    Cs1.Q = 0;
    Cs1.h = 1.e5;
    Cs1.a = true;
  end if;

  if (cardinality(Cs2) == 0) then
    Cs2.Q = 0;
    Cs2.h = 1.e5;
    Cs2.a = true;
  end if;

  /* Mass balance equation */
  BQ = Ce1.Q + Ce2.Q - Cs1.Q - Cs2.Q;
  0 = BQ;

  P = Ce1.P;
  P = Ce2.P;
  P = Cs1.P;
  P = Cs2.P;

  /* Energy balance equation */
  BH = Ce1.Q*Ce1.h + Ce2.Q*Ce2.h - Cs1.Q*Cs1.h - Cs2.Q*Cs2.h + Cth.W;
  0 = BH;

  Ce1.h_vol = h;
  Ce2.h_vol = h;
  Cs1.h_vol = h;
  Cs2.h_vol = h;

  /* Fluid thermodynamic properties */
  if fluid == 3 then
    h = cp*(T - 273.16) + b*P;

    if p_rho > 0 then
      rho = p_rho;
    else
      rho = (-0.0025*(T - 273.16) - 0.1992)*(T - 273.16) + 1004.4;
    end if;
  else
    if specific_enthalpy_as_state_variable then
      T = ThermoSysPro.Properties.Fluid.Temperature_Ph(
        P,
        h,
        fluid,
        mode,
        0,
        0,
        0,
        0);
    else
      h = ThermoSysPro.Properties.Fluid.SpecificEnthalpy_PT(
        P,
        T,
        fluid,
        mode,
        0,
        0,
        0,
        0);
    end if;

    if (p_rho > 0) then
      rho = p_rho;
    else
      rho = ThermoSysPro.Properties.Fluid.Density_Ph(
        P,
        h,
        fluid,
        mode,
        0,
        0,
        0,
        0);
    end if;
  end if;

  Cth.T = T;
  annotation (
    Diagram(coordinateSystem(preserveAspectRatio=false, initialScale=0.1), graphics={Ellipse(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{-60,60},{60,-60}},
          endAngle=360),Line(points={{-90,0},{90,0}}),Line(points={{0,90},{0,-100}})}),
    Icon(coordinateSystem(preserveAspectRatio=false, initialScale=0.1), graphics={Line(points={{0,90},{0,-100}}),Line(points={{-90,0},{90,0}}),Ellipse(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{-60,60},{60,-60}},
          endAngle=360)}),
    Window(
      x=0.16,
      y=0.27,
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
end VolumeBTh;
