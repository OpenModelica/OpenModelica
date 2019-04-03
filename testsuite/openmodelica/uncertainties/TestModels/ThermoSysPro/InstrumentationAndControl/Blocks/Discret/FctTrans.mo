within ThermoSysPro.InstrumentationAndControl.Blocks.Discret;
block FctTrans
  parameter Real b[:]={1} "Coefficients numérateurs de la fonction de transfert";
  parameter Real a[:]={1,1} "Coefficients dénominateurs de la fonction de transfert";
  parameter Real SampleOffset=0 "Instant de départ de l'échantillonnage (s)";
  parameter Real SampleInterval=0.01 "Période d'échantillonnage (s)";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  Real x[size(a, 1) - 1];
  parameter Integer na=size(a, 1);
  parameter Integer nb(max=na)=size(b, 1);
  Real x1;
  Real xn;
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(points={{82,0},{-84,0}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-92,92},{86,12}}, textString="b(z)", fillColor={0,0,255}),Text(lineColor={0,0,255}, extent={{-90,-12},{90,-90}}, textString="a(z)", fillColor={0,0,255})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillPattern=FillPattern.None),Line(points={{40,0},{-44,0}}, color={0,0,0}, thickness=0.5),Text(lineColor={0,0,255}, extent={{-54,54},{54,4}}, textString="b(z)", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-54,-6},{56,-56}}, textString="a(z)", fillColor={0,0,0}),Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{60,0},{100,0}})}), Documentation(info="<html>
<p><b>Adapted from the ModelicaAdditions.Blocks.Discrete library</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
equation
  when sample(SampleOffset, SampleInterval) then
    [x;xn]=[x1;pre(x)];
    [u.signal]=transpose([a])*[x1;pre(x)];
    [y.signal]=transpose([zeros(na - nb, 1);b])*[x1;pre(x)];
  end when;
end FctTrans;
