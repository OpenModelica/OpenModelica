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
    package CaOscillations "Oxhamre2005_Ca_oscillation"
      extends BioChem.Icons.Example;
      model Cytosol
        extends BioChem.Compartments.MainCompartment(V(start=1));
        import BioChem.Math.*;
        import BioChem.Constants.*;
        model Ca_Cyt_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000007\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.chebi:CHEBI%3A29108\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end Ca_Cyt_;

        model Jpump_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000029\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0051481\"/>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0006816\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          parameter Real Fpump_0=2;
          parameter Real Kpump=0.1;
        equation
          rr=Fpump_0*s1.c/(Kpump + s1.c);
        end Jpump_;

        annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000004\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0005829\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"), experiment(StartTime=0.0, StopTime=120, NumberOfIntervals=-1, Algorithm="dassl", Tolerance=1e-06), Documentation(info="<html>
<h1>Ca Oscillations</h1>
This example is a Modelica version of the model presented in <i>A Minimal Generic Model of Bacteria-Induced Intracellular Ca<sup>2+</sup>
Oscillations in Epithelial Cells</i> by Camilla Oxhamre, Agneta Richter-Dahlfors, Vladimir P. Zhdanov, and Bengt Kasemoy. (Biophysical Journal Volume 88 April 2005 2976-2981)

<h2>Abstract</h2>
The toxin &alpha-hemolysin expressed by uropathogenic Escherichia coli bacteria was recently shown as the first
pathophysiologically relevant protein to induce oscillations of the intracellular Ca<sup>2+</sup> concentration in target cells. Here, we
propose a generic three-variable kinetic model describing the Ca<sup>2+</sup> oscillations induced in single rat renal epithelial cells by this
toxin. Specifically, we take into account the interplay between 1), the cytosolic Ca<sup>2+</sup> concentration; 2), IP<sub>3</sub>-sensitive Ca<sup>2+</sup>
channels located in the membrane separating the cytosol and endoplasmic reticulum; and 3), toxin-related activation of
production of IP<sub>3</sub> by phospholipase C. With these ingredients, the predicted response of cells exposed to the toxin is in good
agreement with the results of experiments.
<h2>Simulations</h2>
The simulation results are shown in the
 <a href=\"#fig1\">Figure 1</a>. This plot corresponds to Fig 1C of the paper (Oxhamre 2005).
<br>

