within ThermoSysPro.Thermal.BoundaryConditions;
model HeatSource "Heat source"
  parameter ThermoSysPro.Units.AbsoluteTemperature T0[:]={300} "Source temperature (active if option_temperature=1)";
  parameter Modelica.SIunits.Power W0[:]={2000000.0} "Heat power emitted by the source (active if option_temperature=2)";
  parameter Integer option_temperature=1 "1:temperature fixed - 2:heat power fixed";
  ThermoSysPro.Thermal.Connectors.ThermalPort C[N] annotation(Placement(transformation(x=0.0, y=-98.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-98.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.InputReal ISignal annotation(Placement(transformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=true, rotation=-90.0), iconTransformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=true, rotation=-90.0)));
protected
  parameter Integer N=size(T0, 1);
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={255,127,0}),Text(lineColor={0,0,255}, extent={{-40,40},{40,-38}}, textString="C"),Line(color={0,0,255}, points={{0,-40},{0,-88}}),Line(color={0,0,255}, points={{0,-88},{12,-68}}),Line(color={0,0,255}, points={{0,-88},{-12,-70}})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={255,127,0}),Line(color={0,0,255}, points={{0,-40},{0,-88}}),Line(color={0,0,255}, points={{0,-88},{-12,-70}}),Line(color={0,0,255}, points={{0,-88},{12,-68}}),Text(lineColor={0,0,255}, extent={{-40,40},{40,-38}}, textString="C")}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
equation
  if cardinality(ISignal) == 0 then
    if option_temperature == 1 then
      C.T=T0;
    elseif option_temperature == 2 then
      C.W=-W0;
    else
      assert(false, "HeatSource : incorrect option");
    end if;
    ISignal.signal=0;
  else
    if option_temperature == 1 then
      C.T=fill(ISignal.signal, N);
    elseif option_temperature == 2 then
      C.W=fill(-ISignal.signal, N);
    else
      assert(false, "HeatSource : incorrect option");
    end if;
  end if;
end HeatSource;
