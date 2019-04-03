within ThermoSysPro.InstrumentationAndControl.Blocks.Continu;
block PI
  parameter Real k=1 "Gain";
  parameter Real Ti=1 "Constante de temps (s)";
  parameter Real ureset0=0 "Valeur de la sortie sur reset (si ureset non connecté)";
  parameter Boolean permanent=false "Calcul du permanent";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ureset annotation(Placement(transformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical reset annotation(Placement(transformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
protected
  Real x;
  Real x0;
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Line(points={{-74,64},{-74,-80}}, color={192,192,192}),Line(points={{-74,-80},{70,-80}}, color={192,192,192}),Polygon(points={{92,-80},{70,-72},{70,-88},{92,-80}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-74,-68},{-74,2},{66,58}}, thickness=0.25),Text(lineColor={0,0,255}, extent={{-32,70},{0,42}}, textString="PI", fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Text(lineColor={0,0,255}, extent={{-36,-34},{54,-74}}, textString="Ti=%Ti", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-38,10},{52,-30}}, textString="K=%k", fillColor={0,0,0}),Polygon(points={{-74,86},{-82,64},{-66,64},{-74,86}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{62,0},{100,0}}),Rectangle(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Rectangle(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-68,24},{-24,-18}}, textString="k", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-32,48},{60,0}}, textString="T s + 1", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-30,-8},{52,-40}}, textString="T s", fillColor={0,0,0}),Line(points={{-24,0},{54,0}}, color={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Continuous library</b></p>
</HTML>
<html>
<p><b>Version 1.6</b></p>
</HTML>
"));
initial equation
  if permanent then
    der(x)=0;
  else
    x=(1/k - 1)*ureset.signal/k;
  end if;
equation
  if cardinality(reset) == 0 then
    reset.signal=false;
  end if;
  if cardinality(ureset) == 0 then
    ureset.signal=ureset0;
  end if;
  when not reset.signal then
    x0=ureset.signal/k - u.signal;
    reinit(x, x0);
  end when;
  der(x)=if reset.signal then 0 else u.signal/Ti;
  y.signal=if reset.signal then ureset.signal else k*(x + u.signal);
end PI;
