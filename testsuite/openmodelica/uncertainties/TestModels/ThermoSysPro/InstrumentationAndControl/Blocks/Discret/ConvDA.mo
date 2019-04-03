within ThermoSysPro.InstrumentationAndControl.Blocks.Discret;
block ConvDA
  parameter Real maxval=1 "Valeur maximale en entrée";
  parameter Real minval=-maxval "Valeur minimale en entrée";
  parameter Real bits=12 "Nombre de bits du convertisseur DA";
  parameter Real SampleOffset=0 "Instant de départ de l'échantillonnage (s)";
  parameter Real SampleInterval=0.01 "Période d'échantillonnage (s)";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  Real qInterval(start=(maxval - minval)/2^bits) "quantization interval";
  Real uBound "bounded input";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={192,192,192}),Line(color={0,0,255}, points={{-80,-30},{-46,-30},{-46,0},{-20,0},{-20,22},{-8,22},{-8,44},{12,44},{12,20},{30,20},{30,0},{62,0},{62,-22},{88,-22}}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-80,-30},{-46,-30},{-46,0},{-20,0},{-20,22},{-8,22},{-8,44},{12,44},{12,20},{30,20},{30,0},{62,0},{62,-22},{88,-22}})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
algorithm
  qInterval:=(maxval - minval)/2^bits;
  when sample(SampleOffset, SampleInterval) then
      uBound:=if u.signal > maxval then maxval else if u.signal < minval then minval else u.signal;
    y.signal:=qInterval*floor(abs(uBound/qInterval) + 0.5)*sign(uBound);
  end when;
end ConvDA;
