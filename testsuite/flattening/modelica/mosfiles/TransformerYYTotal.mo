package Modelica "Modelica Standard Library"
  extends Icons.Library;
  annotation(preferedView="info", version="2.2.1", versionDate="2006-03-24", conversion(from(version="1.6", ModelicaAdditions(version="1.5"), MultiBody(version="1.0.1"), MultiBody(version="1.0"), Matrices(version="0.8"), script="Scripts/ConvertModelica_from_1.6_to_2.1.mos"), from(version="2.1 Beta1", script="Scripts/ConvertModelica_from_2.1Beta1_to_2.1.mos"), noneFromVersion="2.1", noneFromVersion="2.2"), Dymola(checkSum="539989979:1143034484"), Settings(NewStateSelection=true), Documentation(info="<HTML>
<p>
Package <b>Modelica</b> is a <b>standardized</b> and <b>free</b> package
that is developed together with the Modelica language from the
Modelica Association, see <a href=\"http://www.Modelica.org\">http://www.Modelica.org</a>.
It is also called <b>Modelica Standard Library</b>.
It provides model components in many domains that are based on
standardized interface definitions. Some typical examples are shown
in the next figure:
</p>

<p>
<img src=\"./Images/UsersGuide/ModelicaLibraries.png\">
</p>

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"Modelica://Modelica.UsersGuide\">Users Guide</a>
     discusses some aspects of the Modelica Standard Library, such as
     interface definitions and used conventions.</li>
<li><a href=\"Modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
    summarizes the changes of new versions of this package.</li>
<li> Packages <b>Examples</b> in the various subpackages, demonstrate
     how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
Copyright &copy; 1998-2006, Modelica Association.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p>
<p> <b>Note:</b> This is a <i>subset</i> of the official Modelica package with minor changes made by MathCore Engineering AB.
For a complete list of changes see the <a href=\"Modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>.
</p>
</HTML>
", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  package Math "Mathematical functions (e.g., sin, cos) and operations on matrices (e.g., norm, solve, eig, exp)"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Invisible=true, Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-59,-56},{42,-9}}, textString="f(x)", fontName="Arial")}), Documentation(info="<HTML>
<p>
This package contains <b>basic mathematical functions</b> (such as sin(..)),
as well as functions operating on <b>matrices</b>.
</p>

<dl>
<dt><b>Main Author:</b>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
    Institut f&uuml;r Robotik und Mechatronik<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    Germany<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
</dl>

<p>
Copyright &copy; 1998-2006, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</HTML>
", revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Function tempInterpol2 added.</li>
<li><i>Oct. 24, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Icons for icon and diagram level introduced.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>

</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    function sin "sine"
      extends baseIcon1;
      input SI.Angle u;
      output Real y;
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{12,36},{84,84}}, textString="sin", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-105,72},{-85,88}}, textString="1", fontName="Arial"),Text(visible=true, extent={{70,5},{90,25}}, textString="2*pi", fontName="Arial"),Text(visible=true, extent={{-105,-88},{-85,-72}}, textString="-1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>

</html>"));

      external "C" y=sin(u) ;

    end sin;

    function asin "inverse sine (-1 <= u <= 1)"
      extends baseIcon2;
      input Real u;
      output SI.Angle y;
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-88,30},{-16,78}}, textString="asin", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-40,-88},{-15,-72}}, textString="-pi/2", fontName="Arial"),Text(visible=true, extent={{-38,72},{-13,88}}, textString=" pi/2", fontName="Arial"),Text(visible=true, extent={{70,5},{90,25}}, textString="+1", fontName="Arial"),Text(visible=true, extent={{-90,1},{-70,21}}, textString="-1", fontName="Arial"),Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>

