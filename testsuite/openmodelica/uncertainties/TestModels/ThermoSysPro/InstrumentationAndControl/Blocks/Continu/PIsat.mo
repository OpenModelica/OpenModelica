within ThermoSysPro.InstrumentationAndControl.Blocks.Continu;
block PIsat
  parameter Real k=1 "Gain";
  parameter Real Ti=1 "Constante de temps (s)";
  parameter Real maxval=1 "Valeur maximale de la sortie";
  parameter Real minval=0 "Valeur minimale de la sortie";
  parameter Real ureset0=0 "Valeur de la sortie sur reset (si ureset non connecté)";
  parameter Boolean permanent=false "Calcul du permanent";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Line(points={{-74,64},{-74,-80}}, color={192,192,192}),Line(points={{-74,-80},{70,-80}}, color={192,192,192}),Polygon(points={{92,-80},{70,-72},{70,-88},{92,-80}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-74,-68},{-74,2},{30,42}}, thickness=0.25),Text(lineColor={0,0,255}, extent={{-32,70},{0,42}}, textString="PI", fillColor={192,192,192}),Line(color={0,0,255}, points={{30,42},{86,42}}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Text(lineColor={0,0,255}, extent={{-38,10},{52,-30}}, textString="K=%k", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-36,-34},{54,-74}}, textString="Ti=%Ti", fillColor={0,0,0}),Polygon(points={{-74,86},{-82,64},{-66,64},{-74,86}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Continuous library</b></p>
</HTML>
"), Diagram);
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  NonLineaire.Limiteur Limiteur1(maxval=maxval, minval=minval) annotation(Placement(transformation(x=80.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Math.Add Add2(k1=-1, k2=+1) annotation(Placement(transformation(x=30.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  Math.Gain Gain3(Gain=1/k) annotation(Placement(transformation(x=-10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ureset annotation(Placement(transformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical reset annotation(Placement(transformation(x=-10.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=-10.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  Math.Gain Gain(Gain=k) annotation(Placement(transformation(x=-36.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Math.Feedback Feedback1 annotation(Placement(transformation(x=-70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true)));
  Integrateur Integrateur1(k=1/Ti, permanent=permanent, ureset0=ureset0) annotation(Placement(transformation(x=0.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Math.Add Add1 annotation(Placement(transformation(x=42.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Math.Gain Gain1(Gain=k) annotation(Placement(transformation(x=-36.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  NonLineaire.Selecteur Selecteur1(C1=0) annotation(Placement(transformation(x=10.0, y=-20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(ureset) == 1 then
    Integrateur1.ureset.signal=ureset0;
  end if;
  if cardinality(reset) == 2 then
    Integrateur1.reset.signal=false;
  end if;
  connect(Limiteur1.y,y) annotation(Line(points={{91,0},{110,0}}));
  connect(Gain3.u,Add2.y) annotation(Line(points={{1,70},{19,70}}));
  connect(u,Feedback1.u1) annotation(Line(points={{-110,0},{-90,0},{-90,30},{-81,30}}));
  connect(Limiteur1.y,Add2.u1) annotation(Line(points={{91,0},{94,0},{94,76},{41,76}}));
  connect(Gain3.y,Feedback1.u2) annotation(Line(points={{-21,70},{-70,70},{-70,41}}));
  connect(Integrateur1.y,Add1.u1) annotation(Line(points={{11,30},{20,30},{20,6},{31,6}}));
  connect(ureset,Integrateur1.ureset) annotation(Line(points={{-110,-80},{-20,-80},{-20,22},{-11,22}}));
  connect(reset,Integrateur1.reset) annotation(Line(points={{-10,-110},{-10,10},{0,10},{0,19}}, color={0,0,255}, pattern=LinePattern.Dash));
  connect(Add1.y,Limiteur1.u) annotation(Line(points={{53,0},{69,0}}));
  connect(Add1.y,Add2.u2) annotation(Line(points={{53,0},{60,0},{60,64},{41,64}}));
  connect(Feedback1.y,Gain.u) annotation(Line(points={{-59,30},{-47,30}}));
  connect(Gain.y,Integrateur1.u) annotation(Line(points={{-25,30},{-11,30}}));
  connect(u,Gain1.u) annotation(Line(points={{-110,0},{-90,0},{-90,-30},{-47,-30}}));
  connect(Selecteur1.y,Add1.u2) annotation(Line(points={{21,-20},{26,-20},{26,-6},{31,-6}}));
  connect(Gain1.y,Selecteur1.u2) annotation(Line(points={{-25,-30},{-14,-30},{-14,-28},{-1,-28}}));
  connect(reset,Selecteur1.uCond) annotation(Line(points={{-10,-110},{-10,-20},{-1,-20}}, color={0,0,255}, pattern=LinePattern.Dash));
end PIsat;
