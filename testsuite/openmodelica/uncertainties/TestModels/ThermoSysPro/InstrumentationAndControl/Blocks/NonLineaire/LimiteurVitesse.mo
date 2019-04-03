within ThermoSysPro.InstrumentationAndControl.Blocks.NonLineaire;
block LimiteurVitesse
  parameter Real dmax=1 "Valeur maximale de la dérivée de la sortie";
  parameter Real dmin=-1 "Valeur minimale de la dérivée de la sortie";
  parameter Real Ti(min=Modelica.Constants.small)=0.01 "Constante de temps (s)";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(points={{78,60},{40,60},{-40,-60},{-80,-60}}, color={0,0,0}),Line(points={{-86,0},{88,0}}, color={160,160,160}),Polygon(points={{96,0},{86,-5},{86,5},{96,0}}, fillPattern=FillPattern.Solid, lineColor={160,160,160}, fillColor={160,160,160}),Polygon(points={{0,84},{-5,74},{5,74},{0,84}}, fillPattern=FillPattern.Solid, lineColor={160,160,160}, fillColor={160,160,160}),Line(points={{0,-80},{0,74}}, color={160,160,160}),Text(lineColor={0,0,255}, extent={{-94,-8},{-32,-30}}, textString="%dmin", fillColor={160,160,160}),Text(lineColor={0,0,255}, extent={{30,34},{92,12}}, textString="%dmax", fillColor={160,160,160})}), Diagram, Documentation(info="<html>
<p><b>Version 1.7</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Continu.Derivee Derivee1(Ti=Ti) annotation(Placement(transformation(x=-50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Continu.Integrateur Integrateur1 annotation(Placement(transformation(x=50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Limiteur Limiteur1(maxval=dmax, minval=dmin) annotation(Placement(transformation(x=0.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Sources.Horloge Horloge1 annotation(Placement(transformation(x=-70.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Sources.Constante Constante1(k=0) annotation(Placement(transformation(x=-70.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Math.Supeg Supeg1 annotation(Placement(transformation(x=-30.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Logique.Edge Edge1 annotation(Placement(transformation(x=10.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(u,Derivee1.u) annotation(Line(points={{-110,0},{-61,0}}));
  connect(Integrateur1.y,y) annotation(Line(points={{61,0},{110,0}}, color={0,0,255}));
  connect(Derivee1.y,Limiteur1.u) annotation(Line(points={{-39,0},{-11,0}}, color={0,0,255}));
  connect(Limiteur1.y,Integrateur1.u) annotation(Line(points={{11,0},{39,0}}, color={0,0,255}));
  connect(u,Integrateur1.ureset) annotation(Line(points={{-110,0},{-80,0},{-80,-20},{28,-20},{28,-8},{39,-8}}));
  connect(Horloge1.y,Supeg1.u1) annotation(Line(points={{-59,-50},{-50,-50},{-50,-64},{-41,-64}}, color={0,0,255}));
  connect(Constante1.y,Supeg1.u2) annotation(Line(points={{-59,-90},{-50,-90},{-50,-76},{-41,-76}}, color={0,0,255}));
  connect(Supeg1.yL,Edge1.uL) annotation(Line(points={{-19,-70},{-1,-70}}));
  connect(Edge1.yL,Integrateur1.reset) annotation(Line(points={{21,-70},{50,-70},{50,-11}}));
end LimiteurVitesse;