<a name=\"fig1\"></a>
<img src=\"../Images/cytosol.png\" alt=\"Fig1: Simulation results\">
</html>", revisions=""));
        Endoplasmic_Reticulum_Model Endoplasmic_Reticulum(p1_sbml=p1_sbml, p2_sbml=p2_sbml, p3_sbml=p3_sbml) annotation(Placement(visible=true, transformation(origin={-28.4357,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        inner Real Cytosol_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        inner Real Endoplasmic_Reticulum_V=Endoplasmic_Reticulum.V "Variable used to make the compartment volume of inner compartments accessible. Do not edit.";
        Cytosol.Ca_Cyt_ Ca_Cyt(c(start=0)) annotation(Placement(visible=true, transformation(origin={-10.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Real n_sbml(start=1);
        parameter Real n0=1;
        parameter Real kbN=0.5;
        parameter Real kappa=5;
        Real p1_sbml(start=0);
        parameter Real p11=0.2;
        parameter Real p12=0.8;
        parameter Real K1=5;
        Real p2_sbml(start=0);
        parameter Real K2=0.7;
        Real p3_sbml(start=0.95);
        parameter Real k31=0.5;
        parameter Real K3=0.7;
        Cytosol.Jpump_ Jpump annotation(Placement(visible=true, transformation(origin={50.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
      equation
        connect(Ca_Cyt.n1,Endoplasmic_Reticulum.Ca_Cyt_node) annotation(Line(visible=true, origin={-29.2619,-10.8}, points={{19.2619,-29.2},{19.2619,-16.2},{-14.175,-16.2},{-14.175,30.8},{-10.1738,30.8}}, smooth=Smooth.Bezier));
        connect(Endoplasmic_Reticulum.CaER_node,Jpump.p1) annotation(Line(visible=true, origin={27.5214,13.75}, points={{-44.9571,6.25},{22.4786,6.25},{22.4786,-12.5}}, smooth=Smooth.Bezier));
        connect(Ca_Cyt.n1,Jpump.s1) annotation(Line(visible=true, origin={30.0,-33.75}, points={{-40.0,-6.25},{20.0,-6.25},{20.0,12.5}}, smooth=Smooth.Bezier));
        n_sbml=n0*(exp((-kbN)*time) + kappa*(1 - exp((-kbN)*time)));
        p1_sbml=p11 + p12*n_sbml/(K1 + n_sbml);
        p2_sbml=Ca_Cyt.c/(K2 + Ca_Cyt.c);
        der(p3_sbml)=-k31*Ca_Cyt.c*p3_sbml + k31*K3*(1 - p3_sbml);
      end Cytosol;

      model Endoplasmic_Reticulum_Model
        extends BioChem.Compartments.Compartment(V(start=1));
        import BioChem.Math.*;
        import BioChem.Constants.*;
        model CaER_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000006\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.chebi:CHEBI%3A29108\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end CaER_;

        model Jch_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000027\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0051482\"/>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0006816\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          parameter Real Fch_0=8;
          input Real p1_sbml;
          input Real p2_sbml;
          input Real p3_sbml;
        equation
          rr=Fch_0*p1_sbml*p2_sbml*p3_sbml;
        end Jch_;

        model Jleak_
          extends BioChem.Interfaces.Reactions.Uui;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000028\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0006816\"/>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0007204\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
          parameter Real Fleak=0.5;
        equation
          rr=Fleak;
        end Jleak_;

        annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000005\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0005790\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        inner Real Endoplasmic_Reticulum_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        Endoplasmic_Reticulum_Model.CaER_ CaER(c(start=0)) annotation(Placement(visible=true, transformation(origin={10.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-540)));
        input Real p1_sbml;
        input Real p2_sbml;
        input Real p3_sbml;
        BioChem.Interfaces.Nodes.SubstanceConnector Ca_Cyt_node annotation(Placement(visible=true, transformation(origin={-90.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-110.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Endoplasmic_Reticulum_Model.Jch_ Jch(p1_sbml=p1_sbml, p2_sbml=p2_sbml, p3_sbml=p3_sbml) annotation(Placement(visible=true, transformation(origin={-80.0,-20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        Endoplasmic_Reticulum_Model.Jleak_ Jleak annotation(Placement(visible=true, transformation(origin={-80.0,43.7135}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        BioChem.Interfaces.Nodes.SubstanceConnector CaER_node annotation(Placement(visible=true, transformation(origin={90.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      equation
        connect(Jleak.p1,Ca_Cyt_node) annotation(Line(visible=true, origin={-85.0,22.1159}, points={{5.0,10.3476},{5.0,0.8841},{-5.0,0.8841},{-5.0,-12.1159}}, smooth=Smooth.Bezier));
        connect(Jch.p1,Ca_Cyt_node) annotation(Line(visible=true, origin={-85.0,-1.1875}, points={{5.0,-7.5625},{5.0,-1.8125},{-5.0,-1.8125},{-5.0,11.1875}}, smooth=Smooth.Bezier));
        connect(CaER.n1,CaER_node) annotation(Line(visible=true, origin={63.5,5.0}, points={{-53.5,5.0},{13.5,5.0},{13.5,-5.0},{26.5,-5.0}}, smooth=Smooth.Bezier));
        connect(CaER.n1,Jleak.s1) annotation(Line(visible=true, origin={-31.2,38.6787}, points={{41.2,-28.6787},{28.2,-28.6787},{28.2,20.5363},{-48.8,20.5363},{-48.8,16.2848}}, smooth=Smooth.Bezier));
        connect(CaER.n1,Jch.s1) annotation(Line(visible=true, origin={-31.2,-16.4506}, points={{41.2,26.4506},{28.2,26.4506},{28.2,-19.0509},{-48.8,-19.0509},{-48.8,-14.7994}}, smooth=Smooth.Bezier));
      end Endoplasmic_Reticulum_Model;

      annotation(Documentation(info="
<html>
<h1>Ca Oscillations</h1>
This example is a Modelica version of the model presented in <i>A Minimal Generic Model of Bacteria-Induced Intracellular Ca<sup>2+</sup>
Oscillations in Epithelial Cells</i> by Camilla Oxhamre, Agneta Richter-Dahlfors, Vladimir P. Zhdanov, and Bengt Kasemoy. (Biophysical Journal Volume 88 April 2005 2976-2981).<br><br>

See
<a href=\"Modelica://BioChem.Examples.CaOscillations.Cytosol\">Cytosol</a>
 for more documentation and simulation results.
</html>", revisions=""));
      annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#metaid_0000030\">
      <dc:creator rdf:parseType=\"Resource\">
        <rdf:Bag>
          <rdf:li rdf:parseType=\"Resource\">
            <vCard:N rdf:parseType=\"Resource\">
              <vCard:Family>Dharuri</vCard:Family>
              <vCard:Given>Harish</vCard:Given>
            </vCard:N>
            <vCard:EMAIL>Harish_Dharuri@kgi.edu</vCard:EMAIL>
            <vCard:ORG>
              <vCard:Orgname>Keck Graduate Institute</vCard:Orgname>
            </vCard:ORG>
          </rdf:li>
        </rdf:Bag>
      </dc:creator>
      <dcterms:created rdf:parseType=\"Resource\">
        <dcterms:W3CDTF>2005-08-25T11:00:43Z</dcterms:W3CDTF>
      </dcterms:created>
      <dcterms:modified rdf:parseType=\"Resource\">
        <dcterms:W3CDTF>2008-08-21T11:54:50Z</dcterms:W3CDTF>
      </dcterms:modified>
      <bqmodel:is>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:biomodels.db:BIOMD0000000047\"/>
        </rdf:Bag>
      </bqmodel:is>
      <bqmodel:isDescribedBy>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:pubmed:15596518\"/>
        </rdf:Bag>
      </bqmodel:isDescribedBy>
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0019722\"/>
          <rdf:li rdf:resource=\"urn:miriam:obo.go:GO%3A0048016\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
      <bqbiol:is>
        <rdf:Bag>
          <rdf:li rdf:resource=\"urn:miriam:taxonomy:10114\"/>
          <rdf:li rdf:resource=\"urn:miriam:kegg.pathway:rno04020\"/>
        </rdf:Bag>
      </bqbiol:is>
    </rdf:Description>
  </rdf:RDF>"));
    end CaOscillations;

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
model BioChem_Examples_CaOscillations_Cytosol
  extends BioChem.Examples.CaOscillations.Cytosol;
end BioChem_Examples_CaOscillations_Cytosol;
