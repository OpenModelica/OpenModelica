within ThermoSysPro.HeatNetworksCooling;
model AbsorberWaterLiBr "Absorption of H2O into a H2O LiBr solution, and exchange with cold water"
  parameter Real DPf=0 "Pressure losses in the cold fluid a a percent of the pressure at the inlet";
  Modelica.SIunits.Power W(start=1000000.0) "Power exchanged";
  Real DPc(start=10) "Pressure losses in the hot fluid a a percent of the pressure at the inlet";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-74,80},{-64,90},{64,90},{74,80},{74,-80},{64,-90},{-64,-90},{-74,-80},{-74,80}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Polygon(points={{74,-10},{74,-80},{64,-90},{-64,-90},{-74,-80},{-74,-10},{-26,-10},{-4,66},{64,66},{64,54},{8,54},{26,-10},{74,-10}}, lineColor={0,0,0}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(points={{-64,60},{0,60},{0,-16},{0,-62},{-64,-62}}, color={0,0,255}, thickness=0.5),Line(points={{-14,78},{0,68},{14,78}}, color={0,0,255}, thickness=0.5)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-74,80},{-64,90},{64,90},{74,80},{74,-80},{64,-90},{-64,-90},{-74,-80},{-74,80}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Polygon(points={{74,-10},{74,-80},{64,-90},{-64,-90},{-74,-80},{-74,-10},{-26,-10},{-4,66},{64,66},{64,54},{8,54},{26,-10},{74,-10}}, lineColor={0,0,0}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(points={{-64,60},{0,60},{0,-16},{0,-62},{-64,-62}}, color={0,0,255}, thickness=0.5),Line(points={{-14,78},{0,68},{14,78}}, color={0,0,255}, thickness=0.5)}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Benoît Bride</li>
</ul>
</html>
"));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ef "Cold fluid inlet" annotation(Placement(transformation(x=-74.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-74.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Sf "Cold fluid outlet" annotation(Placement(transformation(x=-72.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-72.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionInlet Ec "Water solution inlet" annotation(Placement(transformation(x=74.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=74.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionOutlet Sc "Water solution outlet" annotation(Placement(transformation(x=0.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profe annotation(Placement(transformation(x=-90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profs annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph provap annotation(Placement(transformation(x=90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Evap annotation(Placement(transformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Sf.Q=Ef.Q;
  0=if Ef.Q > 0 then Ef.h - Ef.h_vol else Sf.h - Sf.h_vol;
  0=Evap.h - Evap.h_vol;
  Sc.Q=Ec.Q + Evap.Q;
  Sf.P=if Ef.Q > 0 then Ef.P - DPf*Ef.P/100 else Ef.P + DPf*Ec.P/100;
  Sc.P=Ec.P - DPc*Ec.P/100;
  Evap.P=Sc.P;
  Sf.h=Ef.h + W/Ef.Q;
  W=Ec.Q*ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Ec.T, Ec.Xh2o) - Sc.Q*ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Sc.T, Ec.Xh2o) + Evap.Q*Evap.h;
  Sc.Xh2o=ThermoSysPro.Properties.WaterSolution.MassFraction_eq_PT(Sc.P, Sc.T);
  Sc.Xh2o=(Evap.Q + Ec.Xh2o*Ec.Q)/Sc.Q;
  profe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ef.P, Ef.h, 0);
  profs=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Sf.P, Sf.h, 0);
  provap=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Evap.P, Evap.h, 0);
end AbsorberWaterLiBr;
