within ThermoSysPro.WaterSteam.LoopBreakers;
model LoopingPQ
  parameter ThermoSysPro.Units.AbsolutePressure P=100000.0 "Pression imposée en sortie";
  parameter Modelica.SIunits.MassFlowRate Q=1.0 "Débit imposé";
  annotation(Diagram, Icon(coordinateSystem(scale=0.01, extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,30},{100,-30}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,0,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Bruno Péchiné</li>
</ul>
</html>
"), Diagram(coordinateSystem(scale=0.01, extent={{-100,-100},{100,100}})), Icon(coordinateSystem(scale=0.01, extent={{-100,-100},{100,100}})));
  ThermoSysPro.WaterSteam.Connectors.FluidInletI C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.LoopBreakers.LoopBreakerQ qLoopBreaker annotation(Placement(transformation(x=-70.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.InvSingularPressureLoss pressureCloserWaterSteam annotation(Placement(transformation(x=30.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.RefP pressureReference annotation(Placement(transformation(x=70.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.RefQ massFlowSetWaterSteam annotation(Placement(transformation(x=-30.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Debit(k=Q) annotation(Placement(transformation(x=-70.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Pression(k=P) annotation(Placement(transformation(x=30.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(Debit.y,massFlowSetWaterSteam.IMassFlow) annotation(Line(points={{-59,40},{-30,40},{-30,11}}));
  connect(Pression.y,pressureReference.IPressure) annotation(Line(points={{41,40},{70,40},{70,11}}));
  connect(C1,qLoopBreaker.C1) annotation(Line(points={{-100,0},{-80,0}}));
  connect(qLoopBreaker.C2,massFlowSetWaterSteam.C1) annotation(Line(points={{-60,0},{-40,0}}, color={0,0,255}));
  connect(massFlowSetWaterSteam.C2,pressureCloserWaterSteam.C1) annotation(Line(points={{-20,0},{20,0}}, color={0,0,255}));
  connect(pressureCloserWaterSteam.C2,pressureReference.C1) annotation(Line(points={{40,0},{60,0}}, color={0,0,255}));
  connect(pressureReference.C2,C2) annotation(Line(points={{80,0},{100,0}}, color={0,0,255}));
end LoopingPQ;
