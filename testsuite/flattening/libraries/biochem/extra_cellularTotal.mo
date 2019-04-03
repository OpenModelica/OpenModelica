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
    type EquilibriumCoefficient= Real(quantity="Equilibrium coefficient", unit="1") "" annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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

    model BoundarySubstance "Substance with a concentration not determined by reactions, but by events"
      annotation(Documentation(info="<html>
<p>
Substance with a concentration not determined by reactions, i.e., the substance is on the <em>boundary</em> of the reaction system.
The concentration of the substance can only be changed by events.
<p>
Corresponds to SBML species not changed by any SBML rules and with either or both of the <em>boundaryCondition</em> and <em>fixed</em> attributes set to true
</p>
</html>
"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, origin={-1.42109e-14,50}, fillPattern=FillPattern.Solid, extent={{-100,-150},{100,-100}}, textString="%name", fontName="Arial"),Ellipse(visible=true, lineColor={170,0,0}, fillColor={255,0,0}, fillPattern=FillPattern.Sphere, extent={{-50,-50},{50,50}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      extends BioChem.Interfaces.Substances.InputSubstance(n.stateSelect=StateSelect.prefer, c.stateSelect=StateSelect.prefer);
    equation
      der(n)=0;
    end BoundarySubstance;

    model SignalSubstance "Substance with a concentration not determined by reactions, but by external equations (translated into SBML assignments)"
      annotation(Documentation(info="<html>
<p>
Substance with a concentration not determined by reactions, instead the substance consentration is regulated by external equations.
<p>
Corresponds to SBML species changed by any SBML rules.
</p>
</html>
"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, origin={7.10543e-15,50}, fillPattern=FillPattern.Solid, extent={{-100,-150},{100,-100}}, textString="%name", fontName="Arial"),Ellipse(visible=true, lineColor={0,0,127}, fillColor={85,170,255}, fillPattern=FillPattern.Sphere, extent={{-50,-50},{50,50}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      extends BioChem.Interfaces.Substances.InputSubstance;
    end SignalSubstance;

  end Substances;

  package Reactions "Reaction edges"
    extends Icons.Library;
    annotation(Documentation(info="<html>
<h1>Reactions</h1>
 <p>

 This package contains reaction models. Each reaction is represented
 by an arrow, and substances are connected to the arrowheads.
 The reactions in this package accept one to three reactants and products,
 and some reactions also need an activator/inhibitor/modifier.
 Substances are connected to the arrowheads, and activators/inhibitors/modifiers are
 connected to the top or bottom of the circle containing a plus, a minus or the letter M.
 <br><br>
 Reactions can take place between two compartments. If the reaction has more than one substrates or products,
 all substrates need to be located in one compartment, and all products also need to be in one compartment.
 </p>
 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, origin={15.9037,-7.71383}, fillPattern=FillPattern.Solid, extent={{-85.9037,-92.2862},{-50,57.7138}}, textString="A", fontName="Arial"),Text(visible=true, origin={-10,-7.71383}, fillPattern=FillPattern.Solid, extent={{25,-92.2862},{60,57.7138}}, textString="B", fontName="Arial"),Line(visible=true, origin={-0.31,-6.93}, points={{-31.5,-17.25},{10.31,-17.25}}, thickness=3, arrow={Arrow.None,Arrow.Open}, arrowSize=20)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    package FastEquilibrium "Base classes for reactions with fast (instant) equilibrium"
      extends Icons.Library;
      annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>
<h1>FastEquilibrium</h1>
The reaction in the FastEquilibrium package is used to model reactions that are very fast, and could be seen as an instant balance. These models are approximated to very fast reactions, if translated to SBML.

<br>
<img src=\"../Images/Fast.png\" >
<br>
</html>", revisions=""));
      model Uuf "Uni-Uni fast (instant) equilibrium reaction"
        extends BioChem.Interfaces.Reactions.Basics.FastEquilibrium;
        extends BioChem.Interfaces.Reactions.Basics.OneSubstrateReversible;
        extends BioChem.Interfaces.Reactions.Basics.OneProduct;
        parameter BioChem.Units.EquilibriumCoefficient kS1=1 "Equilibrium coefficient for the substrate";
        parameter BioChem.Units.EquilibriumCoefficient kP1=1 "Equilibrium coefficient for the product";
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      equation
        p1.c=s1.c*kP1/kS1;
        s1.r + p1.r=0;
      end Uuf;

    end FastEquilibrium;

  end Reactions;

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
      partial model InputSubstance "Basics for a substance"
        annotation(Documentation(info="<html>
<p>
The base class for all substances.
<p>
Corresponds to SBML species changed by SBML rules and with the <em>boundaryCondition</em> attribute set to true and the <em>constant</em> attribute set to false.
</p>
</html>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={123,152,255}, extent={{-50,-50},{50,50}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        input BioChem.Units.Concentration c "Current concentration of substance (mM)";
        BioChem.Units.MolarFlowRate rNet "Net flow rate of substance into the node";
        BioChem.Units.AmountOfSubstance n "Number of moles of substance in pool (mol)";
        BioChem.Interfaces.Nodes.SubstanceConnector n1 annotation(Placement(visible=true, transformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={0,0}, extent={{-16,-16},{16,16}}, rotation=0)));
      protected
        outer BioChem.Units.Volume V "Compartment volume";
      equation
        rNet=n1.r;
        c=n1.c;
        V=n1.V;
        c=n/V;
      end InputSubstance;

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
      partial model Uur "Uni-Uni reversible reaction"
        extends BioChem.Interfaces.Reactions.Basics.Reaction;
        extends BioChem.Interfaces.Reactions.Basics.OneSubstrateReversible;
        extends BioChem.Interfaces.Reactions.Basics.OneProduct;
        BioChem.Units.StoichiometricCoefficient nS1=1 "Stoichiometric coefficient for the substrate";
        BioChem.Units.StoichiometricCoefficient nP1=1 "Stoichiometric coefficient for the product";
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      equation
        s1.r=nS1*rr;
        p1.r=-nP1*rr;
      end Uur;

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

      partial model Ubi "Uni-Bi irreversible reaction"
        extends BioChem.Interfaces.Reactions.Basics.Reaction;
        extends BioChem.Interfaces.Reactions.Basics.OneSubstrate;
        extends BioChem.Interfaces.Reactions.Basics.TwoProducts;
        BioChem.Units.StoichiometricCoefficient nS1=1 "Stoichiometric coefficient for the substrate";
        BioChem.Units.StoichiometricCoefficient nP1=1 "Stoichiometric coefficient for product 1";
        BioChem.Units.StoichiometricCoefficient nP2=1 "Stoichiometric coefficient for product 2";
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      equation
        s1.r=nS1*rr;
        p1.r=-nP1*rr;
        p2.r=-nP2*rr;
      end Ubi;

      partial model Bui "Bi-Uni irreversible reaction"
        extends BioChem.Interfaces.Reactions.Basics.Reaction;
        extends BioChem.Interfaces.Reactions.Basics.TwoSubstrates;
        extends BioChem.Interfaces.Reactions.Basics.OneProduct;
        BioChem.Units.StoichiometricCoefficient nS1=1 "Stoichiometric coefficient for substrate 1";
        BioChem.Units.StoichiometricCoefficient nS2=1 "Stoichiometric coefficient for substrate 2";
        BioChem.Units.StoichiometricCoefficient nP1=1 "Stoichiometric coefficient for the product";
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      equation
        s1.r=nS1*rr;
        s2.r=nS2*rr;
        p1.r=-nP1*rr;
      end Bui;

      partial model Bbi "Bi-Bi irreversible reaction"
        extends BioChem.Interfaces.Reactions.Basics.Reaction;
        extends BioChem.Interfaces.Reactions.Basics.TwoSubstrates;
        extends BioChem.Interfaces.Reactions.Basics.TwoProducts;
        BioChem.Units.StoichiometricCoefficient nS1=1 "Stoichiometric coefficient for substrate 1";
        BioChem.Units.StoichiometricCoefficient nS2=1 "Stoichiometric coefficient for substrate 2";
        BioChem.Units.StoichiometricCoefficient nP1=1 "Stoichiometric coefficient for product 1";
        BioChem.Units.StoichiometricCoefficient nP2=1 "Stoichiometric coefficient for product 2";
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      equation
        s1.r=nS1*rr;
        s2.r=nS2*rr;
        p1.r=-nP1*rr;
        p2.r=-nP2*rr;
      end Bbi;

      package Modifiers "Partial models of modifiers to reactions"
        extends Icons.Library;
        annotation(Documentation(info="", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model Modifier
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,56.25},{0,6.25}}, color={0,0,255}, arrow={Arrow.None,Arrow.Open}, arrowSize=30)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Interfaces.Nodes.ModifierConnector m1 annotation(Placement(visible=true, transformation(origin={5.55111e-16,90}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-3.10862e-15,90}, extent={{-20,-20},{20,20}}, rotation=0)));
        equation
          m1.r=0;
        end Modifier;

        model MultipleModifiers
          annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={255,255,0}, fillColor={255,255,127}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,65.0},{25.0,115.0}}),Line(visible=true, origin={0.0,29.1679}, points={{0.0,29.17},{0.0,-29.17}}, arrow={Arrow.None,Arrow.Filled}, arrowSize=30)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          parameter Integer dimM "number of modifiers";
          BioChem.Interfaces.Nodes.ModifierConnector m[dimM] annotation(Placement(visible=true, transformation(origin={-2.9976e-15,90}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-8.88178e-16,90}, extent={{-18.75,-18.75},{18.75,18.75}}, rotation=0)));
        equation
          m.r=fill(0, dimM);
        end MultipleModifiers;

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

        model OneSubstrateReversible
          annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-50.0,0.0},{-100.0,0.0}}, color={170,0,0}, arrow={Arrow.None,Arrow.Open}, arrowSize=50)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Interfaces.Nodes.SubstrateConnector s1 annotation(Placement(visible=true, transformation(origin={-80,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-112.5,2.22045e-16}, extent={{-12.5,-12.5},{12.5,12.5}}, rotation=0)));
        end OneSubstrateReversible;

        partial model TwoSubstrates "SubstanceConnectors for two substrates"
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,50},{-62.5,50},{-50,0}}, color={170,0,0}, smooth=Smooth.Bezier),Line(visible=true, points={{-100,-50},{-62.5,-50},{-50,0}}, color={170,0,0}, smooth=Smooth.Bezier)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Interfaces.Nodes.SubstrateConnector s1 annotation(Placement(visible=true, transformation(origin={-100,40}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-112.5,50}, extent={{-12.5,-12.5},{12.5,12.5}}, rotation=0)));
          BioChem.Interfaces.Nodes.SubstrateConnector s2 annotation(Placement(visible=true, transformation(origin={-100,-40}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-112.5,-50}, extent={{-12.5,-12.5},{12.5,12.5}}, rotation=0)));
        end TwoSubstrates;

        partial model TwoProducts "SubstanceConnectors for two products"
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{50,0},{62.5,50},{102.4,50}}, color={170,0,0}, arrow={Arrow.None,Arrow.Open}, arrowSize=35, smooth=Smooth.Bezier),Line(visible=true, points={{50,0},{62.5,-50},{100,-50}}, color={170,0,0}, arrow={Arrow.None,Arrow.Open}, arrowSize=35, smooth=Smooth.Bezier)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Interfaces.Nodes.ProductConnector p2 annotation(Placement(visible=true, transformation(origin={100,-40}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={112.5,-50}, extent={{-12.5,-12.5},{12.5,12.5}}, rotation=0)));
          BioChem.Interfaces.Nodes.ProductConnector p1 annotation(Placement(visible=true, transformation(origin={100,40}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={112.5,50}, extent={{-12.5,-12.5},{12.5,12.5}}, rotation=0)));
        end TwoProducts;

        partial model Reaction "Basics for a reaction edge"
          annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-50,0},{50,0}}, color={170,0,0}),Text(visible=true, origin={-4.44089e-15,1.42109e-14}, fillColor={77,77,77}, fillPattern=FillPattern.Solid, extent={{-100,-150},{97.9,-100}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Units.ReactionRate rr "Rate of the reaction" annotation(__MathCore_reactionrate=true);
        end Reaction;

        partial model FastEquilibrium "Basics for a reaction edge"
          annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-50.0,0.0},{50.0,0.0}}, color={0,0,255}, pattern=LinePattern.DashDotDot, thickness=2),Text(visible=true, origin={-0.0,0.0}, fillColor={77,77,77}, fillPattern=FillPattern.Solid, extent={{-100.0,-150.0},{97.9,-100.0}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        end FastEquilibrium;

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
    package centralMetabolism
      extends BioChem.Icons.Example;
      model cytosol "cytosol"
        extends BioChem.Compartments.Compartment(V(start=2));
        model DHAP_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00111 \"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end DHAP_;

        model G3P_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00661\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end G3P_;

        model NADH_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00004\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end NADH_;

        model FDP_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C05378\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end FDP_;

        model PYR_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00022\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end PYR_;

        model ADP_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00008\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end ADP_;

        model IMP_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00130\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end IMP_;

        model ATP_
          extends BioChem.Substances.SignalSubstance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00002\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end ATP_;

        model AMP_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00020\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end AMP_;

        model LAC_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C01432\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end LAC_;

        model NAD_
          extends BioChem.Substances.SignalSubstance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00003\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end NAD_;

        model CP_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C02305\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end CP_;

        model Cr_
          extends BioChem.Substances.SignalSubstance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00300\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end Cr_;

        model GLY_
          extends BioChem.Substances.BoundarySubstance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00182\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end GLY_;

        model PN_
          extends BioChem.Substances.SignalSubstance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00009\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end PN_;

        model G6P_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00092\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end G6P_;

        model F6P_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C05345\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end F6P_;

        model jda_
          extends BioChem.Interfaces.Reactions.Uur(nS1=cytosol_V/bamp, nP1=cytosol_V);
          parameter Real KmAMP=0.3;
          parameter Real KmIMP=3.54545;
          parameter Real KcatDA=121;
          outer Real cytosol_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real bamp;
        equation
          rr=KcatDA*s1.c/(KmAMP + s1.c) - 0.01*p1.c/(KmIMP + p1.c);
        end jda_;

        model vgpdh_
          extends BioChem.Interfaces.Reactions.Bbi(nS1=2*cytosol_V/badp);
          extends BioChem.Interfaces.Reactions.Modifiers.Modifier;
          parameter Real KcatGPDH=78595.6;
          parameter Real KmGPDH=0.0369;
          parameter Real KmADP=1.4;
          parameter Real KmPN=120;
          outer Real cytosol_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real badp;
        equation
          rr=KcatGPDH*s2.c*s1.c*m1.c/((KmGPDH + s2.c)*(s1.c + KmADP)*(m1.c + KmPN));
        end vgpdh_;

        model vpfk_
          extends BioChem.Interfaces.Reactions.Ubi(nP2=cytosol_V/badp);
          parameter Real n_sbml=2;
          parameter Real KcatPFK=400;
          parameter Real KmF6P=3.49515;
          outer Real cytosol_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real badp;
        equation
          rr=KcatPFK*s1.c^n_sbml/(KmF6P + s1.c^n_sbml);
        end vpfk_;

        model vald_
          extends BioChem.Interfaces.Reactions.Uui(nP1=2);
          parameter Real kt;
          parameter Real ka1=0.01;
          parameter Real ka2=1.65;
          parameter Real ka3=3000;
          parameter Real ka4=0.125;
          parameter Real ka5=340;
          parameter Real ka6=14000000.0;
          parameter Real ka7=56000;
        equation
          rr=(ka7*s1.c - ka6*p1.c*kt*p1.c)/(ka1 + ka2*p1.c + s1.c + ka3*p1.c*s1.c + ka4*kt*p1.c + ka5*p1.c*kt*p1.c);
        end vald_;

        model vldh_
          extends BioChem.Interfaces.Reactions.Bui;
          extends BioChem.Interfaces.Reactions.Modifiers.Modifier;
          parameter Real kia=0.00245;
          parameter Real kmb=0.137;
          parameter Real kip=7.3;
          parameter Real kmq=0.1;
          parameter Real kiq=0.5;
          parameter Real k1ib=0.1;
          parameter Real kmp=1;
          parameter Real kma=0.00844;
          parameter Real kib=0.228;
          parameter Real kf=458;
          parameter Real kr=135;
          parameter Real e0=8;
        equation
          rr=e0*(s2.c*s1.c*kf/(kia*kmb) - kr*p1.c*m1.c/(kiq*kmp))/(s2.c/kia + s2.c*s1.c/(kia*kmb) + s2.c*s1.c*p1.c/(kia*kip*kmb) + s2.c*kmq*p1.c/(kia*kiq*kmp) + (1 + s1.c/k1ib)*(1 + s1.c*kma/(kia*kmb) + kmq*p1.c/(kiq*kmp)) + m1.c/kiq + s1.c*kma*m1.c/(kia*kiq*kmb) + p1.c*m1.c/(kiq*kmp) + s1.c*p1.c*m1.c/(kib*kiq*kmp));
        end vldh_;

        model vpdh_
          extends BioChem.Interfaces.Reactions.Bui(nS2=cytosol_V/badp, nP1=3.67);
          extends BioChem.Interfaces.Reactions.Modifiers.Modifier;
          parameter Real KmPYR=0.5;
          parameter Real KcatPDH=1;
          outer Real cytosol_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real badp;
        equation
          rr=KcatPDH*s1.c*m1.c/((s1.c + KmPYR)*(m1.c + 0.1));
        end vpdh_;

        model jak_
          extends BioChem.Interfaces.Reactions.Uur(nS1=cytosol_V/bamp, nP1=2*cytosol_V/badp);
          extends BioChem.Interfaces.Reactions.Modifiers.Modifier;
          parameter Real KcatAK=150000;
          outer Real cytosol_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real bamp;
          input Real badp;
        equation
          rr=KcatAK*(m1.c*s1.c - p1.c*p1.c)/(1 + s1.c/0.1 + p1.c/0.1 + m1.c*(10 + s1.c/0.01) + p1.c*(10 + p1.c/0.01 + s1.c/3.49));
        end jak_;

        model vgph_
          extends BioChem.Interfaces.Reactions.Uui;
          extends BioChem.Interfaces.Reactions.Modifiers.MultipleModifiers(dimM=3);
          parameter Real kh;
          parameter Real KcatGPH=248;
          input Real bamp;
        equation
          rr=KcatGPH*m[3].c*(0.002 + m[2].c + m[1].c/bamp)/((0.014 + m[2].c + m[1].c/bamp)*(8*(0.01 + m[2].c + m[1].c/bamp)/(0.002 + m[2].c + m[1].c/bamp) + m[3].c));
        end vgph_;

        model jatpase_
          extends BioChem.Interfaces.Reactions.Uui(nP1=cytosol_V/badp);
          parameter Real KcatATPase=370 "I am unsure about this value";
          outer Real cytosol_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real badp;
        equation
          rr=KcatATPase*s1.c/(s1.c + 0.05);
        end jatpase_;

        model jck_
          extends BioChem.Interfaces.Reactions.Bbi(nP1=cytosol_V/badp);
          parameter Real KcatCK=1970;
          outer Real cytosol_V "Variable used to access the volume of an outer compartment. Do not edit.";
          input Real badp;
        equation
          rr=KcatCK*(20*s1.c*s2.c/10.85 - 29.333*p1.c*p2.c/0.1)/(1 + s2.c/34.9 + p2.c/0.8 + s1.c*(1.43 + s2.c/10.85) + p1.c*(16.7 + p2.c/0.1 + s2.c/2.1));
        end jck_;

        inner Real cytosol_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        centralMetabolism.cytosol.NADH_ NADH(c(start=0.00406177)) "NADH" annotation(Placement(visible=true, transformation(origin={100.0,-20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.FDP_ FDP(c(start=0.0999758)) "Fructose 1,6-diphosphate" annotation(Placement(visible=true, transformation(origin={-19.7747,-40.109}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.PYR_ PYR(c(start=0.148871)) "Pyruvate" annotation(Placement(visible=true, transformation(origin={100.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180)));
        centralMetabolism.cytosol.ADP_ ADP(c(start=0.0695775)) "ADP" annotation(Placement(visible=true, transformation(origin={-19.7747,-20.109}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.IMP_ IMP(c(start=0.650608)) "IMP" annotation(Placement(visible=true, transformation(origin={-120.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        centralMetabolism.cytosol.ATP_ ATP(c(start=12.7913)=atp) "ATP" annotation(Placement(visible=true, transformation(origin={-10.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-720)));
        centralMetabolism.cytosol.AMP_ AMP(c(start=0.000398124)) "AMP" annotation(Placement(visible=true, transformation(origin={-120.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        centralMetabolism.cytosol.LAC_ LAC(c(start=4.34299)) "Lactate" annotation(Placement(visible=true, transformation(origin={140.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.NAD_ NAD(c(start=0.695938)=nad) "NAD" annotation(Placement(visible=true, transformation(origin={120.0,-60.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-450)));
        centralMetabolism.cytosol.CP_ CP(c(start=28.2621)) "Phosphocreatine" annotation(Placement(visible=true, transformation(origin={-80.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        centralMetabolism.cytosol.Cr_ Cr(c(start=25.7379)=cr) "Creatine" annotation(Placement(visible=true, transformation(origin={-80.0,50.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180)));
        centralMetabolism.cytosol.GLY_ GLY(c(start=1)) "Glycogen" annotation(Placement(visible=true, transformation(origin={-140.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.PN_ PN(c=pn) "Inorganic phosphate" annotation(Placement(visible=true, transformation(origin={80.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180)));
        centralMetabolism.cytosol.G6P_ G6P(c(start=0.603855/(1 + kh))) "Glucose 6-phosphate" annotation(Placement(visible=true, transformation(origin={-100.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.F6P_ F6P(c(start=0.603855*kh/(1 + kh))) "Fructose 6-phosphate" annotation(Placement(visible=true, transformation(origin={-60.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-360)));
        centralMetabolism.cytosol.jda_ jda(bamp=bamp) "jda" annotation(Placement(visible=true, transformation(origin={-120.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        centralMetabolism.cytosol.vpfk_ vpfk(badp=badp) "vpfk" annotation(Placement(visible=true, transformation(origin={-40.0,-30.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0)));
        centralMetabolism.cytosol.vldh_ vldh "vldh" annotation(Placement(visible=true, transformation(origin={120.0,-30.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0)));
        centralMetabolism.cytosol.vpdh_ vpdh(badp=badp) "vpdh" annotation(Placement(visible=true, transformation(origin={120.0,-90.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.jak_ jak(bamp=bamp, badp=badp) "jak" annotation(Placement(visible=true, transformation(origin={10.0,30.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=90)));
        centralMetabolism.cytosol.vgph_ vgph(bamp=bamp, kh=kh) "vgph" annotation(Placement(visible=true, transformation(origin={-120.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.jatpase_ jatpase(badp=badp) "jatpase" annotation(Placement(visible=true, transformation(origin={-40.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        centralMetabolism.cytosol.jck_ jck(badp=badp) "jck" annotation(Placement(visible=true, transformation(origin={-70.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        BioChem.Interfaces.Nodes.SubstanceConnector node_LAC annotation(Placement(visible=true, transformation(origin={140.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={125.0384,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.mitochondria mitochondria(badp=badp) annotation(Placement(visible=true, transformation(origin={100.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        input Real bamp;
        input Real badp;
        input Real pn;
        input Real atp;
        input Real cr;
        input Real nad;
        parameter Real kh;
        annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<h1>Cytosol</h1>
<a name=\"fig1\"></a>
<img src=\"../Images/figure1.jpg\" width=\"640px\" height=\"446px\" alt=\"Fig1: Biochemical scheme\">
<p><em><strong>Fig. 1.</strong> Scheme of glycolysis and coupled processes simulated in the model: consumption and synthesis of ATP and transformation of reducing equivalents of NADH. The relevant equations, which account for stoicheiometry of the ATP production, are given in Supplementary materials. One molecule of ATP is consumed per molecule of fructose 6-phosphate in the phosphofructokinase reaction; two molecules of ATP per molecule of triose phospate (four molecules per hexose molecule) are then produced on the way to pyruvate; 2.5 molecules of ATP are produced when one molecule of NADH is oxidized. Cytosolic NADH is produced in the reaction of glyceraldehyde-3-phosphate dehydrogenase and consumed when pyruvate is transformed to lactate. In mitochondria one molecule of NADH is produced in the pyruvate dehydrogenase reaction and then three NADH molecules and one FADH2 molecule in the tricarboxylate cycle. Abbreviations: AK, adenylate kinase (EC 2.7.4.3); CK, creatine kinase (EC 2.7.3.2); CP, phosphocreatine; Cr, creatine; F6P, fructose 6-phosphate; FBP, fructose 1,6-bisphosphate; G6P, glucose 6-phosphate; GAPDH, glyceraldehyde-3-phosphate dehydrogenase (EC 1.2.1.12);
GPh, glycogen phosphorylase (EC 2.4.1.1); Lac, lactate; LDH, lactate dehydrogenase (EC 1.1.1.27); PFK, phosphofructokinase (EC 2.7.1.11); GPI, glucose phosphate isomerase (EC 5.3.1.9.); Pyr, pyruvate. Subscripts: m, mitochondrial; c, cytosolic.</em></p>", revisions=""));
        parameter Real kt;
        BioChem.Reactions.FastEquilibrium.Uuf vH6P(kP1=kh) "Fast equilibrium reaction for the compound of G6P and F6P" annotation(Placement(visible=true, transformation(origin={-80.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.vald_ vald(kt=kt) "vald" annotation(Placement(visible=true, transformation(origin={0.2253,-40.109}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0)));
        centralMetabolism.cytosol.DHAP_ DHAP(c.start=0.07427/(1 + kt)) annotation(Placement(visible=true, transformation(origin={20.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.G3P_ G3P(c.start=0.07427*kt/(1 + kt)) annotation(Placement(visible=true, transformation(origin={60.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.cytosol.vgpdh_ vgpdh_1(badp=badp) annotation(Placement(visible=true, transformation(origin={80.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        BioChem.Reactions.FastEquilibrium.Uuf vT3P(kS1=1, kP1=kt) "Fast equilibrium reaction for the compound of G6P and F6P" annotation(Placement(visible=true, transformation(origin={40.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      equation
        connect(PN.n1,vgph.m[3]) annotation(Line(visible=true, origin={-43.1831,-17.0363}, points={{123.1831,7.0363},{23.1831,13.8613},{-53.1252,-3.9637},{-76.8169,-3.9637}}, smooth=Smooth.Bezier));
        connect(vgpdh_1.m1,PN.n1) annotation(Line(visible=true, origin={80.0,-15.5}, points={{0.0,-5.5},{0.0,5.5}}, smooth=Smooth.Bezier));
        connect(PYR.n1,vgpdh_1.p2) annotation(Line(visible=true, origin={94.1667,-38.3333}, points={{5.8333,-1.6667},{-2.9167,-1.6667},{-2.9167,3.3333}}, smooth=Smooth.Bezier));
        connect(PYR.n1,vpdh.s1) annotation(Line(visible=true, origin={99.5833,-70.0}, points={{0.4167,30.0},{-9.5833,-15.0},{9.1667,-15.0}}, smooth=Smooth.Bezier));
        connect(vldh.s1,PYR.n1) annotation(Line(visible=true, origin={105.8333,-38.3333}, points={{2.9167,3.3333},{2.9167,-1.6667},{-5.8333,-1.6667}}, smooth=Smooth.Bezier));
        connect(vT3P.s1,DHAP.n1) annotation(Line(visible=true, origin={24.375,-40.0}, points={{4.375,0.0},{-4.375,0.0}}));
        connect(vT3P.p1,G3P.n1) annotation(Line(visible=true, origin={55.625,-40.0}, points={{-4.375,0.0},{4.375,0.0}}));
        connect(vald.p1,DHAP.n1) annotation(Line(visible=true, origin={14.3169,-40.0363}, points={{-2.8416,-0.0727},{-2.8416,0.0363},{5.6831,0.0363}}));
        connect(ADP.n1,mitochondria.node_ADP) annotation(Line(visible=true, origin={29.9388,18.5441}, points={{-49.7135,-38.6531},{-14.7833,-28.5441},{4.222,16.7428},{57.4791,16.7428}}, smooth=Smooth.Bezier));
        connect(ADP.n1,vpdh.s2) annotation(Line(visible=true, origin={31.3122,-73.3958}, points={{-51.0869,53.2868},{-21.3122,-1.1347},{9.2453,-24.5854},{77.4378,-21.6042}}, smooth=Smooth.Bezier));
        connect(G3P.n1,vgpdh_1.s2) annotation(Line(visible=true, origin={62.9167,-36.6667}, points={{-2.9167,-3.3333},{-2.9167,1.6667},{5.8333,1.6667}}, smooth=Smooth.Bezier));
        connect(vgph.p1,G6P.n1) annotation(Line(visible=true, origin={-105.8333,-30.0}, points={{-2.9167,0.0},{-2.9167,0.0},{5.8333,0.0}}, smooth=Smooth.Bezier));
        connect(jatpase.s1,ATP.n1) annotation(Line(visible=true, origin={-30.0,27.0833}, points={{-10.0,-5.8333},{-10.0,2.9167},{20.0,2.9167}}, smooth=Smooth.Bezier));
        connect(jck.p1,ADP.n1) annotation(Line(visible=true, origin={-63.2582,-1.5662}, points={{-1.7418,20.3162},{-1.7418,1.5662},{43.4835,-18.5428}}, smooth=Smooth.Bezier));
        connect(FDP.n1,vald.s1) annotation(Line(visible=true, origin={-16.8581,-40.109}, points={{-2.9166,0.0},{-2.9167,0.0},{5.8334,0.0}}, smooth=Smooth.Bezier));
        connect(vgpdh_1.p1,NADH.n1) annotation(Line(visible=true, origin={94.1667,-21.6667}, points={{-2.9167,-3.3333},{-2.9167,1.6667},{5.8333,1.6667}}, smooth=Smooth.Bezier));
        connect(vpdh.p1,mitochondria.node_NADHm) annotation(Line(visible=true, origin={128.4604,-19.1758}, points={{2.7896,-70.8242},{21.5396,-70.8242},{19.4827,64.1758},{-15.8864,64.1758}}, smooth=Smooth.Bezier));
        connect(ADP.n1,jak.p1) annotation(Line(visible=true, origin={-4.8874,-4.2701}, points={{-14.8873,-15.8389},{0.2923,-3.5556},{14.8874,7.589},{14.8874,23.0201}}, smooth=Smooth.Bezier));
        connect(NAD.n1,vldh.m1) annotation(Line(visible=true, origin={120.0,-49.5}, points={{0.0,-10.5},{0.0,10.5}}, smooth=Smooth.Bezier));
        connect(Cr.n1,jck.s2) annotation(Line(visible=true, origin={-78.3333,44.1667}, points={{-1.6667,5.8333},{-1.6667,-2.9167},{3.3333,-2.9167}}, smooth=Smooth.Bezier));
        connect(IMP.n1,vgph.m[1]) annotation(Line(visible=true, origin={-120.0,-17.3333}, points={{0.0,7.3333},{0.0,-3.6667},{0.0,-3.6667}}, smooth=Smooth.Bezier));
        connect(ATP.n1,jak.m1) annotation(Line(visible=true, origin={-6.3333,30.0}, points={{-3.6667,0.0},{-3.6667,0.0},{7.3333,0.0}}, smooth=Smooth.Bezier));
        connect(jck.p2,CP.n1) annotation(Line(visible=true, origin={-76.6667,12.9167}, points={{1.6667,5.8333},{1.6667,-2.9167},{-3.3333,-2.9167}}, smooth=Smooth.Bezier));
        connect(AMP.n1,jak.s1) annotation(Line(visible=true, origin={-30.0,71.6841}, points={{-90.0,-41.6841},{-90.0,-1.6841},{40.0,-1.6841},{40.0,-30.4341}}, smooth=Smooth.Bezier));
        connect(jatpase.p1,ADP.n1) annotation(Line(visible=true, origin={-33.2582,-13.8227}, points={{-6.7418,12.5727},{-6.7418,5.6243},{13.4835,-6.2863}}, smooth=Smooth.Bezier));
        connect(FDP.n1,vpfk.p1) annotation(Line(visible=true, origin={-22.6914,-36.7756}, points={{2.9167,-3.3334},{-5.8333,-3.3334},{-6.0586,1.7756}}, smooth=Smooth.Bezier));
        connect(NAD.n1,vpdh.m1) annotation(Line(visible=true, origin={120.0,-70.5}, points={{0.0,10.5},{0.0,-10.5}}, smooth=Smooth.Bezier));
        connect(NADH.n1,mitochondria.node_NADH) annotation(Line(visible=true, origin={108.7675,7.2}, points={{-8.7675,-27.2},{-8.7675,-14.2},{6.845,-14.2},{6.845,27.8},{3.845,27.8}}, smooth=Smooth.Bezier));
        connect(ATP.n1,mitochondria.node_ATP) annotation(Line(visible=true, origin={32.2535,41.25}, points={{-42.2535,-11.25},{-28.6502,3.75},{25.7571,3.75},{55.1466,3.75}}, smooth=Smooth.Bezier));
        connect(F6P.n1,vpfk.s1) annotation(Line(visible=true, origin={-57.0833,-30.0}, points={{-2.9167,0.0},{-2.9167,0.0},{5.8333,0.0}}, smooth=Smooth.Bezier));
        connect(vH6P.s1,G6P.n1) annotation(Line(visible=true, origin={-115.625,-80.0}, points={{24.375,50.0},{15.625,50.0}}, smooth=Smooth.Bezier));
        connect(AMP.n1,vgph.m[2]) annotation(Line(visible=true, origin={-170.5636,9.014}, points={{50.5636,20.986},{20.5636,0.986},{50.5636,-30.014}}, smooth=Smooth.Bezier));
        connect(IMP.n1,jda.p1) annotation(Line(visible=true, origin={-120.0,-4.1667}, points={{0.0,-5.8333},{0.0,2.9167},{0.0,2.9167}}, smooth=Smooth.Bezier));
        connect(ADP.n1,vpfk.p2) annotation(Line(visible=true, origin={-22.6914,-23.4423}, points={{2.9167,3.3333},{-5.8333,3.3333},{-6.0586,-1.5577}}, smooth=Smooth.Bezier));
        connect(vgpdh_1.s1,ADP.n1) annotation(Line(visible=true, origin={8.8565,-22.5545}, points={{59.8935,-2.4455},{-15.6312,-2.4455},{-15.6312,2.4455},{-28.6312,2.4455}}, smooth=Smooth.Bezier));
        connect(vH6P.p1,F6P.n1) annotation(Line(visible=true, origin={-65.8333,-30.0}, points={{-2.9167,0.0},{-2.9167,0.0},{5.8333,0.0}}, smooth=Smooth.Bezier));
        connect(LAC.n1,node_LAC) annotation(Line(visible=true, origin={140.0,-16.6667}, points={{0.0,-13.3333},{0.0,6.6667},{0.0,6.6667}}, smooth=Smooth.Bezier));
        connect(ATP.n1,jck.s1) annotation(Line(visible=true, origin={-43.0,45.9685}, points={{33.0,-15.9685},{33.0,6.2028},{-22.0,6.2028},{-22.0,-1.7185},{-22.0,-4.7185}}, smooth=Smooth.Bezier));
        connect(AMP.n1,jda.s1) annotation(Line(visible=true, origin={-120.0,24.1667}, points={{0.0,5.8333},{0.0,-2.9167},{0.0,-2.9167}}, smooth=Smooth.Bezier));
        connect(vldh.s2,NADH.n1) annotation(Line(visible=true, origin={105.8333,-21.6667}, points={{2.9167,-3.3333},{2.9167,1.6667},{-5.8333,1.6667}}, smooth=Smooth.Bezier));
        connect(LAC.n1,vldh.p1) annotation(Line(visible=true, origin={137.0833,-30.0}, points={{2.9167,0.0},{2.9167,0.0},{-5.8333,0.0}}, smooth=Smooth.Bezier));
        connect(GLY.n1,vgph.s1) annotation(Line(visible=true, origin={-137.0833,-30.0}, points={{-2.9167,0.0},{-2.9167,0.0},{5.8333,0.0}}, smooth=Smooth.Bezier));
      end cytosol;

      model extra_cellular
        annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<h1>Energy metabolism of human muscle</h1>
<p>The model simulates the processes of utilization of energy stored in the form of glycogen. This is the main energy supply of working muscle. The pathway includes glycolytic and TCA cycle reactions stoichiometrically connected with synthesis ATP, which is used mainly for mechanical work (ATPase). The biochemical scheme of the simulated processes is shown in <a href=\"#fig1\">Figure 1</a>.</p>
<a name=\"fig1\"></a>
<img src=\"../Images/figure1a.png\" width=\"640px\" height=\"446px\" alt=\"Fig1: Biochemical scheme\">
<p><em><strong>Fig. 1.</strong> Scheme of glycolysis and coupled processes simulated in the model: consumption and synthesis of ATP and transformation of reducing equivalents of NADH. The relevant equations, which account for stoicheiometry of the ATP production, are given in Supplementary materials. One molecule of ATP is consumed per molecule of fructose 6-phosphate in the phosphofructokinase reaction; two molecules of ATP per molecule of triose phospate (four molecules per hexose molecule) are then produced on the way to pyruvate; 2.5 molecules of ATP are produced when one molecule of NADH is oxidized. Cytosolic NADH is produced in the reaction of glyceraldehyde-3-phosphate dehydrogenase and consumed when pyruvate is transformed to lactate. In mitochondria one molecule of NADH is produced in the pyruvate dehydrogenase reaction and then three NADH molecules and one FADH2 molecule in the tricarboxylate cycle. Abbreviations: AK, adenylate kinase (EC 2.7.4.3); CK, creatine kinase (EC 2.7.3.2); CP, phosphocreatine; Cr, creatine; F6P, fructose 6-phosphate; FBP, fructose 1,6-bisphosphate; G6P, glucose 6-phosphate; GAPDH, glyceraldehyde-3-phosphate dehydrogenase (EC 1.2.1.12);
GPh, glycogen phosphorylase (EC 2.4.1.1); Lac, lactate; LDH, lactate dehydrogenase (EC 1.1.1.27); PFK, phosphofructokinase (EC 2.7.1.11); GPI, glucose phosphate isomerase (EC 5.3.1.9.); Pyr, pyruvate. Subscripts: m, mitochondrial; c, cytosolic.</em></p>
<p>This model was used to study the biochemical effects of training programmes, consisted of 14 training sessions either with 24 (short period, SP) or 72 h (long period, LP) intervals between the individual sessions  (Parra et al., 2000). In this example the analysed data included the change in enzyme activities after both tytes of training as <a href=\"#tab1\">Table 1</a> shows.</p>
<a name=\"tab1\"></a>
<p><em><strong>Table 1</strong><br>
 Measured enzyme activity in biobpsy before and after training (Parra et al. 2000). </em></p>
<img src=\"../Images/table1.jpg\" width=\"640px\" height=\"122px\" alt=\"Tab1:  enzyme activity in biobpsy\">
<p>Moreover, the concentrations of metabolites at rest and after 30s of maximal intensity exercise were measured before and after accomplishing the training programs. The measured metabolites are adenine nucleotides and the forms of creatine (<a href=\"#tab2\">Table 2</a>) and intermediates of glycolysis (<a href=\"#tab3\">Table 3</a>).</p>
<a name=\"tab2\"></a>
<p><em><strong>Table 2</strong></em></p>
<img src=\"../Images/table2.jpg\" width=\"640px\" height=\"306px\" alt=\"Tab2:  concentrations of metabolites at rest and after 30s of maximal intensity exercise \">
<p>The model simulates the experimental data as an example in <a href=\"#fig2\">Figure 2</a> shows. The switch from rest to maximal intensity exercise in the model simulation induced by the change of only one parameter, increase of ATPase activity; stimulation of all the metabolic fluxes is a result of activation by the products of ATP hydrolysis.</p>
<p>
The simulation have shown that after short periods of training the glycolytic flux at rest was three times higher than it had been before training, whereas during exercise the flux and energy consumption remained the same as before training. Long periods of training had less effect on the glycolytic flux at rest, but increased it in response to exercise, increasing the contribution of oxidative phosphorylation.
This model and data analysis are described in (Selivanov VA, de Atauri P, Centelles JJ, Cadefau J, Parra J, Cussó R, Carreras J, Cascante M. (2008) The changes in the energy metabolism of human muscle induced by training.  J Theor Biol. 252, 402-410)
</p>
<a name=\"tab3\"></a>
<p><em><strong>Table 3</strong></em></p>
<img src=\"../Images/table3.jpg\" width=\"640px\" height=\"283px\" alt=\"Tab3:  concentrations of metabolites at rest and after 30s of maximal intensity exercise \">
<br><br>
<a name=\"fig2\"></a>
<img src=\"../Images/figure2.jpg\" width=\"526px\" height=\"620px\" alt=\"Fig2:  concentrations of metabolites during 30s of maximal intensity exercise \">
<p><em><strong>Fig. 2.</strong> Time-courses of high-energy phophates and glycolytic intermediates during 30s of maximal exercise before training. Points with error bars are experimental metabolite concentrations at rest and after 30s of excersise. For simulation at the beginning of excersise (time=0), ATPase activity increased from 3.2 to 200 mM min<sup>-1</sup>. Other parameters are given in Table 1 and Supplementary materials. Abbrevetaions are given in <a href=\"#fig1\">Fig. 1</a>,</em></p>
<h2>Simulations</h2>
<p>The time scale of the model is minutes, so it simulates 0.5 min of maximal intensity exercise. The model produces the same results as seen from experiments.</p>
<p>If simulated for more than 0.5 minutes the model has numerical problems. In real life a person cannot maintain maximal intensity exercise, then fatigue comes and the intensity decreases. So, steady state at maximal intensity does not exist in real life either.</p>
", revisions=""), __MathCore(RDF=""), experiment(StartTime=0.0, StopTime=0.5, Algorithm="dassl", Tolerance=1e-05));
        extends BioChem.Compartments.MainCompartment(V(start=2));
        model LACext_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C01432\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end LACext_;

        model vef_
          extends BioChem.Interfaces.Reactions.Uui;
          parameter Real VmaxEF=15;
          parameter Real KmLAC=26.8483;
        equation
          rr=VmaxEF*s1.c/(KmLAC + s1.c);
        end vef_;

        centralMetabolism.cytosol cytosol(bamp=bamp, badp=badp, kh=kh, pn=pn, atp=atp, kt=kt, nad=nad, cr=cr) annotation(Placement(visible=true, transformation(origin={1.221,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.extra_cellular.vef_ vef "vef" annotation(Placement(visible=true, transformation(origin={40.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-360)));
        centralMetabolism.extra_cellular.LACext_ LACext(c.start=0) "Lactate" annotation(Placement(visible=true, transformation(origin={70.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        inner Real default_V=V "Variable used to make the compartment volume accessible for inner components. Do not edit.";
        inner Real cytosol_V=cytosol.V "Variable used to make the compartment volume of inner compartments accessible. Do not edit.";
        parameter Real iv1=0.603855;
        parameter Real iv2=0.0999758;
        parameter Real iv3=0.07427;
        parameter Real iv4=0.148871;
        parameter Real iv5=4.34299;
        parameter Real iv6=0.00406177;
        parameter Real iv7=1.72073e-05;
        parameter Real iv8=0.0695775;
        parameter Real iv9=28.2621;
        parameter Real iv10=0.000398124;
        parameter Real iv11=0.650608;
        parameter Real nv19=1;
        parameter Real nv20=1.14947;
        parameter Real kamp=0.00841471;
        parameter Real k2amp=200;
        parameter Real kadp=0.05;
        parameter Real k2adp=84.7376;
        parameter Real tan=27.5 "";
        parameter Real tcr=54;
        parameter Real kt=0.085;
        parameter Real kh=0.2;
        parameter Real PNt=139.117;
        Real adpt;
        Real ampt;
        Real atp;
        Real atpt;
        Real badp;
        Real bamp;
        Real pn;
        Real cr;
        Real nad;
      equation
        connect(vef.p1,LACext.n1) annotation(Line(visible=true, origin={60.625,0.0}, points={{-9.375,0.0},{9.375,-0.0}}));
        connect(cytosol.node_LAC,vef.s1) annotation(Line(visible=true, origin={21.2374,-0.0}, points={{-7.5126,0.0},{7.5126,-0.0}}));
        badp=k2adp*kadp/(kadp + cytosol.ADP.c);
        adpt=cytosol.ADP.c*badp;
        atpt=tan - adpt - ampt - cytosol.IMP.c;
        ampt=cytosol.AMP.c*bamp;
        atp=atpt/cytosol.V;
        pn=(PNt - atpt*3 - adpt*2 - ampt - cytosol.CP.c*2 - cytosol.IMP.c - (cytosol.G6P.c + cytosol.F6P.c + cytosol.FDP.c*2 + cytosol.G3P.c + cytosol.DHAP.c)*cytosol.V)/cytosol.V;
        bamp=k2amp*kamp/(kamp + cytosol.AMP.c);
        nad=0.7 - cytosol.NADH.c;
        cr=tcr - cytosol.CP.c;
      end extra_cellular;

      model mitochondria
        extends BioChem.Compartments.Compartment(V.start=2);
        annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model NADH_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00004\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end NADH_;

        model NAD_
          extends BioChem.Substances.Substance;
          annotation(__MathCore(RDF="<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:vCard=\"http://www.w3.org/2001/vcard-rdf/3.0#\" xmlns:bqbiol=\"http://biomodels.net/biology-qualifiers/\" xmlns:bqmodel=\"http://biomodels.net/model-qualifiers/\">
    <rdf:Description rdf:about=\"#\">
      <bqbiol:isVersionOf>
        <rdf:Bag>
          <rdf:li rdf:resource=\"http://www.genome.jp/kegg/#C00003\"/>
        </rdf:Bag>
      </bqbiol:isVersionOf>
    </rdf:Description>
  </rdf:RDF>"));
        end NAD_;

        model jox_
          extends BioChem.Interfaces.Reactions.Bbi(nS1=2.5*cytosol_V/badp);
          outer Real cytosol_V "Variable used to access the volume of an outer compartment. Do not edit.";
          Real badp;
        equation
          rr=10000*s1.c*s2.c/((0.01 + s1.c)*(0.15 + s2.c));
        end jox_;

        model vn_
          extends BioChem.Interfaces.Reactions.Uui;
          parameter Real VmaxN=10.8347;
          parameter Real KmNADH=0.216694;
        equation
          rr=VmaxN*s1.c/(KmNADH + s1.c);
        end vn_;

        centralMetabolism.mitochondria.NADH_ NADHm(c.start=0) "NADH" annotation(Placement(visible=true, transformation(origin={-20.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.mitochondria.NAD_ NADm(c.start=0) "NAD" annotation(Placement(visible=true, transformation(origin={20.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.mitochondria.jox_ jox(badp=badp) "jox" annotation(Placement(visible=true, transformation(origin={-0.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        BioChem.Interfaces.Nodes.SubstrateConnector node_ADP annotation(Placement(visible=true, transformation(origin={-20.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-125.8208,-47.131}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        BioChem.Interfaces.Nodes.SubstanceConnector node_NADHm annotation(Placement(visible=true, transformation(origin={-30.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={125.7398,50.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        centralMetabolism.mitochondria.vn_ vn "vn" annotation(Placement(visible=true, transformation(origin={-50.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        BioChem.Interfaces.Nodes.SubstrateConnector node_NADH annotation(Placement(visible=true, transformation(origin={-80.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={126.1247,-50.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        BioChem.Interfaces.Nodes.ProductConnector node_ATP annotation(Placement(visible=true, transformation(origin={20.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-125.999,50.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Real badp;
      equation
        connect(jox.p1,NADm.n1) annotation(Line(visible=true, origin={14.1667,8.3333}, points={{-2.9167,-3.3333},{-2.9167,1.6667},{5.8333,1.6667}}, smooth=Smooth.Bezier));
        connect(NADHm.n1,node_NADHm) annotation(Line(visible=true, origin={-29.831,-9.3231}, points={{9.831,-0.6769},{-0.169,-0.6769},{-0.169,-20.6769}}, smooth=Smooth.Bezier));
        connect(vn.p1,NADHm.n1) annotation(Line(visible=true, origin={-29.375,-10.0}, points={{-9.375,0.0},{9.375,0.0}}));
        connect(NADHm.n1,jox.s2) annotation(Line(visible=true, origin={-14.1667,-8.3333}, points={{-5.8333,-1.6667},{2.9167,-1.6667},{2.9167,3.3333}}, smooth=Smooth.Bezier));
        connect(jox.p2,node_ATP) annotation(Line(visible=true, origin={17.0833,-6.6667}, points={{-5.8333,1.6667},{2.9167,1.6667},{2.9167,-3.3333}}));
        connect(jox.s1,node_ADP) annotation(Line(visible=true, origin={-14.1667,8.3333}, points={{2.9167,-3.3333},{2.9167,1.6667},{-5.8333,1.6667}}, smooth=Smooth.Bezier));
        connect(vn.s1,node_NADH) annotation(Line(visible=true, origin={-70.625,-10.0}, points={{9.375,0.0},{-9.375,0.0}}));
      end mitochondria;

    end centralMetabolism;

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

end BioChem;
model BioChem_Examples_centralMetabolism_extra_cellular
  extends BioChem.Examples.centralMetabolism.extra_cellular;
end BioChem_Examples_centralMetabolism_extra_cellular;
