within NewDataReconciliationSimpleTests;
function PT
  input Modelica.SIunits.AbsolutePressure P "Pressure";
  input Modelica.SIunits.Temperature T "Temperature";
  input Integer mode = 0 "IF97 region - 0:automatic computation";
  input Integer fluid = 1 "Fluid number - 1: IF97 - 7: SimpleWater";

  output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_pT pro
    annotation (Placement(transformation(extent={{-80,40},{-40,80}}, rotation=0)));
algorithm

  if (fluid == 1) then
    pro := ThermoSysPro.Properties.WaterSteam.IF97.Water_PT(
      P,
      T,
      mode);
  else
    assert(false, "Prop.PT : incorrect fluid number");
  end if;

  annotation (
    smoothOrder = 2,
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Text(extent={{-134,104},{142,44}}, textString=
                                               "%name"),
        Ellipse(
          extent={{-100,40},{100,-100}},
          lineColor={255,127,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-84,-4},{84,-52}},
          lineColor={255,127,0},
          textString=
               "fonction")}),
    Window(
      x=0.06,
      y=0.1,
      width=0.75,
      height=0.73),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end PT;
