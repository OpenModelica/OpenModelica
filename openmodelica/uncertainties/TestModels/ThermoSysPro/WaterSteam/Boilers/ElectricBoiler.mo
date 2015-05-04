within ThermoSysPro.WaterSteam.Boilers;
model ElectricBoiler "Electric boiler"
  parameter Modelica.SIunits.Power W=1000000.0 "Electrical power";
  parameter Real eta=100 "Boiler efficiency (percent)";
  parameter ThermoSysPro.Units.DifferentialPressure deltaP=0 "Pressure loss";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsoluteTemperature Te(start=300) "Inlet temperature";
  ThermoSysPro.Units.AbsoluteTemperature Ts(start=500) "Outlet temperature";
  Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow";
  ThermoSysPro.Units.SpecificEnthalpy deltaH "Specific enthalpy variation between the outlet and the inlet";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,80},{100,-80}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(points={{22,54},{-30,2},{30,2},{-24,-52},{-28,-56}}, color={255,0,0}, thickness=0.5),Polygon(points={{-26,-50},{-22,-54},{-28,-56},{-26,-50}}, lineColor={255,0,0}, lineThickness=0.5, fillColor={255,0,0}, fillPattern=FillPattern.Solid)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,80},{100,-80}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Polygon(points={{-26,-48},{-20,-54},{-28,-56},{-26,-48}}, fillPattern=FillPattern.Solid, lineColor={255,0,0}, lineThickness=1.0, fillColor={255,0,0}),Line(points={{22,54},{-30,2},{30,2},{-24,-52},{-28,-56}}, color={255,0,0}, thickness=1.0)}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b> </p>
<p><b>ThermoSysPro Version 2.0</b> </p>
</html>", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
  Connectors.FluidInlet Ce annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs annotation(Placement(transformation(x=100.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proe annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pros annotation(Placement(transformation(x=90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Ce.P - Cs.P=deltaP;
  Ce.Q=Cs.Q;
  Q=Ce.Q;
  Cs.h - Ce.h=deltaH;
  0=if Q > 0 then Ce.h - Ce.h_vol else Cs.h - Cs.h_vol;
  W=Q*deltaH/eta/100;
  proe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ce.P, Ce.h, mode);
  pros=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Cs.P, Cs.h, mode);
  Te=proe.T;
  Ts=pros.T;
end ElectricBoiler;
