within ThermoSysPro.WaterSteam.Junctions;
model Mixer8 "Mixer with eight inlets"
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-40,80},{40,0}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Ellipse(lineColor={0,0,255}, extent={{-40,2},{40,-80}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(color={0,0,255}, points={{40,0},{92,0}}),Line(color={0,0,255}, points={{-92,-40},{-40,-40}}),Line(points={{-30,90},{-30,66}}, color={0,0,255}),Line(points={{30,92},{30,66}}, color={0,0,255}),Line(points={{-30,-66},{-30,-90}}, color={0,0,255}),Line(points={{30,-66},{30,-90}}, color={0,0,255}),Line(color={0,0,255}, points={{-92,40},{-40,40}}),Line(points={{-38,-52},{-92,-90}}, color={0,0,255}),Line(points={{-38,54},{-92,90}}, color={0,0,255})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-40,80},{40,0}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Ellipse(lineColor={0,0,255}, extent={{-40,0},{40,-80}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(points={{-30,90},{-30,66}}, color={0,0,255}),Line(points={{-30,-66},{-30,-90}}, color={0,0,255}),Line(points={{30,92},{30,66}}, color={0,0,255}),Line(points={{30,-66},{30,-90}}, color={0,0,255}),Line(color={0,0,255}, points={{-92,40},{-40,40}}),Line(color={0,0,255}, points={{-92,-40},{-40,-40}}),Line(color={0,0,255}, points={{40,0},{92,0}}),Line(points={{-38,-52},{-92,-90}}, color={0,0,255}),Line(points={{-38,54},{-92,90}}, color={0,0,255})}), Documentation(info="<html>
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
  Connectors.FluidInlet Ce5 annotation(Placement(transformation(x=-100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce6 annotation(Placement(transformation(x=-102.0, y=-99.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-102.0, y=-99.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce7 annotation(Placement(transformation(x=-30.0, y=-99.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-30.0, y=-99.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce3 annotation(Placement(transformation(x=-102.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-102.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce2 annotation(Placement(transformation(x=-30.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-30.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce1 annotation(Placement(transformation(x=30.0, y=102.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=30.0, y=102.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce8 annotation(Placement(transformation(x=30.0, y=-99.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=30.0, y=-99.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce4 annotation(Placement(transformation(x=-102.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-102.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-70.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(Ce1) == 0 then
    Ce1.Q=0;
    Ce1.h=100000.0;
    Ce1.b=true;
  end if;
  if cardinality(Ce2) == 0 then
    Ce2.Q=0;
    Ce2.h=100000.0;
    Ce2.b=true;
  end if;
  if cardinality(Ce3) == 0 then
    Ce3.Q=0;
    Ce3.h=100000.0;
    Ce3.b=true;
  end if;
  if cardinality(Ce4) == 0 then
    Ce4.Q=0;
    Ce4.h=100000.0;
    Ce4.b=true;
  end if;
  if cardinality(Ce5) == 0 then
    Ce5.Q=0;
    Ce5.h=100000.0;
    Ce5.b=true;
  end if;
  if cardinality(Ce6) == 0 then
    Ce6.Q=0;
    Ce6.h=100000.0;
    Ce6.b=true;
  end if;
  if cardinality(Ce7) == 0 then
    Ce7.Q=0;
    Ce7.h=100000.0;
    Ce7.b=true;
  end if;
  if cardinality(Ce8) == 0 then
    Ce8.Q=0;
    Ce8.h=100000.0;
    Ce8.b=true;
  end if;
  if cardinality(Cs) == 0 then
    Cs.Q=0;
    Cs.h=100000.0;
    Cs.a=true;
  end if;
  P=Ce1.P;
  P=Ce2.P;
  P=Ce3.P;
  P=Ce4.P;
  P=Ce5.P;
  P=Ce6.P;
  P=Ce7.P;
  P=Ce8.P;
  P=Cs.P;
  Ce1.h_vol=h;
  Ce2.h_vol=h;
  Ce3.h_vol=h;
  Ce4.h_vol=h;
  Ce5.h_vol=h;
  Ce6.h_vol=h;
  Ce7.h_vol=h;
  Ce8.h_vol=h;
  Cs.h_vol=h;
  0=Ce1.Q + Ce2.Q + Ce3.Q + Ce4.Q + Ce5.Q + Ce6.Q + Ce7.Q + Ce8.Q - Cs.Q;
  0=Ce1.Q*Ce1.h + Ce2.Q*Ce2.h + Ce3.Q*Ce3.h + Ce4.Q*Ce4.h + Ce5.Q*Ce5.h + Ce6.Q*Ce6.h + Ce7.Q*Ce7.h + Ce8.Q*Ce8.h - Cs.Q*Cs.h;
  pro=ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);
  T=pro.T;
end Mixer8;