</html>"));

      external "C" y=asin(u) ;

    end asin;

    function exp "exponential, base e"
      extends baseIcon2;
      input Real u;
      output Real y;
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,-80.3976},{68,-80.3976}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-80.3976},{68,-72.3976},{68,-88.3976},{90,-80.3976}}),Line(visible=true, points={{-80,-80},{-31,-77.9},{-6.03,-74},{10.9,-68.4},{23.7,-61},{34.2,-51.6},{43,-40.3},{50.3,-27.8},{56.7,-13.5},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-86,2},{-14,50}}, textString="exp", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,-80.3976},{84,-80.3976}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,-80.3976},{84,-74.3976},{84,-86.3976},{100,-80.3976}}),Line(visible=true, points={{-80,-80},{-31,-77.9},{-6.03,-74},{10.9,-68.4},{23.7,-61},{34.2,-51.6},{43,-40.3},{50.3,-27.8},{56.7,-13.5},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-31,72},{-11,88}}, textString="20", fontName="Arial"),Text(visible=true, extent={{-92,-103},{-72,-83}}, textString="-3", fontName="Arial"),Text(visible=true, extent={{70,-103},{90,-83}}, textString="3", fontName="Arial"),Text(visible=true, extent={{-18,-73},{2,-53}}, textString="1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{96,-102},{116,-82}}, textString="u", fontName="Arial")}));

      external "C" y=exp(u) ;

    end exp;

    partial function baseIcon1 "Basic icon for mathematical function with y-axis on left side"
      annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,80},{-88,80}}, color={192,192,192}),Line(visible=true, points={{-80,-80},{-88,-80}}, color={192,192,192}),Line(visible=true, points={{-80,-90},{-80,84}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-75,90},{-55,110}}, textString="y", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,100},{-86,84},{-74,84},{-80,100}})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Line(visible=true, points={{-80,-80},{-80,68}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,110},{150,150}}, textString="%name", fontName="Arial")}));
    end baseIcon1;

    partial function baseIcon2 "Basic icon for mathematical function with y-axis in middle"
      annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,80},{-8,80}}, color={192,192,192}),Line(visible=true, points={{0,-80},{-8,-80}}, color={192,192,192}),Line(visible=true, points={{0,-90},{0,84}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{5,90},{25,110}}, textString="y", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{0,100},{-6,84},{6,84},{0,100}})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Line(visible=true, points={{0,-80},{0,68}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{0,90},{-8,68},{8,68},{0,90}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,110},{150,150}}, textString="%name", fontName="Arial")}));
    end baseIcon2;

  end Math;

  package Electrical "Library for electrical models (analog, digital, machines, multi-phase)"
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Documentation(info="<html>
<p>
This library contains electrical components to build up analog and digital circuits,
as well as machines to model electrical motors and generators,
especially three phase induction machines such as an asynchronous motor.
</p>

</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, extent={{-29,-27},{3,-13}}),Line(visible=true, points={{37,-58},{62,-58}}),Line(visible=true, points={{36,-49},{61,-49}}),Line(visible=true, points={{-78,-50},{-43,-50}}),Line(visible=true, points={{-67,-55},{-55,-55}}),Line(visible=true, points={{-61,-50},{-61,-20},{-29,-20}}),Line(visible=true, points={{3,-20},{48,-20},{48,-49}}),Line(visible=true, points={{48,-58},{48,-78},{-61,-78},{-61,-55}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    package Analog "Library for analog electrical models"
      import SI = Modelica.SIunits;
      extends Modelica.Icons.Library2;
      annotation(preferedView="info", Window(x=0.05, y=0.06, width=0.16, height=0.58, library=1, autolayout=1), classOrder={"Examples","*"}, Documentation(info="<html>
<p>
This package contains packages for analog electrical components:
<ul>
<li>Basic: basic components (resistor, capacitor, conductor, inductor, transformer, gyrator)</li>
<li>Semiconductors: semiconductor devices (diode, bipolar and MOS transistors)</li>
<li>Lines: transmission lines (lossy and lossless)</li>
<li>Ideal: ideal elements (switches, diode, transformer, idle, short, ...)</li>
<li>Sources: time-dependend and controlled voltage and current sources</li>
<li>Sensors: sensors to measure potential, voltage, and current</li>
</ul>
</p>
<dl>
<dt>
<b>Main Authors:</b></dt>
<dd>
<a href=\"http://people.eas.iis.fhg.de/Christoph.Clauss/\">Christoph Clau&szlig;</a>
    &lt;<a href=\"mailto:clauss@eas.iis.fhg.de\">clauss@eas.iis.fhg.de</a>&gt;<br>
    <a href=\"http://people.eas.iis.fhg.de/Andre.Schneider/\">Andr&eacute; Schneider</a>
    &lt;<a href=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</a>&gt;<br>
    Fraunhofer Institute for Integrated Circuits<br>
    Design Automation Department<br>
    Zeunerstra&szlig;e 38<br>
    D-01069 Dresden</dd>
</dl>


<p>
Copyright &copy; 1998-2006, Modelica Association and Fraunhofer-Gesellschaft.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      package Sources "Time-dependend and controlled voltage and current sources"
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Documentation(info="<html>
<p>
This package contains time-dependend and controlled voltage and current sources.
</p>

</HTML>
", revisions="<html>
<dl>
<dt>
<b>Main Authors:</b>
<dd>
<a href=\"http://people.eas.iis.fhg.de/Christoph.Clauss/\">Christoph Clau&szlig;</a>
    &lt;<a href=\"mailto:clauss@eas.iis.fhg.de\">clauss@eas.iis.fhg.de</a>&gt;<br>
    <a href=\"http://people.eas.iis.fhg.de/Andre.Schneider/\">Andr&eacute; Schneider</a>
    &lt;<a href=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</a>&gt;<br>
    Fraunhofer Institute for Integrated Circuits<br>
    Design Automation Department<br>
    Zeunerstra&szlig;e 38<br>
    D-01069 Dresden<br>
<p>
<dt>
<b>Copyright:</b>
<dd>
Copyright &copy; 1998-2006, Modelica Association and Fraunhofer-Gesellschaft.<br>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".</i><br>
<p>
</dl>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model SineVoltage "Sine voltage source"
          parameter SI.Voltage V=1 "Amplitude of sine wave";
          parameter SI.Angle phase=0 "Phase of sine wave";
          parameter SI.Frequency freqHz=1 "Frequency of sine wave";
          extends Interfaces.VoltageSource(redeclare Modelica.Blocks.Sources.Sine signalSource(amplitude=V, freqHz=freqHz, phase=phase) );
          annotation(Documentation(revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-90},{-80,84}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,100},{-86,84},{-74,84},{-80,100}}),Line(visible=true, points={{-99,-40},{85,-40}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{101,-40},{85,-34},{85,-46},{101,-40}}),Line(visible=true, points={{-40,0},{-31.6,34.2},{-26.1,53.1},{-21.3,66.4},{-17.1,74.6},{-12.9,79.1},{-8.64,79.8},{-4.42,76.6},{-0.2,69.7},{4.02,59.4},{8.84,44.1},{14.9,21.2},{27.5,-30.8},{33,-50.2},{37.8,-64.2},{42,-73.1},{46.2,-78.4},{50.5,-80},{54.7,-77.6},{58.9,-71.5},{63.1,-61.9},{67.9,-47.2},{74,-24.8},{80,0}}, thickness=0.5, smooth=Smooth.Bezier),Line(visible=true, points={{-40.5,-2.22e-16},{-79.5,-2.22e-16}}, thickness=0.5),Text(visible=true, lineColor={0,0,255}, fillColor={160,160,160}, extent={{-106,-29},{-60,-11}}, textString="offset", fontName="Arial"),Line(visible=true, points={{-41,-2},{-41,-40}}, color={192,192,192}, pattern=LinePattern.Dot),Text(visible=true, lineColor={0,0,255}, fillColor={160,160,160}, extent={{-60,-61},{-14,-43}}, textString="startTime", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={160,160,160}, extent={{84,-72},{108,-52}}, textString="time", fontName="Arial"),Line(visible=true, points={{-9,79},{43,79}}, color={192,192,192}, pattern=LinePattern.Dot),Line(visible=true, points={{-42,-1},{50,0}}, color={192,192,192}, pattern=LinePattern.Dot),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{33,80},{30,67},{37,67},{33,80}}),Text(visible=true, lineColor={0,0,255}, fillColor={160,160,160}, extent={{37,39},{83,57}}, textString="V", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{33,1},{30,14},{36,14},{33,1},{33,1}}),Line(visible=true, points={{33,79},{33,0}}, color={192,192,192}),Text(visible=true, lineColor={0,0,255}, fillColor={160,160,160}, extent={{-70,82.5},{-5,108.5}}, textString="v = p.v - n.v", fontName="Arial")}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-66,0},{-56.2,29.9},{-49.8,46.5},{-44.2,58.1},{-39.3,65.2},{-34.3,69.2},{-29.4,69.8},{-24.5,67},{-19.6,61},{-14.6,52},{-9,38.6},{-1.98,18.6},{12.79,-26.9},{19.1,-44},{24.8,-56.2},{29.7,-64},{34.6,-68.6},{39.5,-70},{44.5,-67.9},{49.4,-62.5},{54.3,-54.1},{59.9,-41.3},{67,-21.7},{74,0}}, color={192,192,192}, smooth=Smooth.Bezier)}));
        end SineVoltage;

      end Sources;

      package Interfaces "Connectors and partial models for Analog electrical components"
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Documentation(info="<html>
<p>
This package contains connectors and interfaces (partial models) for
analog electrical components.
</p>

</HTML>
", revisions="<html>
<dl>
<dt>
<b>Main Authors:</b>
<dd>
<a href=\"http://people.eas.iis.fhg.de/Christoph.Clauss/\">Christoph Clau&szlig;</a>
    &lt;<a href=\"mailto:clauss@eas.iis.fhg.de\">clauss@eas.iis.fhg.de</a>&gt;<br>
    <a href=\"http://people.eas.iis.fhg.de/Andre.Schneider/\">Andr&eacute; Schneider</a>
    &lt;<a href=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</a>&gt;<br>
    Fraunhofer Institute for Integrated Circuits<br>
    Design Automation Department<br>
    Zeunerstra&szlig;e 38<br>
    D-01069 Dresden<br>
<p>
<dt>
</dl>

<b>Copyright:</b>
<dl>
<dd>
Copyright &copy; 1998-2006, Modelica Association and Fraunhofer-Gesellschaft.<br>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".</i><br>
<p>
</dl>

<ul>
<li><i> 1998</i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        connector Pin "Pin of an electrical component"
          SI.Voltage v "Potential at the pin";
          flow SI.Current i "Current flowing into the pin";
          annotation(defaultComponentName="pin", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}})}), Documentation(revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"));
        end Pin;

        connector PositivePin "Positive pin of an electric component"
          extends Pin;
          annotation(defaultComponentName="pin_p", Documentation(info="<html><p>Connectors PositivePin
and NegativePin are nearly identical.
The only difference is that the icons are different in order
to identify more easily the pins of a component. Usually,
connector PositivePin is used for the positive and
connector NegativePin for the negative pin of an electrical
component.</p></html>", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}}),Text(visible=true, fillColor={0,0,255}, extent={{-160,50},{40,110}}, textString="%name", fontName="Arial")}));
        end PositivePin;

        connector NegativePin "Negative pin of an electric component"
          extends Pin;
          annotation(defaultComponentName="pin_n", Documentation(info="<html><p>Connectors PositivePin
and NegativePin are nearly identical.
The only difference is that the icons are different in order
to identify more easily the pins of a component. Usually,
connector PositivePin is used for the positive and
connector NegativePin for the negative pin of an electrical
component.</p></html>", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}}),Text(visible=true, fillColor={0,0,255}, extent={{-40,50},{160,110}}, textString="%name", fontName="Arial")}));
        end NegativePin;

        partial model OnePort "Component with two electrical pins p and n and current i from p to n"
          SI.Voltage v "Voltage drop between the two pins (= p.v - n.v)";
          SI.Current i "Current flowing from pin p to pin n";
          annotation(Documentation(info="<HTML>
<P>
Superclass of elements which have <b>two</b> electrical pins:
the positive pin connector <i>p</i>, and the negative pin
connector <i>n</i>. It is assumed that the current flowing
into pin p is identical to the current flowing out of pin n.
This current is provided explicitly as current i.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-110,20},{-85,20}}, color={160,160,160}),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-95,23},{-85,20},{-95,17},{-95,23}}),Line(visible=true, points={{90,20},{115,20}}, color={160,160,160}),Line(visible=true, points={{-125,0},{-115,0}}, color={160,160,160}),Line(visible=true, points={{-120,-5},{-120,5}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{-110,25},{-90,45}}, textString="i", fontName="Arial"),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{105,23},{115,20},{105,17},{105,23}}),Line(visible=true, points={{115,0},{125,0}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{90,25},{110,45}}, textString="i", fontName="Arial")}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          PositivePin p "Positive pin (potential p.v > n.v for positive voltage drop v)" annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          NegativePin n "Negative pin" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{10,-10},{-10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{10,-10},{-10,10}}, rotation=0)));
        equation
          v=p.v - n.v;
          0=p.i + n.i;
          i=p.i;
        end OnePort;

        partial model TwoPort "Component with two electrical ports, including current"
          SI.Voltage v1 "Voltage drop over the left port";
          SI.Voltage v2 "Voltage drop over the right port";
          SI.Current i1 "Current flowing from pos. to neg. pin of the left port";
          SI.Current i2 "Current flowing from pos. to neg. pin of the right port";
          annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-120,53},{-110,50},{-120,47},{-120,53}}),Line(visible=true, points={{-136,50},{-111,50}}, color={160,160,160}),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{127,-47},{137,-50},{127,-53},{127,-47}}),Line(visible=true, points={{111,-50},{136,-50}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{112,-44},{128,-29}}, textString="i2", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{118,52},{135,67}}, textString="i2", fontName="Arial"),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{120,53},{110,50},{120,47},{120,53}}),Line(visible=true, points={{111,50},{136,50}}, color={160,160,160}),Line(visible=true, points={{-136,-49},{-111,-49}}, color={160,160,160}),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-126,-46},{-136,-49},{-126,-52},{-126,-46}}),Text(visible=true, fillColor={160,160,160}, extent={{-127,-46},{-110,-31}}, textString="i1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-136,53},{-119,68}}, textString="i1", fontName="Arial")}), Documentation(revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>", info="<html>

</html>"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          PositivePin p1 "Positive pin of the left port (potential p1.v > n1.v for positive voltage drop v1)" annotation(Placement(visible=true, transformation(origin={-100,50}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,50}, extent={{-10,-10},{10,10}}, rotation=0)));
          NegativePin n1 "Negative pin of the left port" annotation(Placement(visible=true, transformation(origin={-100,-50}, extent={{10,-10},{-10,10}}, rotation=0), iconTransformation(origin={-100,-50}, extent={{10,-10},{-10,10}}, rotation=0)));
          PositivePin p2 "Positive pin of the right port (potential p2.v > n2.v for positive voltage drop v2)" annotation(Placement(visible=true, transformation(origin={100,50}, extent={{10,-10},{-10,10}}, rotation=0), iconTransformation(origin={100,50}, extent={{10,-10},{-10,10}}, rotation=0)));
          NegativePin n2 "Negative pin of the right port" annotation(Placement(visible=true, transformation(origin={100,-50}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,-50}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          v1=p1.v - n1.v;
          v2=p2.v - n2.v;
          0=p1.i + n1.i;
          0=p2.i + n2.i;
          i1=p1.i;
          i2=p2.i;
        end TwoPort;

        partial model VoltageSource "Interface for voltage sources"
          extends OnePort;
          parameter SI.Voltage offset=0 "Voltage offset";
          parameter SI.Time startTime=0 "Time offset";
          annotation(Documentation(revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-50,-50},{50,50}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,80},{150,120}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-90,0},{90,0}}),Text(visible=true, fillColor={0,0,255}, extent={{-120,0},{-20,50}}, textString="+", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{20,0},{120,50}}, textString="-", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          replaceable Modelica.Blocks.Interfaces.SignalSource signalSource(final offset=offset, final startTime=startTime) annotation(Placement(visible=true, transformation(origin={80,80}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          v=signalSource.y;
        end VoltageSource;

      end Interfaces;

      package Ideal "Ideal electrical elements such as switches, diode, transformer, operational amplifier"
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Documentation(info="<html>
<p>
This package contains electrical components with idealized behaviour:
</p>

</HTML>
", revisions="<html>
<dl>
<dt>
<b>Main Authors:</b>
<dd>
<a href=\"http://people.eas.iis.fhg.de/Christoph.Clauss/\">Christoph Clau&szlig;</a>
    &lt;<a href=\"mailto:clauss@eas.iis.fhg.de\">clauss@eas.iis.fhg.de</a>&gt;<br>
    <a href=\"http://people.eas.iis.fhg.de/Andre.Schneider/\">Andr&eacute; Schneider</a>
    &lt;<a href=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</a>&gt;<br>
    Fraunhofer Institute for Integrated Circuits<br>
    Design Automation Department<br>
    Zeunerstra&szlig;e 38<br>
    D-01069 Dresden<br>
<p>
<dt>
<b>Copyright:</b>
<dd>
Copyright &copy; 1998-2006, Modelica Association and Fraunhofer-Gesellschaft.<br>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".</i><br>
<p>
</dl>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model IdealTransformer "Ideal electrical transformer"
          extends Interfaces.TwoPort;
          parameter Real n=1 "Turns ratio";
          annotation(Documentation(info="<html>
<P>
The ideal transformer is an ideal two-port resistive circuit element
which is characterized by the following two equations:
</P>
<PRE>
    v1 =  n * v2
    i2 = -n * i1
</PRE>
<P>
where <i>n</i> is a real number called the turns ratio.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,0},{-20,25}}, startAngle=-90, endAngle=90),Line(visible=true, points={{-96,50},{-32,50}}, color={0,0,255}),Line(visible=true, points={{-96,-50},{-32,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,25},{45,50}}, startAngle=90, endAngle=-90),Line(visible=true, points={{32,50},{96,50}}, color={0,0,255}),Line(visible=true, points={{32,-50},{96,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,25},{-20,50}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-25},{-20,0}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-50},{-20,-25}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,0},{45,25}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-25},{45,0}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-50},{45,-25}}, startAngle=90, endAngle=-90)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100,80},{100,114.8}}, textString="%name", fontName="Arial"),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-50},{-20,-25}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-25},{-20,0}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,0},{-20,25}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,25},{-20,50}}, startAngle=-90, endAngle=90),Line(visible=true, points={{-90,50},{-32,50}}, color={0,0,255}),Line(visible=true, points={{-90,-50},{-32,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-50},{45,-25}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-25},{45,0}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,0},{45,25}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,25},{45,50}}, startAngle=90, endAngle=-90),Line(visible=true, points={{32,50},{90,50}}, color={0,0,255}),Line(visible=true, points={{32,-50},{90,-50}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, extent={{-100,-100},{100,-80}}, textString="n=%n", fontName="Arial")}));
        equation
          v1=n*v2;
          i2=-n*i1;
        end IdealTransformer;

      end Ideal;

      package Basic "Basic electrical components such as resistor, capacitor, transformer"
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Documentation(info="<HTML>
<p>
This package contains basic analog electrical components.
</p>

</HTML>
", revisions="<html>
<dl>
<dt>
<b>Main Authors:</b>
<dd>
<a href=\"http://people.eas.iis.fhg.de/Christoph.Clauss/\">Christoph Clau&szlig;</a>
    &lt;<a href=\"mailto:clauss@eas.iis.fhg.de\">clauss@eas.iis.fhg.de</a>&gt;<br>
    <a href=\"http://people.eas.iis.fhg.de/Andre.Schneider/\">Andr&eacute; Schneider</a>
    &lt;<a href=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</a>&gt;<br>
    Fraunhofer Institute for Integrated Circuits<br>
    Design Automation Department<br>
    Zeunerstra&szlig;e 38<br>
    D-01069 Dresden<br>
<p>
</dl>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model Ground "Ground node"
          annotation(Documentation(info="<HTML>
<P>
Ground of an electrical circuit. The potential at the
ground node is zero. Every electrical circuit has to contain
at least one ground object.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-60,50},{60,50}}, color={0,0,255}),Line(visible=true, points={{-40,30},{40,30}}, color={0,0,255}),Line(visible=true, points={{-20,10},{20,10}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,50}}, color={0,0,255}),Text(visible=true, fillColor={0,0,255}, extent={{-144,-60},{138,0}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-60,50},{60,50}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-40,30},{40,30}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-20,10},{20,10}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{0,96},{0,50}}, color={0,0,255}, thickness=0.5),Text(visible=true, extent={{-24,-38},{22,-6}}, textString="p.v=0", fontName="Arial")}));
          Interfaces.Pin p annotation(Placement(visible=true, transformation(origin={0,100}, extent={{-10,10},{10,-10}}, rotation=90), iconTransformation(origin={0,100}, extent={{-10,10},{10,-10}}, rotation=90)));
        equation
          p.v=0;
        end Ground;

        model Resistor "Ideal linear electrical resistor"
          extends Interfaces.OnePort;
          parameter SI.Resistance R=1 "Resistance";
          annotation(Documentation(info="<HTML>
<P>
The linear resistor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by <i>i*R = v</i>.
The Resistance <i>R</i> is allowed to be positive, zero, or negative.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-30},{70,30}}),Line(visible=true, points={{-90,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{90,0}}, color={0,0,255}),Text(visible=true, extent={{-144,-100},{144,-60}}, textString="R=%R", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{-144,40},{144,100}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, extent={{-70,-30},{70,30}}),Line(visible=true, points={{-96,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{96,0}}, color={0,0,255})}));
        equation
          R*i=v;
        end Resistor;

        model Inductor "Ideal linear electrical inductor"
          extends Interfaces.OnePort;
          parameter SI.Inductance L=1 "Inductance";
          annotation(Documentation(info="<HTML>
<P>
The linear inductor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by  <i>v = L * di/dt</i>.
The Inductance <i>L</i> is allowed to be positive, zero, or negative.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-60,-15},{-30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{-30,-15},{0,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{0,-15},{30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{30,-15},{60,15}}, endAngle=180),Line(visible=true, points={{60,0},{96,0}}, color={0,0,255}),Line(visible=true, points={{-96,0},{-60,0}}, color={0,0,255})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-60,-15},{-30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{-30,-15},{0,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{0,-15},{30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{30,-15},{60,15}}, endAngle=180),Line(visible=true, points={{60,0},{90,0}}, color={0,0,255}),Line(visible=true, points={{-90,0},{-60,0}}, color={0,0,255}),Text(visible=true, extent={{-138,-102},{144,-60}}, textString="L=%L", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{-146,38},{148,100}}, textString="%name", fontName="Arial")}));
        equation
          L*der(i)=v;
        end Inductor;

      end Basic;

    end Analog;

    package MultiPhase "Library for electrical components with 2, 3 or more phases"
      extends Modelica.Icons.Library2;
      annotation(version="1.1", versionDate="2006-01-12", classOrder={"Examples","*"}, preferedView="info", Documentation(info="<HTML>
<p>
This package contains packages for electrical multiphase components, based on Modelica.Electrical.Analog:
<ul>
<li>Basic: basic components (resistor, capacitor, inductor, ...)</li>
<li>Ideal: ideal elements (switches, diode, transformer, ...)</li>
<li>Sensors: sensors to measure potentials, voltages, and currents</li>
<li>Sources: time-dependend and controlled voltage and current sources</li>
</ul>
This package is intended to be used the same way as Modelica.Electrical.Analog
but to make design of multiphase models easier.<br>
The package is based on the plug: a composite connector containing m pins.<br>
It is possible to connect plugs to plugs or single pins of a plug to single pins.<br>
Potentials may be accessed as <tt>plug.pin[].v</tt>, currents may be accessed as <tt>plug.pin[].i</tt>.
</p>
<p>
Further development:
<ul>
<li>temperature-dependent resistor</li>
<li>lines (m-phase models)</li>
</ul>
</p>
<dl>
<p>
  <dt><b>Main Author:</b></dt>
  <dd>
  <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
  Technical Consulting & Electrical Engineering<br>
  A-3423 St.Andrae-Woerdern<br>Austria<br>
  email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a>
  </dd>
</p>
</dl>
<p>
Copyright &copy; 1998-2005, Modelica Association and Anton Haumer.
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</HTML>", revisions="<html>
  <ul>
  <li>v1.0 2004/10/01 Anton Haumer</li>
  <li>v1.1 2006/01/12 Anton Haumer<br>
      added Sensors.PowerSensor</li>
  </ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-60,-90},{40,10}}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-40,-34},{-20,-14}}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{0,-34},{20,-14}}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-20,-74},{0,-54}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      package Basic "Basic components for electrical multiphase models"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains basic analog electrical multiphase components.
