within DataReconciliationSimpleTests;
model SinkP "Water/steam sink with fixed pressure"
  parameter Modelica.SIunits.AbsolutePressure P0=100000 "Sink pressure" annotation(__OpenModelica_BoundaryCondition = true);
  parameter Modelica.SIunits.Temperature T0=290
    "Sink temperature (active if option_temperature=1)" annotation(__OpenModelica_BoundaryCondition = true);
  parameter Modelica.SIunits.SpecificEnthalpy h0=100000
    "Sink specific enthalpy (active if option_temperature=2)" annotation(__OpenModelica_BoundaryCondition = true);
  parameter Integer option_temperature=1
    "1:temperature fixed - 2:specific enthalpy fixed";
  parameter Integer mode=1
    "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";

public
  Modelica.SIunits.AbsolutePressure P "Fluid pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  Modelica.SIunits.Temperature T "Fluid temperature";
  Modelica.SIunits.SpecificEnthalpy h "Fluid enthalpy";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
    "Propri�t�s de l'eau"
    annotation (Placement(transformation(extent={{-100,80},{-80,100}}, rotation=
           0)));
public
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure
    annotation (Placement(transformation(
        origin={50,0},
        extent={{-10,-10},{10,10}},
        rotation=180)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy
    annotation (Placement(transformation(
        origin={0,-50},
        extent={{10,-10},{-10,10}},
        rotation=270)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet C       annotation (Placement(transformation(extent={{
            -110,-10},{-90,10}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ITemperature
    annotation (Placement(transformation(
        origin={0,50},
        extent={{-10,-10},{10,10}},
        rotation=270)));
equation

  C.P = P;
  C.Q = Q;
  C.h_vol = h;

  if (cardinality(IPressure) == 0) then
    IPressure.signal = P0;
  end if;

  P = IPressure.signal;

  if (cardinality(ITemperature) == 0) then
      ITemperature.signal = T0;
  end if;

  if (cardinality(ISpecificEnthalpy) == 0) then
      ISpecificEnthalpy.signal = h0;
  end if;

  if (option_temperature == 1) then
    T = ITemperature.signal;
    h = ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(P, T, 0);
  elseif (option_temperature == 2) then
    h = ISpecificEnthalpy.signal;
    T = pro.T;
  else
    assert(false, "SinkPressureWaterSteam: incorrect option");
  end if;

  pro = ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, h, mode);

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{-90,0},{-40,0},{-58,10}}),
        Line(points={{-40,0},{-58,-10}}),
        Text(extent={{40,28},{58,8}}, textString=
                                          "P"),
        Text(extent={{-40,-40},{-10,-60}}, textString=
                                             "h / T"),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={127,255,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{-94,26},{98,-30}}, textString=
                                             "P")}),
    Window(
      x=0.06,
      y=0.16,
      width=0.67,
      height=0.71),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{-90,0},{-40,0},{-58,10}}),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={127,255,0},
          fillPattern=FillPattern.Solid),
        Line(points={{-40,0},{-58,-10}}),
        Text(extent={{-94,26},{98,-30}}, textString=
                                             "P"),
        Text(extent={{40,28},{58,8}}, textString=
                                          "P"),
        Text(extent={{-40,-40},{-10,-60}}, textString=
                                             "h / T")}),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<p><u><b>Authors</b></u></p>
<ul>
<li>Daniel Bouskela</li>
<li>Baligh El Hefni </li>
</ul>
</html>"));
end SinkP;
