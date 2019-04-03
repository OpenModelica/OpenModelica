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
        type Volume_litre= Real(final quantity="Volume", final unit="l") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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
    package MichaelisMenten "Michaelis-Menten kinetics reactions"
      extends Icons.Library;
      annotation(Documentation(info="<html>
<h1>MichaelisMenten</h1>
 <p>
This package contains irreversible and reversible Michaelis-Menten reactions. Currently the library is limited to one-substrate and one-product reactions.
Michaelis-Menten kinetics describes the kinetics of many enzymes. It is named after Leonor Michaelis and Maud Menten. This kinetic model is relevant to situations where the concentration of enzyme is much lower than the concentration of substrate (i.e. where enzyme concentration is the limiting factor), and when the enzyme is not allosteric.
 </p>

<br>
<img src=\"../../Images/MichaelisMenten.png\" >
<br>


 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      model Uur "Uni-uni reversible simple Michaelis-Menten"
        annotation(Documentation(info="<html>
 <p>
 Uni-uni reversible simple Michaelis-Menten.
 </p>
 </html>
 "), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        extends BioChem.Interfaces.Reactions.Uur;
        parameter BioChem.Units.Concentration KmS=1 "Forward Michaelis-Menten constant";
        parameter BioChem.Units.Concentration KmP=1 "Reverse Michaelis-Menten constant";
        parameter BioChem.Units.ReactionRate vF=1 "Forward maximum velocity";
        parameter BioChem.Units.ReactionRate vR=1 "Reverse maximum velocity";
      equation
        rr=(vF*s1.c/KmS - vR*p1.c/KmP)/(1 + s1.c/KmS + p1.c/KmP);
      end Uur;

    end MichaelisMenten;

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
        BioChem.Units.Concentration c "Current concentration of substance (mM)";
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

      package Basics "Basic properties of reactions"
        extends Icons.Library;
        annotation(Documentation(info="", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        partial model OneProduct "SubstanceConnector for one product"
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{50,0},{100,0}}, color={170,0,0}, arrow={Arrow.None,Arrow.Open}, arrowSize=50)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Interfaces.Nodes.ProductConnector p1 annotation(Placement(visible=true, transformation(origin={80,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={112.5,2.22045e-16}, extent={{-12.5,-12.5},{12.5,12.5}}, rotation=0)));
        end OneProduct;

        model OneSubstrateReversible
          annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-50.0,0.0},{-100.0,0.0}}, color={170,0,0}, arrow={Arrow.None,Arrow.Open}, arrowSize=50)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          BioChem.Interfaces.Nodes.SubstrateConnector s1 annotation(Placement(visible=true, transformation(origin={-80,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-112.5,2.22045e-16}, extent={{-12.5,-12.5},{12.5,12.5}}, rotation=0)));
        end OneSubstrateReversible;

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
        inner BioChem.Units.Volume V(start=1) "Compartment volume";
      end Compartment;

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
    model EnzMM "An enzymatic reaction with Michaelis-Menten kinetics"
      annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      annotation(Documentation(info="<html>
<h1>EnzMM</h1>

 <p>
 An enzymatic reaction with Michaelis-Menten kinetics.
 The parameter values in this model are arbitrarily chosen,
 to obtain a fully functional model, realistic parameter values must be used.
 </p>
 </html>
 ", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={170,0,0}, fillPattern=FillPattern.Solid, extent={{-100,-25},{-50,25}}),Ellipse(visible=true, fillColor={0,85,0}, fillPattern=FillPattern.Solid, extent={{50,-25},{100,25}}),Line(visible=true, points={{-50,0},{50,0}}, arrow={Arrow.Open,Arrow.Open}, arrowSize=30)}));
      extends BioChem.Compartments.Compartment;
      Substances.Substance F6P(c.start=2) "Fructose-6-phosphate" annotation(Placement(visible=true, transformation(origin={10,10}, extent={{-10,-10},{10,10}}, rotation=0)));
      Reactions.MichaelisMenten.Uur uur(vF=1.5, KmS=0.1, KmP=0.05) annotation(Placement(visible=true, transformation(origin={-10,10}, extent={{-10,-10},{10,10}}, rotation=0)));
      Substances.Substance G6P(c.start=1) "Glucose-6-phosphate" annotation(Placement(visible=true, transformation(origin={-30,10}, extent={{-10,-10},{10,10}}, rotation=0)));
    equation
      connect(uur.p1,F6P.n1) annotation(Line(visible=true, points={{1.25,10},{10,10}}));
      connect(G6P.n1,uur.s1) annotation(Line(visible=true, points={{-30,10},{-21.25,10}}));
    end EnzMM;

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
      extends BioChem.Interfaces.Compartments.Compartment;
    equation
      der(V)=0 "Compartment volume is constant";
    end Compartment;

  end Compartments;

end BioChem;
model BioChem_Examples_EnzMM
  BioChem.Examples.EnzMM t;
end BioChem_Examples_EnzMM;
