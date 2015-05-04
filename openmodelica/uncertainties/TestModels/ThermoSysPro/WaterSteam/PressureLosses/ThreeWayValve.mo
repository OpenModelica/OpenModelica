within ThermoSysPro.WaterSteam.PressureLosses;
model ThreeWayValve "Three way valve"
  parameter ThermoSysPro.Units.Cv Cvmax1=8005.42 "Valve 1 max CV";
  parameter ThermoSysPro.Units.Cv Cvmax2=8005.42 "Valve 2 max CV";
  parameter Real caract1[:,2]=[0,0;1,Cvmax1] "Valve 1 - Position vs. Cv characteristics (active if mode_caract1=true)";
  parameter Real caract2[:,2]=[0,0;1,Cvmax2] "Valve 2 - Position vs. Cv characteristics (active if mode_caract2=true)";
  parameter Integer mode_caract1=0 "Valve 1 - 0:linear characteristics - 1:characteristics is given by caract1[]";
  parameter Integer mode_caract2=0 "Valve 2 - 0:linear characteristics - 1:characteristics is given by caract2[]";
  parameter Modelica.SIunits.Volume V=1 "Three way valve volume";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  annotation(structurallyIncomplete, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-46,-30},{-12,-52}}, textString="Valve 1"),Text(lineColor={0,0,255}, extent={{36,-6},{70,-28}}, textString="Valve 2")}));
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,0},{-100,-80},{100,0},{100,-80},{-100,0}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Polygon(lineColor={0,0,255}, points={{-20,-100},{0,-40},{20,-100},{-20,-100}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Polygon(lineColor={0,0,255}, points={{40,40},{-40,40},{-40,56},{-38,74},{-32,84},{-20,94},{0,100},{20,94},{32,84},{38,72},{40,54},{40,40}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{0,-40},{40,40},{-40,40},{0,-40}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2003</b></p>
</HTML>
<html>
<p><b>Version 1.4</b></p>
</HTML>
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{34,-4},{68,-26}}, textString="Valve 2")}));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Ouv annotation(Placement(transformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  Connectors.FluidInletI C1 annotation(Placement(transformation(x=-100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutletI C2 annotation(Placement(transformation(x=100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.ControlValve Valve1(Cvmax=Cvmax1, caract=caract1, mode_caract=mode_caract1, p_rho=p_rho, mode=mode, continuous_flow_reversal=continuous_flow_reversal, fluid=fluid) annotation(Placement(transformation(x=6.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=true, rotation=-90.0)));
  Connectors.FluidOutletI C3 annotation(Placement(transformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.ControlValve Valve2(Cvmax=Cvmax2, caract=caract2, mode_caract=mode_caract2, p_rho=p_rho, mode=mode, continuous_flow_reversal=continuous_flow_reversal, fluid=fluid) annotation(Placement(transformation(x=50.0, y=6.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Constante1 annotation(Placement(transformation(x=-70.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Math.Add Add1(k2=-1) annotation(Placement(transformation(x=-30.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.VolumeA VolumeA1(V=V, p_rho=p_rho, mode=mode) annotation(Placement(transformation(x=0.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss PerteDP1(K=0, continuous_flow_reversal=continuous_flow_reversal, fluid=fluid) annotation(Placement(transformation(x=-50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(Ouv,Valve2.Ouv) annotation(Line(points={{0,110},{0,60},{50,60},{50,17}}));
  connect(Constante1.y,Add1.u1) annotation(Line(points={{-59,70},{-50,70},{-50,56},{-41,56}}, color={0,0,255}));
  connect(Ouv,Add1.u2) annotation(Line(points={{0,110},{0,90},{-90,90},{-90,44},{-41,44}}));
  connect(Add1.y,Valve1.Ouv) annotation(Line(points={{-19,50},{20,50},{20,-40},{17,-40}}, color={0,0,255}));
  connect(VolumeA1.Cs1,Valve2.C1) annotation(Line(points={{10,0},{40,0}}, color={0,0,255}));
  connect(VolumeA1.Cs2,Valve1.C1) annotation(Line(points={{0,-10},{0,-30},{8.88178e-16,-30}}, color={0,0,255}));
  connect(Valve1.C2,C3) annotation(Line(points={{-8.88178e-16,-50},{-8.88178e-16,-78},{0,-78},{0,-100}}, color={0,0,255}));
  connect(PerteDP1.C2,VolumeA1.Ce1) annotation(Line(points={{-40,0},{-10,0}}, color={0,0,255}));
  connect(Valve2.C2,C2) annotation(Line(points={{60,0},{80,0},{80,-40},{100,-40}}, color={0,0,255}));
  connect(PerteDP1.C1,C1) annotation(Line(points={{-60,0},{-80,0},{-80,-40},{-100,-40}}, color={0,0,255}));
end ThreeWayValve;
