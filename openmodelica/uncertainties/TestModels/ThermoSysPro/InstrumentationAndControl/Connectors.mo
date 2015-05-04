within ThermoSysPro.InstrumentationAndControl;
package Connectors "Connectors"
  annotation(Icon(coordinateSystem(extent={{0,0},{311,211}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-120,135},{120,70}}, textString="%name", fillColor={255,0,0}),Text(lineColor={0,0,255}, extent={{-90,40},{70,10}}, textString="Library", fillColor={160,160,160}),Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),Polygon(points={{16,-71},{29,-67},{29,-74},{16,-71}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Solid),Polygon(points={{-32,-21},{-46,-17},{-46,-25},{-32,-21}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  connector InputDateAndTime
    input ThermoSysPro.InstrumentationAndControl.Common.DateEtHeure signal;
    annotation(Icon(coordinateSystem(extent={{-1,-1},{1,1}}), graphics={Polygon(lineColor={0,0,255}, points={{-1,1},{1,0},{-1,-1},{-1,1}}, fillColor={0,0,0}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  end InputDateAndTime;

  connector OutputDateAndTime
    output ThermoSysPro.InstrumentationAndControl.Common.DateEtHeure signal;
    annotation(Icon(coordinateSystem(extent={{-1,-1},{1,1}}), graphics={Polygon(lineColor={0,0,255}, points={{-1,1},{1,0},{-1,-1},{-1,1}}, fillPattern=FillPattern.Solid, fillColor={192,192,192})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  end OutputDateAndTime;

  connector InputReal
    input Real signal;
    annotation(Diagram, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,100},{-100,-100},{100,0},{-100,100}}, fillPattern=FillPattern.Solid, fillColor={0,127,255})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  end InputReal;

  connector InputLogical
    input Boolean signal;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,100},{-100,-100},{100,0},{-100,100}}, fillPattern=FillPattern.Solid, fillColor={255,255,0})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  end InputLogical;

  connector InputInteger
    input Integer signal;
    annotation(Diagram, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,100},{-100,-100},{100,0},{-100,100}}, fillPattern=FillPattern.Solid, fillColor={255,0,255})}), Documentation(info="<html>
<p><b>Version 1.6</b></p>
</HTML>
"));
  end InputInteger;

  connector OuputInteger
    output Integer signal;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,100},{-100,-100},{100,0},{-100,100}}, fillPattern=FillPattern.Solid, fillColor={255,0,127})}), Documentation(info="<html>
<p><b>Version 1.6</b></p>
</HTML>
"));
  end OuputInteger;

  connector OutputLogical
    output Boolean signal;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,100},{-100,-100},{100,0},{-100,100}}, fillPattern=FillPattern.Solid, fillColor={127,255,0})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  end OutputLogical;

  connector OutputReal
    output Real signal;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,100},{-100,-100},{100,0},{-100,100}}, fillPattern=FillPattern.Solid, fillColor={0,255,255})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  end OutputReal;

end Connectors;
