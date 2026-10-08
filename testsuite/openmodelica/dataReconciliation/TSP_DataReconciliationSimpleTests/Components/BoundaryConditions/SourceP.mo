within TSP_DataReconciliationSimpleTests.Components.BoundaryConditions;
model SourceP
  "Water/steam source with fixed pressure"
  parameter Modelica.Units.SI.AbsolutePressure P0=300000
    "Source pressure"
    annotation (__OpenModelica_BoundaryCondition=true);
  parameter Modelica.Units.SI.Temperature T0=290
    "Source temperature (active if option_temperature=1)"
    annotation (__OpenModelica_BoundaryCondition=true);
  parameter Modelica.Units.SI.SpecificEnthalpy h0=100000
    "Source specific enthalpy (active if option_temperature=2)"
    annotation (__OpenModelica_BoundaryCondition=true);
  parameter Integer option_temperature=1
    "1:temperature fixed - 2:specific enthalpy fixed";
  parameter Integer mode=1
    "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Modelica.Units.SI.AbsolutePressure P
    "Fluid pressure";
  Modelica.Units.SI.MassFlowRate Q
    "Mass flow rate";
  Modelica.Units.SI.Temperature T
    "Fluid temperature";
  Modelica.Units.SI.SpecificEnthalpy h
    "Fluid enthalpy";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}},rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy
    annotation (Placement(transformation(origin={0,-50},extent={{10,-10},{-10,10}},rotation=270)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet C
    annotation (Placement(transformation(extent={{90,-10},{110,10}},rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ITemperature
    annotation (Placement(transformation(origin={0,50},extent={{-10,-10},{10,10}},rotation=270)));
equation
  C.P=P;
  C.Q=Q;
  C.h_vol=h;
  if(cardinality(
    IPressure) == 0) then
    IPressure.signal=P0;
  end if;
  P=IPressure.signal;
  if(cardinality(
    ITemperature) == 0) then
    ITemperature.signal=T0;
  end if;
  if(cardinality(
    ISpecificEnthalpy) == 0) then
    ISpecificEnthalpy.signal=h0;
  end if;
  if(option_temperature == 1) then
    T=ITemperature.signal;
    h=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(
      P,
      T,
      0);
  elseif(option_temperature == 2) then
    h=ISpecificEnthalpy.signal;
    T=ThermoSysPro.Properties.Fluid.Temperature_Ph(
      P,
      h,
      1,
      mode,
      0,
      0,
      0,
      0);
  else
    assert(
      false,
      "SourcePressureWaterSteam: incorrect option");
  end if;
  annotation (
    Diagram(
      coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}),
      graphics={
        Line(
          points={{40,0},{90,0},{72,10}}),
        Line(
          points={{90,0},{72,-10}}),
        Text(
          extent={{-58,30},{-40,10}},
          textString="P"),
        Text(
          extent={{-40,-40},{-10,-60}},
          textString="h / T"),
        Rectangle(
          lineColor={0,0,255},
          fillColor={127,255,0},
          fillPattern=FillPattern.Solid,
          extent={{-40,40},{40,-40}}),
        Text(
          extent={{-94,28},{98,-28}},
          textString="P")}),
    Icon(
      coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}),
      graphics={
        Line(
          points={{40,0},{90,0},{72,10}}),
        Rectangle(
          lineColor={0,0,255},
          fillColor={127,255,0},
          fillPattern=FillPattern.Solid,
          extent={{-40,40},{40,-40}}),
        Line(
          points={{90,0},{72,-10}}),
        Text(
          extent={{-94,28},{98,-28}},
          textString="P"),
        Text(
          extent={{-58,30},{-40,10}},
          textString="P"),
        Text(
          extent={{-40,-40},{-10,-60}},
          textString="h / T")}),
    Window(
      x=0.45,
      y=0.01,
      width=0.35,
      height=0.49),
    Documentation(
      info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
    ",
      revisions="<html>
<p><u><b>Authors</b></u></p>
<ul>
<li>Daniel Bouskela</li>
<li>Baligh El Hefni </li>
</ul>
</html>"));
end SourceP;
