within ModelicaDataReconciliationSimpleTests.Components.Junctions;
model Splitter44 "Splitter with four outlets"
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5 - 3: Simple";
  parameter Modelica.Units.SI.SpecificHeatCapacity cp=4200 "Specific heat capacity";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real alpha1 "Extraction coefficient for outlet 1 (<=1)";
  Real alpha2 "Extraction coefficient for outlet 2 (<=1)";
  Modelica.Units.SI.Pressure P(start=10e5) "Fluid pressure";
  Modelica.Units.SI.SpecificEnthalpy h(start=10e5) "Fluid specific enthalpy";
  Modelica.Units.SI.Temperature T "Fluid temperature";
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce annotation (Placement(transformation(extent={{-110,-8},{-90,12}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs3 annotation (Placement(transformation(extent={{90,30},{110,50}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs4 annotation (Placement(transformation(extent={{90,-50},{110,-30}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs1 annotation (Placement(transformation(extent={{30,90},{50,110}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs2 annotation (Placement(transformation(extent={{30,-110},{50,-90}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Ialpha1 "Extraction coefficient for outlet 1 (<=1)" annotation (Placement(transformation(extent={{0,70},{20,90}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Ialpha2 "Extraction coefficient for outlet 2 (<=1)" annotation (Placement(transformation(extent={{0,-90},{20,-70}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation (Placement(transformation(extent={{60,70},{80,90}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Oalpha2 annotation (Placement(transformation(extent={{60,-90},{80,-70}}, rotation=0)));
equation
  if cardinality(Ialpha1) == 0 then
    Ialpha1.signal = 1;
  end if;
  if cardinality(Ialpha2) == 0 then
    Ialpha2.signal = 1;
  end if;
  /* Fluid pressure */
  P = Ce.P;
  P = Cs1.P;
  P = Cs2.P;
  P = Cs3.P;
  P = Cs4.P;
  /* Fluid specific enthalpy (singular if all flows = 0) */
  Ce.h_vol = h;
  Cs1.h_vol = h;
  Cs2.h_vol = h;
  Cs3.h_vol = h;
  Cs4.h_vol = h;
  /* Mass balance equation */
  0 = Ce.Q - Cs1.Q - Cs2.Q - Cs3.Q - Cs4.Q;
  /* Energy balance equation */
  0 = Ce.Q*Ce.h - Cs1.Q*Cs1.h - Cs2.Q*Cs2.h - Cs3.Q*Cs3.h - Cs4.Q*Cs4.h;
  /* Mass flows at outlets 1 and 2 */
  if cardinality(Ialpha1) <> 0 then
    Cs1.Q = Ialpha1.signal*Ce.Q;
  end if;
  if cardinality(Ialpha2) <> 0 then
    Cs2.Q = Ialpha2.signal*Ce.Q;
  end if;
  alpha1 = 1;
  //Cs1.Q / Ce.Q;
  Oalpha1.signal = alpha1;
  alpha2 = 1;
  //Cs2.Q / Ce.Q;
  Oalpha2.signal = alpha2;
  /* Fluid thermodynamic properties */
  if fluid == 3 then
    h = cp*(T - 273.16);
  else
    T = ThermoSysPro.Properties.Fluid.Temperature_Ph(
      P,
      h,
      fluid,
      mode,
      0,
      0,
      0,
      0);
  end if;
  annotation (
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={Polygon(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          points={{-100,20},{20,20},{20,100},{60,100},{60,60},{100,60},{100,20},{60,20},{60,-20},{100,-20},{100,-60},{60,-60},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20}}),Text(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{18,92},{64,52}},
          textString="1"),Text(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{50,58},{96,18}},
          textString="3"),Text(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{50,-20},{96,-60}},
          textString="4"),Text(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{18,-54},{64,-94}},
          textString="2")}),
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={Polygon(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          points={{-100,20},{20,20},{20,100},{60,100},{60,60},{100,60},{100,20},{60,20},{60,-20},{100,-20},{100,-60},{60,-60},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20}}),Text(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{18,92},{64,52}},
          textString="1"),Text(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{50,58},{96,18}},
          textString="3"),Text(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{50,-20},{96,-60}},
          textString="4"),Text(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          extent={{18,-54},{64,-94}},
          textString="2")}),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
    ", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
    "));
end Splitter44;
