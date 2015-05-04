within ThermoSysPro.InstrumentationAndControl.Blocks.Continu;
block FctTrans
  parameter Real b[:]={1} "Coefficients numérateurs de la fonction de transfert (par puissances décroissantes)";
  parameter Real a[:]={1,1} "Coefficients dénominateurs de la fonction de transfert (par puissances décroissantes)";
  parameter Real U0=0 "Valeur de la sortie à l'instant initial (si non permanent et si u0 non connecté)";
  parameter Boolean permanent=false "Calcul du permanent";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u0 annotation(Placement(transformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Integer na=size(a, 1);
  parameter Integer nb(max=na)=size(b, 1);
  parameter Integer nx=na - 1;
  Real x[nx];
  Real x1dot;
  Real xn;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{62,0},{102,0}}),Line(points={{-50,0},{50,0}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-55,55},{55,5}}, textString="b(s)", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-55,-5},{55,-55}}, textString="a(s)", fillColor={0,0,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-90,10},{90,90}}, textString="b(s)"),Line(color={0,0,255}, points={{-80,0},{80,0}}),Text(lineColor={0,0,255}, extent={{-90,-10},{90,-90}}, textString="a(s)")}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Continuous library</b></p>
</HTML>
<html>
<p><b>Version 1.7</b></p>
</HTML>
"));
initial equation
  if permanent then
    der(x)=zeros(nx);
  elseif nx > 0 then
    transpose([zeros(na - nb, 1);b])*[x1dot;x]=[u0.signal];
  else
  end if;
equation
  if cardinality(u0) == 0 then
    u0.signal=U0;
  end if;
  [der(x);xn]=[x1dot;x];
  [u.signal]=transpose([a])*[x1dot;x];
  [y.signal]=transpose([zeros(na - nb, 1);b])*[x1dot;x];
end FctTrans;
