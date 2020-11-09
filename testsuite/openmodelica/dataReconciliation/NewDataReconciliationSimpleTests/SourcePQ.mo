within NewDataReconciliationSimpleTests;
model SourcePQ "Water/steam source with fixed pressure and mass flow rate"
  parameter Modelica.SIunits.AbsolutePressure P0=300000
    "Fluid pressure (active if IPressure connector is not connected)" annotation(__OpenModelica_BoundaryCondition = true);
  parameter Modelica.SIunits.MassFlowRate Q0=100
    "Mass flow (active if IMassFlow connector is not connected)" annotation(__OpenModelica_BoundaryCondition = true);
  parameter Modelica.SIunits.SpecificEnthalpy h0=100000
    "Fluid specific enthalpy (active if IEnthalpy connector is not connected)" annotation(__OpenModelica_BoundaryCondition = true);

public
  Modelica.SIunits.AbsolutePressure P "Fluid pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  Modelica.SIunits.SpecificEnthalpy h "Fluid specific enthalpy";

public
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IMassFlow
    annotation (Placement(transformation(
        origin={0,50},
        extent={{-10,-10},{10,10}},
        rotation=270)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}}, rotation=
            0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy
    annotation (Placement(transformation(
        origin={0,-50},
        extent={{10,-10},{-10,10}},
        rotation=270)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet C                annotation (Placement(transformation(
          extent={{90,-10},{110,10}}, rotation=0)));
equation

  C.P = P;
  C.Q = Q;
  C.h_vol = h;

  /* Mass flow */
  if (cardinality(IMassFlow) == 0) then
    IMassFlow.signal = Q0;
  end if;

  Q = IMassFlow.signal;

  /* Pressure */
  if (cardinality(IPressure) == 0) then
    IPressure.signal = P0;
  end if;

  P = IPressure.signal;

  /* Specific enthalpy */
  if (cardinality(ISpecificEnthalpy) == 0) then
    ISpecificEnthalpy.signal = h0;
  end if;

  h = ISpecificEnthalpy.signal;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{40,0},{90,0},{72,10}}),
        Line(points={{90,0},{72,-10}}),
        Text(extent={{-58,30},{-40,10}}, textString=
                                             "P"),
        Text(extent={{-28,60},{-10,40}}, textString=
                                             "Q"),
        Text(extent={{-30,-40},{-12,-60}}, textString=
                                             "h"),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-22,20},{20,-24}},
          lineColor={0,0,255},
          textString=
               "P Q")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{40,0},{90,0},{72,10}}),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Line(points={{90,0},{72,-10}}),
        Text(extent={{-30,60},{-10,40}}, textString=
                                             "Q"),
        Text(extent={{-60,30},{-40,10}}, textString=
                                             "P"),
        Text(extent={{-32,-40},{-12,-60}}, textString=
                                             "h"),
        Text(
          extent={{-22,20},{20,-24}},
          lineColor={0,0,255},
          textString=
               "P Q")}),
    Window(
      x=0.23,
      y=0.15,
      width=0.81,
      height=0.71),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<p><u><b>Authors</b></u></p>
<ul>
<li>Baligh El Hefni</li>
<li>Daniel Bouskela </li>
</ul>
</html>"));
end SourcePQ;