</p>

</HTML>", revisions="<html>
<dl>
<p>
  <dt><b>Main Authors:</b></dt>
  <dd>
  <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
  Technical Consulting & Electrical Engineering<br>
  A-3423 St.Andrae-Woerdern<br>Austria<br>
  email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a>
  </dd>
</p>
<p>
  <dt><b>Release Notes:</b></dt>
  <dd>
  <ul>
  <li> v1.0 2004/10/01 Anton Haumer</li>
  </ul>
  </dd>
<p>
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-80,-70},{60,-10}}),Line(visible=true, points={{60,-40},{80,-40}}, color={0,0,255}),Line(visible=true, points={{-100,-40},{-80,-40}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model Star "Star-connection"
          parameter Integer m(final min=1)=3 "number of phases";
          annotation(Documentation(info="<HTML>
<p>
Connects all pins of plug_p to pin_n, thus establishing a so-called star-connection.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,60},{150,120}}, textString="%name", fontName="Arial"),Line(visible=true, points={{80,0},{0,0}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{0,0},{-39,68}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{0,0},{-38,-69}}, color={0,0,255}, thickness=0.5),Text(visible=true, lineColor={0,0,255}, extent={{-100,-110},{100,-70}}, textString="m=%m", fontName="Arial"),Line(visible=true, points={{-90,0},{-40,0}}, color={0,0,255}),Line(visible=true, points={{80,0},{90,0}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Interfaces.PositivePlug plug_p(final m=m) annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Modelica.Electrical.Analog.Interfaces.NegativePin pin_n annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          for j in 1:m loop
            connect(plug_p.pin[j],pin_n);
          end for;
        end Star;

        model Resistor "Ideal linear electrical resistors"
          extends Interfaces.TwoPlug;
          parameter Modelica.SIunits.Resistance R[m]=fill(1, m) "Resistance";
          annotation(Documentation(info="<HTML>
<p>
Contains m resistors (Modelica.Electrical.Analog.Basic.Resistor)
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-30},{70,30}}),Line(visible=true, points={{-90,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{90,0}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,40},{150,100}}, textString="%name", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, extent={{-100,-100},{100,-60}}, textString="m=%m", fontName="Arial")}));
          Modelica.Electrical.Analog.Basic.Resistor resistor[m](final R=R) annotation(Placement(visible=true, transformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          connect(resistor.n,plug_n.pin) annotation(Line(visible=true, origin={55,0}, points={{-45,0},{45,0}}, color={0,0,255}));
          connect(resistor.p,plug_p.pin) annotation(Line(visible=true, origin={-55,0}, points={{45,0},{-45,0}}, color={0,0,255}));
        end Resistor;

        model Inductor "Ideal linear electrical inductors"
          extends Interfaces.TwoPlug;
          parameter Modelica.SIunits.Inductance L[m]=fill(1, m) "Inductance";
          annotation(Documentation(info="<HTML>
<p>
Contains m inductors (Modelica.Electrical.Analog.Basic.Inductor)
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-60,-15},{-30,15}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-30,-15},{0,15}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{0,-15},{30,15}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{30,-15},{60,15}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-60,-30},{60,0}}),Line(visible=true, points={{60,0},{90,0}}, color={0,0,255}),Line(visible=true, points={{-90,0},{-60,0}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,40},{150,100}}, textString="%name", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, extent={{-100,-100},{100,-60}}, textString="m=%m", fontName="Arial")}));
          Modelica.Electrical.Analog.Basic.Inductor inductor[m](final L=L) annotation(Placement(visible=true, transformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          connect(inductor.n,plug_n.pin) annotation(Line(visible=true, origin={55,0}, points={{-45,0},{45,0}}, color={0,0,255}));
          connect(inductor.p,plug_p.pin) annotation(Line(visible=true, origin={-55,0}, points={{45,0},{-45,0}}, color={0,0,255}));
        end Inductor;

      end Basic;

      package Examples "Multiphase test examples"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains test examples of analog electrical multiphase circuits.
</p>

</HTML>", revisions="<html>
<dl>
<p>
  <dt><b>Main Authors:</b></dt>
  <dd>
  <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
  Technical Consulting & Electrical Engineering<br>
  A-3423 St.Andrae-Woerdern<br>Austria<br>
  email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a>
  </dd>
</p>
<p>
  <dt><b>Release Notes:</b></dt>
  <dd>
  <ul>
  <li> v1.0 2004/10/01 Anton Haumer</li>
  </ul>
  </dd>
<p>
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={128,128,128}, extent={{-60,-88},{40,12}}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{-30,-10},{-30,-66},{28,-38},{-30,-10}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model TransformerYY "Test example with multiphase components"
          annotation(Documentation(info="<HTML>
<p>
Test example with multiphase components:<br>
Star-connected voltage source feeds via a Y-Y-transformer with internal impedance (RT, LT) a load resistor RT.<br>
Using f=5 Hz LT=3mH defines nominal voltage drop of approximately 10 %.<br>
Simulate for 1 second (2 periods) and compare voltages and currents of source, transformer and load.
</p>
</HTML>"), experiment(StopTime=1.0), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          extends Modelica.Icons.Example;
          parameter Integer m=3 "Number of phases";
          parameter Modelica.SIunits.Voltage V=1 "Amplitude of Star-Voltage";
          parameter Modelica.SIunits.Frequency f=5 "Frequency";
          parameter Modelica.SIunits.Inductance LT=0.003 "Transformer stray inductance";
          parameter Modelica.SIunits.Resistance RT=0.05 "Transformer resistance";
          parameter Modelica.SIunits.Resistance RL=1 "Load Resistance";
          Sources.SineVoltage SineVoltage1(V=fill(V, m), freqHz=fill(f, m), m=m) annotation(Placement(visible=true, transformation(origin={-80,20}, extent={{-10,-10},{10,10}}, rotation=180)));
          Modelica.Electrical.Analog.Basic.Ground GroundS1 annotation(Placement(visible=true, transformation(origin={-90,-90}, extent={{-10,-10},{10,10}}, rotation=0)));
          Ideal.IdealTransformer IdealTransformer1(m=m) annotation(Placement(visible=true, transformation(origin={-30,10}, extent={{-10,-10},{10,10}}, rotation=0)));
          Modelica.Electrical.Analog.Basic.Ground GroundT2 annotation(Placement(visible=true, transformation(origin={-20,-90}, extent={{-10,-10},{10,10}}, rotation=0)));
          Basic.Resistor RT1(m=m, R=fill(RT, m)) annotation(Placement(visible=true, transformation(origin={10,20}, extent={{-10,-10},{10,10}}, rotation=0)));
          Basic.Inductor LT1(m=m, L=fill(LT, m)) annotation(Placement(visible=true, transformation(origin={40,20}, extent={{-10,-10},{10,10}}, rotation=0)));
          Basic.Resistor RL1(m=m, R=fill(RL, m)) annotation(Placement(visible=true, transformation(origin={80,20}, extent={{-10,-10},{10,10}}, rotation=0)));
          Modelica.Electrical.Analog.Basic.Ground GroundT1 annotation(Placement(visible=true, transformation(origin={-40,-90}, extent={{-10,-10},{10,10}}, rotation=0)));
          Basic.Star StarT2(m=m) annotation(Placement(visible=true, transformation(origin={-20,-62.5}, extent={{-10,-10},{10,10}}, rotation=-90)));
          Basic.Star StarT1(m=m) annotation(Placement(visible=true, transformation(origin={-40,-62.5}, extent={{-10,-10},{10,10}}, rotation=-90)));
          Basic.Star StarS1(m=m) annotation(Placement(visible=true, transformation(origin={-90,-62.5}, extent={{-10,-10},{10,10}}, rotation=-90)));
          Basic.Star StarL1(m=m) annotation(Placement(visible=true, transformation(origin={90,-62.5}, extent={{-10,-10},{10,10}}, rotation=-90)));
        equation
          connect(LT1.plug_n,RL1.plug_p) annotation(Line(visible=true, points={{50,20},{70,20}}, color={0,0,255}));
          connect(RT1.plug_n,LT1.plug_p) annotation(Line(visible=true, points={{20,20},{30,20}}, color={0,0,255}));
          connect(IdealTransformer1.plug_p2,RT1.plug_p) annotation(Line(visible=true, points={{-20,20},{0,20}}, color={0,0,255}));
          connect(SineVoltage1.plug_p,IdealTransformer1.plug_p1) annotation(Line(visible=true, points={{-70,20},{-40,20}}, color={0,0,255}));
          connect(StarT2.pin_n,GroundT2.p) annotation(Line(visible=true, points={{-20,-72.5},{-20,-80}}, color={0,0,255}));
          connect(StarT2.plug_p,IdealTransformer1.plug_n2) annotation(Line(visible=true, points={{-20,-52.5},{-20,0}}, color={0,0,255}));
          connect(StarT1.pin_n,GroundT1.p) annotation(Line(visible=true, points={{-40,-72.5},{-40,-72},{-40,-80}}, color={0,0,255}));
          connect(IdealTransformer1.plug_n1,StarT1.plug_p) annotation(Line(visible=true, points={{-40,0},{-40,-52.5}}, color={0,0,255}));
          connect(StarS1.pin_n,GroundS1.p) annotation(Line(visible=true, points={{-90,-72.5},{-90,-80}}, color={0,0,255}));
          connect(StarS1.plug_p,SineVoltage1.plug_n) annotation(Line(visible=true, points={{-90,-52.5},{-90,20},{-90,20}}, color={0,0,255}));
          connect(RL1.plug_n,StarL1.plug_p) annotation(Line(visible=true, points={{90,20},{90,-52.5}}, color={0,0,255}));
        end TransformerYY;

      end Examples;

      package Ideal "Multiphase components with idealized behaviour"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains analog electrical multiphase components with idealized behaviour,
like thyristor, diode, switch, transformer.
</p>

</HTML>", revisions="<html>
<dl>
<p>
  <dt><b>Main Authors:</b></dt>
  <dd>
  <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
  Technical Consulting & Electrical Engineering<br>
  A-3423 St.Andrae-Woerdern<br>Austria<br>
  email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a>
  </dd>
</p>
<p>
  <dt><b>Release Notes:</b></dt>
  <dd>
  <ul>
  <li> v1.0 2004/10/01 Anton Haumer</li>
  </ul>
  </dd>
<p>
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,-40},{80,-40}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{20,-40},{-40,0},{-40,-80},{20,-40}}),Line(visible=true, points={{20,0},{20,-80}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model IdealTransformer "Multiphase ideal transformer"
          extends Interfaces.FourPlug;
          parameter Real n[m]=fill(1, m) "Turns ratio";
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-50},{-20,-25}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-25},{-20,0}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,0},{-20,25}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,25},{-20,50}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-72,-60},{-33,60}}),Line(visible=true, points={{-90,50},{-32,50}}, color={0,0,255}),Line(visible=true, points={{-90,-50},{-32,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-50},{45,-25}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-25},{45,0}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,0},{45,25}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,25},{45,50}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{33,-60},{72,60}}),Line(visible=true, points={{32,50},{90,50}}, color={0,0,255}),Line(visible=true, points={{32,-50},{90,-50}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, extent={{-80,60},{80,100}}, textString="m=%m", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{-100,-110},{100,-50}}, textString="%name", fontName="Arial")}), Documentation(info="<HTML>
<p>
Contains m ideal transformers (Modelica.Electrical.Analog.Ideal.IdealTransformer).
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Modelica.Electrical.Analog.Ideal.IdealTransformer idealTransformer[m](final n=n) annotation(Placement(visible=true, transformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          connect(plug_n2.pin,idealTransformer.n2) annotation(Line(visible=true, points={{100,-100},{10,-100},{10,-5}}, color={0,0,255}));
          connect(plug_n1.pin,idealTransformer.n1) annotation(Line(visible=true, points={{-100,-100},{-10,-100},{-10,-5}}, color={0,0,255}));
          connect(plug_p2.pin,idealTransformer.p2) annotation(Line(visible=true, points={{100,100},{10,100},{10,5}}, color={0,0,255}));
          connect(plug_p1.pin,idealTransformer.p1) annotation(Line(visible=true, points={{-100,100},{-10,100},{-10,5}}, color={0,0,255}));
        end IdealTransformer;

      end Ideal;

      package Interfaces "Interfaces for electrical multiphase models"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains connectors and interfaces (partial models) for
electrical multiphase components, based on Modelica.Electrical.Analog.
</p>

</HTML>", revisions="<html>
<dl>
<p>
  <dt><b>Main Authors:</b></dt>
  <dd>
  <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
  Technical Consulting & Electrical Engineering<br>
  A-3423 St.Andrae-Woerdern<br>Austria<br>
  email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a>
  </dd>
</p>
<p>
  <dt><b>Release Notes:</b></dt>
  <dd>
  <ul>
  <li> v1.0 2004/10/01 Anton Haumer</li>
  </ul>
  </dd>
<p>
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-60,-90},{40,10}}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-40,-34},{-20,-14}}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{0,-34},{20,-14}}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-20,-74},{0,-54}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        connector Plug "Plug with m pins for an electric component"
          parameter Integer m(final min=1)=3 "number of phases";
          annotation(Documentation(info="<HTML>
<p>
Connectors PositivePlug and NegativePlug are nearly identical.
The only difference is that the icons are different in order
to identify more easily the plugs of a component.
Usually, connector PositivePlug is used for the positive and
connector NegativePlug for the negative plug of an electrical component.<br>
Connector Plug is a composite connector containing m Pins (Modelica.Electrical.Analog.Interfaces.Pin).
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Modelica.Electrical.Analog.Interfaces.Pin pin[m] annotation(Placement(visible=true, transformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        end Plug;

        connector PositivePlug "Positive plug with m pins"
          extends Plug;
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{-100,-179},{100,-99}}, textString="%name", fontName="Arial")}), Documentation(info="<HTML>
<p>
Connectors PositivePlug and NegativePlug are nearly identical.
The only difference is that the icons are different in order
to identify more easily the plugs of a component.
Usually, connector PositivePlug is used for the positive and
connector NegativePlug for the negative plug of an electrical component.<br>
Connector Plug is a composite connector containing m Pins (Modelica.Electrical.Analog.Interfaces.Pin).
</p>
</HTML>"));
        end PositivePlug;

        connector NegativePlug "Negative plug with m pins"
          extends Plug;
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{-100,-180},{100,-100}}, textString="%name", fontName="Arial")}), Documentation(info="<HTML>
<p>
Connectors PositivePlug and NegativePlug are nearly identical.
The only difference is that the icons are different in order
to identify more easily the plugs of a component.
Usually, connector PositivePlug is used for the positive and
connector NegativePlug for the negative plug of an electrical component.<br>
Connector Plug is a composite connector containing m Pins (Modelica.Electrical.Analog.Interfaces.Pin).
</p>
</HTML>"));
        end NegativePlug;

        partial model TwoPlug "Component with one m-phase electric port"
          parameter Integer m(min=1)=3 "number of phases";
          Modelica.SIunits.Voltage v[m] "Voltage drops between the two plugs";
          Modelica.SIunits.Current i[m] "Currents flowing into positive plugs";
          annotation(Documentation(info="<HTML>
<p>
Superclass of elements which have <b>two</b> electrical plugs:
the positive plug connector <i>plug_p</i>, and the negative plug connector <i>plug_n</i>.
The currents flowing into plug_p are provided explicitly as currents i[m].
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          PositivePlug plug_p(final m=m) annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          NegativePlug plug_n(final m=m) annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          v=plug_p.pin.v - plug_n.pin.v;
          i=plug_p.pin.i;
        end TwoPlug;

        partial model FourPlug "Component with two m-phase electric ports"
          parameter Integer m(final min=1)=3 "number of phases";
          Modelica.SIunits.Voltage v1[m] "Voltage drops over the left port";
          Modelica.SIunits.Voltage v2[m] "Voltage drops over the right port";
          Modelica.SIunits.Current i1[m] "Current flowing into positive plug of the left port";
          Modelica.SIunits.Current i2[m] "Current flowing into positive plug of the right port";
          annotation(Documentation(info="<HTML>
<p>
Superclass of elements which have <b>four</b> electrical plugs.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          PositivePlug plug_p1(final m=m) annotation(Placement(visible=true, transformation(origin={-100,100}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,100}, extent={{-10,-10},{10,10}}, rotation=0)));
          PositivePlug plug_p2(final m=m) annotation(Placement(visible=true, transformation(origin={100,100}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,100}, extent={{-10,-10},{10,10}}, rotation=0)));
          NegativePlug plug_n1(final m=m) annotation(Placement(visible=true, transformation(origin={-100,-100}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,-100}, extent={{-10,-10},{10,10}}, rotation=0)));
          NegativePlug plug_n2(final m=m) annotation(Placement(visible=true, transformation(origin={100,-100}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,-100}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          v1=plug_p1.pin.v - plug_n1.pin.v;
          v2=plug_p2.pin.v - plug_n2.pin.v;
          i1=plug_p1.pin.i;
          i2=plug_p2.pin.i;
        end FourPlug;

      end Interfaces;

      package Sources "Multiphase voltage and current sources"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains time-dependend and controlled multiphase voltage and current sources:
<ul>
<li>SignalVoltage: fed by Modelica.Blocks.Sources arbitrary waveforms of voltages are possible</li>
<li>SineVoltage : phase shift between consecutive voltages by default <tt>= pi/m</tt></li>
<li>SignalCurrent: fed by Modelica.Blocks.Sources arbitrary waveforms of currents are possible</li>
<li>SineCurrent : phase shift between consecutive currents by default <tt>= pi/m</tt></li>
</ul>
</p>

</HTML>", revisions="<html>
<dl>
<p>
  <dt><b>Main Authors:</b></dt>
  <dd>
  <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
  Technical Consulting & Electrical Engineering<br>
  A-3423 St.Andrae-Woerdern<br>Austria<br>
  email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a>
  </dd>
</p>
<p>
  <dt><b>Release Notes:</b></dt>
  <dd>
  <ul>
  <li> v1.0 2004/10/01 Anton Haumer</li>
  </ul>
  </dd>
<p>
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,-40},{-60,-40}}, color={0,0,255}),Line(visible=true, points={{-60,-40},{40,-40}}, color={0,0,255}),Line(visible=true, points={{40,-40},{80,-40}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-60,-90},{40,10}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model SineVoltage "Multiphase sine voltage source"
          extends Interfaces.TwoPlug;
          parameter Modelica.SIunits.Voltage V[m]=fill(1, m) "Amplitudes of sine waves";
          parameter Modelica.SIunits.Angle phase[m]=-array((j - 1)/m*2*Modelica.Constants.pi for j in 1:m) "Phases of sine waves";
          parameter Modelica.SIunits.Frequency freqHz[m]=fill(1, m) "Frequencies of sine waves";
          parameter Modelica.SIunits.Voltage offset[m]=zeros(m) "Voltage offsets";
          parameter Modelica.SIunits.Time startTime[m]=zeros(m) "Time offsets";
          annotation(Documentation(info="<HTML>
<p>
Contains m sine voltage sources (Modelica.Electrical.Analog.Sources.SineVoltage)
with a default phase shift of -(j-1)/m * 2*pi for j in 1:m.
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{-50,0}}, color={0,0,255}),Line(visible=true, points={{50,0},{90,0}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-50,-50},{50,50}}),Line(visible=true, points={{-50,0},{50,0}}, color={0,0,255}),Line(visible=true, points={{-70,0},{-60.2,29.9},{-53.8,46.5},{-48.2,58.1},{-43.3,65.2},{-38.3,69.2},{-33.4,69.8},{-28.5,67},{-23.6,61},{-18.6,52},{-13,38.6},{-5.98,18.6},{8.79,-26.9},{15.1,-44},{20.8,-56.2},{25.7,-64},{30.6,-68.6},{35.5,-70},{40.5,-67.9},{45.4,-62.5},{50.3,-54.1},{55.9,-41.3},{63,-21.7},{70,0}}, color={192,192,192}, smooth=Smooth.Bezier),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,-110},{150,-50}}, textString="%name", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, extent={{-100,60},{100,100}}, textString="m=%m", fontName="Arial")}));
          Modelica.Electrical.Analog.Sources.SineVoltage sineVoltage[m](final V=V, final phase=phase, final freqHz=freqHz, final offset=offset, final startTime=startTime) annotation(Placement(visible=true, transformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          connect(sineVoltage.n,plug_n.pin) annotation(Line(visible=true, points={{10,0},{100,0}}, color={0,0,255}));
          connect(sineVoltage.p,plug_p.pin) annotation(Line(visible=true, points={{-10,0},{-100,0}}, color={0,0,255}));
        end SineVoltage;

      end Sources;

    end MultiPhase;

  end Electrical;

  package Blocks "Library for basic input/output control blocks (continuous, discrete, logical, table blocks)"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, extent={{-32,-35},{16,-6}}),Rectangle(visible=true, extent={{-32,-85},{16,-56}}),Line(visible=true, points={{16,-20},{49,-20},{49,-71},{16,-71}}),Line(visible=true, points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{16,-71},{29,-67},{29,-74},{16,-71}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-32,-21},{-46,-17},{-46,-25},{-32,-21}})}), Documentation(info="<html>
<p>
This library contains input/output blocks to build up block diagrams.
</p>

<dl>
<dt><b>Main Author:</b>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
    Oberpfaffenhofen<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
</dl>
<br>
<br>

<p>
Copyright &copy; 1998-2006, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</HTML>
", revisions="<html>
<ul>
<li><i>June 23, 2004</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Introduced new block connectors and adapated all blocks to the new connectors.
       Included subpackages Continuous, Discrete, Logical, Nonlinear from
       package ModelicaAdditions.Blocks.
       Included subpackage ModelicaAdditions.Table in Modelica.Blocks.Sources
       and in the new package Modelica.Blocks.Tables.
       Added new blocks to Blocks.Sources and Blocks.Logical.
       </li>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New subpackage Examples, additional components.
       </li>
<li><i>June 20, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
       Michael Tiller:<br>
       Introduced a replaceable signal type into
       Blocks.Interfaces.RealInput/RealOutput:
<pre>
   replaceable type SignalType = Real
</pre>
       in order that the type of the signal of an input/output block
       can be changed to a physical type, for example:
<pre>
   Sine sin1(outPort(redeclare type SignalType=Modelica.SIunits.Torque))
</pre>
      </li>
<li><i>Sept. 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Renamed to Blocks. New subpackages Math, Nonlinear.
       Additional components in subpackages Interfaces, Continuous
       and Sources. </li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    package Sources "Signal source blocks generating Real and Boolean signals"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
      extends Modelica.Icons.Library;
      annotation(preferedView="info", Documentation(info="<HTML>
<p>
This package contains <b>source</b> components, i.e., blocks which
have only output signals. These blocks are used as signal generators
for Real, Integer and Boolean signals.
</p>

<p>
All Real source signals (with the exception of the Constant source)
have at least the following two parameters:
</p>

<table border=1 cellspacing=0 cellpadding=2>
  <tr><td><b>offset</b></td>
      <td>Value which is added to the signal</td>
  </tr>
  <tr><td><b>startTime</b></td>
      <td>Start time of signal. For time &lt; startTime,
                the output y is set to offset.</td>
  </tr>
</table>

<p>
The <b>offset</b> parameter is especially useful in order to shift
the corresponding source, such that at initial time the system
is stationary. To determine the corresponding value of offset,
usually requires a trimming calculation.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Integer sources added. Step, TimeTable and BooleanStep slightly changed.</li>
<li><i>Nov. 8, 1999</i>
       by <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
       <A HREF=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</A>,
       <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
       (nperiod=-1 is an infinite number of periods).</li>
<li><i>Oct. 31, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
       <A HREF=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</A>,
       All sources vectorized. New sources: ExpSine, Trapezoid,
       BooleanConstant, BooleanStep, BooleanPulse, SampleTrigger.
       Improved documentation, especially detailed description of
       signals in diagram layer.</li>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{0,0},{430,-442}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      block Sine "Generate sine signal"
        parameter Real amplitude=1 "Amplitude of sine wave";
        parameter SIunits.Frequency freqHz=1 "Frequency of sine wave";
        parameter SIunits.Angle phase=0 "Phase of sine wave";
        parameter Real offset=0 "Offset of output signal";
        parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
        extends Interfaces.SO;
        annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-90},{-80,84}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,100},{-86,84},{-74,84},{-80,100}}),Line(visible=true, points={{-99,-40},{85,-40}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{101,-40},{85,-34},{85,-46},{101,-40}}),Line(visible=true, points={{-40,0},{-31.6,34.2},{-26.1,53.1},{-21.3,66.4},{-17.1,74.6},{-12.9,79.1},{-8.64,79.8},{-4.42,76.6},{-0.2,69.7},{4.02,59.4},{8.84,44.1},{14.9,21.2},{27.5,-30.8},{33,-50.2},{37.8,-64.2},{42,-73.1},{46.2,-78.4},{50.5,-80},{54.7,-77.6},{58.9,-71.5},{63.1,-61.9},{67.9,-47.2},{74,-24.8},{80,0}}, thickness=0.5, smooth=Smooth.Bezier),Line(visible=true, points={{-41,-2},{-80,-2}}, thickness=0.5),Text(visible=true, fillColor={160,160,160}, extent={{-128,-11},{-82,7}}, textString="offset", fontName="Arial"),Line(visible=true, points={{-41,-2},{-41,-40}}, color={192,192,192}, pattern=LinePattern.Dot),Text(visible=true, fillColor={160,160,160}, extent={{-60,-61},{-14,-43}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{84,-72},{108,-52}}, textString="time", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-74,86},{-33,106}}, textString="y", fontName="Arial"),Line(visible=true, points={{-9,79},{43,79}}, color={192,192,192}, pattern=LinePattern.Dot),Line(visible=true, points={{-42,-1},{50,0}}, color={192,192,192}, pattern=LinePattern.Dot),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{33,80},{30,67},{37,67},{33,80}}),Text(visible=true, fillColor={160,160,160}, extent={{37,39},{83,57}}, textString="amplitude", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{33,1},{30,14},{36,14},{33,1},{33,1}}),Line(visible=true, points={{33,79},{33,0}}, color={192,192,192})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-147,-152},{153,-112}}, textString="freqHz=%freqHz", fontName="Arial")}));
      protected
        constant Real pi=Modelica.Constants.pi;
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-90,0},{68,0}}, color={192,192,192}),Polygon(points={{90,0},{68,8},{68,-8},{90,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, color={0,0,0}),Text(extent={{-147,-152},{153,-112}}, textString="freqHz=%freqHz", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,-90},{-80,84}}, color={192,192,192}),Polygon(points={{-80,100},{-86,84},{-74,84},{-80,100}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-99,-40},{85,-40}}, color={192,192,192}),Polygon(points={{101,-40},{85,-34},{85,-46},{101,-40}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-40,0},{-31.6,34.2},{-26.1,53.1},{-21.3,66.4},{-17.1,74.6},{-12.9,79.1},{-8.64,79.8},{-4.42,76.6},{-0.201,69.7},{4.02,59.4},{8.84,44.1},{14.9,21.2},{27.5,-30.8},{33,-50.2},{37.8,-64.2},{42,-73.1},{46.2,-78.4},{50.5,-80},{54.7,-77.6},{58.9,-71.5},{63.1,-61.9},{67.9,-47.2},{74,-24.8},{80,0}}, color={0,0,0}, thickness=0.5),Line(points={{-41,-2},{-80,-2}}, color={0,0,0}, thickness=0.5),Text(extent={{-128,7},{-82,-11}}, textString="offset", fillColor={160,160,160}),Line(points={{-41,-2},{-41,-40}}, color={192,192,192}, pattern=LinePattern.Dash),Text(extent={{-60,-43},{-14,-61}}, textString="startTime", fillColor={160,160,160}),Text(extent={{84,-52},{108,-72}}, textString="time", fillColor={160,160,160}),Text(extent={{-74,106},{-33,86}}, textString="y", fillColor={160,160,160}),Line(points={{-9,79},{43,79}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-42,-1},{50,0}}, color={192,192,192}, pattern=LinePattern.Dash),Polygon(points={{33,80},{30,67},{37,67},{33,80}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{37,57},{83,39}}, textString="amplitude", fillColor={160,160,160}),Polygon(points={{33,1},{30,14},{36,14},{33,1},{33,1}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{33,79},{33,0}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None})}), Documentation(info="<html>

</html>"));
      equation
        y=offset + (if time < startTime then 0 else amplitude*Modelica.Math.sin(2*pi*freqHz*(time - startTime) + phase));
      end Sine;

    end Sources;

    package Interfaces "Connectors and partial models for input/output blocks"
      import Modelica.SIunits;
      extends Modelica.Icons.Library;
      annotation(preferedView="info", Documentation(info="<HTML>
<p>
This package contains interface definitions for
<b>continuous</b> input/output blocks with Real,
Integer and Boolean signals. Furthermore, it contains
partial models for continuous and discrete blocks.
</p>

</HTML>
", revisions="<html>
<ul>
<li><i>Oct. 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Added several new interfaces. <a href=\"../Documentation/ChangeNotes1.5.html\">Detailed description</a> available.
<li><i>Oct. 24, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       RealInputSignal renamed to RealInput. RealOutputSignal renamed to
       output RealOutput. GraphBlock renamed to BlockIcon. SISOreal renamed to
       SISO. SOreal renamed to SO. I2SOreal renamed to M2SO.
       SignalGenerator renamed to SignalSource. Introduced the following
       new models: MIMO, MIMOs, SVcontrol, MVcontrol, DiscreteBlockIcon,
       DiscreteBlock, DiscreteSISO, DiscreteMIMO, DiscreteMIMOs,
       BooleanBlockIcon, BooleanSISO, BooleanSignalSource, MI2BooleanMOs.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{0,0},{733,-491}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      connector RealSignal "Real port (both input/output possible)"
        replaceable type SignalType= Real annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        extends SignalType;
        annotation(Documentation(info="<html>
<p>
Connector with one signal of type Real (no icon, no input/output prefix).
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end RealSignal;

      connector RealOutput= output RealSignal "'output Real' as connector" annotation(defaultComponentName="y", Documentation(info="<html>
<p>
Connector with one output signal of type Real.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,100},{100,0},{-100,-100},{-100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,50},{0,0},{-100,-50},{-100,50}}),Text(visible=true, fillColor={0,0,127}, extent={{-100,60},{130,140}}, textString="%name", fontName="Arial")}));
      partial block BlockIcon "Basic graphical layout of input/output block"
        annotation(Documentation(info="<html>
<p>
Block that has only the basic icon for an input/output
block (no declarations, no equations). Most blocks
of package Modelica.Blocks inherit directly or indirectly
from this block.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,110},{150,150}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end BlockIcon;

      partial block SO "Single Output continuous control block"
        extends BlockIcon;
        annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>
<p>
Block has one continuous Real output signal.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        RealOutput y "Connector of Real output signal" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
      end SO;

      partial block SignalSource "Base class for continuous signal source"
        extends SO;
        parameter Real offset=0 "offset of output signal";
        parameter SIunits.Time startTime=0 "output = offset for time < startTime";
        annotation(Documentation(info="<html>
<p>
Basic block for Real sources of package Blocks.Sources.
This component has one continuous Real output signal y
and two parameters (offset, startTime) to shift the
generated signal.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end SignalSource;

    end Interfaces;

  end Blocks;

  package SIunits "Type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Invisible=true, Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-63,-67},{45,-13}}, textString="[kg.m2]", fontName="Arial")}), Documentation(info="<html>
<p>This package provides predefined types, such as <i>Mass</i>,
<i>Angle</i>, <i>Time</i>, based on the international standard
on units, e.g.,
</p>

<pre>   <b>type</b> Angle = Real(<b>final</b> quantity = \"Angle\",
                     <b>final</b> unit     = \"rad\",
                     displayUnit    = \"deg\");
</pre>

<p>
as well as conversion functions from non SI-units to SI-units
and vice versa in subpackage
<a href=\"Modelica://Modelica.SIunits.Conversions\">Conversions</a>.
</p>

<p>
For an introduction how units are used in the Modelica standard library
with package SIunits, have a look at:
<a href=\"Modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
</p>

<p>
Copyright &copy; 1998-2006, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p>

</html>", revisions="<html>
<ul>
<li><i>Dec. 14, 2005</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Add users guide and removed \"min\" values for Resistance and Conductance.</li>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
<li><i>June 6, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Introduced the following new types<br>
       type Temperature = ThermodynamicTemperature;<br>
       types DerDensityByEnthalpy, DerDensityByPressure,
       DerDensityByTemperature, DerEnthalpyByPressure,
       DerEnergyByDensity, DerEnergyByPressure<br>
       Attribute \"final\" removed from min and max values
       in order that these values can still be changed to narrow
       the allowed range of values.<br>
       Quantity=\"Stress\" removed from type \"Stress\", in order
       that a type \"Stress\" can be connected to a type \"Pressure\".</li>
<li><i>Oct. 27, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New types due to electrical library: Transconductance, InversePotential,
       Damping.</li>
<li><i>Sept. 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Renamed from SIunit to SIunits. Subpackages expanded, i.e., the
       SIunits package, does no longer contain subpackages.</li>
<li><i>Aug 12, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Type \"Pressure\" renamed to \"AbsolutePressure\" and introduced a new
       type \"Pressure\" which does not contain a minimum of zero in order
       to allow convenient handling of relative pressure. Redefined
       BulkModulus as an alias to AbsolutePressure instead of Stress, since
       needed in hydraulics.</li>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Bug-fix: Double definition of \"Compressibility\" removed
       and appropriate \"extends Heat\" clause introduced in
       package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
<li><i>April 8, 1998</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and Astrid Jaschinski:<br>
       Complete ISO 31 chapters realized.</li>
<li><i>Nov. 15, 1997</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>:<br>
       Some chapters realized.</li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{169,86},{349,236}}),Polygon(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{169,236},{189,256},{369,256},{349,236},{169,236}}),Polygon(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{369,256},{369,106},{349,86},{349,236},{369,256}}),Text(visible=true, fillColor={160,160,160}, extent={{179,196},{339,226}}, textString="Library", fontName="Arial"),Text(visible=true, extent={{206,119},{314,173}}, textString="[kg.m2]", fontName="Arial"),Text(visible=true, fillColor={255,0,0}, extent={{163,264},{406,320}}, textString="Modelica.SIunits", fontName="Arial")}));
    package Conversions "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Library2;
      annotation(preferedView="info", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, lineThickness=1, extent={{-92,-67},{-33,-7}}, textString="°C", fontName="Arial"),Text(visible=true, extent={{22,-67},{82,-7}}, textString="K", fontName="Arial"),Line(visible=true, points={{-26,-36},{6,-36}}),Polygon(visible=true, pattern=LinePattern.None, fillPattern=FillPattern.Solid, points={{6,-28},{6,-45},{26,-37},{6,-28}})}), Documentation(info="<HTML>
<p>This package provides conversion functions from the non SI Units
defined in package Modelica.SIunits.Conversions.NonSIunits to the
corresponding SI Units defined in package Modelica.SIunits and vice
versa. It is recommended to use these functions in the following
way (note, that all functions have one Real input and one Real output
argument):</p>
<pre>
  <b>import</b> SI = Modelica.SIunits;
  <b>import</b> Modelica.SIunits.Conversions.*;
     ...
  <b>parameter</b> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
  <b>parameter</b> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
  <b>parameter</b> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                      // to radian per seconds
</pre>

</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Library2;
        type Temperature_degC= Real(final quantity="ThermodynamicTemperature", final unit="degC") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        annotation(preferedView="info", Documentation(info="<HTML>
<p>
This package provides predefined types, such as <b>Angle_deg</b> (angle in
degree), <b>AngularVelocity_rpm</b> (angular velocity in revolutions per
minute) or <b>Temperature_degF</b> (temperature in degree Fahrenheit),
which are in common use but are not part of the international standard on
units according to ISO 31-1992 \"General principles concerning quantities,
units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
the use of their multiples and of certain other units\".</p>
<p>If possible, the types in this package should not be used. Use instead
types of package Modelica.SIunits. For more information on units, see also
the book of Francois Cardarelli <b>Scientific Unit Conversion - A
Practical Guide to Metrication</b> (Springer 1997).</p>
<p>Some units, such as <b>Temperature_degC/Temp_C</b> are both defined in
Modelica.SIunits and in Modelica.Conversions.NonSIunits. The reason is that these
definitions have been placed erroneously in Modelica.SIunits although they
are not SIunits. For backward compatibility, these type definitions are
still kept in Modelica.SIunits.</p>
</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-66,-67},{52,-13}}, textString="[rev/min]", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end NonSIunits;

    end Conversions;

    type Angle= Real(final quantity="Angle", final unit="rad", displayUnit="deg") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Time= Real(final quantity="Time", final unit="s") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Velocity= Real(final quantity="Velocity", final unit="m/s") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Acceleration= Real(final quantity="Acceleration", final unit="m/s2") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Frequency= Real(final quantity="Frequency", final unit="Hz") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type ElectricCurrent= Real(final quantity="ElectricCurrent", final unit="A") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Current= ElectricCurrent annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type ElectricPotential= Real(final quantity="ElectricPotential", final unit="V") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Voltage= ElectricPotential annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Inductance= Real(final quantity="Inductance", final unit="H") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Resistance= Real(final quantity="Resistance", final unit="Ohm") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    defineunit m;
    defineunit kg;
    defineunit s;
    defineunit A;
    defineunit K;
    defineunit mol;
    defineunit cd;
    defineunit rad (exp="m/m");
    defineunit sr (exp="m2/m2");
    defineunit Hz (exp="s-1", weight=0.8);
    defineunit N (exp="m.kg.s-2");
    defineunit Pa (exp="N/m2");
    defineunit W (exp="J/s");
    defineunit J (exp="N.m");
    defineunit C (exp="s.A");
    defineunit V (exp="W/A");
    defineunit F (exp="C/V");
    defineunit Ohm (exp="V/A");
    defineunit S (exp="A/V");
    defineunit Wb (exp="V.s");
    defineunit S (exp="A/V");
    defineunit Wb (exp="V.s");
    defineunit T (exp="Wb/m2");
    defineunit H (exp="Wb/A");
    defineunit lm (exp="cd.sr");
    defineunit lx (exp="lm/m2");
    defineunit Bq (exp="s-1");
    defineunit Gy (exp="J/kg");
    defineunit Sv (exp="J/kg");
    defineunit kat (exp="s-1.mol");
  end SIunits;

  package Icons "Icon definitions"
    annotation(preferedView="info", Documentation(info="<html>
<p>
This package contains definitions for the graphical layout of
components which may be used in different libraries.
The icons can be utilized by inheriting them in the desired class
using \"extends\".
</p>
<dl>
<dt><b>Main Author:</b>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)<br>
    Oberpfaffenhofen<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
</dl>

<p>
Copyright &copy; 1998-2006, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</HTML>
", revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Added new icons <b>Function</b>, <b>Enumerations</b> and <b>Record</b>.</li>
<li><i>June 6, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Replaced <b>model</b> keyword by <b>package</b> if the main
       usage is for inheriting from a package.<br>
       New icons <b>GearIcon</b> and <b>MotorIcon</b>.</li>
<li><i>Sept. 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Renaming package Icon to Icons.
       Model Advanced removed (icon not accepted on the Modelica meeting).
       New model Library2, which is the Library icon with enough place
       to add library specific elements in the icon. Icon also used in diagram
       level for models Info, TranslationalSensor, RotationalSensor.</li>
<li><i>July 15, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Model Caution renamed to Advanced, model Sensor renamed to
       TranslationalSensor, new model RotationalSensor.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version.</li>
</ul>
<br>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-100,-100},{80,50}}),Polygon(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}),Polygon(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}),Text(visible=true, fillColor={255,0,0}, extent={{-120,70},{120,135}}, textString="%name", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-90,10},{70,40}}, textString="Library", fontName="Arial"),Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-100,-100},{80,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}),Text(visible=true, fillColor={160,160,160}, extent={{-90,10},{70,40}}, textString="Library", fontName="Arial"),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-64,-20},{-50,-4},{50,-4},{36,-20},{-64,-20},{-64,-20}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-64,-84},{36,-20}}),Text(visible=true, fillColor={128,128,128}, extent={{-60,-38},{32,-24}}, textString="Library", fontName="Arial"),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,-4},{50,-70},{36,-84},{36,-20},{50,-4}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    partial package Library "Icon for library"
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-100,-100},{80,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}),Text(visible=true, fillColor={0,0,255}, extent={{-85,-85},{65,35}}, textString="Library", fontName="Arial"),Text(visible=true, fillColor={255,0,0}, extent={{-120,73},{120,122}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Library;

    partial package Library2 "Icon for library where additional icon elements shall be added"
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-100,-100},{80,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}),Text(visible=true, fillColor={255,0,0}, extent={{-120,70},{120,125}}, textString="%name", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, fillPattern=FillPattern.Solid, extent={{-90,10},{70,40}}, textString="Library", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Library2;

    partial model Example "Icon for an example model"
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{80,50}}),Polygon(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}),Polygon(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-85,-85},{65,35}}, textString="Example", fontName="Arial"),Text(visible=true, fillColor={255,0,0}, extent={{-120,73},{120,132}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Example;

  end Icons;

  package Constants "Mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Library2;
    constant Real e=Modelica.Math.exp(1.0);
    constant Real pi=2*Modelica.Math.asin(1.0);
    constant Real D2R=pi/180 "Degree to Radian";
    constant Real R2D=180/pi "Radian to Degree";
    constant Real eps=1e-15 "Biggest number such that 1.0 + eps = 1.0";
    constant Real small=1e-60 "Smallest number such that small and -small are representable on the machine";
    constant Real inf=1e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    constant Integer Integer_inf=1073741823 "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    constant SI.Velocity c=299792458 "Speed of light in vacuum";
    constant SI.Acceleration g_n=9.80665 "Standard acceleration of gravity on earth";
    constant Real G(final unit="m3/(kg.s2)")=6.6742e-11 "Newtonian constant of gravitation";
    constant Real h(final unit="J.s")=6.6260693e-34 "Planck constant";
    constant Real k(final unit="J/K")=1.3806505e-23 "Boltzmann constant";
    constant Real R(final unit="J/(mol.K)")=8.314472 "Molar gas constant";
    constant Real sigma(final unit="W/(m2.K4)")=5.6704e-08 "Stefan-Boltzmann constant";
    constant Real N_A(final unit="1/mol")=6.0221415e+23 "Avogadro constant";
    constant Real mue_0(final unit="N/A2")=4*pi*1e-07 "Magnetic constant";
    constant Real epsilon_0(final unit="F/m")=1/(mue_0*c*c) "Electric constant";
    constant NonSI.Temperature_degC T_zero=-273.15 "Absolute zero temperature";
    annotation(Documentation(info="<html>
<p>
This package provides often needed constants from mathematics, machine
dependent constants and constants from nature. The latter constants
(name, value, description) are from the following source:
</p>

<dl>
<dt>Peter J. Mohr and Barry N. Taylor (1999):</dt>
<dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 1998</b>.
    Journal of Physical and Chemical Reference Data, Vol. 28, No. 6, 1999 and
    Reviews of Modern Physics, Vol. 72, No. 2, 2000. See also <a href=
\"http://physics.nist.gov/cuu/Constants/\">http://physics.nist.gov/cuu/Constants/</a></dd>
</dl>

<p>CODATA is the Committee on Data for Science and Technology.</p>

<dl>
<dt><b>Main Author:</b></dt>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
    Oberpfaffenhofen<br>
    Postfach 11 16<br>
    D-82230 We&szlig;ling<br>
    email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
</dl>


<p>
Copyright &copy; 1998-2006, Modelica Association and DLR.
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</html>
", revisions="<html>
<ul>
<li><i>Nov 8, 2004</i>
       by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Constants updated according to 2002 CODATA values.</li>
<li><i>Dec 9, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Constants updated according to 1998 CODATA values. Using names, values
       and description text from this source. Included magnetic and
       electric constant.</li>
<li><i>Sep 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Constants eps, inf, small introduced.</li>
<li><i>Nov 15, 1997</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-34,-38},{12,-38}}, thickness=0.5),Line(visible=true, points={{-20,-38},{-24,-48},{-28,-56},{-34,-64}}, thickness=0.5),Line(visible=true, points={{-2,-38},{2,-46},{8,-56},{14,-64}}, thickness=0.5)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  end Constants;

end Modelica;
model Modelica_Electrical_MultiPhase_Examples_TransformerYY
  extends Modelica.Electrical.MultiPhase.Examples.TransformerYY;
end Modelica_Electrical_MultiPhase_Examples_TransformerYY;
