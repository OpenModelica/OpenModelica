within ThermoSysPro.HeatNetworksCooling;
model DesorberWaterLiBr "Water LiBr solution desorber with water heating"
  parameter Real Eff=0.65 "Thermal exchange efficiency (=W/Wmax)";
  parameter ThermoSysPro.Units.DifferentialPressure DPc=0 "Pressure losses in the hot fluid a a percent of the pressure at the inlet";
  parameter Real Pth=0.15 "Thermal losses fraction (=losses/W)";
  Modelica.SIunits.Power W(start=1000000.0) "Power exchnaged with the solution";
  Modelica.SIunits.Power Wpth(start=1000000.0) "Thermal losses power";
  Modelica.SIunits.Power Wtot(start=1000000.0) "Hot water total power";
  Modelica.SIunits.Power Wmaxf(start=1000000.0) "Maximum power acceptable by the solution";
  Modelica.SIunits.Power Wmaxc(start=1000000.0) "Maximum power releasable by the hot water";
  ThermoSysPro.Units.AbsoluteTemperature Tsatc(start=400) "Hot water saturation temperature at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hminc(start=100000.0) "Minimum specific enthalpy reachable by the hot water";
  Real Xmin "Minimum mass fraction reachable by the solution";
  Modelica.SIunits.MassFlowRate Qs_min(start=100) "Minimum solution mass flow rate at the outlet";
  Modelica.SIunits.MassFlowRate Qv_max(start=100) "Maximum steam mass flow rate at the outlet";
  Modelica.SIunits.Power Wmax(start=1000000.0) "Maximum power exchangeable";
  ThermoSysPro.Units.DifferentialTemperature DTm(start=40) "Differences of the average temperatures between the hot and cold sides";
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ec annotation(Placement(transformation(x=-74.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-74.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Svap annotation(Placement(transformation(x=0.0, y=90.5, scale=0.1, aspectRatio=1.05, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=90.5, scale=0.1, aspectRatio=1.05, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Sc annotation(Placement(transformation(x=-72.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-72.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionInlet Ef annotation(Placement(transformation(x=74.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=74.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionOutlet Sf annotation(Placement(transformation(x=2.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=2.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proce annotation(Placement(transformation(x=-90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph procs annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph provap annotation(Placement(transformation(x=90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Sc.Q=Ec.Q;
  Ef.P=Sf.P;
  Svap.P=Sf.P;
  0=if Ec.Q > 0 then Ec.h - Ec.h_vol else Sc.h - Sc.h_vol;
  Tsatc=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(Sc.P);
  if Tsatc > Ef.T then
    Hminc=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(Sc.P, Ef.T, 0);
  elseif Tsatc < Ef.T then
    Hminc=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(Sc.P, Ef.T, 0);
  else
    Hminc=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(Sc.P, Ef.T, 1);
  end if;
  Wmaxc=Ec.Q*(Ec.h - Hminc);
  Xmin=ThermoSysPro.Properties.WaterSolution.MassFraction_eq_PT(Sf.P, proce.T);
  Qs_min=Ef.Q*(1 - Ef.Xh2o)/(1 - Xmin);
  Qv_max=Ef.Q*(1 - (1 - Ef.Xh2o)/(1 - Xmin));
  Wmaxf=Ef.Q*ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Ef.T, Ef.Xh2o) - Qs_min*ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(proce.T, Xmin) + Qv_max*Svap.h;
  Wmax=min(Wmaxf, Wmaxc);
  W=Eff*Wmax;
  Wpth=W*Pth;
  Wtot=W + Wpth;
  proce=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ec.P, Ec.h, 0);
  procs=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Sc.P, Sc.h, 0);
  provap=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Svap.P, Svap.h, 0);
  Sf.Q=Ef.Q*(1 - Ef.Xh2o)/(1 - Sf.Xh2o);
  Svap.Q=Ef.Q*(1 - (1 - Ef.Xh2o)/(1 - Sf.Xh2o));
  Sc.P=if Ec.Q > 0 then Ec.P - DPc*Ec.P/100 else Ec.P + DPc*Ec.P/100;
  Svap.h=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(Svap.P, Sf.T, 2);
  Sf.Xh2o=ThermoSysPro.Properties.WaterSolution.MassFraction_eq_PT(Sf.P, Sf.T);
  Sc.h=Ec.h - Wtot/Ec.Q;
  W=Ef.Q*ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Ef.T, Ef.Xh2o) - Sf.Q*ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Sf.T, Sf.Xh2o) + Svap.Q*Svap.h;
  DTm=proce.T - procs.T - (Sf.T - Ef.T);
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-74,80},{-64,90},{64,90},{74,80},{74,-80},{64,-90},{-64,-90},{-74,-80},{-74,80}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Polygon(points={{74,-10},{74,-80},{64,-90},{-64,-90},{-74,-80},{-74,-10},{-26,-10},{-4,66},{64,66},{64,54},{8,54},{26,-10},{74,-10}}, lineColor={0,0,0}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(points={{-64,60},{0,60},{0,-16},{0,-62},{-64,-62}}, color={0,0,255}, thickness=0.5),Line(points={{-12,68},{0,78},{14,68}}, color={0,0,255}, thickness=0.5)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-74,80},{-64,90},{64,90},{74,80},{74,-80},{64,-90},{-64,-90},{-74,-80},{-74,80}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Polygon(points={{74,-10},{74,-80},{64,-90},{-64,-90},{-74,-80},{-74,-10},{-26,-10},{-4,66},{64,66},{64,54},{8,54},{26,-10},{74,-10}}, lineColor={0,0,0}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(points={{-64,60},{0,60},{0,-16},{0,-62},{-64,-62}}, color={0,0,255}, thickness=0.5),Line(points={{-12,68},{0,78},{14,68}}, color={0,0,255}, thickness=0.5)}), Documentation(info="<html>
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
end DesorberWaterLiBr;
