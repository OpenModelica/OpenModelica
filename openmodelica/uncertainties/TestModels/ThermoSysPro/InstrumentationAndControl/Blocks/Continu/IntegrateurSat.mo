within ThermoSysPro.InstrumentationAndControl.Blocks.Continu;
block IntegrateurSat
  parameter Real k=1 "Gain";
  parameter Real maxval=1 "Valeur maximale de la sortie";
  parameter Real minval=0 "Valeur minimale de la sortie";
  parameter Real ureset0=0 "Valeur de la sortie sur reset (si ureset non connecté)";
  parameter Boolean permanent=false "Calcul du permanent";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ureset annotation(Placement(transformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical reset annotation(Placement(transformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
protected
  Real x;
  Real x0;
  annotation(Diagram, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Line(points={{-80,78},{-80,-90}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-90,-80},{82,-80}}, color={192,192,192}),Polygon(points={{90,-80},{68,-72},{68,-88},{90,-80}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-54,84},{6,24}}, textString="I", fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-36,-34},{54,-74}}, textString="K=%k", fillColor={0,0,0}),Line(color={0,0,255}, points={{-80,-80},{20,20},{80,20}})}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Continuous library</b></p>
</HTML>
<html>
<p><b>Version 1.7</b></p>
</HTML>
"));
initial equation
  if permanent then
    der(x)=0;
  else
    x=(1/k - 1)*ureset.signal/k;
  end if;
equation
  assert(maxval > minval, "IntegrateurSat : Le paramètre maxval doit être supérieur au paramètre minval");
  if cardinality(reset) == 0 then
    reset.signal=false;
  end if;
  if cardinality(ureset) == 0 then
    ureset.signal=ureset0;
  end if;
  when not reset.signal then
    x0=ureset.signal/k;
    reinit(x, x0);
  end when;
  der(x)=if reset.signal or y.signal > maxval and u.signal > 0 or y.signal < minval and u.signal < 0 then 0 else u.signal;
  y.signal=if reset.signal then ureset.signal else k*x;
end IntegrateurSat;
