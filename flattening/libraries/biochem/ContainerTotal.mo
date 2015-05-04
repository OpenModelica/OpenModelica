package Modelica "Modelica Standard Library (Version 3.1)"
  extends Modelica.Icons.Library;
  annotation(preferredView="info", version="3.1", versionBuild=5, versionDate="2009-08-14", dateModified="2009-12-18 08:49:49Z", revisionId="$Id:: package.mo 3222 2009-12-18 08:53:50Z #$", conversion(noneFromVersion="3.0.1", noneFromVersion="3.0", from(version="2.1", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version="2.2", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version="2.2.1", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version="2.2.2", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos")), __Dymola_classOrder={"UsersGuide","Blocks","StateGraph","Electrical","Magnetic","Mechanics","Fluid","Media","Thermal","Math","Utilities","Constants","Icons","SIunits"}, Settings(NewStateSelection=true), Documentation(info="<HTML>
<p>
Package <b>Modelica</b> is a <b>standardized</b> and <b>free</b> package
that is developed together with the Modelica language from the
Modelica Association, see
<a href=\"http://www.Modelica.org\">http://www.Modelica.org</a>.
It is also called <b>Modelica Standard Library</b>.
It provides model components in many domains that are based on
standardized interface definitions. Some typical examples are shown
in the next figure:
</p>

<p>
<img src=\"../Images/UsersGuide/ModelicaLibraries.png\">
</p>

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"Modelica://Modelica.UsersGuide.Overview\">Overview</a>
  provides an overview of the Modelica Standard Library
  inside the <a href=\"Modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
<li><a href=\"Modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
 summarizes the changes of new versions of this package.</li>
<li> <a href=\"Modelica://Modelica.UsersGuide.Contact\">Contact</a>
  lists the contributors of the Modelica Standard Library.</li>
<li> The <b>Examples</b> packages in the various libraries, demonstrate
  how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
This version of the Modelica Standard Library consists of
</p>
<ul>
<li> <b>922</b> models and blocks, and</li>
<li> <b>615</b> functions
</ul>
<p>
that are directly usable (= number of public, non-partial classes).
</p>


<p>
<b>Licensed by the Modelica Association under the Modelica License 2</b><br>
Copyright &copy; 1998-2009, ABB, arsenal research, T.&nbsp;Bödrich, DLR, Dynasim, Fraunhofer, Modelon,
TU Hamburg-Harburg, Politecnico di Milano.
</p>

<p>
<i>This Modelica package is <u>free</u> software and
the use is completely at <u>your own risk</u>;
it can be redistributed and/or modified under the terms of the
Modelica license 2, see the license conditions (including the
disclaimer of warranty)
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense2\">here</a></u>
or at
<a href=\"http://www.Modelica.org/licenses/ModelicaLicense2\">
http://www.Modelica.org/licenses/ModelicaLicense2</a>.
</p>

</HTML>
"));
  package Math "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Library2;
    function asin "Inverse sine (-1 <= u <= 1)"
      extends baseIcon2;
      input Real u;
      output SI.Angle y;

      external "C" y=asin(u) ;
      annotation(Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}, grid={2,2}), graphics={Line(points={{-90,0},{68,0}}, color={192,192,192}),Polygon(points={{90,0},{68,8},{68,-8},{90,0}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, color={0,0,0}),Text(extent={{-88,78},{-16,30}}, lineColor={192,192,192}, textString="asin")}), Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}, grid={2,2}), graphics={Text(extent={{-40,-72},{-15,-88}}, textString="-pi/2", lineColor={0,0,255}),Text(extent={{-38,88},{-13,72}}, textString=" pi/2", lineColor={0,0,255}),Text(extent={{68,-9},{88,-29}}, textString="+1", lineColor={0,0,255}),Text(extent={{-90,21},{-70,1}}, textString="-1", lineColor={0,0,255}),Line(points={{-100,0},{84,0}}, color={95,95,95}),Polygon(points={{98,0},{82,6},{82,-6},{98,0}}, lineColor={95,95,95}, fillColor={95,95,95}, fillPattern=FillPattern.Solid),Line(points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, color={0,0,255}, thickness=0.5),Text(extent={{82,24},{102,4}}, lineColor={95,95,95}, textString="u"),Line(points={{0,80},{86,80}}, color={175,175,175}, smooth=Smooth.None),Line(points={{80,86},{80,-10}}, color={175,175,175}, smooth=Smooth.None)}), Documentation(info="<html>
<p>
This function returns y = asin(u), with -1 &le; u &le; +1:
</p>

<p>
<img src=\"../Images/Math/asin.png\">
</p>
</html>"), Library="ModelicaExternalC");
    end asin;

    function exp "Exponential, base e"
      extends baseIcon2;
      input Real u;
      output Real y;

      external "C" y=exp(u) ;
      annotation(Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}, grid={2,2}), graphics={Line(points={{-90,-80.3976},{68,-80.3976}}, color={192,192,192}),Polygon(points={{90,-80.3976},{68,-72.3976},{68,-88.3976},{90,-80.3976}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-80,-80},{-31,-77.9},{-6.03,-74},{10.9,-68.4},{23.7,-61},{34.2,-51.6},{43,-40.3},{50.3,-27.8},{56.7,-13.5},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, color={0,0,0}),Text(extent={{-86,50},{-14,2}}, lineColor={192,192,192}, textString="exp")}), Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}, grid={2,2}), graphics={Line(points={{-100,-80.3976},{84,-80.3976}}, color={95,95,95}),Polygon(points={{98,-80.3976},{82,-74.3976},{82,-86.3976},{98,-80.3976}}, lineColor={95,95,95}, fillColor={95,95,95}, fillPattern=FillPattern.Solid),Line(points={{-80,-80},{-31,-77.9},{-6.03,-74},{10.9,-68.4},{23.7,-61},{34.2,-51.6},{43,-40.3},{50.3,-27.8},{56.7,-13.5},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, color={0,0,255}, thickness=0.5),Text(extent={{-31,72},{-11,88}}, textString="20", lineColor={0,0,255}),Text(extent={{-92,-81},{-72,-101}}, textString="-3", lineColor={0,0,255}),Text(extent={{66,-81},{86,-101}}, textString="3", lineColor={0,0,255}),Text(extent={{2,-69},{22,-89}}, textString="1", lineColor={0,0,255}),Text(extent={{78,-54},{98,-74}}, lineColor={95,95,95}, textString="u"),Line(points={{0,80},{88,80}}, color={175,175,175}, smooth=Smooth.None),Line(points={{80,84},{80,-84}}, color={175,175,175}, smooth=Smooth.None)}), Documentation(info="<html>
<p>
This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
</p>

<p>
<img src=\"../Images/Math/exp.png\">
</p>
</html>"), Library="ModelicaExternalC");
    end exp;

    partial function baseIcon2 "Basic icon for mathematical function with y-axis in middle"
      annotation(Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,100},{100,-100}}, lineColor={0,0,0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid),Line(points={{0,-80},{0,68}}, color={192,192,192}),Polygon(points={{0,90},{-8,68},{8,68},{0,90}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{-150,150},{150,110}}, textString="%name", lineColor={0,0,255})}), Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={Line(points={{0,80},{-8,80}}, color={95,95,95}),Line(points={{0,-80},{-8,-80}}, color={95,95,95}),Line(points={{0,-90},{0,84}}, color={95,95,95}),Text(extent={{5,104},{25,84}}, lineColor={95,95,95}, textString="y"),Polygon(points={{0,98},{-6,82},{6,82},{0,98}}, lineColor={95,95,95}, fillColor={95,95,95}, fillPattern=FillPattern.Solid)}), Documentation(revisions="<html>
<p>
Icon for a mathematical function, consisting of an y-axis in the middle.
It is expected, that an x-axis is added and a plot of the function.
</p>
</html>"));
    end baseIcon2;

    annotation(Invisible=true, Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={Text(extent={{-59,-9},{42,-56}}, lineColor={0,0,0}, textString="f(x)")}), Documentation(info="<HTML>
<p>
This package contains <b>basic mathematical functions</b> (such as sin(..)),
as well as functions operating on <b>vectors</b> and <b>matrices</b>.
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
Copyright &copy; 1998-2009, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense2\">here</a>.</i>
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

</html>"));
  end Math;

  package SIunits "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Library2;
    package Conversions "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Library2;
      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Library2;
        type Volume_litre= Real(final quantity="Volume", final unit="l") "Volume in litres";
        annotation(Documentation(info="<HTML>
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
"), Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={Text(extent={{-66,-13},{52,-67}}, lineColor={0,0,0}, textString="[km/h]")}));
      end NonSIunits;

      annotation(Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={Text(extent={{-33,-7},{-92,-67}}, lineColor={0,0,0}, lineThickness=1, textString="°C"),Text(extent={{82,-7},{22,-67}}, lineColor={0,0,0}, textString="K"),Line(points={{-26,-36},{6,-36}}, color={0,0,0}),Polygon(points={{6,-28},{6,-45},{26,-37},{6,-28}}, pattern=LinePattern.None, fillColor={0,0,0}, fillPattern=FillPattern.Solid, lineColor={0,0,255})}), Documentation(info="<HTML>
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
"));
    end Conversions;

    type Angle= Real(final quantity="Angle", final unit="rad", displayUnit="deg");
    annotation(Invisible=true, Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={Text(extent={{-63,-13},{45,-67}}, lineColor={0,0,0}, textString="[kg.m2]")}), Documentation(info="<html>
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
Copyright &copy; 1998-2009, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense2\">here</a>.</i>
</p>

</html>", revisions="<html>
<ul>
<li><i>Dec. 14, 2005</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Add User's Guide and removed \"min\" values for Resistance and Conductance.</li>
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
</html>"), Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{169,86},{349,236}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{169,236},{189,256},{369,256},{349,236},{169,236}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{369,256},{369,106},{349,86},{349,236},{369,256}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Text(extent={{179,226},{339,196}}, lineColor={160,160,164}, textString="Library"),Text(extent={{206,173},{314,119}}, lineColor={0,0,0}, textString="[kg.m2]"),Text(extent={{163,320},{406,264}}, lineColor={255,0,0}, textString="Modelica.SIunits")}));
  end SIunits;

  package Icons "Library of icons"
    partial package Library "Icon for library"
      annotation(Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}, grid={1,1}), graphics={Rectangle(extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Text(extent={{-85,35},{65,-85}}, lineColor={0,0,255}, textString="Library"),Text(extent={{-120,122},{120,73}}, lineColor={255,0,0}, textString="%name")}), Documentation(info="<html>
<p>
This icon is designed for a <b>library</b>.
</p>
</html>"));
    end Library;

    partial package Library2 "Icon for library where additional icon elements shall be added"
      annotation(Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}, grid={1,1}), graphics={Rectangle(extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Text(extent={{-120,125},{120,70}}, lineColor={255,0,0}, textString="%name"),Text(extent={{-90,40},{70,10}}, lineColor={160,160,164}, textString="Library")}), Documentation(info="<html>
<p>
This icon is designed for a <b>package</b> where a package
specific graphic is additionally included in the icon.
</p>
</html>"));
    end Library2;

    annotation(Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Text(extent={{-120,135},{120,70}}, lineColor={255,0,0}, textString="%name"),Text(extent={{-90,40},{70,10}}, lineColor={160,160,164}, textString="Library"),Rectangle(extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Polygon(points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, lineColor={0,0,255}),Text(extent={{-90,40},{70,10}}, lineColor={160,160,164}, textString="Library"),Polygon(points={{-64,-20},{-50,-4},{50,-4},{36,-20},{-64,-20},{-64,-20}}, lineColor={0,0,0}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Rectangle(extent={{-64,-20},{36,-84}}, lineColor={0,0,0}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{-60,-24},{32,-38}}, lineColor={128,128,128}, textString="Library"),Polygon(points={{50,-4},{50,-70},{36,-84},{36,-20},{50,-4}}, lineColor={0,0,0}, fillColor={192,192,192}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p>
This package contains definitions for the graphical layout of
components which may be used in different libraries.
The icons can be utilized by inheriting them in the desired class
using \"extends\" or by directly copying the \"icon\" layer.
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
Copyright &copy; 1998-2009, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense2\">here</a>.</i>
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
</html>"));
  end Icons;

end Modelica;
package BioChem
  extends Icons.Library;
  annotation(uses(Modelica(version="2.2.1")), version="1.0", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={3.55271e-15,3.76}, points={{-50,-60},{-50,-27.52},{10,-27.52}}, smooth=Smooth.Bezier),Line(visible=true, origin={-1.135,4.09474}, points={{-48.865,10},{-48.865,-27.61},{11.135,-27.61}}, arrow={Arrow.None,Arrow.Open}, arrowSize=30, smooth=Smooth.Bezier),Ellipse(visible=true, origin={30.4112,-23.4648}, lineColor={0,85,0}, fillColor={0,170,0}, fillPattern=FillPattern.Sphere, extent={{-20.4112,-20},{20.4112,20}}),Ellipse(visible=true, origin={6.28735,-0.665395}, lineColor={161,107,0}, fillColor={250,167,0}, fillPattern=FillPattern.Sphere, extent={{-76.2873,-79.3346},{-35.4736,-39.3346}}),Ellipse(visible=true, origin={4.98569,-1.03187}, lineColor={117,0,0}, fillColor={170,0,0}, fillPattern=FillPattern.Sphere, extent={{-75.8122,-6.13331},{-34.9857,33.8667}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  annotation(preferedView="info", Documentation(info="<html>


<h1>About the BioChem Library</h1>
<p>
 BioChem is a package for biochemical modeling and simulation with Modelica.
</p>

 <h2>Basic idea of the library</h2>
 <p>
 The design idea behind the <em>BioChem</em> library is to create a general purpose Modelica library
for modeling, simulation and visualization of biological and biochemical systems.
The classes implemented in the BioChem library describe substances and reactions that can
take place in-between these substances in a diverse number of biochemical pathways.
</p>

<br>
<img src=\"Images/Library.png\" ><caption> Packages in the library </caption>
<br>

 <h2>Library Structure</h2>
 <p>
 Since the design objective for <em>BioChem</em> was to provide properties and attributes that are
common in biological and biochemical systems the library contains several packages holding
classes and partial models. The classes can be used as they are in sub libraries to <em>BioChem</em>,
while the partial models must be further extended to fully functional models.
</p>
<h2>Users Guide</h2>
<p>
Users Guide discusses some aspects of the <em>BioChem</em> Library, including a Getting Started chapter.
</p>
<h2>References</h2>
<p>
<b>BioChem - A Biological and Chemical Library for Modelica (Conference paper)</b><br>
Emma Larsdotter Nilsson, Peter Fritzson.
Proceedings of the 3rd International Modelica Conference (November 3-4, Linköping, Sweden) 2003, pp. 215-220
<br>
<br>
<b>A minimal cascade model for the mitotic oscillator involving cyclin
and cdc2 kinase</b><br>
Albert Goldbeter.
Proc. Nati. Acad. Sci. USA
Vol. 88, pp. 9107-9111, October 1991
Cell Biology
<br>
<br>

<b>Hierarchical modeling of diabetes</b><br>
Elin Nyman. ISRN:LiU-IKE-EX-09/14. Linköping University 2009.

<br>
<br>


<b>A Minimal Generic Model of Bacteria-Induced Intracellular Ca<sup>2+</sup>
Oscillations in Epithelial Cells</b><br>
Camilla Oxhamre, Agneta Richter-Dahlfors, Vladimir P. Zhdanov, and Bengt Kasemo. Biophysical Journal Volume 88 April 2005 2976-2981.
<br>
<br>



<b> A mathematical model of metabolic insulin signaling.</b><br>
  A. Sedaghat, R, A. Sherman, and J. Quon, Michael. American Journal of Physiology - Endocrinology and Metabolism, 283:1048-1101, Jul 2002.

<br>
<br>





<b>Modeling the cell division cycle: cdc2 and cyclin interactions</b><br>
John J. Tyson. Proc. Nati. Acad. Sci. USA
Vol. 88, pp. 7328-7332, August 1991
Cell Biology
<br>
<br>
<b>Modeling Feedback Loops of the Mammalian Circadian Oscillator</b><br>
Becker-Weimann S, Wolf J, Herzel H, Kramer A. Biophysical Journal Volume 87 November 2004 3023-3034

<br>
<br>
</p>



 </html>
 ", revisions="
 <html>
 <h1>Version history</h1>
 <p>The first version of the library was created by Emma Larsdotter Nilsson at Linköping University.
The current version of the library has been further developed by Erik Ulfhielm at
Linköping University, and by MathCore Engineering AB.
</p>
 <ul>
 Main Author 2007-2009: MathCore Engineering AB <br>
 Main Author 2006: Erik Ulfhielm <br>
 Main Author 2004-2005: Emma Larsdotter Nilsson <br> <br>
 Copyright (c) 2005-2008 MathCore Engineering AB, Linköpings universitet and Modelica Association <br> <br>
 The BioChem package is free software and can be redistributed <br>
 and/or modified under the terms of the Modelica License with <br>
 the additional provision that changed parts of BioChem also <br>
 must be made available under this License. <br>
 </ul>
 </html>
 "));
  package Math
    extends Icons.Library;
    annotation(Diagram(coordinateSystem(extent={{-148.5,105},{148.5,-105}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, origin={1.40855,-8.72502}, fillPattern=FillPattern.Solid, extent={{-81.4085,-69.705},{56.8628,38.725}}, textString="f(x)", fontName="Arial")}), Documentation(info="<html>
<h1>Math</h1>
A number of mathematical functions are used in pathway models. Some of these can be found in

<a href=\"Modelica://Modelica.Math\">Modelica.Math</a>

while others have been added in this package.
<br>
<img src=\"./Images/Math.png\" >
<br>


</html>", revisions=""));
  end Math;

  package Icons "Icons"
    extends Library;
    partial package Library
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-100,-100},{80,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Library;

    partial package Example "Icon for an example model"
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{80,50}}),Polygon(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}),Polygon(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-85,-85},{65,35}}, textString="Example", fontName="Arial"),Text(visible=true, fillColor={255,0,0}, extent={{-120,73},{120,132}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Example;

    annotation(Documentation(info="<html>
<h1>Icons</h1>
This package contains icons that are used in the library.
</html>", revisions=""));
  end Icons;

  package Units "Units used in BioChem"
    extends Icons.Library;
    annotation(Documentation(info="
 <html>
<h1>Units</h1>
 <p>
 This pace contains definitions of units that are common in biochemical models.
 </p>
 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, origin={0,-13.3333}, fillPattern=FillPattern.Solid, extent={{-100,-86.6667},{73.34,43.3333}}, textString="C", fontName="Arial"),Text(visible=true, origin={0,-10}, fillPattern=FillPattern.Solid, extent={{6.51,6.81},{50,53.19}}, textString="o", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Volume= Modelica.SIunits.Conversions.NonSIunits.Volume_litre annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type StoichiometricCoefficient= Real(quantity="Stoichiometric coefficient", unit="1") "" annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type ReactionRate= Real(quantity="Reaction rate", unit="mol/s") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type MolarFlowRate= Real(quantity="Molar flow rate", unit="mol/s") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Concentration= Real(quantity="Concentration", unit="mol/l", min=0) annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type AmountOfSubstance= Real(quantity="AmountOfSubstance", unit="mol", min=0) annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  end Units;

  package Substances "Reaction nodes"
    extends Icons.Library;
    annotation(Documentation(info="<html>
<h1>Substances</h1>
 <p>
 This package contains different types of nodes needed for representing a substance in a biochemical pathway.
 Substances are connected to reactions through connectors placed
 on the rim of the circle representing the substance.<br>
The substance models are specified by extending the partial models of substance nodes in
<a href=\"Modelica://BioChem.Interfaces.Substances\">Substances</a>
 and adding additional attributes and equations.
The
<a href=\"Modelica://BioChem.Substances.Substance\">Substances</a>

 model is used when the concentration in a substance node is allowed to change without restrictions during a simulation, while

<a href=\"Modelica://BioChem.Substances.BoundarySubstance\">BoundarySubstances</a>
 is used when the concentration can only be changed using events. This correspond to species with the fixed or boundary attribute set in SBML.<br>
The
<a href=\"Modelica://BioChem.Substances.AmbientSubstance\">AmbientSubstance</a>
 is a substance used as a reservoir in reactions. This corresponds to the empty list of reactants or the empty list of products in an SBML reaction.
When the concentration is not determined by reactions, the

<a href=\"Modelica://BioChem.Substances.SignalSubstance\">SignalSubstance</a>
 model is used. Then the substance concentration is regulated by external equations, and it  corresponds to SBML species changed by any SBML rules.
 </p>
<a name=\"fig1\"></a>
<img src=\"../Images/Substance.png\" alt=\"Fig1: Substance\">
</html>

 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, origin={-10,-50}, lineColor={0,56,0}, fillColor={0,85,0}, fillPattern=FillPattern.Sphere, extent={{-60,-20},{-20,20}}),Ellipse(visible=true, origin={38,-10}, lineColor={100,100,0}, fillColor={255,255,0}, fillPattern=FillPattern.Sphere, extent={{-28,-60},{12,-20}}),Ellipse(visible=true, origin={-30.0032,-2.75056}, lineColor={0,0,71}, fillColor={0,0,127}, fillPattern=FillPattern.Sphere, extent={{0.0032,-13.4697},{40,26.5303}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    model Substance "Substance with variable concentration"
      annotation(Documentation(info="<html>
 <p>
 A substance with variable concentration.
 </p>
 </html>
 "), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, origin={7.10543e-15,50}, fillPattern=FillPattern.Solid, extent={{-100,-150},{100,-100}}, textString="%name", fontName="Arial"),Ellipse(visible=true, lineColor={0,85,0}, fillColor={0,170,0}, fillPattern=FillPattern.Sphere, extent={{-50,-50},{50,50}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      extends BioChem.Interfaces.Substances.Substance;
    equation
      der(n)=rNet;
    end Substance;

    model AmbientSubstance "Substance used as a reservoir in reactions"
      annotation(Documentation(info="<html>
<p>
Substance used as a reservoir in reactions.
<p>
Corresponds to the empty list of reactants or the empty list of products in an SBML reaction.
</p>
</html>
"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, origin={1.77636e-15,50}, fillPattern=FillPattern.Solid, extent={{-100,-150},{100,-100}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-50,-50},{50,50}}, thickness=10)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      extends BioChem.Interfaces.Substances.Substance;
    equation
      der(n)=0;
    end AmbientSubstance;

  end Substances;

  package Interfaces "Connection points and icons used in the BioChem package"
    extends Icons.Library;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>
<h1>Interfaces</h1>
This package contains partial models that can be used as building blocks for components such as different types of substances, compartments, and reactions.
The models are designed to make it easy to create new customized components as well as to make these components possible to translate to and from SBML.<br>
The package contains the following packages: <br>
<ul>
<li>Compartments - Properties used when creating different compartments.</li>
<li>Nodes - Connection points used as interfaces between different components.</li>
<li>Reactions - Building blocks for reactions.</li>
<li>Substances - Basic substance types.</li>
</ul>

 </html>
 ", revisions=""), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    package Substances
      extends Icons.Library;
      partial model Substance "Basics for a substance"
        annotation(Documentation(info="<html>
<p>
The base class for all substances.
<p>
Corresponds to SBML species changed by SBML rules and with the <em>boundaryCondition</em> attribute set to true and the <em>constant</em> attribute set to false.
</p>
</html>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={123,152,255}, extent={{-50,-50},{50,50}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        BioChem.Units.Concentration c(stateSelect=StateSelect.prefer) "Current concentration of substance (mM)";
        BioChem.Units.MolarFlowRate rNet "Net flow rate of substance into the node";
        BioChem.Units.AmountOfSubstance n(stateSelect=StateSelect.prefer) "Number of moles of substance in pool (mol)";
        BioChem.Interfaces.Nodes.SubstanceConnector n1 annotation(Placement(visible=true, transformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={0,0}, extent={{-16,-16},{16,16}}, rotation=0)));
      protected
        outer BioChem.Units.Volume V "Compartment volume";
      equation
        rNet=n1.r;
        c=n1.c;
        V=n1.V;
        c=n/V;
      end Substance;

      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>
<h1>Substances</h1>
This package contains partial models of different kinds of nodes needed to represent substances in biological and biochemical systems. The basic attributes corresponding to the properties that are studied during simulations, i.e., the amount and the concentration of the substance, are declared in these partial models.
</html>", revisions=""));
    end Substances;

    package Reactions "Partial models, extended by models in the subpackage Reactions"
      extends Icons.Library;
      annotation(Documentation(info="<html>
<h1>Reactions</h1>
 <p>
This package contains partial reaction models that can be used as templates when composing new reactions. In fact all reactions found in the
<a href=\"Modelica://BioChem.Reactions\">Reactions</a>
 are based on these partial reaction models.
All reactions need at least one substrate and at least one product. This package contains base classes for any combination of substrates and products for reversible as well as irreversible reactions, as illustrated in <a href=\"#fig1\">Figure 1</a>. The first letter in the reaction name indicates the number of substrates, and the second the number of products. Finally, the third letter indicates if the reaction is reversible (r) or irreversible (i). All these information is also illustrated by the icon.
 </p>

<a name=\"fig1\"></a>
<img src=\"../../Images/Reactions.png\" alt=\"Fig1:Reactions\"><br>
<i>Figure 1:  Some of the reactions</i><br>

 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      partial model Uui "Uni-Uni irreversible reaction"
        extends BioChem.Interfaces.Reactions.Basics.Reaction;
        extends BioChem.Interfaces.Reactions.Basics.OneSubstrate;
        extends BioChem.Interfaces.Reactions.Basics.OneProduct;
        BioChem.Units.StoichiometricCoefficient nS1=1 "Stoichiometric coefficient for the substrate";
        BioChem.Units.StoichiometricCoefficient nP1=1 "Stoichiometric coefficient for the product";
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      equation
        s1.r=nS1*rr;
        p1.r=-nP1*rr;
      end Uui;

      package Modifiers "Partial models of modifiers to reactions"
        extends Icons.Library;
        annotation(Documentation(info="", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model Modifier
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,56.25},{0,6.25}}, color={0,0,255}, arrow={Arrow.None,Arrow.Open}, arrowSize=30)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Interfaces.Nodes.ModifierConnector m1 annotation(Placement(visible=true, transformation(origin={5.55111e-16,90}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-3.10862e-15,90}, extent={{-20,-20},{20,20}}, rotation=0)));
        equation
          m1.r=0;
        end Modifier;

      end Modifiers;

      package Basics "Basic properties of reactions"
        extends Icons.Library;
        annotation(Documentation(info="", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        partial model OneSubstrate "SubstanceConnector for one substrate"
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-50,0},{-100,0}}, color={170,0,0}, arrowSize=25)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Interfaces.Nodes.SubstrateConnector s1 annotation(Placement(visible=true, transformation(origin={-80,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-112.5,-2.22045e-16}, extent={{-12.5,-12.5},{12.5,12.5}}, rotation=0)));
        end OneSubstrate;

        partial model OneProduct "SubstanceConnector for one product"
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{50,0},{100,0}}, color={170,0,0}, arrow={Arrow.None,Arrow.Open}, arrowSize=50)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Interfaces.Nodes.ProductConnector p1 annotation(Placement(visible=true, transformation(origin={80,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={112.5,2.22045e-16}, extent={{-12.5,-12.5},{12.5,12.5}}, rotation=0)));
        end OneProduct;

        partial model Reaction "Basics for a reaction edge"
          annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-50,0},{50,0}}, color={170,0,0}),Text(visible=true, origin={-4.44089e-15,1.42109e-14}, fillColor={77,77,77}, fillPattern=FillPattern.Solid, extent={{-100,-150},{97.9,-100}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Units.ReactionRate rr "Rate of the reaction" annotation(__MathCore_reactionrate=true);
        end Reaction;

      end Basics;

    end Reactions;

    package Nodes "Connector interfaces used in the package"
      extends Icons.Library;
      annotation(Documentation(info="<html>
<h1>Nodes</h1>
 <p>
 This package contains connection points used in the <b>BioChem</b> package.<br>
The reaction between two or more substances is described by the molar flow rate between the involved substances. The molar flow rate is typically expressed as a function of the concentration or amount of substance. Therefore the interface or nodes contain not only the molar flow rate and concentration, but also the volume, in order to make it possible to calculate the amount of substance if needed. <br>
The interfaces in the  library are all identical except for the graphics, and the volume variable V. The different graphics are used to indicate if respective substance should be seen as substrate, product, modifier, etc., in a reaction. The variable V  is an output variable in the

<a href=\"Modelica://BioChem.Interfaces.Nodes.SubstanceConnector\">SubstanceConnector</a>


 and an input variable in all the other nodes.
The variables available in each connection point are described below:



</table>
<h3> Variables in nodes </h3>
<table border=\"1\">
<TR><TH>Variable name<TH>Description<TH>Unit
<TR><TD>c<TD>Concentration<TD>mol
<TR><TD>V<TD>Volume<TD>l
<TR><TD>r<TD>Reaction rate<TD>mol/s
</table>


 </p>
 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      connector SubstrateConnector "Connector between substances and reactions (substrate side of reaction)"
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,85,127}, fillColor={0,85,127}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,85,0}, fillColor={255,255,255}, extent={{-20,-20},{20,20}}),Line(visible=true, points={{-20,20},{20,-20}}, color={0,85,0}),Line(visible=true, points={{-20,-20},{20,20}}, color={0,85,0})}));
        BioChem.Units.Concentration c;
        flow BioChem.Units.MolarFlowRate r;
        input BioChem.Units.Volume V;
      end SubstrateConnector;

      connector SubstanceConnector "Connector between substances and reactions"
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,85,0}, fillColor={0,85,127}, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,85,0}, fillColor={255,255,255}, extent={{-20,-20},{20,20}}),Line(visible=true, points={{-20,20},{20,-20}}, color={0,85,0}),Line(visible=true, points={{-20,-20},{20,20}}, color={0,85,0})}));
        BioChem.Units.Concentration c;
        flow BioChem.Units.MolarFlowRate r;
        output BioChem.Units.Volume V;
      end SubstanceConnector;

      connector ProductConnector "Connector between substances and reactions (product side of reaction)"
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,85,0}, fillColor={255,255,255}, extent={{-20,-20},{20,20}}),Line(visible=true, points={{-20,20},{20,-20}}, color={0,85,0}),Line(visible=true, points={{-20,-20},{20,20}}, color={0,85,0})}));
        BioChem.Units.Concentration c;
        flow BioChem.Units.MolarFlowRate r;
        input BioChem.Units.Volume V;
      end ProductConnector;

      connector ModifierConnector "Connector between general modifieres and reactions"
        annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,85,0}, fillColor={255,255,255}, extent={{-20,-20},{20,20}}),Line(visible=true, points={{-20,20},{20,-20}}, color={0,85,0}),Line(visible=true, points={{-20,-20},{20,20}}, color={0,85,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,0}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}));
        BioChem.Units.Concentration c;
        flow BioChem.Units.MolarFlowRate r;
        input BioChem.Units.Volume V;
      end ModifierConnector;

    end Nodes;

    package Compartments "Properties for compartments"
      extends Icons.Library;
      annotation(Documentation(info="
 <html>
<h1>Compartments</h1>

 <p>
 The partial models in this package collect some basic properties of compartments, such as volume and temperature. These partial models are extended by models in
<a href=\"Modelica://BioChem.Compartments\">BioChem.Compartments</a> , and the compartment properties can be accessed by all substances in the compartment.
 </p>
<br>
<img src=\"../../Images/InterfaceCompartments.png\" >
<br>

 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      partial model Compartment "Default properties for a compartment"
        annotation(Documentation(info="
 <html>
 <p>
 A partial model describing the basics of a default compartment.
 </p>
 </html>
 "), defaultComponentName="compartment", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100,-170},{100,-120}}, textString="%name", fontName="Arial"),Rectangle(visible=true, lineColor={0,0,127}, fillColor={0,170,255}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-110,-110},{110,110}}, radius=20)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        inner BioChem.Units.Volume V(start=1, stateSelect=StateSelect.prefer) "Compartment volume";
      end Compartment;

      partial model MainCompartment "Default properties for a compartment."
        annotation(Documentation(info="<html>
 <p>
 Main compartment model.
 </p>
 </html>
 "), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100,-170},{100,-120}}, textString="%name", fontName="Arial"),Text(visible=true, fillPattern=FillPattern.Solid, extent={{-82.12,-80},{80,80}}, textString="main", fontName="Arial", textStyle={TextStyle.Bold})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        extends BioChem.Interfaces.Compartments.Compartment;
      end MainCompartment;

    end Compartments;

  end Interfaces;

  package Examples "Some examples of BioChem models"
    extends Icons.Library;
    annotation(Documentation(info="<html>
<h1>Examples</h1>
 <p>
 This package contains several examples of pathways. Including basic examples as an asymmetric reaction with Michaelis-Menten kinetics to more advanced multi compartment models.
 </p>
 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,127}, fillColor={85,85,255}, fillPattern=FillPattern.Sphere, extent={{25,-85},{50,-60}}),Ellipse(visible=true, lineColor={89,0,0}, fillColor={199,0,0}, fillPattern=FillPattern.Sphere, extent={{-75,-85},{-50,-60}}),Ellipse(visible=true, origin={-1.77636e-15,-8.81}, lineColor={0,85,0}, fillColor={0,170,0}, fillPattern=FillPattern.Sphere, extent={{-25,-43.69},{3.55271e-15,-18.69}}),Ellipse(visible=true, origin={-1.77636e-15,-20}, lineColor={79,79,0}, fillColor={255,255,0}, fillPattern=FillPattern.Sphere, extent={{-25,30},{0,55}}),Line(visible=true, origin={0,-8.50446}, points={{-12.65,18.5045},{-12.65,-18.69}}, arrow={Arrow.Open,Arrow.Open}, arrowSize=10),Line(visible=true, points={{0,-40},{20,-40},{34.02,-60}}, arrow={Arrow.None,Arrow.Open}, arrowSize=10, smooth=Smooth.Bezier),Line(visible=true, points={{-50,-72.78},{25,-72.78}}, arrow={Arrow.Open,Arrow.Open}, arrowSize=10),Line(visible=true, points={{-24.8834,-40},{-45.6721,-40},{-60,-60}}, arrow={Arrow.None,Arrow.Open}, arrowSize=10, smooth=Smooth.Bezier)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    package CircadianOscillator "Weimann2004_CircadianOscillator"
      extends BioChem.Icons.Example;
      model Container
        extends BioChem.Compartments.MainCompartment(V(start=1));
        import BioChem.Math.*;
        import BioChem.Constants.*;
        BioChem.Examples.CircadianOscillator.Nucleus nucleus(k3t=k3t, k3d=k3d, k6t=k6t, k6d=k6d, k6a=k6a, k7a=k7a, k7d=k7d) annotation(Placement(visible=true, transformation(origin={-30.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Cytoplasm cytoplasm(trans_per2_cry=trans_per2_cry, k1d=k1d, k2b=k2b, q=q, k2d=k2d, k2t=k2t, trans_Bmal1=trans_Bmal1, k4d=k4d, k5b=k5b, k5d=k5d, k5t=k5t) annotation(Placement(visible=true, transformation(origin={21.5395,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180)));
        inner Real Nucleus_V=nucleus.V "Variable used to make the compartment volume of inner compartments accessible. Do not edit.";
        inner Real Cytoplasm_V=cytoplasm.V "Variable used to make the compartment volume of inner compartments accessible. Do not edit.";
        inner Real Container_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        Real trans_per2_cry(start=0);
        parameter Real v1b=9;
        parameter Real c_sbml=0.01;
        parameter Real k1b=1;
        parameter Real k1i=0.56;
        parameter Real hill_coeff=8;
        Real trans_Bmal1(start=0);
        parameter Real v4b=3.6;
        parameter Real r_sbml=3;
        parameter Real k4b=2.16;
        Real y5_y6_y7(start=3.05);
        parameter Real k1d=0.12;
        parameter Real k2b=0.3;
        parameter Real q=2;
        parameter Real k2d=0.05;
        parameter Real k2t=0.24;
        parameter Real k3t=0.02;
        parameter Real k3d=0.12;
        parameter Real k4d=0.75;
        parameter Real k5b=0.24;
        parameter Real k5d=0.06;
        parameter Real k5t=0.45;
        parameter Real k6t=0.06;
        parameter Real k6d=0.12;
        parameter Real k6a=0.09;
        parameter Real k7a=0.003;
        parameter Real k7d=0.09;
        annotation(Documentation(info="<html>
<h1>Circadian Oscillator</h1>

This example is the modelica version of the model presented in
<i>Modeling feedback loops of the Mammalian circadian oscillator</i> by
Becker-Weimann S, Wolf J, Herzel H, Kramer A. (Biophysical Journal Volume 87 November 2004 3023-3034)

<h2>Abstract</h2>
The suprachiasmatic nucleus governs daily variations of physiology and behavior in mammals. Within single neurons, interlocked transcriptional/translational feedback loops generate circadian rhythms on the molecular level. We present a mathematical model that reflects the essential features of the mammalian circadian oscillator to characterize the differential roles of negative and positive feedback loops. The oscillations that are obtained have a 24-h period and are robust toward parameter variations even when the positive feedback is replaced by a constantly expressed activator. This demonstrates the crucial role of the negative feedback for rhythm generation. Moreover, it explains the rhythmic phenotype of Rev-erbalpha-/- mutant mice, where a positive feedback is missing. The interplay of negative and positive feedback reveals a complex dynamics. In particular, the model explains the unexpected rescue of circadian oscillations in Per2Brdm1/Cry2-/- double-mutant mice (Per2Brdm1 single-mutant mice are arrhythmic). Here, a decrease of positive feedback strength associated with mutating the Per2 gene is compensated by the Cry2-/- mutation that simultaneously decreases the negative feedback strength. Finally, this model leads us to a testable prediction of a molecular and behavioral phenotype: circadian oscillations should be rescued when arrhythmic Per2Brdm1 mutant mice are crossed with Rev- erbalpha -/- mutant mice.

<h2>Simulations</h2>
The simulation results are shown in the
 <a href=\"#fig1\">Figure 1</a>. This plot corresponds to Fig 3A from the paper (Becker-Weimann, 2004).

<a name=\"fig1\"></a>
<img src=\"../Images/Container.png\" alt=\"Fig1: Simulation results\">

</html>", revisions=""), experiment(StartTime=0, StopTime=150, NumberOfIntervals=-1, Algorithm="dassl", Tolerance=1e-06));
      equation
        connect(cytoplasm.y5_node,nucleus.y5_node) annotation(Line(visible=true, origin={-4.2302,-19.0}, points={{14.7697,0.0},{-14.7697,0.0}}));
        connect(nucleus.y6_node,cytoplasm.y6_node) annotation(Line(visible=true, origin={-4.2302,-1.0}, points={{-14.7697,0.0},{14.7697,0.0}}));
        connect(cytoplasm.y2_node,nucleus.y2_node) annotation(Line(visible=true, origin={-4.2302,-7.0}, points={{14.7697,0.0},{-14.7697,0.0}}));
        connect(nucleus.y3_node,cytoplasm.y3_node) annotation(Line(visible=true, origin={-4.2302,-13.0}, points={{-14.7697,0.0},{14.7697,0.0}}));
        trans_per2_cry=v1b*(nucleus.y7.c + c_sbml)/(k1b*(1 + (nucleus.y3.c/k1i)^hill_coeff) + nucleus.y7.c + c_sbml);
        trans_Bmal1=v4b*nucleus.y3.c^r_sbml/(k4b^r_sbml + nucleus.y3.c^r_sbml);
        y5_y6_y7=cytoplasm.y5.c + nucleus.y6.c + nucleus.y7.c;
      end Container;

      model Nucleus "Nucleus"
        extends BioChem.Compartments.Compartment(V(start=1));
        import BioChem.Math.*;
        import BioChem.Constants.*;
        model y3_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000035\">
      <bqbiol:hasPart>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:O15055\"/>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:Q16526\"/>
        </rdf:Bag>
      </bqbiol:hasPart>
    </rdf:Description>
  </rdf:RDF>"));
        end y3_;

        model y6_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000038\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:Q8IUT4\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end y6_;

        model y7_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000039\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:Q8IUT4\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end y7_;

        model per2_cry_nuclear_export_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000049\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0051168\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k3t;
        equation
          rr=Nucleus_V*k3t*s1.c;
        end per2_cry_nuclear_export_;

        model nuclear_per2_cry_complex_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000050\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0044257\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k3d;
        equation
          rr=Nucleus_V*k3d*s1.c;
        end nuclear_per2_cry_complex_degradation_;

        model BMAL1_nuclear_export_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000056\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0051168\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k6t;
        equation
          rr=Nucleus_V*k6t*s1.c;
        end BMAL1_nuclear_export_;

        model nuclear_BMAL1_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000057\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0044257\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k6d;
        equation
          rr=Nucleus_V*k6d*s1.c;
        end nuclear_BMAL1_degradation_;

        model BMAL1_activation_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000058\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0051091\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k6a;
        equation
          rr=Nucleus_V*k6a*s1.c;
        end BMAL1_activation_;

        model BMAL1_deactivation_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000059\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0043433\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k7a;
        equation
          rr=Nucleus_V*k7a*s1.c;
        end BMAL1_deactivation_;

        model Active_BMAL1_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000060\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0044257\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Nucleus_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k7d;
        equation
          rr=Nucleus_V*k7d*s1.c;
        end Active_BMAL1_degradation_;

        inner Real Nucleus_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        BioChem.Examples.CircadianOscillator.Nucleus.y3_ y3(c(start=1.1)) "PER2_CRY_complex_nucleus" annotation(Placement(visible=true, transformation(origin={70.0,-50.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        BioChem.Examples.CircadianOscillator.Nucleus.y6_ y6(c(start=1)) "BMAL1_nucleus" annotation(Placement(visible=true, transformation(origin={-10.0,50.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180)));
        BioChem.Examples.CircadianOscillator.Nucleus.y7_ y7(c(start=1.05)) "Active BMAL1" annotation(Placement(visible=true, transformation(origin={-45.6104,-16.1148}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180)));
        BioChem.Interfaces.Nodes.SubstanceConnector y3_node annotation(Placement(visible=true, transformation(origin={90.0,-60.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        parameter Real k3t;
        BioChem.Interfaces.Nodes.SubstanceConnector y2_node annotation(Placement(visible=true, transformation(origin={90.0,60.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        BioChem.Examples.CircadianOscillator.Nucleus.per2_cry_nuclear_export_ per2_cry_nuclear_export(k3t=k3t) "per2_cry_nuclear_export" annotation(Placement(visible=true, transformation(origin={68.1433,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        BioChem.Substances.AmbientSubstance ambientSubstance annotation(Placement(visible=true, transformation(origin={10.0,-50.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        parameter Real k3d;
        BioChem.Examples.CircadianOscillator.Nucleus.nuclear_per2_cry_complex_degradation_ nuclear_per2_cry_complex_degradation(k3d=k3d) "nuclear_per2_cry_complex_degradation" annotation(Placement(visible=true, transformation(origin={40.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180)));
        BioChem.Interfaces.Nodes.SubstanceConnector y6_node annotation(Placement(visible=true, transformation(origin={90.0,90.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,90.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        parameter Real k6t;
        BioChem.Interfaces.Nodes.SubstanceConnector y5_node annotation(Placement(visible=true, transformation(origin={90.0,-90.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,-90.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Nucleus.BMAL1_nuclear_export_ BMAL1_nuclear_export(k6t=k6t) "BMAL1_nuclear_export" annotation(Placement(visible=true, transformation(origin={-80.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        parameter Real k6d;
        BioChem.Examples.CircadianOscillator.Nucleus.nuclear_BMAL1_degradation_ nuclear_BMAL1_degradation(k6d=k6d) "nuclear_BMAL1_degradation" annotation(Placement(visible=true, transformation(origin={10.0,10.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=90)));
        parameter Real k6a;
        Nucleus.BMAL1_activation_ BMAL1_activation(k6a=k6a) "BMAL1_activation" annotation(Placement(visible=true, transformation(origin={-30.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        parameter Real k7a;
        Nucleus.BMAL1_deactivation_ BMAL1_deactivation(k7a=k7a) "BMAL1_deactivation" annotation(Placement(visible=true, transformation(origin={-61.7118,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        parameter Real k7d;
        BioChem.Examples.CircadianOscillator.Nucleus.Active_BMAL1_degradation_ Active_BMAL1_degradation(k7d=k7d) "Active_BMAL1_degradation" annotation(Placement(visible=true, transformation(origin={-30.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      equation
        connect(y3.n1,nuclear_per2_cry_complex_degradation.s1) annotation(Line(visible=true, origin={58.0633,-45.0}, points={{11.9367,-5.0},{-2.5617,-5.0},{-2.5617,5.0},{-6.8133,5.0}}, smooth=Smooth.Bezier));
        connect(y3.n1,per2_cry_nuclear_export.s1) annotation(Line(visible=true, origin={69.0717,-15.5633}, points={{0.9283,-34.4367},{0.9283,10.0617},{-0.9284,10.0617},{-0.9284,14.3133}}, smooth=Smooth.Bezier));
        connect(y3.n1,y3_node) annotation(Line(visible=true, origin={76.6667,-56.6667}, points={{-6.6667,6.6667},{-6.6667,-3.3333},{13.3333,-3.3333}}, smooth=Smooth.Bezier));
        connect(y7.n1,BMAL1_activation.p1) annotation(Line(visible=true, origin={-35.2035,-11.1599}, points={{-10.4069,-4.9549},{5.2035,-4.9549},{5.2035,9.9099}}, smooth=Smooth.Bezier));
        connect(y7.n1,Active_BMAL1_degradation.s1) annotation(Line(visible=true, origin={-44.1569,-32.0383}, points={{-1.4535,15.9235},{-1.4535,-7.9617},{2.9069,-7.9617}}, smooth=Smooth.Bezier));
        connect(y7.n1,BMAL1_deactivation.s1) annotation(Line(visible=true, origin={-56.3447,-11.1599}, points={{10.7343,-4.9549},{-5.3671,-4.9549},{-5.3671,9.9099}}, smooth=Smooth.Bezier));
        connect(y6.n1,BMAL1_deactivation.p1) annotation(Line(visible=true, origin={-44.4745,40.4167}, points={{34.4745,9.5833},{-17.2373,9.5833},{-17.2373,-19.1667}}, smooth=Smooth.Bezier));
        connect(y6.n1,BMAL1_activation.s1) annotation(Line(visible=true, origin={-20.0,30.5633}, points={{10.0,19.4367},{10.0,-5.0617},{-10.0,-5.0617},{-10.0,-9.3133}}, smooth=Smooth.Bezier));
        connect(y6.n1,nuclear_BMAL1_degradation.s1) annotation(Line(visible=true, origin={0.0,30.5633}, points={{-10.0,19.4367},{-10.0,-5.0617},{10.0,-5.0617},{10.0,-9.3133}}, smooth=Smooth.Bezier));
        connect(y6.n1,BMAL1_nuclear_export.s1) annotation(Line(visible=true, origin={-56.6667,43.75}, points={{46.6667,6.25},{-23.3333,6.25},{-23.3333,-12.5}}, smooth=Smooth.Bezier));
        connect(y6.n1,y6_node) annotation(Line(visible=true, origin={58.5,70.0}, points={{-68.5,-20.0},{18.5,-20.0},{18.5,20.0},{31.5,20.0}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,nuclear_per2_cry_complex_degradation.p1) annotation(Line(visible=true, origin={21.9367,-45.0}, points={{-11.9367,-5.0},{2.5617,-5.0},{2.5617,5.0},{6.8133,5.0}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,nuclear_BMAL1_degradation.p1) annotation(Line(visible=true, origin={10.0,-25.625}, points={{0.0,-24.375},{0.0,24.375}}, smooth=Smooth.Bezier));
        connect(BMAL1_nuclear_export.p1,y5_node) annotation(Line(visible=true, origin={-23.3333,-57.0833}, points={{-56.6667,65.8333},{-56.6667,-32.9167},{113.3333,-32.9167}}, smooth=Smooth.Bezier));
        connect(per2_cry_nuclear_export.p1,y2_node) annotation(Line(visible=true, origin={79.0717,43.8125}, points={{-10.9284,-22.5625},{-10.9284,3.1875},{10.9283,3.1875},{10.9283,16.1875}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,Active_BMAL1_degradation.p1) annotation(Line(visible=true, origin={-9.4367,-45.0}, points={{19.4367,-5.0},{-5.0617,-5.0},{-5.0617,5.0},{-9.3133,5.0}}, smooth=Smooth.Bezier));
      end Nucleus;

      model Cytoplasm "Cytoplasm"
        extends BioChem.Compartments.Compartment(V(start=1));
        import BioChem.Math.*;
        import BioChem.Constants.*;
        model y1_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000033\">
      <bqbiol:encodes>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:O15055\"/>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:Q16526\"/>
        </rdf:Bag>
      </bqbiol:encodes>
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.chebi:CHEBI%3A33699\"/>
          <rdf:li rdf:resource=\"urn:miriam:kegg.compound:C00046\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end y1_;

        model y2_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000034\">
      <bqbiol:hasPart>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:O15055\"/>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:Q16526\"/>
        </rdf:Bag>
      </bqbiol:hasPart>
    </rdf:Description>
  </rdf:RDF>"));
        end y2_;

        model y4_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000036\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.chebi:CHEBI%3A33699\"/>
          <rdf:li rdf:resource=\"urn:miriam:kegg.compound:C00046\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
      <bqbiol:encodes>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:Q8IUT4\"/>
        </rdf:Bag>
      </bqbiol:encodes>
    </rdf:Description>
  </rdf:RDF>"));
        end y4_;

        model y5_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000037\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:uniprot:Q8IUT4\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end y5_;

        model per2_cry_transcription_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000044\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0006350\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real trans_per2_cry;
        equation
          rr=Cytoplasm_V*trans_per2_cry;
        end per2_cry_transcription_;

        model per2_cry_mRNA_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000045\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0006402\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k1d;
        equation
          rr=Cytoplasm_V*k1d*s1.c;
        end per2_cry_mRNA_degradation_;

        model per2_cry_complex_formation_
          extends BioChem.Interfaces.Reactions.Uui;
          extends BioChem.Interfaces.Reactions.Modifiers.Modifier;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000046\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0046982\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k2b;
          parameter Real q;
        equation
          rr=Cytoplasm_V*k2b*m1.c^q;
        end per2_cry_complex_formation_;

        model cytoplasmic_per2_cry_complex_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000047\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0044257\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k2d;
        equation
          rr=Cytoplasm_V*k2d*s1.c;
        end cytoplasmic_per2_cry_complex_degradation_;

        model per2_cry_nuclear_import_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000048\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0051170\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k2t;
        equation
          rr=Cytoplasm_V*k2t*s1.c;
        end per2_cry_nuclear_import_;

        model Bmal1_transcription_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000051\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0006350\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real trans_Bmal1;
        equation
          rr=Cytoplasm_V*trans_Bmal1;
        end Bmal1_transcription_;

        model Bmal1_mRNA_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000052\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0006402\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k4d;
        equation
          rr=Cytoplasm_V*k4d*s1.c;
        end Bmal1_mRNA_degradation_;

        model BMAL1_translation_
          extends BioChem.Interfaces.Reactions.Uui;
          extends BioChem.Interfaces.Reactions.Modifiers.Modifier;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000053\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0006412\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k5b;
        equation
          rr=Cytoplasm_V*k5b*m1.c;
        end BMAL1_translation_;

        model cytoplasmic_BMAL1_degradation_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000054\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0044257\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k5d;
        equation
          rr=Cytoplasm_V*k5d*s1.c;
        end cytoplasmic_BMAL1_degradation_;

        model BMAL1_nuclear_import_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000055\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0051170\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          outer Real Cytoplasm_V "Variable used to access the volume of an outer compartment. Do not edit.";
          parameter Real k5t;
        equation
          rr=Cytoplasm_V*k5t*s1.c;
        end BMAL1_nuclear_import_;

        inner Real Cytoplasm_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        Cytoplasm.y1_ y1(c(start=0.2)) "Per2 or Cry mRNA" annotation(Placement(visible=true, transformation(origin={170.0,60.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Cytoplasm.y2_ y2(c(start=0)) "PER2_CRY_complex_cytoplasm" annotation(Placement(visible=true, transformation(origin={140.0,-21.8298}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Cytoplasm.y4_ y4(c(start=0.8)) "Bmal1 mRNA" annotation(Placement(visible=true, transformation(origin={64.8293,-60.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Cytoplasm.y5_ y5(c(start=1)) "BMAL1_cytoplasm" annotation(Placement(visible=true, transformation(origin={20.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        BioChem.Substances.AmbientSubstance ambientSubstance annotation(Placement(visible=true, transformation(origin={90.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        input Real trans_per2_cry;
        Cytoplasm.per2_cry_transcription_ per2_cry_transcription(trans_per2_cry=trans_per2_cry) "per2_cry_transcription" annotation(Placement(visible=true, transformation(origin={130.0,50.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        parameter Real k1d;
        Cytoplasm.per2_cry_mRNA_degradation_ per2_cry_mRNA_degradation(k1d=k1d) "per2_cry_mRNA_degradation" annotation(Placement(visible=true, transformation(origin={130.0,70.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180)));
        parameter Real k2b;
        parameter Real q;
        Cytoplasm.per2_cry_complex_formation_ per2_cry_complex_formation(k2b=k2b, q=q) "per2_cry_complex_formation" annotation(Placement(visible=true, transformation(origin={152.1486,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        parameter Real k2d;
        Cytoplasm.cytoplasmic_per2_cry_complex_degradation_ cytoplasmic_per2_cry_complex_degradation(k2d=k2d) "cytoplasmic_per2_cry_complex_degradation" annotation(Placement(visible=true, transformation(origin={120.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        parameter Real k2t;
        BioChem.Interfaces.Nodes.SubstanceConnector y3_node annotation(Placement(visible=true, transformation(origin={190.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Cytoplasm.per2_cry_nuclear_import_ per2_cry_nuclear_import(k2t=k2t) "per2_cry_nuclear_import" annotation(Placement(visible=true, transformation(origin={180.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        BioChem.Interfaces.Nodes.SubstanceConnector y2_node annotation(Placement(visible=true, transformation(origin={190.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        input Real trans_Bmal1;
        Cytoplasm.Bmal1_transcription_ Bmal1_transcription(trans_Bmal1=trans_Bmal1) "Bmal1_transcription" annotation(Placement(visible=true, transformation(origin={74.9249,-23.3818}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        parameter Real k4d;
        Cytoplasm.Bmal1_mRNA_degradation_ Bmal1_mRNA_degradation(k4d=k4d) "Bmal1_mRNA_degradation" annotation(Placement(visible=true, transformation(origin={100.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        parameter Real k5b;
        Cytoplasm.BMAL1_translation_ BMAL1_translation(k5b=k5b) "BMAL1_translation" annotation(Placement(visible=true, transformation(origin={60.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180)));
        parameter Real k5d;
        Cytoplasm.cytoplasmic_BMAL1_degradation_ cytoplasmic_BMAL1_degradation(k5d=k5d) "cytoplasmic_BMAL1_degradation" annotation(Placement(visible=true, transformation(origin={60.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        parameter Real k5t;
        BioChem.Interfaces.Nodes.SubstanceConnector y6_node annotation(Placement(visible=true, transformation(origin={190.0,-90.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,-90.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Cytoplasm.BMAL1_nuclear_import_ BMAL1_nuclear_import(k5t=k5t) "BMAL1_nuclear_import" annotation(Placement(visible=true, transformation(origin={50.0,-80.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-450)));
        BioChem.Interfaces.Nodes.SubstanceConnector y5_node annotation(Placement(visible=true, transformation(origin={190.0,80.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,90.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{0.0,-100.0},{200.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      equation
        connect(BMAL1_nuclear_import.p1,y6_node) annotation(Line(visible=true, origin={128.8,-92.4506}, points={{-78.8,1.2006},{-78.8,-3.0509},{48.2,-3.0509},{48.2,2.4506},{61.2,2.4506}}, smooth=Smooth.Bezier));
        connect(y2.n1,y2_node) annotation(Line(visible=true, origin={169.0149,-25.9149}, points={{-29.0149,4.0851},{8.5,4.0851},{8.5,-4.0851},{20.9851,-4.0851}}, smooth=Smooth.Bezier));
        connect(per2_cry_nuclear_import.p1,y3_node) annotation(Line(visible=true, origin={183.3333,27.0833}, points={{-3.3333,-5.8333},{-3.3333,2.9167},{6.6667,2.9167}}, smooth=Smooth.Bezier));
        connect(y5.n1,y5_node) annotation(Line(visible=true, origin={121.75,70.0}, points={{-101.75,-50.0},{-41.75,30.0},{65.25,10.0},{68.25,10.0}}, smooth=Smooth.Bezier));
        connect(y2.n1,per2_cry_nuclear_import.s1) annotation(Line(visible=true, origin={166.6667,-14.9699}, points={{-26.6667,-6.8599},{13.3333,-6.8599},{13.3333,13.7199}}, smooth=Smooth.Bezier));
        connect(y1.n1,per2_cry_complex_formation.m1) annotation(Line(visible=true, origin={167.0495,33.3333}, points={{2.9505,26.6667},{2.9505,-13.3333},{-5.9009,-13.3333}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,per2_cry_complex_formation.s1) annotation(Line(visible=true, origin={120.0594,32.4506}, points={{-30.0594,-2.4506},{-17.0594,-2.4506},{-17.0594,3.0509},{32.0892,3.0509},{32.0892,-1.2006}}, smooth=Smooth.Bezier));
        connect(y2.n1,per2_cry_complex_formation.p1) annotation(Line(visible=true, origin={146.0743,-1.0207}, points={{-6.0743,-20.8091},{-6.0743,5.5192},{6.0743,5.5192},{6.0743,9.7707}}, smooth=Smooth.Bezier));
        connect(y2.n1,cytoplasmic_per2_cry_complex_degradation.s1) annotation(Line(visible=true, origin={130.0,-8.5207}, points={{10.0,-13.3091},{10.0,3.0192},{-10.0,3.0192},{-10.0,7.2707}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,cytoplasmic_per2_cry_complex_degradation.p1) annotation(Line(visible=true, origin={110.0,27.0833}, points={{-20.0,2.9167},{10.0,2.9167},{10.0,-5.8333}}, smooth=Smooth.Bezier));
        connect(y1.n1,per2_cry_transcription.p1) annotation(Line(visible=true, origin={150.5633,55.0}, points={{19.4367,5.0},{-5.0617,5.0},{-5.0617,-5.0},{-9.3133,-5.0}}, smooth=Smooth.Bezier));
        connect(y1.n1,per2_cry_mRNA_degradation.s1) annotation(Line(visible=true, origin={150.5633,65.0}, points={{19.4367,-5.0},{-5.0617,-5.0},{-5.0617,5.0},{-9.3133,5.0}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,per2_cry_mRNA_degradation.p1) annotation(Line(visible=true, origin={99.5833,56.6667}, points={{-9.5833,-26.6667},{-9.5833,13.3333},{19.1667,13.3333}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,per2_cry_transcription.s1) annotation(Line(visible=true, origin={106.872,42.5}, points={{-16.872,-12.5},{-2.6325,-2.5},{7.6265,7.5},{11.878,7.5}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,BMAL1_translation.s1) annotation(Line(visible=true, origin={83.75,10.0}, points={{6.25,20.0},{6.25,-10.0},{-12.5,-10.0}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,Bmal1_mRNA_degradation.p1) annotation(Line(visible=true, origin={95.0,-4.4367}, points={{-5.0,34.4367},{-5.0,-10.0617},{5.0,-10.0617},{5.0,-14.3133}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,Bmal1_transcription.s1) annotation(Line(visible=true, origin={82.4624,0.5269}, points={{7.5376,29.4731},{7.5376,-8.4072},{-7.5375,-8.4072},{-7.5375,-12.6587}}, smooth=Smooth.Bezier));
        connect(ambientSubstance.n1,cytoplasmic_BMAL1_degradation.p1) annotation(Line(visible=true, origin={80.625,30.0}, points={{9.375,-0.0},{-9.375,0.0}}, smooth=Smooth.Bezier));
        connect(y5.n1,cytoplasmic_BMAL1_degradation.s1) annotation(Line(visible=true, origin={39.4367,25.0}, points={{-19.4367,-5.0},{5.0617,-5.0},{5.0617,5.0},{9.3133,5.0}}, smooth=Smooth.Bezier));
        connect(y5.n1,BMAL1_nuclear_import.s1) annotation(Line(visible=true, origin={35.0,-44.4367}, points={{-15.0,64.4367},{-15.0,-20.0617},{15.0,-20.0617},{15.0,-24.3133}}, smooth=Smooth.Bezier));
        connect(y5.n1,BMAL1_translation.p1) annotation(Line(visible=true, origin={39.4367,10.0}, points={{-19.4367,10.0},{5.0617,10.0},{5.0617,-10.0},{9.3133,-10.0}}, smooth=Smooth.Bezier));
        connect(y4.n1,BMAL1_translation.m1) annotation(Line(visible=true, origin={62.4147,-24.2512}, points={{2.4147,-35.7488},{2.4147,10.2487},{-2.4147,10.2487},{-2.4147,15.2512}}, smooth=Smooth.Bezier));
        connect(y4.n1,Bmal1_transcription.p1) annotation(Line(visible=true, origin={69.8771,-43.0996}, points={{-5.0478,-16.9004},{-5.0478,4.2163},{5.0478,4.2163},{5.0478,8.4678}}, smooth=Smooth.Bezier));
        connect(y4.n1,Bmal1_mRNA_degradation.s1) annotation(Line(visible=true, origin={88.2764,-53.75}, points={{-23.4471,-6.25},{11.7236,-6.25},{11.7236,12.5}}, smooth=Smooth.Bezier));
      end Cytoplasm;

      annotation(Documentation(info="<html>
<h1>Circadian Oscillator</h1>

This example is the modelica version of the model presented in
<i>Modeling feedback loops of the Mammalian circadian oscillator</i> by
Becker-Weimann S, Wolf J, Herzel H, Kramer A. (Biophysical Journal Volume 87 November 2004 3023-3034)

<br>
<br>
See
<a href=\"Modelica://BioChem.Examples.CircadianOscillator.Container\">Container</a>
 for more documentation and simulation results.
</html>", revisions=""));
      annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000002\">
      <dc:creator rdf:parseType=\"Resource\">
        <rdf:Bag>
          <rdf:li rdf:parseType=\"Resource\">
            <vCard:N rdf:parseType=\"Resource\">
              <vCard:Family>Dharuri</vCard:Family>
              <vCard:Given>Harish</vCard:Given>
            </vCard:N>
            <vCard:EMAIL>hdharuri@cds.caltech.edu</vCard:EMAIL>
            <vCard:ORG>
              <vCard:Orgname>California Institute of Technology</vCard:Orgname>
            </vCard:ORG>
          </rdf:li>
        </rdf:Bag>
      </dc:creator>
      <dcterms:created rdf:parseType=\"Resource\">
        <dcterms:W3CDTF>2008-04-16T11:56:13Z</dcterms:W3CDTF>
      </dcterms:created>
      <dcterms:modified rdf:parseType=\"Resource\">
        <dcterms:W3CDTF>2008-08-20T18:28:56Z</dcterms:W3CDTF>
      </dcterms:modified>
      <bqmodel:is>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:biomodels.db:BIOMD0000000170\"/>
        </rdf:Bag>
      </bqmodel:is>
      <bqmodel:isDescribedBy>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:pubmed:15347590\"/>
        </rdf:Bag>
      </bqmodel:isDescribedBy>
      <bqbiol:isPartOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:kegg.pathway:hsa04710\"/>
        </rdf:Bag>
      </bqbiol:isPartOf>
      <bqbiol:is>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:taxonomy:40674\"/>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0007623\"/>
        </rdf:Bag>
      </bqbiol:is>
    </rdf:Description>
  </rdf:RDF>"));
    end CircadianOscillator;

  end Examples;

  package Compartments "Different types of compartments used in the package"
    extends Icons.Library;
    annotation(Documentation(info="<html>
<h1>Compartments</h1>


 <p>
This package contains compartment models. All models using the BioChem package must inherit a compartment.
In order to be able to control the environment of the reaction during a simulation a chemical reaction must take place in a restricted screened-off container. Within this container the basic physical properties, e.g. volume and temperature, are the same for all reactions that take place and all substances contained in that container. In
<a href=\"Modelica://BioChem.Compartments\">BioChem.Compartments</a>

this is solved using the Modelica inner-outer construct, i.e., providing a \"semiglobal\" variable for a whole compartment declared using the inner prefix. Thus, all substances in a compartment can automatically refer to the compartment volume.
The classes in the package so far are illustrated in
 <a href=\"#fig1\">Figure 1</a>.
 The difference between the both compartments are the icons. The reason for having both in the library is that it is needed for the SBML import and export. To be able to export a model to SBML it needs to have one main compartment, and only one.
</p>

<a name=\"fig1\"></a>
<img src=\"../Images/Compartment.png\" alt=\"Fig1: Compartments\">
 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={5,-7.55952}, lineColor={0,85,0}, fillColor={199,199,149}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-70,-70},{40,30}}, radius=20)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    model Compartment "Default compartment (constant volume)"
      annotation(Documentation(info="<html>
<h1>Compartment</h1>
 <p>
 Default compartment model.
 </p>
 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100,-170},{100,-120}}, textString="%name", fontName="Arial"),Rectangle(visible=true, lineColor={0,85,0}, fillColor={199,199,149}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-110,-110},{110,110}}, radius=20)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      extends BioChem.Interfaces.Compartments.Compartment(V(stateSelect=StateSelect.prefer));
    equation
      der(V)=0 "Compartment volume is constant";
    end Compartment;

    model MainCompartment "Main compartment (constant volume)"
      annotation(Documentation(info="<html>
<h1>MainCompartment</h1>

 <p>
 Main compartment model.
 </p>
 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{-100,-170},{100,-120}}, textString="%name", fontName="Arial"),Rectangle(visible=true, lineColor={0,85,0}, fillColor={199,199,149}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-110,-110},{110,110}}, radius=20),Text(visible=true, fillPattern=FillPattern.Solid, extent={{-82.12,-80},{80,80}}, textString="main", fontName="Arial", textStyle={TextStyle.Bold})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      extends BioChem.Interfaces.Compartments.MainCompartment(V(stateSelect=StateSelect.prefer));
    equation
      der(V)=0 "Compartment volume is constant";
    end MainCompartment;

  end Compartments;

  package Constants "Mathematical constants and constants of nature"
    extends Icons.Library;
    constant Real e=Modelica.Math.exp(1.0);
    constant Real pi=2*Modelica.Math.asin(1.0);
    constant Real inf=1e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    constant Real INF=inf;
    annotation(Documentation(info="<html>
<h1>Constants</h1>
<p>
This package provides often needed mathematical constants that are needed for the SBML import and export.
</p>
</html>
", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, origin={4.3,-7.9383}, fillPattern=FillPattern.Solid, points={{-80,-6.37238},{-80,-6.37238},{-76.12,-6.37238},{-76.12,-6.37238},{-60.75,16.3776},{-9.64,16.3776},{43.88,16.3776},{43.88,16.3776},{43.88,32.7976},{43.88,32.7976},{-11.12,32.7976},{-66.12,32.7976}}, smooth=Smooth.Bezier),Polygon(visible=true, origin={4.3,-7.9383}, fillPattern=FillPattern.Solid, points={{16.84,26.921},{16.84,-51.4935},{33.13,-53.079},{41.24,-38.779},{41.24,-38.779},{45.7,-38.779},{45.7,-38.779},{33.13,-75.549},{6.87,-75.549},{0,-43.079},{5.15652,26.921},{5.15652,26.921},{16.84,26.921}}, smooth=Smooth.Bezier),Polygon(visible=true, origin={4.3,-7.9383}, fillPattern=FillPattern.Solid, points={{-38.493,26.921},{-44.2289,-29.5022},{-70,-66.2689},{-52.4757,-76.921},{-33.5769,-66.2689},{-28.493,26.921},{-28.493,26.921},{-38.493,26.921}}, smooth=Smooth.Bezier)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  end Constants;

end BioChem;
model BioChem_Examples_CircadianOscillator_Container
  extends BioChem.Examples.CircadianOscillator.Container;
end BioChem_Examples_CircadianOscillator_Container;
