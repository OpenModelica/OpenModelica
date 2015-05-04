within ThermoSysPro.InstrumentationAndControl.Blocks;
package Commun
  annotation(Icon(coordinateSystem(extent={{0,0},{313,206}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-90,40},{70,10}}, textString="Unites", fillColor={160,160,160}),Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-120,135},{120,70}}, textString="%name", fillColor={255,0,0})}), Documentation(info="<html>
<p><b>Version 1.1</b></p>
</HTML>
"));
  function rand "rand"
    output Integer y;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-84,18},{84,-30}}, textString="fonction", fillColor={255,127,0}),Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, lineColor={255,127,0}, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-82,-22},{86,-70}}, textString="externe", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));

    external "C" y=rand(0) ;

  end rand;

  function srand "rand"
    input Integer u;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, lineColor={255,127,0}, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-84,18},{84,-30}}, textString="fonction", fillColor={255,127,0}),Text(lineColor={0,0,255}, extent={{-82,-22},{86,-70}}, textString="externe", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));

    external "C" srand(u) ;

  end srand;

  function fmod "fmod"
    input Real u1;
    input Real u2;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, lineColor={255,127,0}, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-84,18},{84,-30}}, textString="fonction", fillColor={255,127,0}),Text(lineColor={0,0,255}, extent={{-82,-22},{86,-70}}, textString="externe", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Version 1.6</b></p>
</HTML>
"));

    external "C" y=fmod(u1,u2) ;

  end fmod;

end Commun;
