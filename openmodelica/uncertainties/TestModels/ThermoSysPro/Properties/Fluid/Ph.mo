within ThermoSysPro.Properties.Fluid;
function Ph
  input ThermoSysPro.Units.AbsolutePressure P "Pressure";
  input ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
  input Integer mode=0 "IF97 region - 0:automatic computation";
  input Integer fluid=1 "Fluid number - 1: IF97 - 2: C3H3F5";
  output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation(Placement(transformation(x=-60.0, y=60.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
algorithm
  if fluid == 1 then
    pro:=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, h, mode);
  elseif fluid == 2 then
    pro:=C3H3F5.C3H3F5_Ph(P, h);
  else
    assert(false, "Prop.Ph : incorrect fluid number");
  end if;
  annotation(smoothOrder=2, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end Ph;
