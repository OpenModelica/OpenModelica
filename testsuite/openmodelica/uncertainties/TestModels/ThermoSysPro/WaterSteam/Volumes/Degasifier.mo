within ThermoSysPro.WaterSteam.Volumes;
model Degasifier
  annotation(Diagram, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-82,12},{82,-80}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,191,255}),Ellipse(extent={{-48,98},{48,20}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={127,191,255}),Rectangle(extent={{20,26},{24,12}}, fillPattern=FillPattern.Solid, lineColor={255,255,255}, fillColor={127,191,255}),Rectangle(extent={{-24,26},{-20,12}}, fillPattern=FillPattern.Solid, lineColor={255,255,255}, fillColor={127,191,255}),Line(points={{-90,80},{-40,80},{-40,80},{-40,80}}, color={0,0,0}),Line(points={{-92,40},{-38,40}}, color={0,0,0}),Line(points={{90,80},{40,80}}, color={0,0,0}),Rectangle(extent={{-82,12},{82,-34}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255})}), Documentation(info="<html>
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
</ul>
</html>
"));
  ThermoSysPro.WaterSteam.Volumes.DegasifierVolume dega1(P0=1128300.0, P(start=1128300.0), steady_state=true, h(start=700000.0), Cs(h_vol(start=700000.0))) annotation(Placement(transformation(x=0.0, y=40.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe DPEau(D=1, continuous_flow_reversal=true, Q(start=1000), Pm(start=1000000.0), lambda=0.01, L=1) annotation(Placement(transformation(x=-50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInletI sourceEau annotation(Placement(transformation(x=-100.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe DPvapeur(D=1, continuous_flow_reversal=true, Q(start=127.81, fixed=false), h(start=2562300.0, fixed=false), Pm(start=1100000.0, fixed=false), lambda=0.01, L=1) annotation(Placement(transformation(x=-50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInletI sourceVapeur annotation(Placement(transformation(x=-100.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.DynamicDrum ballon(Vertical=false, R=4.234, L=33, Cevap=0.09, P0=1155000.0, Tp(start=300), steady_state=true, hv(start=700000.0), P(start=1012830.0), zl(start=8)) annotation(Placement(transformation(x=0.0, y=-50.0, scale=0.3, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe TubeVap(L=0.1, D=1, continuous_flow_reversal=true, Q(fixed=false, start=0), lambda=0.01) annotation(Placement(transformation(x=30.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  Connectors.FluidOutletI puitsEauFond annotation(Placement(transformation(x=-100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false), iconTransformation(x=-100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe DPvapeur1(D=1, continuous_flow_reversal=true, Q(start=1200), h(start=700000), Pm(start=1100000.0), lambda=0.01, L=1) annotation(Placement(transformation(x=-70.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  Connectors.FluidInletI sourceEauFond annotation(Placement(transformation(x=100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInletI sourceSup annotation(Placement(transformation(x=100.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe DPEau1(D=1, continuous_flow_reversal=true, Pm(start=1000000.0), lambda=0.01, L=1, Q(start=1)) annotation(Placement(transformation(x=50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe DPEau2(D=1, continuous_flow_reversal=true, Pm(start=1000000.0), lambda=0.01, L=1, Q(start=1)) annotation(Placement(transformation(x=70.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal yLevel annotation(Placement(transformation(x=113.0, y=0.5, scale=0.13, aspectRatio=0.730769230769231, flipHorizontal=false, flipVertical=false), iconTransformation(x=113.0, y=0.5, scale=0.13, aspectRatio=0.730769230769231, flipHorizontal=false, flipVertical=false)));
equation
  connect(DPEau.C2,dega1.Ce2) annotation(Line(points={{-40,70},{-8,70},{-8,52}}, color={0,0,255}));
  connect(DPvapeur.C2,dega1.Ce1) annotation(Line(points={{-40,30},{-32.6,30},{-32.6,40},{-20,40}}, color={0,0,255}));
  connect(TubeVap.C1,ballon.Cv) annotation(Line(points={{30,-8},{30,-20}}));
  connect(DPvapeur1.C1,ballon.Cd) annotation(Line(points={{-60,-70},{-40,-70},{-40,-80},{-30,-80}}));
  connect(sourceEau,DPEau.C1) annotation(Line(points={{-100,80},{-80,80},{-80,70},{-60,70}}));
  connect(DPvapeur1.C2,puitsEauFond) annotation(Line(points={{-80,-70},{-86,-70},{-86,-80},{-100,-80}}, color={0,0,255}));
  connect(sourceVapeur,DPvapeur.C1) annotation(Line(points={{-100,40},{-80,40},{-80,30},{-60,30}}));
  connect(ballon.Cm,DPEau2.C2) annotation(Line(points={{30,-80},{40,-80},{40,-70},{60,-70}}));
  connect(DPEau2.C1,sourceEauFond) annotation(Line(points={{80,-70},{86,-70},{86,-80},{100,-80}}));
  connect(dega1.Ce3,DPEau1.C2) annotation(Line(points={{8,52},{8,70},{40,70}}));
  connect(DPEau1.C1,sourceSup) annotation(Line(points={{60,70},{80,70},{80,80},{100,80}}));
  connect(dega1.Cs,ballon.Ce1) annotation(Line(points={{-8,28},{-8,20},{-30,20},{-30,-20}}, color={0,0,255}));
  connect(dega1.Ce4,TubeVap.C2) annotation(Line(points={{8,28.4},{8,20},{30,20},{30,12}}, color={0,0,255}));
  connect(ballon.yLevel,yLevel) annotation(Line(points={{33,-50},{80,-50},{80,0.5},{113,0.5}}));
end Degasifier;
