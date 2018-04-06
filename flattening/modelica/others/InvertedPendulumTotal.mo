// name: Inverted Pendulum
// status: correct
// cflags:   --std=2.x
//

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
  package Mechanics "Library to model 1-dim. and 3-dim. mechanical systems (multi-body, rotational, translational)"
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-5,-70},{45,-40}}),Ellipse(visible=true, extent={{-90,-60},{-80,-50}}),Line(visible=true, points={{-85,-55},{-60,-21}}, thickness=0.5),Ellipse(visible=true, extent={{-65,-26},{-55,-16}}),Line(visible=true, points={{-60,-21},{9,-55}}, thickness=0.5),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{4,-60},{14,-50}}),Line(visible=true, points={{-10,-34},{72,-34},{72,-76},{-10,-76}})}), Documentation(info="<HTML>
<p>
This package contains components to model the movement
of 1-dim. rotational, 1-dim. translational, and
3-dim. <b>mechanical systems</b>.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>June 23, 2004</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       included the Mechanics.MultiBody library 1.0 and adapted it to the new
       Blocks connectors.</li>
<li><i>Oct. 27, 2003</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Bearing torque computation added to package <b>Rotational</b>.</li>
<li><i>Oct. 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New components and examples in package <b>Rotational</b>.</li>
<li><i>Oct. 24, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Changes according to the Twente meeting introduced. Especially,
       package Rotational1D renamed to Rotational and package
       Translational1D renamed to Translational. For the particular
       changes in these packages, see the corresponding package
       release notes.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version for 1-dimensional rotational mechanical
       systems based on an existing Dymola library of Martin Otter and
       Hilding Elmqvist.</li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    package Translational "Library to model 1-dimensional, translational mechanical systems"
      package Sensors "Sensors for 1-dim. translational mechanical quantities"
        extends Modelica.Icons.Library2;
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-76,-81},{64,-1}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-6,-61},{-16,-37},{4,-37},{-6,-61}}),Line(visible=true, points={{-6,-21},{-6,-37}}),Line(visible=true, points={{-76,-21},{-6,-21}}),Line(visible=true, points={{-56,-61},{-56,-81}}),Line(visible=true, points={{-36,-61},{-36,-81}}),Line(visible=true, points={{-16,-61},{-16,-81}}),Line(visible=true, points={{4,-61},{4,-81}}),Line(visible=true, points={{24,-61},{24,-81}}),Line(visible=true, points={{44,-61},{44,-81}})}), Documentation(info="<html>

</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model PositionSensor "Ideal sensor to measure the absolute position"
          extends Modelica.Icons.TranslationalSensor;
          annotation(Documentation(info="<html>
<p>
Measures the <i>absolute position s</i> of a flange in an ideal way and provides the result as
output signals (to be further processed with blocks of the
Modelica.Blocks library).
</p>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>First Version from August 26, 1999 by P. Beater</i> </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-70,0},{-90,0}}),Line(visible=true, points={{70.4,0},{100,0}}, color={0,0,191}),Text(visible=true, extent={{80,-62},{114,-28}}, textString="s", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{0,40},{0,100}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{100,0},{70,0}}),Line(visible=true, points={{-70,0},{-96,0}}, color={127,255,0})}));
          Interfaces.Flange_a flange_a "flange to be measured (flange axis directed INTO cut plane, e. g. from left to right)" annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Modelica.Blocks.Interfaces.RealOutput s(redeclare type SignalType= SI.Position ) "Absolute position of flange as output signal" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          s=flange_a.s;
          0=flange_a.f;
        end PositionSensor;

      end Sensors;

      import SI = Modelica.SIunits;
      extends Modelica.Icons.Library2;
      annotation(preferedView="info", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-84,-73},{66,-73}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Sphere, extent={{-81,-65},{-8,-22}}),Line(visible=true, points={{-8,-43},{-1,-43},{6,-64},{17,-23},{29,-65},{40,-23},{50,-44},{61,-44}}),Line(visible=true, points={{-59,-73},{-84,-93}}),Line(visible=true, points={{-11,-73},{-36,-93}}),Line(visible=true, points={{-34,-73},{-59,-93}}),Line(visible=true, points={{14,-73},{-11,-93}}),Line(visible=true, points={{39,-73},{14,-93}}),Line(visible=true, points={{63,-73},{38,-93}})}), Documentation(info="<html>
<p>
This package contains components to model <i>1-dimensional translational
mechanical</i> systems.
</p>
<p>
The <i>filled</i> and <i>non-filled green squares</i> at the left and
right side of a component represent <i>mechanical flanges</i>.
Drawing a line between such squares means that the corresponding
flanges are <i>rigidly attached</i> to each other. The components of this
library can be usually connected together in an arbitrary way. E.g. it is
possible to connect two springs or two sliding masses with inertia directly
together.
<p> The only <i>connection restriction</i> is that the Coulomb friction
elements (Stop) should be only connected
together provided a compliant element, such as a spring, is in between.
The reason is that otherwise the frictional force is not uniquely
defined if the elements are stuck at the same time instant (i.e., there
does not exist a unique solution) and some simulation systems may not be
able to handle this situation, since this leads to a singularity during
simulation. It can only be resolved in a \"clean way\" by combining the
two connected friction elements into
one component and resolving the ambiguity of the frictional force in the
stuck mode.
</p>
<p> Another restriction arises if the hard stops in model Stop are used, i. e.
the movement of the mass is limited by a stop at smax or smin.
<font color=\"#ff0000\"> <b>This requires the states Stop.s and Stop.v</b> </font>. If these states are eliminated during the index reduction
the model will not work. To avoid this any inertias should be connected via springs
to the Stop element, other sliding masses, dampers or hydraulic chambers must be avoided. </p>
<p>
In the <i>icon</i> of every component an <i>arrow</i> is displayed in grey
color. This arrow characterizes the coordinate system in which the vectors
of the component are resolved. It is directed into the positive
translational direction (in the mathematical sense).
In the flanges of a component, a coordinate system is rigidly attached
to the flange. It is called <i>flange frame</i> and is directed in parallel
to the component coordinate system. As a result, e.g., the positive
cut-force of a \"left\" flange (flange_a) is directed into the flange, whereas
the positive cut-force of a \"right\" flange (flange_b) is directed out of the
flange. A flange is described by a Modelica connector containing
the following variables:
</p>
<pre>
   SIunits.Position s  \"absolute position of flange\";
   <i>flow</i> Force f        \"cut-force in the flange\";
</pre>

<p>
This library is designed in a fully object oriented way in order that
components can be connected together in every meaningful combination
(e.g. direct connection of two springs or two shafts with inertia).
As a consequence, most models lead to a system of
differential-algebraic equations of <i>index 3</i> (= constraint
equations have to be differentiated twice in order to arrive at
a state space representation) and the Modelica translator or
the simulator has to cope with this system representation.
According to our present knowledge, this requires that the
Modelica translator is able to symbolically differentiate equations
(otherwise it is e.g. not possible to provide consistent initial
conditions; even if consistent initial conditions are present, most
numerical DAE integrators can cope at most with index 2 DAEs).
</p>

<dl>
<dt><b>Main Author:</b></dt>
<dd>Peter Beater <br>
    Universit&auml;t Paderborn, Abteilung Soest<br>
    Fachbereich Maschinenbau/Automatisierungstechnik<br>
    L&uuml;becker Ring 2 <br>
    D 59494 Soest <br>
    Germany <br>
    email: <A HREF=\"mailto:Beater@mailso.uni-paderborn.de\">Beater@mailso.uni-paderborn.de</A><br>
</dd>
</dl>

<p>
Copyright &copy; 1998-2006, Modelica Association and Universit&auml;t Paderborn, FB 12.
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
<li><i>Version 1.0 (January 5, 2000)</i>
       by Peter Beater <br>
       Realized a first version based on Modelica library Mechanics.Rotational
       by Martin Otter and an existing Dymola library onedof.lib by Peter Beater.
       <br>
<li><i>Version 1.01 (July 18, 2001)</i>
       by Peter Beater <br>
       Assert statement added to \"Stop\", small bug fixes in examples.
       <br><br>
</li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      package Interfaces "Interfaces for 1-dim. translational mechanical components"
        extends Modelica.Icons.Library;
        connector Flange_a "(left) 1D translational flange (flange axis directed INTO cut plane, e. g. from left to right)"
          annotation(defaultComponentName="flange_a", Documentation(info="<html>
This is a flange for 1D translational mechanical systems. In the cut plane of
the flange a unit vector n, called flange axis, is defined which is directed
INTO the cut plane, i. e. from left to right. All vectors in the cut plane are
resolved with respect to
this unit vector. E.g. force f characterizes a vector which is directed in
the direction of n with value equal to f. When this flange is connected to
other 1D translational flanges, this means that the axes vectors of the connected
flanges are identical.
</p>
<p>
The following variables are transported through this connector:
<pre>
  s: Absolute position of the flange in [m]. A positive translation
     means that the flange is translated along the flange axis.
  f: Cut-force in direction of the flange axis in [N].
</pre>
</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,191,0}, fillColor={0,191,0}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,191,0}, fillColor={0,191,0}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}}),Text(visible=true, lineColor={0,191,0}, fillColor={0,191,0}, extent={{-160,50},{40,110}}, textString="%name", fontName="Arial")}));
          SI.Position s "absolute position of flange";
          flow SI.Force f "cut force directed into flange";
        end Flange_a;

        connector Flange_b "right 1D translational flange (flange axis directed OUT OF cut plane)"
          SI.Position s "absolute position of flange";
          flow SI.Force f "cut force directed into flange";
          annotation(defaultComponentName="flange_b", Documentation(info="<html>
This is a flange for 1D translational mechanical systems. In the cut plane of
the flange a unit vector n, called flange axis, is defined which is directed
OUT OF the cut plane. All vectors in the cut plane are resolved with respect to
this unit vector. E.g. force f characterizes a vector which is directed in
the direction of n with value equal to f. When this flange is connected to
other 1D translational flanges, this means that the axes vectors of the connected
flanges are identical.
</p>
<p>
The following variables are transported through this connector:
<pre>
  s: Absolute position of the flange in [m]. A positive translation
     means that the flange is translated along the flange axis.
  f: Cut-force in direction of the flange axis in [N].
</pre>
</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,191,0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,191,0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}}),Text(visible=true, lineColor={0,191,0}, fillColor={0,191,0}, extent={{-40,50},{160,110}}, textString="%name", fontName="Arial")}));
        end Flange_b;

        partial model Compliant "Compliant connection of two translational 1D flanges"
          SI.Distance s_rel "relative distance (= flange_b.s - flange_a.s)";
          SI.Force f "forcee between flanges (positive in direction of flange axis R)";
          annotation(Documentation(info="<html>
<p>
This is a 1D translational component with a <i>compliant </i>connection of two
translational 1D flanges where inertial effects between the two
flanges are not included. The absolute value of the force at the left and the right
flange is the same. It is used to built up springs, dampers etc.
</p>

</HTML>
", revisions="<html>
<p>
<b>Release Notes:</b></p>
<ul>
<li><i>First Version from August 26, 1999 by P. Beater (based on Rotational.Compliant)</i> </li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{50,-90},{20,-80},{20,-100},{50,-90}}),Line(visible=true, points={{-60,-90},{20,-90}})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Flange_a flange_a "(left) driving flange (flange axis directed INTO cut plane, e. g. from left to right)" annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Flange_b flange_b "(right) driven flange (flange axis directed OUT OF cut plane)" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          s_rel=flange_b.s - flange_a.s;
          flange_b.f=f;
          flange_a.f=-f;
        end Compliant;

        annotation(Documentation(info="<html>

</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end Interfaces;

      model Damper "Linear 1D translational damper"
        extends Interfaces.Compliant;
        parameter Real d(final unit="N/ (m/s)", final min=0)=0 "damping constant [N/ (m/s)]";
        SI.Velocity v_rel "relative velocity between flange_a and flange_b";
        annotation(Documentation(info="<html>
<p>
<i>Linear, velocity dependent damper</i> element. It can be either connected
between a sliding mass and the housing (model Fixed), or
between two sliding masses.
</p>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>First Version from August 26, 1999 by P. Beater (based on Rotational.Damper)</i> </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{-60,0}}),Line(visible=true, points={{-60,-30},{-60,30}}),Line(visible=true, points={{-60,-30},{60,-30}}),Line(visible=true, points={{-60,30},{60,30}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-60,-30},{30,30}}),Line(visible=true, points={{30,0},{90,0}}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{50,-90},{20,-80},{20,-100},{50,-90}}),Line(visible=true, points={{-60,-90},{20,-90}}),Text(visible=true, fillColor={0,0,255}, extent={{0,46},{0,106}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{-60,0}}),Line(visible=true, points={{-60,-30},{-60,30}}),Line(visible=true, points={{-60,-30},{60,-30}}),Line(visible=true, points={{-60,30},{60,30}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-60,-30},{30,30}}),Line(visible=true, points={{30,0},{90,0}}),Line(visible=true, points={{-50,60},{50,60}}, color={128,128,128}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{50,63},{60,60},{50,57},{50,63}}),Text(visible=true, fillColor={128,128,128}, extent={{-40,68},{38,90}}, textString="der(s_rel)", fontName="Arial")}));
      equation
        v_rel=der(s_rel);
        f=d*v_rel;
      end Damper;

    end Translational;

    package Rotational "Library to model 1-dimensional, rotational mechanical systems"
      package Sensors "Sensors to measure variables in 1D rotational mechanical components"
        model AngleSensor "Ideal sensor to measure the absolute flange angle"
          extends Modelica.Icons.RotationalSensor;
          annotation(Documentation(info="<html>
<p>
Measures the <b>absolute angle phi</b> of a flange in an ideal
way and provides the result as output signal <b>phi</b>
(to be further processed with blocks of the Modelica.Blocks library).
</p>

</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-70,0},{-96,0}}),Line(visible=true, points={{70,0},{100,0}})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{70,-70},{120,-30}}, textString="phi", fontName="Arial"),Line(visible=true, points={{-70,0},{-90,0}}),Line(visible=true, points={{70,0},{100,0}}, color={0,0,191}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,80},{150,120}}, textString="%name", fontName="Arial")}));
          Interfaces.Flange_a flange_a "flange to be measured" annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Modelica.Blocks.Interfaces.RealOutput phi(redeclare type SignalType= SI.Angle ) "Absolute angle of flange" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          phi=flange_a.phi;
          0=flange_a.tau;
        end AngleSensor;

        extends Modelica.Icons.Library2;
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-56,-61},{-56,-81}}),Line(visible=true, points={{-36,-61},{-36,-81}}),Line(visible=true, points={{-16,-61},{-16,-81}}),Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-76,-81},{64,-1}}),Line(visible=true, points={{4,-61},{4,-81}}),Line(visible=true, points={{24,-61},{24,-81}}),Line(visible=true, points={{44,-61},{44,-81}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-6,-61},{-16,-37},{4,-37},{-6,-61}}),Line(visible=true, points={{-6,-21},{-6,-37}}),Line(visible=true, points={{-76,-21},{-6,-21}}),Line(visible=true, points={{-56,-61},{-56,-81}}),Line(visible=true, points={{-36,-61},{-36,-81}}),Line(visible=true, points={{-16,-61},{-16,-81}})}), Documentation(info="<html>
<p>
This package contains ideal sensor components that provide
the connector variables as signals for further processing with the
Modelica.Blocks library.
</p>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end Sensors;

      import SI = Modelica.SIunits;
      extends Modelica.Icons.Library2;
      annotation(preferedView="info", Documentation(info="<html>

<p>
Library <b>Rotational</b> is a <b>free</b> Modelica package providing
1-dimensional, rotational mechanical components to model in a convenient way
drive trains with frictional losses. A typical, simple example is shown
in the next figure:
</p>

<p><img src=\"../Images/Rotational/driveExample.png\"></p>

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"Modelica://Modelica.Mechanics.Rotational.UsersGuide\">Rotational.UsersGuide</a>
     discusses the most important aspects how to use this library.</li>
<li> <a href=\"Modelica://Modelica.Mechanics.Rotational.Examples\">Rotational.Examples</a>
     contains examples that demonstrate the usage of this library.</li>
</ul>

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
", revisions=""), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-83,-66},{-63,-66}}),Line(visible=true, points={{36,-68},{56,-68}}),Line(visible=true, points={{-73,-66},{-73,-91}}),Line(visible=true, points={{46,-68},{46,-91}}),Line(visible=true, points={{-83,-29},{-63,-29}}),Line(visible=true, points={{36,-32},{56,-32}}),Line(visible=true, points={{-73,-9},{-73,-29}}),Line(visible=true, points={{46,-12},{46,-32}}),Line(visible=true, points={{-73,-91},{46,-91}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-47,-80},{27,-17}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-87,-54},{-47,-41}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{27,-56},{66,-42}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      package Interfaces "Connectors and partial models for 1D rotational mechanical components"
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Documentation(info="<html>
<p>
This package contains connectors and partial models for 1-dim.
rotational mechanical components. The components of this package can
only be used as basic building elements for models.
</p>

</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        connector Flange_a "1D rotational flange (filled square icon)"
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
          annotation(defaultComponentName="flange_a", Documentation(info="<HTML>
<p>
This is a connector for 1D rotational mechanical systems and models
a mechanical flange. The following variables are defined in this connector:
</p>
<pre>
   <b>phi</b>: Absolute rotation angle of the flange in [rad].
   <b>tau</b>: Cut-torque in the flange in [Nm].
</pre>
<p>
There is a second connector for flanges: Flange_b. The connectors
Flange_a and Flange_b are completely identical. There is only a difference
in the icons, in order to easier identify a flange variable in a diagram.
For a discussion on the actual direction of the cut-torque tau and
of the rotation angle, see the information text of package Rotational
(section 4. Sign conventions).
</p>
<p>
If needed, the absolute angular velocity w and the
absolute angular acceleration a of the flange can be determined by
differentiation of the flange angle phi:
</p>
<pre>
     w = der(phi);    a = der(w)
</pre>

</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-160,50},{40,90}}, textString="%name", fontName="Arial"),Ellipse(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}})}));
        end Flange_a;

        connector Flange_b "1D rotational flange (non-filled square icon)"
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
          annotation(defaultComponentName="flange_b", Documentation(info="<HTML>
<p>
This is a connector for 1D rotational mechanical systems and models
a mechanical flange. The following variables are defined in this connector:
</p>
<pre>
   <b>phi</b>: Absolute rotation angle of the flange in [rad].
   <b>tau</b>: Cut-torque in the flange in [Nm].
</pre>
<p>
There is a second connector for flanges: Flange_a. The connectors
Flange_a and Flange_b are completely identical. There is only a difference
in the icons, in order to easier identify a flange variable in a diagram.
For a discussion on the actual direction of the cut-torque tau and
of the rotation angle, see the information text of package Rotational
(section 4. Sign conventions).
</p>
<p>
If needed, the absolute angular velocity w and the
absolute angular acceleration a of the flange can be determined by
differentiation of the flange angle phi:
</p>
<pre>
     w = der(phi);    a = der(w)
</pre>

</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-98,-100},{102,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}}),Text(visible=true, extent={{-40,50},{160,90}}, textString="%name", fontName="Arial")}));
        end Flange_b;

        partial model Compliant "Base class for the compliant connection of two rotational 1D flanges"
          SI.Angle phi_rel(start=0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
          SI.Torque tau "Torque between flanges (= flange_b.tau)";
          annotation(Documentation(info="<html>
<p>
This is a 1D rotational component with a compliant connection of two
rotational 1D flanges where inertial effects between the two
flanges are neglected. The basic assumption is that the cut-torques
of the two flanges sum-up to zero, i.e., they have the same absolute value
but opposite sign: flange_a.tau + flange_b.tau = 0. This base class
is used to built up force elements such as springs, dampers, friction.
</p>

</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Flange_a flange_a "(left) driving flange (flange axis directed INTO cut plane)" annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Flange_b flange_b "(right) driven flange (flange axis directed OUT OF cut plane)" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          phi_rel=flange_b.phi - flange_a.phi;
          flange_b.tau=tau;
          flange_a.tau=-tau;
        end Compliant;

        partial model TwoFlanges "Base class for a component with two rotational 1D flanges"
          annotation(Documentation(info="<html>
<p>
This is a 1D rotational component with two flanges.
It is used e.g. to build up parts of a drive train consisting
of several base components. There are specialized versions of this
base class for rigidly connected flanges (Interfaces.Rigid) and
for a compliant connection of flanges (Interfaces.Compliant).
</p>

</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Flange_a flange_a annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Flange_b flange_b annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        end TwoFlanges;

        partial model Bearing "Base class for interface classes with bearing connector"
          extends TwoFlanges;
          SI.Torque tau_support;
          annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-20,-120},{20,-80}})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-20,-120},{20,-80}})}), Documentation(info="<html>
<p>
This is a 1D rotational component with two flanges and an additional bearing flange.
It is a superclass for the two components TwoFlangesAndBearing and TwoFlangesAndBearingH.</p>

</HTML>
"));
          Flange_a bearing annotation(Placement(visible=true, transformation(origin={0,-100}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={0,-100}, extent={{-10,-10},{10,10}}, rotation=0)));
        end Bearing;

        partial model TwoFlangesAndBearing "Base class for a equation-based component with two rotational 1D flanges and one rotational 1D bearing flange"
          extends Bearing;
          SI.Angle phi_a;
          SI.Angle phi_b;
          annotation(Documentation(info="<html>
<p>
This is a 1D rotational component with two flanges and an additional bearing flange.
It is used e.g. to build up equation-based parts of a drive train.</p>

</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        equation
          if cardinality(bearing) == 0 then
            bearing.phi=0;
          else
            bearing.tau=tau_support;
          end if;
          0=flange_a.tau + flange_b.tau + tau_support;
          phi_a=flange_a.phi - bearing.phi;
          phi_b=flange_b.phi - bearing.phi;
        end TwoFlangesAndBearing;

      end Interfaces;

      model IdealGear "Ideal gear without inertia"
        extends Interfaces.TwoFlangesAndBearing;
        parameter Real ratio=1 "Transmission ratio (flange_a.phi/flange_b.phi)";
        annotation(Documentation(info="<html>
<p>
This element characterices any type of gear box which is fixed in the
ground and which has one driving shaft and one driven shaft.
The gear is <b>ideal</b>, i.e., it does not have inertia, elasticity, damping
or backlash. If these effects have to be considered, the gear has to be
connected to other elements in an appropriate way.
</p>

</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40,-20},{-20,20}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40,20},{-20,140}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{20,60},{40,100}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{20,-60},{40,60}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-96,-10},{-40,10}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{40,-10},{96,10}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-20,70},{20,90}}),Line(visible=true, points={{-90,-80},{-20,-80}}, color={128,128,128}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{0,-80},{-20,-75},{-20,-85},{0,-80}}),Text(visible=true, fillColor={128,128,128}, extent={{34,-86},{34,-72}}, textString="rotation axis", fontName="Arial"),Line(visible=true, points={{-80,20},{-60,20}}),Line(visible=true, points={{-80,-20},{-60,-20}}),Line(visible=true, points={{-70,-20},{-70,-70}}),Line(visible=true, points={{70,-70},{-70,-70}}),Line(visible=true, points={{0,60},{0,-90}}),Line(visible=true, points={{-10,60},{10,60}}),Line(visible=true, points={{-10,100},{10,100}}),Line(visible=true, points={{60,20},{80,20}}),Line(visible=true, points={{60,-20},{80,-20}}),Line(visible=true, points={{70,-20},{70,-70}})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40,-20},{-20,20}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40,20},{-20,140}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{20,60},{40,100}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{20,-60},{40,60}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{40,-10},{100,10}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-20,70},{20,90}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-100,-10},{-40,10}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,140},{150,180}}, textString="%name=%ratio", fontName="Arial"),Line(visible=true, points={{-80,20},{-60,20}}),Line(visible=true, points={{-80,-20},{-60,-20}}),Line(visible=true, points={{-70,-20},{-70,-70}}),Line(visible=true, points={{0,60},{0,-90}}),Line(visible=true, points={{-10,60},{10,60}}),Line(visible=true, points={{-10,100},{10,100}}),Line(visible=true, points={{60,-20},{80,-20}}),Line(visible=true, points={{60,20},{80,20}}),Line(visible=true, points={{70,-20},{70,-70}}),Line(visible=true, points={{70,-70},{-70,-70}})}));
      equation
        phi_a=ratio*phi_b;
        0=ratio*flange_a.tau + flange_b.tau;
      end IdealGear;

      model IdealGearR2T "Gearbox transforming rotational into translational motion"
        parameter Real ratio(final unit="rad/m")=1 "transmission ratio (flange_a.phi/flange_b.s)";
        SI.Torque tau_support;
        SI.Force f_support;
        annotation(Documentation(info="<html>
This is an ideal mass- and inertialess gearbox which transforms a
1D-rotational into a 1D-translational motion. If elasticity, damping
or backlash has to be considered, this ideal gearbox has to be
connected with corresponding elements.
</p>

</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-80,-120},{-40,-80}}),Rectangle(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{40,-120},{80,-80}}),Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-40},{10,40}}),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{-40,-10},{-20,10}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-96,-10},{-70,10}}),Rectangle(visible=true, fillColor={160,160,160}, fillPattern=FillPattern.Solid, extent={{-74,-80},{106,-60}}),Rectangle(visible=true, fillColor={160,160,160}, fillPattern=FillPattern.Solid, extent={{95,-60},{106,-10}}),Text(visible=true, extent={{-100,40},{100,70}}, textString="transform rotation into translation", fontName="Arial"),Polygon(visible=true, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-74,-60},{-54,-40},{-34,-60},{-14,-40},{6,-60},{26,-40},{46,-60},{66,-40},{86,-60},{-74,-60}}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{16,80},{-4,85},{-4,75},{16,80}}),Line(visible=true, points={{-74,80},{-3,80}}, color={128,128,128}),Text(visible=true, fillColor={128,128,128}, extent={{21,75},{89,88}}, textString="rotation axis", fontName="Arial")}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{40,-120},{80,-80}}),Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-40},{10,40}}),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{-40,-10},{-20,10}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-100,-10},{-70,10}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,50},{150,90}}, textString="%name=%ratio", fontName="Arial"),Polygon(visible=true, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-74,-60},{-54,-40},{-34,-60},{-14,-40},{6,-60},{26,-40},{46,-60},{66,-40},{86,-60},{-74,-60}}),Rectangle(visible=true, fillColor={160,160,160}, fillPattern=FillPattern.Solid, extent={{95,-60},{106,-10}}),Rectangle(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-80,-120},{-40,-80}}),Rectangle(visible=true, fillColor={160,160,160}, fillPattern=FillPattern.Solid, extent={{-74,-80},{106,-60}})}));
        Interfaces.Flange_a flange_a annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        Modelica.Mechanics.Translational.Interfaces.Flange_b flange_b annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,10},{10,-10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,10},{10,-10}}, rotation=0)));
        Interfaces.Flange_a bearingR annotation(Placement(visible=true, transformation(origin={-60,-100}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-60,-100}, extent={{-10,-10},{10,10}}, rotation=0)));
        Translational.Interfaces.Flange_a bearingT annotation(Placement(visible=true, transformation(origin={60,-100}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={60,-100}, extent={{-10,-10},{10,10}}, rotation=0)));
      equation
        flange_a.phi - bearingR.phi=ratio*(flange_b.s - bearingT.s);
        0=ratio*flange_a.tau + flange_b.f;
        0=flange_a.tau + tau_support;
        0=flange_b.f + f_support;
        if cardinality(bearingR) == 0 then
          bearingR.phi=0;
        else
          bearingR.tau=tau_support;
        end if;
        if cardinality(bearingT) == 0 then
          bearingT.s=0;
        else
          bearingT.f=f_support;
        end if;
      end IdealGearR2T;

      model Damper "Linear 1D rotational damper"
        extends Interfaces.Compliant;
        parameter Real d(final unit="N.m.s/rad", final min=0)=0 "Damping constant";
        SI.AngularVelocity w_rel "Relative angular velocity between flange_b and flange_a";
        annotation(Documentation(info="<html>
<p>
<b>Linear, velocity dependent damper</b> element. It can be either connected
between an inertia or gear and the housing (component Fixed), or
between two inertia/gear elements.
</p>

</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-96,0},{-60,0}}),Line(visible=true, points={{-60,-30},{-60,30}}),Line(visible=true, points={{-60,-30},{60,-30}}),Line(visible=true, points={{-60,30},{60,30}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-60,-30},{30,30}}),Line(visible=true, points={{30,0},{96,0}}),Line(visible=true, points={{-68,0},{-68,65}}, color={128,128,128}),Text(visible=true, fillColor={0,0,255}, extent={{-22,62},{18,87}}, textString="phi_rel", fontName="Arial"),Line(visible=true, points={{-68,60},{72,60}}, color={128,128,128}),Line(visible=true, points={{72,0},{72,65}}, color={128,128,128}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{62,63},{72,60},{62,57},{62,63}}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{10,-60},{-10,-55},{-10,-65},{10,-60}}),Line(visible=true, points={{-80,-60},{-9,-60}}, color={128,128,128}),Text(visible=true, fillColor={128,128,128}, extent={{14,-66},{82,-53}}, textString="rotation axis", fontName="Arial")}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{-60,0}}),Line(visible=true, points={{-60,-30},{-60,30}}),Line(visible=true, points={{-60,-30},{60,-30}}),Line(visible=true, points={{-60,30},{60,30}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-60,-30},{30,30}}),Line(visible=true, points={{30,0},{90,0}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,40},{150,80}}, textString="%name", fontName="Arial"),Text(visible=true, extent={{-150,-90},{150,-50}}, textString="d=%d", fontName="Arial")}));
      equation
        w_rel=der(phi_rel);
        tau=d*w_rel;
      end Damper;

    end Rotational;

  end Mechanics;

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
    package Matrices "Functions on matrices"
      extends Modelica.Icons.Library;
      annotation(preferedView="info", version="0.8.1", versionDate="2004-08-21", Documentation(info="<HTML>
<h3><font color=\"#008000\">Library content</font></h3>
<p>
This library provides functions operating on matrices:
</p>
<table border=1 cellspacing=0 cellpadding=2>
  <tr><th><i>Function</i></th>
      <th><i>Description</i></th>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.norm\">norm</a>(A)</td>
      <td>1-, 2- and infinity-norm of matrix A</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.isEqual\">isEqual</a>(M1, M2)</td>
      <td>determines whether two matrices have the same size and elements</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.solve\">solve</a>(A,b)</td>
      <td>Solve real system of linear equations A*x=b with a b vector</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.leastSquares\">leastSquares</a>(A,b)</td>
      <td>Solve overdetermined or underdetermined real system of <br>
          linear equations A*x=b in a least squares sense</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.equalityLeastSquares\">equalityLeastSquares</a>(A,a,B,b)</td>
      <td>Solve a linear equality constrained least squares problem:<br>
          min|A*x-a|^2 subject to B*x=b</td>
  </tr>
  <tr><td>(LU,p,info) = <a href=\"Modelica:Modelica.Math.Matrices.LU\">LU</a>(A)</td>
      <td>LU decomposition of square or rectangular matrix</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.LU_solve\">LU_solve</a>(LU,p,b)</td>
      <td>Solve real system of linear equations P*L*U*x=b with a<br>
          b vector and an LU decomposition from \"LU(..)\"</td>
  </tr>
  <tr><td>(Q,R,p) = <a href=\"Modelica:Modelica.Math.Matrices.QR\">QR</a>(A)</td>
      <td> QR decomposition with column pivoting of rectangular matrix (Q*R = A[:,p]) </td>
  </tr>
  <tr><td>eval = <a href=\"Modelica:Modelica.Math.Matrices.eigenValues\">eigenValues</a>(A)<br>
          (eval,evec) = <a href=\"Modelica:Modelica.Math.Matrices.eigenValues\">eigenValues</a>(A)</td>
      <td> compute eigenvalues and optionally eigenvectors<br>
           for a real, nonsymmetric matrix </td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.eigenValueMatrix\">eigenValueMatrix</a>(eigen)</td>
      <td> return real valued block diagonal matrix J of eigenvalues of
            matrix A (A=V*J*Vinv) </td>
  </tr>
  <tr><td>sigma = <a href=\"Modelica:Modelica.Math.Matrices.singularValues\">singularValues</a>(A)<br>
      (sigma,U,VT) = <a href=\"Modelica:Modelica.Math.Matrices.singularValues\">singularValues</a>(A)</td>
      <td> compute singular values and optionally left and right singular vectors </td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.det\">det</a>(A)</td>
      <td> determinant of a matrix (do <b>not</b> use; use rank(..))</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.inv\">inv</a>(A)</td>
      <td> inverse of a matrix </td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.rank\">rank</a>(A)</td>
      <td> rank of a matrix </td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.balance\">balance</a>(A)</td>
      <td>balance a square matrix to improve the condition</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.exp\">exp</a>(A)</td>
      <td> compute the exponential of a matrix by adaptive Taylor series<br>
           expansion with scaling and balancing</td>
  </tr>
  <tr><td>(P, G) = <a href=\"Modelica:Modelica.Math.Matrices.integralExp\">integralExp</a>(A,B)</td>
      <td> compute the exponential of a matrix and its integral</td>
  </tr>
  <tr><td>(P, G, GT) = <a href=\"Modelica:Modelica.Math.Matrices.integralExpT\">integralExpT</a>(A,B)</td>
      <td> compute the exponential of a matrix and two integrals</td>
  </tr>
</table>

<p>
Most functions are solely an interface to the external LAPACK library
(<a href=\"http://www.netlib.org/lapack\">http://www.netlib.org/lapack</a>).
The details of this library are described in:
</p>

<dl>
<dt>Anderson E., Bai Z., Bischof C., Blackford S., Demmel J., Dongarra J.,
    Du Croz J., Greenbaum A., Hammarling S., McKenney A., and Sorensen D.:</dt>
<dd> <b>Lapack Users' Guide</b>.
     Third Edition, SIAM, 1999.</dd>
</dl>


</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      function equalityLeastSquares "Solve a linear equality constrained least squares problem"
        extends Modelica.Icons.Function;
        input Real A[:,:] "Minimize |A*x - a|^2";
        input Real a[size(A, 1)];
        input Real B[:,size(A, 2)] "subject to B*x=b";
        input Real b[size(B, 1)];
        output Real x[size(A, 2)] "solution vector";
        annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
x = Matrices.<b>equalityLeastSquares</b>(A,a,B,b);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
This function returns the
solution <b>x</b> of the linear equality-constrained least squares problem:
</p>
<blockquote>
<p>
min|<b>A</b>*<b>x</b> - <b>a</b>|^2 over <b>x</b>, subject to <b>B</b>*<b>x</b> = <b>b</b>
</p>
</blockquote>

<p>
It is required that the dimensions of A and B fulfill the following
relationship:
</p>

<blockquote>
size(B,1) &le; size(A,2) &le; size(A,1) + size(B,1)
</blockquote>

<p>
Note, the solution is computed with the LAPACK function \"dgglse\"
using the generalized RQ factorization under the assumptions that
B has full row rank (= size(B,1)) and the matrix [A;B] has
full column rank (= size(A,2)). In this case, the problem
has a unique solution.
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      protected
        Integer info;
      algorithm
        assert(size(A, 2) >= size(B, 1) and size(A, 2) <= size(A, 1) + size(B, 1), "It is required that size(B,1) <= size(A,2) <= size(A,1) + size(B,1)\n" + "This relationship is not fulfilled, since the matrices are declared as:\n" + "  A[" + String(size(A, 1)) + "," + String(size(A, 2)) + "], B[" + String(size(B, 1)) + "," + String(size(B, 2)) + "]\n");
        (x,info):=LAPACK.dgglse_vec(A, a, B, b);
        assert(info == 0, "Solving a linear equality-constrained least squares problem
with function \"Matrices.equalityLeastSquares\" failed.");
      end equalityLeastSquares;

    protected
      package LAPACK "Interface to LAPACK library"
        extends Modelica.Icons.Library;
        function dgglse_vec "Solve a linear equality constrained least squares problem"
          extends Modelica.Icons.Function;
          input Real A[:,:] "Minimize |A*x - c|^2";
          input Real c[size(A, 1)];
          input Real B[:,size(A, 2)] "subject to B*x=d";
          input Real d[size(B, 1)];
          output Real x[size(A, 2)] "solution vector";
          output Integer info;
        protected
          Integer nrow_A=size(A, 1);
          Integer nrow_B=size(B, 1);
          Integer ncol_A=size(A, 2) "(min=nrow_B,max=nrow_A+nrow_B) required";
          Real Awork[nrow_A,ncol_A]=A;
          Real Bwork[nrow_B,ncol_A]=B;
          Real cwork[nrow_A]=c;
          Real dwork[nrow_B]=d;
          Integer lwork=ncol_A + nrow_B + max(nrow_A, max(ncol_A, nrow_B))*5;
          Real work[lwork];

          external "FORTRAN 77" dgglse(nrow_A,ncol_A,nrow_B,Awork,nrow_A,Bwork,nrow_B,cwork,dwork,x,work,lwork,info)           annotation(Library="Lapack");
          annotation(Coordsys(extent=[-100,-100;100,100], grid=[2,2], component=[20,20]), Documentation(info="Lapack documentation

  Purpose
  =======

  DGGLSE solves the linear equality constrained least squares (LSE)
  problem:

          minimize || A*x - c ||_2   subject to B*x = d

  using a generalized RQ factorization of matrices A and B, where A is
  M-by-N, B is P-by-N, assume P <= N <= M+P, and ||.||_2 denotes vector
  2-norm. It is assumed that

                       rank(B) = P                                  (1)

  and the null spaces of A and B intersect only trivially, i.e.,

   intersection of Null(A) and Null(B) = {0} <=> rank( ( A ) ) = N  (2)
                                                     ( ( B ) )

  where N(A) denotes the null space of matrix A. Conditions (1) and (2)
  ensure that the problem LSE has a unique solution.

  Arguments
  =========

  M       (input) INTEGER
          The number of rows of the matrix A.  M >= 0.

  N       (input) INTEGER
          The number of columns of the matrices A and B. N >= 0.
          Assume that P <= N <= M+P.

  P       (input) INTEGER
          The number of rows of the matrix B.  P >= 0.

  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
          On entry, the P-by-M matrix A.
          On exit, A is destroyed.

  LDA     (input) INTEGER
          The leading dimension of the array A. LDA >= max(1,M).

  B       (input/output) DOUBLE PRECISION array, dimension (LDB,N)
          On entry, the P-by-N matrix B.
          On exit, B is destroyed.

  LDB     (input) INTEGER
          The leading dimension of the array B. LDB >= max(1,P).

  C       (input/output) DOUBLE PRECISION array, dimension (M)
          On entry, C contains the right hand side vector for the
          least squares part of the LSE problem.
          On exit, the residual sum of squares for the solution
          is given by the sum of squares of elements N-P+1 to M of
          vector C.

  D       (input/output) DOUBLE PRECISION array, dimension (P)
          On entry, D contains the right hand side vector for the
          constrained equation.
          On exit, D is destroyed.

  X       (output) DOUBLE PRECISION array, dimension (N)
          On exit, X is the solution of the LSE problem.

  WORK    (workspace) DOUBLE PRECISION array, dimension (LWORK)
          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.

  LWORK   (input) INTEGER
          The dimension of the array WORK. LWORK >= N+P+max(N,M,P).
          For optimum performance LWORK >=
          N+P+max(M,P,N)*max(NB1,NB2), where NB1 is the optimal
          blocksize for the QR factorization of M-by-N matrix A.
          NB2 is the optimal blocksize for the RQ factorization of
          P-by-N matrix B.

  INFO    (output) INTEGER
          = 0:  successful exit.
          < 0:  if INFO = -i, the i-th argument had an illegal value.
"), Window(x=0.34, y=0.06, width=0.6, height=0.6));
        end dgglse_vec;

      end LAPACK;

    end Matrices;

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
        model SignalVoltage "Generic voltage source using the input signal as source voltage"
          SI.Current i "Current flowing from pin p to pin n";
          annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-50,-50},{50,50}}),Line(visible=true, points={{-96,0},{-50,0}}),Line(visible=true, points={{50,0},{96,0}}),Line(visible=true, points={{-50,0},{50,0}}),Line(visible=true, points={{-109,20},{-84,20}}, color={160,160,160}),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-94,23},{-84,20},{-94,17},{-94,23}}),Line(visible=true, points={{91,20},{116,20}}, color={160,160,160}),Text(visible=true, lineColor={0,0,255}, fillColor={160,160,160}, extent={{-109,25},{-89,45}}, textString="i", fontName="Arial"),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{106,23},{116,20},{106,17},{106,23}}),Text(visible=true, lineColor={0,0,255}, fillColor={160,160,160}, extent={{91,25},{111,45}}, textString="i", fontName="Arial"),Line(visible=true, points={{-119,-5},{-119,5}}, color={160,160,160}),Line(visible=true, points={{-124,0},{-114,0}}, color={160,160,160}),Line(visible=true, points={{116,0},{126,0}}, color={160,160,160})}), Documentation(revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Martin Otter<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-50,-50},{50,50}}),Line(visible=true, points={{-90,0},{-50,0}}),Line(visible=true, points={{50,0},{90,0}}),Line(visible=true, points={{-50,0},{50,0}}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100,-120},{100,-80}}, textString="%name", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{-120,0},{-20,50}}, textString="+", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{20,0},{120,50}}, textString="-", fontName="Arial")}));
          Interfaces.PositivePin p annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Interfaces.NegativePin n annotation(Placement(visible=true, transformation(origin={100,0}, extent={{10,-10},{-10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{10,-10},{-10,10}}, rotation=0)));
          Modelica.Blocks.Interfaces.RealInput v(redeclare type SignalType= SI.Voltage ) "Voltage between pin p and n (= p.v - n.v) as input signal" annotation(Placement(visible=true, transformation(origin={0,70}, extent={{-20,-20},{20,20}}, rotation=-90), iconTransformation(origin={0,70}, extent={{-20,-20},{20,20}}, rotation=-90)));
        equation
          v=p.v - n.v;
          0=p.i + n.i;
          i=p.i;
        end SignalVoltage;

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

      end Interfaces;

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

        model EMF "Electromotoric force (electric/mechanic transformer)"
          parameter Real k(final unit="N.m/A")=1 "Transformation coefficient";
          SI.Voltage v "Voltage drop between the two pins";
          SI.Current i "Current flowing from positive to negative pin";
          SI.AngularVelocity w "Angular velocity of flange_b";
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,90},{0,40}}, color={0,0,255}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{40,-10},{100,10}}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}}),Line(visible=true, points={{0,-90},{0,-40}}, color={0,0,255}),Text(visible=true, fillColor={0,0,255}, extent={{20,-100},{100,-40}}, textString="%name", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{30,40},{119,100}}, textString="k=%k", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-17,95},{-20,85},{-23,95},{-17,95}}),Line(visible=true, points={{-20,110},{-20,85}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{-40,90},{-30,110}}, textString="i", fontName="Arial"),Line(visible=true, points={{9,75},{19,75}}, color={192,192,192}),Line(visible=true, points={{0,96},{0,40}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-40,-40},{40,40}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{40,-10},{96,10}}),Line(visible=true, points={{-20,-110},{-20,-85}}, color={160,160,160}),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-17,-100},{-20,-110},{-23,-100},{-17,-100}}),Text(visible=true, fillColor={160,160,160}, extent={{-40,-110},{-30,-90}}, textString="i", fontName="Arial"),Line(visible=true, points={{8,-79},{18,-79}}, color={192,192,192}),Line(visible=true, points={{0,-96},{0,-40}}, color={0,0,255}),Line(visible=true, points={{14,80},{14,70}}, color={192,192,192}),Line(visible=true, points={{140,0},{110,0}}),Text(visible=true, extent={{114,-14},{148,-4}}, textString="flange_b.phi", fontName="Arial"),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{140,3},{150,0},{140,-3},{140,3},{140,3}}),Text(visible=true, extent={{112,6},{148,16}}, textString="flange_b.tau", fontName="Arial"),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{120,35},{100,40},{100,30},{120,35}}),Line(visible=true, points={{30,35},{101,35}}, color={128,128,128}),Text(visible=true, fillColor={128,128,128}, extent={{37,46},{105,59}}, textString="rotation axis", fontName="Arial")}), Documentation(info="<HTML>
<p>
EMF transforms electrical energy into rotational mechanical energy.
It is used as basic building block of an electrical motor. The mechanical
connector flange_b can be connected to elements of the
Modelica.Mechanics.Rotational library. flange_b.tau is the cut-torque,
flange_b.phi is the angle at the rotational connection.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Martin Otter<br> initially implemented<br>
       </li>
</ul>
</html>"));
          Interfaces.PositivePin p annotation(Placement(visible=true, transformation(origin={0,100}, extent={{-10,-10},{10,10}}, rotation=-90), iconTransformation(origin={0,100}, extent={{-10,-10},{10,10}}, rotation=-90)));
          Interfaces.NegativePin n annotation(Placement(visible=true, transformation(origin={0,-100}, extent={{-10,-10},{10,10}}, rotation=-90), iconTransformation(origin={0,-100}, extent={{-10,-10},{10,10}}, rotation=-90)));
          Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          v=p.v - n.v;
          0=p.i + n.i;
          i=p.i;
          w=der(flange_b.phi);
          k*w=v;
          flange_b.tau=-k*i;
        end EMF;

      end Basic;

    end Analog;

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
    package Types "Constants and types with choices, especially to build menus"
      extends Modelica.Icons.Library;
      annotation(preferedView="info", Documentation(info="<HTML>
<p>
In this package <b>types</b> and <b>constants</b> are defined that are used
in library Modelica.Blocks. The types have additional annotation choices
definitions that define the menus to be built up in the graphical
user interface when the type is used as parameter in a declaration.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      package Init "Type, constants and menu choices to define initialization of blocks"
        annotation(Documentation(info="<html>

</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        extends Modelica.Icons.Enumeration;
        constant Integer NoInit=1 "no initialization (start values are used as guess values with fixed=false)";
        constant Integer SteadyState=2 "steady state initialization (derivatives of states are zero)";
        constant Integer InitialState=3 "initialization with initial states";
        constant Integer InitialOutput=4 "initialization with initial outputs (and steady state of the states if possibles)";
        type Temp "Temporary type of initialization with choices for menus (until enumerations are available)"
          extends Modelica.Icons.TypeInteger(min=1, max=4);
          annotation(Evaluate=true, choices(choice=Modelica.Blocks.Types.Init.NoInit "no initialization (start values are used as guess values with fixed=false)", choice=Modelica.Blocks.Types.Init.SteadyState "steady state initialization (derivatives of states are zero)", choice=Modelica.Blocks.Types.Init.InitialState "initialization with initial states", choice=Modelica.Blocks.Types.Init.InitialOutput "initialization with initial outputs (and steady state of the states if possibles)"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        end Temp;

      end Init;

    end Types;

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
      block Constant "Generate constant signal of type Real"
        parameter Real k=1 "Constant output value";
        extends Interfaces.SO;
        annotation(defaultComponentName="const", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,0},{80,0}}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="k=%k", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-80,0},{80,0}}, thickness=0.5),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{-75,76},{-22,94}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-101,-12},{-81,8}}, textString="k", fontName="Arial")}), Documentation(info="<html>

</html>"));
      equation
        y=k;
      end Constant;

      block Pulse "Generate pulse signal of type Real"
        parameter Real amplitude=1 "Amplitude of pulse";
        parameter Real width(final min=Modelica.Constants.small, final max=100)=50 "Width of pulse in % of periods";
        parameter Modelica.SIunits.Time period(final min=Modelica.Constants.small)=1 "Time for one period";
        parameter Real offset=0 "Offset of output signals";
        parameter Modelica.SIunits.Time startTime=0 "Output = offset for time < startTime";
        extends Modelica.Blocks.Interfaces.SO;
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,-70},{-40,-70},{-40,44},{0,44},{0,-70},{40,-70},{40,44},{79,44}}),Text(visible=true, extent={{-147,-152},{153,-112}}, textString="period=%period", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,1},{-37,-12},{-30,-12},{-34,1}}),Line(visible=true, points={{-34,-1},{-34,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-33,-70},{-36,-57},{-30,-57},{-33,-70},{-33,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{-78,-36},{-35,-24}}, textString="offset", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-31,-87},{15,-69}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-76,79},{-35,99}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Line(visible=true, points={{-10,0},{-10,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-80,0},{-10,0},{-10,50},{30,50},{30,0},{50,0},{50,50},{90,50}}, thickness=0.5),Line(visible=true, points={{-10,88},{-10,49}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{30,74},{30,50}}, color={160,160,160}, pattern=LinePattern.Dash),Line(visible=true, points={{50,88},{50,50}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-10,83},{51,83}}, color={192,192,192}),Line(visible=true, points={{-10,69},{30,69}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{0,85},{46,97}}, textString="period", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-9,69},{30,81}}, textString="width", fontName="Arial"),Line(visible=true, points={{-43,50},{-10,50}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-34,50},{-34,1}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-78,20},{-37,34}}, textString="amplitude", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,49},{-37,36},{-30,36},{-34,49}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,1},{-37,14},{-31,14},{-34,1},{-34,1}}),Line(visible=true, points={{90,50},{90,0},{100,0}}, thickness=0.5),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-10,69},{-1,71},{-1,67},{-10,69}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{30,69},{22,71},{22,67},{30,69}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-10,83},{-1,85},{-1,81},{-10,83}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,83},{42,85},{42,81},{50,83}})}), Documentation(info="<html>

</html>"));
      protected
        Modelica.SIunits.Time T0(final start=startTime) "Start time of current period";
        Modelica.SIunits.Time T_width=period*width/100;
      equation
        when sample(startTime, period) then
          T0=time;
        end when;
        y=offset + (if time < startTime or time >= T0 + T_width then 0 else amplitude);
      end Pulse;

      block TimeTable "Generate a (possibly discontinuous) signal by linear interpolation in a table"
        parameter Real table[:,2]=[0,0;1,1;2,4] "Table matrix (time = first column)";
        parameter Real offset=0 "Offset of output signal";
        parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
        extends Interfaces.SO;
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-48,-50},{2,70}}),Line(visible=true, points={{-48,-50},{-48,70},{52,70},{52,-50},{-48,-50},{-48,-20},{52,-20},{52,10},{-48,10},{-48,40},{52,40},{52,70},{2,70},{2,-51}}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="offset=%offset", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-20,-30},{30,90}}),Line(visible=true, points={{-20,-30},{-20,90},{80,90},{80,-30},{-20,-30},{-20,0},{80,0},{80,30},{-20,30},{-20,60},{80,60},{80,90},{30,90},{30,-31}}),Text(visible=true, fillColor={160,160,160}, extent={{-77,-58},{-38,-42}}, textString="offset", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-31,-30},{-33,-40},{-28,-40},{-31,-30}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-30,-70},{-33,-60},{-28,-60},{-30,-70},{-30,-70}}),Line(visible=true, points={{-31,-31},{-31,-70}}, color={192,192,192}),Line(visible=true, points={{-20,-20},{-20,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Text(visible=true, fillColor={160,160,160}, extent={{-38,-88},{8,-70}}, textString="startTime", fontName="Arial"),Line(visible=true, points={{-20,-30},{-80,-30}}, color={192,192,192}, pattern=LinePattern.Dash),Text(visible=true, fillColor={160,160,160}, extent={{-73,78},{-41,93}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{66,-93},{91,-81}}, textString="time", fontName="Arial"),Text(visible=true, extent={{-15,68},{24,83}}, textString="time", fontName="Arial"),Text(visible=true, extent={{33,67},{76,83}}, textString="y", fontName="Arial")}));
      protected
        Real a "Interpolation coefficients a of actual interval (y=a*x+b)";
        Real b "Interpolation coefficients b of actual interval (y=a*x+b)";
        Integer last(start=1) "Last used lower grid index";
        SIunits.Time nextEvent(start=0) "Next event instant";
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Rectangle(extent={{-48,70},{2,-50}}, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-48,-50},{-48,70},{52,70},{52,-50},{-48,-50},{-48,-20},{52,-20},{52,10},{-48,10},{-48,40},{52,40},{52,70},{2,70},{2,-51}}, color={0,0,0}),Text(extent={{-150,-150},{150,-110}}, textString="offset=%offset", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Rectangle(extent={{-20,90},{30,-30}}, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-20,-30},{-20,90},{80,90},{80,-30},{-20,-30},{-20,0},{80,0},{80,30},{-20,30},{-20,60},{80,60},{80,90},{30,90},{30,-31}}, color={0,0,0}),Text(extent={{-77,-42},{-38,-58}}, textString="offset", fillColor={160,160,160}),Polygon(points={{-31,-30},{-33,-40},{-28,-40},{-31,-30}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-30,-70},{-33,-60},{-28,-60},{-30,-70},{-30,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-31,-31},{-31,-70}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Line(points={{-20,-20},{-20,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Text(extent={{-38,-70},{8,-88}}, textString="startTime", fillColor={160,160,160}),Line(points={{-20,-30},{-80,-30}}, color={192,192,192}, pattern=LinePattern.Dash),Text(extent={{-73,93},{-41,78}}, textString="y", fillColor={160,160,160}),Text(extent={{66,-81},{91,-93}}, textString="time", fillColor={160,160,160}),Text(extent={{-15,83},{24,68}}, textString="time", fillColor={0,0,0}),Text(extent={{33,83},{76,67}}, textString="y", fillColor={0,0,0})}), Documentation(info="<HTML>
<p>
This block generates an output signal by <b>linear interpolation</b> in
a table. The time points and function values are stored in a matrix
<b>table[i,j]</b>, where the first column table[:,1] contains the
time points and the second column contains the data to be interpolated.
The table interpolation has the following proporties:
</p>
<ul>
<li>The time points need to be <b>monotonically increasing</b>. </li>
<li><b>Discontinuities</b> are allowed, by providing the same
    time point twice in the table. </li>
<li>Values <b>outside</b> of the table range, are computed by
    <b>extrapolation</b> through the last or first two points of the
    table.</li>
<li>If the table has only <b>one row</b>, no interpolation is performed and
    the function value is just returned independantly of the
    actual time instant.</li>
<li>Via parameters <b>startTime</b> and <b>offset</b> the curve defined
    by the table can be shifted both in time and in the ordinate value.
<li>The table is implemented in a numerically sound way by
    generating <b>time events</b> at interval boundaries,
    in order to not integrate over a discontinuous or not differentiable
    points.
</li>
</ul>
<p>
Example:
</p>
<pre>
   table = [0  0
            1  0
            1  1
            2  4
            3  9
            4 16]
If, e.g., time = 1.0, the output y =  0.0 (before event), 1.0 (after event)
    e.g., time = 1.5, the output y =  2.5,
    e.g., time = 2.0, the output y =  4.0,
    e.g., time = 5.0, the output y = 23.0 (i.e. extrapolation).
</pre>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>Oct. 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Corrected interface from
<pre>
    parameter Real table[:, :]=[0, 0; 1, 1; 2, 4];
</pre>
       to
<pre>
    parameter Real table[:, <b>2</b>]=[0, 0; 1, 1; 2, 4];
</pre>
       </li>
<li><i>Nov. 7, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
</html>"));
        function getInterpolationCoefficients "Determine interpolation coefficients and next time event"
          input Real table[:,2] "Table for interpolation";
          input Real offset "y-offset";
          input Real startTime "time-offset";
          input Real t "Actual time instant";
          input Integer last "Last used lower grid index";
          input Real TimeEps "Relative epsilon to check for identical time instants";
          output Real a "Interpolation coefficients a (y=a*x + b)";
          output Real b "Interpolation coefficients b (y=a*x + b)";
          output Real nextEvent "Next event instant";
          output Integer next "New lower grid index";
        protected
          Integer columns=2 "Column to be interpolated";
          Integer ncol=2 "Number of columns to be interpolated";
          Integer nrow=size(table, 1) "Number of table rows";
          Integer next0;
          Real tp;
          Real dt;
        algorithm
          next:=last;
          nextEvent:=t - TimeEps*abs(t);
          tp:=t + TimeEps*abs(t) - startTime;
          if tp < 0.0 then
            nextEvent:=startTime;
            a:=0;
            b:=offset;
          elseif nrow < 2 then
            a:=0;
            b:=offset + table[1,columns];
          else
            while (next < nrow and tp >= table[next,1]) loop
              next:=next + 1;
            end while;
            if next < nrow then
              nextEvent:=startTime + table[next,1];
            end if;
            next0:=next - 1;
            dt:=table[next,1] - table[next0,1];
            if dt <= TimeEps*abs(table[next,1]) then
              a:=0;
              b:=offset + table[next,columns];
            else
              a:=(table[next,columns] - table[next0,columns])/dt;
              b:=offset + table[next0,columns] - a*table[next0,1];
            end if;
          end if;
          b:=b - a*startTime;
        end getInterpolationCoefficients;

      algorithm
        when {time >= pre(nextEvent),initial()} then
                  (a,b,nextEvent,last):=getInterpolationCoefficients(table, offset, startTime, time, last, 100*Modelica.Constants.eps);
        end when;
      equation
        y=a*time + b;
      end TimeTable;

      block BooleanConstant "Generate constant signal of type Boolean"
        parameter Boolean k=true "Constant output value";
        extends Interfaces.partialBooleanSource;
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,0},{80,0}}),Text(visible=true, extent={{-150,-140},{150,-110}}, textString="%k", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,0},{80,0}}, thickness=0.5),Text(visible=true, fillColor={160,160,160}, extent={{-83,0},{-63,20}}, textString="k", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-100,-6},{-80,6}}, textString="true", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-104,-70},{-78,-58}}, textString="false", fontName="Arial")}), Documentation(info="<html>

</html>"));
      equation
        y=k;
      end BooleanConstant;

    end Sources;

    package Routing "Blocks to combine and extract signals"
      extends Icons.Library;
      block Multiplex3 "Multiplexer block for three input connectors"
        extends Modelica.Blocks.Interfaces.BlockIcon;
        parameter Integer n1=1 "dimension of input signal connector 1";
        parameter Integer n2=1 "dimension of input signal connector 2";
        parameter Integer n3=1 "dimension of input signal connector 3";
        annotation(Documentation(info="<HTML>
<p>
The output connector is the <b>concatenation</b> of the three input connectors.
Note, that the dimensions of the input connector signals have to be
explicitly defined via parameters n1, n2 and n3.
</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{8,0},{102,0}}),Line(visible=true, points={{-100,70},{-60,70},{-4,6}}),Line(visible=true, points={{-100,0},{-12,0}}),Line(visible=true, points={{-100,-70},{-62,-70},{-4,-4}}),Ellipse(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-14,-14},{16,16}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,70},{-60,70},{-4,6}}),Line(visible=true, points={{-100,-70},{-62,-70},{-4,-4}}),Line(visible=true, points={{8,0},{102,0}}),Ellipse(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-14,-14},{16,16}}),Line(visible=true, points={{-100,0},{-12,0}})}));
        Modelica.Blocks.Interfaces.RealInput u1[n1] "Connector of Real input signals 1" annotation(Placement(visible=true, transformation(origin={-120,70}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,70}, extent={{-20,-20},{20,20}}, rotation=0)));
        Modelica.Blocks.Interfaces.RealInput u2[n2] "Connector of Real input signals 2" annotation(Placement(visible=true, transformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0)));
        Modelica.Blocks.Interfaces.RealInput u3[n3] "Connector of Real input signals 3" annotation(Placement(visible=true, transformation(origin={-120,-70}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,-70}, extent={{-20,-20},{20,20}}, rotation=0)));
        Modelica.Blocks.Interfaces.RealOutput y[n1 + n2 + n3] "Connector of Real output signals" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
      equation
        [y]=[u1;u2;u3];
      end Multiplex3;

      annotation(Documentation(info="<html>
<p>
This package contains blocks to combine and extract signals.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Routing;

    package Nonlinear "Discontinuous or non-differentiable algebraic control blocks"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Library;
      annotation(preferedView="info", Documentation(info="
<HTML>
<p>
This package contains <b>discontinuous</b> and
<b>non-differentiable, algebraic</b> input/output blocks.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New block VariableLimiter added.
<li><i>August 22, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.
</li>
</ul>
</html>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{0,0},{207,-132}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      block Limiter "Limit the range of a signal"
        parameter Real uMax=1 "Upper limits of input signals";
        parameter Real uMin=-uMax "Lower limits of input signals";
        parameter Boolean limitsAtInit=true "= false, if limits are ignored during initializiation (i.e., y=u)";
        extends Interfaces.SISO;
        annotation(Documentation(info="
<HTML>
<p>
The Limiter block passes its input signal as output signal
as long as the input is within the specified upper and lower
limits. If this is not the case, the corresponding limits are passed
as output.
</p>
</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,-90},{0,68}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{0,90},{-8,68},{8,68},{0,90}}),Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,-8},{68,8},{90,0}}),Line(visible=true, points={{-80,-70},{-50,-70},{50,70},{80,70}}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="uMax=%uMax", fontName="Arial"),Text(visible=true, extent={{-150,110},{150,150}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,-60},{0,50}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{0,60},{-5,50},{5,50},{0,60}}),Line(visible=true, points={{-60,0},{50,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{60,0},{50,-5},{50,5},{60,0}}),Line(visible=true, points={{-50,-40},{-30,-40},{30,40},{50,40}}),Text(visible=true, fillColor={128,128,128}, extent={{46,-18},{68,-6}}, textString="u", fontName="Arial"),Text(visible=true, fillColor={128,128,128}, extent={{-30,50},{-5,70}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={128,128,128}, extent={{-58,-54},{-28,-42}}, textString="uMin", fontName="Arial"),Text(visible=true, fillColor={128,128,128}, extent={{26,40},{66,56}}, textString="uMax", fontName="Arial")}));
      equation
        assert(uMax >= uMin, "Limiter: Limits must be consistent. However, uMax (=" + String(uMax) + ") < uMin (=" + String(uMin) + ")");
        if initial() and not limitsAtInit then
          y=u;
          assert(u >= uMin - 0.01*abs(uMin) and u <= uMax + 0.01*abs(uMax), "Limiter: During initialization the limits have been ignored.\n" + "However, the result is that the input u is not within the required limits:\n" + "  u = " + String(u) + ", uMin = " + String(uMin) + ", uMax = " + String(uMax));
        else
          y=smooth(0, if u > uMax then uMax else if u < uMin then uMin else u);
        end if;
      end Limiter;

    end Nonlinear;

    package Math "Mathematical functions as input/output blocks"
      import Modelica.SIunits;
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Library;
      annotation(preferedView="info", Documentation(info="
<HTML>
<p>
This package contains basic <b>mathematical operations</b>,
such as summation and multiplication, and basic <b>mathematical
functions</b>, such as <b>sqrt</b> and <b>sin</b>, as
input/output blocks. All blocks of this library can be either
connected with continuous blocks or with sampled-data blocks.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New blocks added: RealToInteger, IntegerToReal, Max, Min, Edge, BooleanChange, IntegerChange.</li>
<li><i>August 7, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized (partly based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist).
</li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{0,0},{446,-493}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      block Gain "Output the product of a gain value with the input signal"
        parameter Real k=1 "Gain value multiplied with input signal";
        annotation(Documentation(info="
<HTML>
<p>
This block computes output <i>y</i> as
<i>product</i> of gain <i>k</i> with the
input <i>u</i>:
</p>
<pre>
    y = k * u;
</pre>

</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,191}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,-100},{-100,100},{100,0},{-100,-100}}),Text(visible=true, extent={{-150,-140},{150,-100}}, textString="k=%k", fontName="Arial"),Text(visible=true, extent={{-150,100},{150,140}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,191}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,-100},{-100,100},{100,0},{-100,-100}}),Text(visible=true, extent={{-76,-34},{0,38}}, textString="k", fontName="Arial")}));
        Interfaces.RealInput u "Input signal connector" annotation(Placement(visible=true, transformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0)));
        Interfaces.RealOutput y "Output signal connector" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
      equation
        y=k*u;
      end Gain;

      block MatrixGain "Output the product of a gain matrix with the input signal vector"
        parameter Real K[:,:]=[1,0;0,1] "Gain matrix which is multiplied with the input";
        extends Interfaces.MIMO(final nin=size(K, 2), final nout=size(K, 1));
        annotation(Documentation(info="
<HTML>
<p>
This blocks computes output vector <b>y</b> as <i>product</i> of the
gain matrix <b>K</b> with the input signal vector <b>u</b>:
</p>
<pre>
    <b>y</b> = <b>K</b> * <b>u</b>;
</pre>
<p>
Example:
</p>
<pre>
   parameter: <b>K</b> = [0.12 2; 3 1.5]
   results in the following equations:
     | y[1] |     | 0.12  2.00 |   | u[1] |
     |      |  =  |            | * |      |
     | y[2] |     | 3.00  1.50 |   | u[2] |
</pre>

</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={160,160,160}, extent={{-90,-60},{90,60}}, textString="*K", fontName="Arial"),Text(visible=true, extent={{-150,110},{150,150}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Text(visible=true, fillColor={160,160,160}, extent={{-90,-60},{90,60}}, textString="*K", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
      equation
        y=K*u;
      end MatrixGain;

      block Feedback "Output difference between commanded and feedback input"
        annotation(Documentation(info="
<HTML>
<p>
This blocks computes output <b>y</b> as <i>difference</i> of the
commanded input <b>u1</b> and the feedback
input <b>u2</b>:
</p>
<pre>
    <b>y</b> = <b>u1</b> - <b>u2</b>;
</pre>
<p>
Example:
</p>
<pre>
     parameter:   n = 2
  results in the following equations:
     y = u1 - u2
</pre>

</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,191}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-20,-20},{20,20}}),Line(visible=true, points={{-60,0},{-20,0}}, color={0,0,191}),Line(visible=true, points={{20,0},{80,0}}, color={0,0,191}),Line(visible=true, points={{0,-20},{0,-60}}, color={0,0,191}),Text(visible=true, extent={{-14,-94},{82,0}}, textString="-", fontName="Arial"),Text(visible=true, extent={{-100,60},{100,110}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-20,-20},{20,20}}),Line(visible=true, points={{-60,0},{-20,0}}),Line(visible=true, points={{20,0},{80,0}}),Line(visible=true, points={{0,-20},{0,-60}}),Text(visible=true, extent={{-12,-84},{84,10}}, textString="-", fontName="Arial")}));
        input Interfaces.RealInput u1 annotation(Placement(visible=true, transformation(origin={-80,0}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-80,0}, extent={{-20,-20},{20,20}}, rotation=0)));
        output Interfaces.RealOutput y annotation(Placement(visible=true, transformation(origin={90,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={90,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        input Interfaces.RealInput u2 annotation(Placement(visible=true, transformation(origin={0,-80}, extent={{-20,-20},{20,20}}, rotation=90), iconTransformation(origin={0,-80}, extent={{-20,-20},{20,20}}, rotation=90)));
      equation
        y=u1 - u2;
      end Feedback;

    end Math;

    package Logical "Components with Boolean input and output signals"
      extends Modelica.Icons.Library;
      annotation(preferedView="info", Documentation(info="<html>
<p>
This package provides blocks with Boolean input and output signals
to describe logical networks. A typical example for a logical
network built with package Logical is shown in the next figure:
</p>
<p align=\"center\">
<img src=\"../Images/LogicalNetwork1.png\">
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      block Switch "Switch between two Real signals"
        extends Blocks.Interfaces.partialBooleanBlockIcon;
        annotation(defaultComponentName="switch1", Documentation(info="<html>
<p>The Logical.Switch switches, depending on the
logical connector u2 (the middle connector)
between the two possible input signals
u1 (upper connector) and u3 (lower connector).</p>
<p>If u2 is <b>true</b>, the output signal y is set equal to
u1, else it is set equal to u3.</p>
</html>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{12,0},{100,0}}),Line(visible=true, points={{-100,0},{-40,0}}, color={255,0,127}),Line(visible=true, points={{-100,-80},{-40,-80},{-40,-80}}),Line(visible=true, points={{-40,12},{-40,-12}}, color={255,0,127}),Line(visible=true, points={{-100,80},{-38,80}}),Line(visible=true, points={{-38,80},{6,2}}, thickness=1),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{2,-6},{18,8}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        Blocks.Interfaces.RealInput u1 "Connector of first Real input signal" annotation(Placement(visible=true, transformation(origin={-120,80}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,80}, extent={{-20,-20},{20,20}}, rotation=0)));
        Blocks.Interfaces.BooleanInput u2 "Connector of Boolean input signal" annotation(Placement(visible=true, transformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0)));
        Blocks.Interfaces.RealInput u3 "Connector of second Real input signal" annotation(Placement(visible=true, transformation(origin={-120,-80}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,-80}, extent={{-20,-20},{20,20}}, rotation=0)));
        Blocks.Interfaces.RealOutput y "Connector of Real output signal" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
      equation
        y=if u2 then u1 else u3;
      end Switch;

    end Logical;

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

      connector BooleanSignal= Boolean "Boolean port (both input/output possible)" annotation(Documentation(info="<html>
<p>
Connector with one signal of type Boolean (no icon, no input/output prefix).
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      connector RealInput= input RealSignal "'input Real' as connector" annotation(defaultComponentName="u", Documentation(info="<html>
<p>
Connector with one input signal of type Real.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={0,0,127}, fillPattern=FillPattern.Solid, points={{-100,100},{100,0},{-100,-100},{-100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={0,0,127}, fillPattern=FillPattern.Solid, points={{0,50},{100,0},{0,-50},{0,50}}),Text(visible=true, fillColor={0,0,127}, extent={{-120,60},{100,105}}, textString="%name", fontName="Arial")}));
      connector RealOutput= output RealSignal "'output Real' as connector" annotation(defaultComponentName="y", Documentation(info="<html>
<p>
Connector with one output signal of type Real.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,100},{100,0},{-100,-100},{-100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,50},{0,0},{-100,-50},{-100,50}}),Text(visible=true, fillColor={0,0,127}, extent={{-100,60},{130,140}}, textString="%name", fontName="Arial")}));
      connector BooleanInput= input BooleanSignal "'input Boolean' as connector" annotation(defaultComponentName="u", Documentation(info="<html>
<p>
Connector with one input signal of type Boolean.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={255,0,255}, fillColor={255,0,255}, fillPattern=FillPattern.Solid, points={{-100,100},{100,0},{-100,-100},{-100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={255,0,255}, fillColor={255,0,255}, fillPattern=FillPattern.Solid, points={{0,50},{100,0},{0,-50},{0,50}}),Text(visible=true, fillColor={255,0,255}, extent={{-120,60},{100,105}}, textString="%name", fontName="Arial")}));
      connector BooleanOutput= output BooleanSignal "'output Boolean' as connector" annotation(defaultComponentName="y", Documentation(info="<html>
<p>
Connector with one output signal of type Boolean.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={255,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,100},{100,0},{-100,-100},{-100,100}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={255,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100,50},{0,0},{-100,-50},{-100,50}}),Text(visible=true, fillColor={255,0,255}, extent={{-100,60},{130,140}}, textString="%name", fontName="Arial")}));
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

      partial block SISO "Single Input Single Output continuous control block"
        extends BlockIcon;
        annotation(Documentation(info="<html>
<p>
Block has one continuous Real input and one continuous Real output signal.
</p>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        RealInput u "Connector of Real input signal" annotation(Placement(visible=true, transformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0)));
        RealOutput y "Connector of Real output signal" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
      end SISO;

      partial block MIMO "Multiple Input Multiple Output continuous control block"
        extends BlockIcon;
        parameter Integer nin=1 "Number of inputs";
        parameter Integer nout=1 "Number of outputs";
        annotation(Documentation(info="<HTML>
<p>
Block has a continuous Real input and a continuous Real output signal vector.
The signal sizes of the input and output vector may be different.
</p>
</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        RealInput u[nin] "Connector of Real input signals" annotation(Placement(visible=true, transformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0)));
        RealOutput y[nout] "Connector of Real output signals" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
      end MIMO;

      partial block partialBooleanBlockIcon "Basic graphical layout of logical block"
        annotation(Documentation(info="<html>
<p>
Block that has only the basic icon for an input/output,
Boolean block (no declarations, no equations) used especially
in the Blocks.Logical library.
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={210,210,210}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, lineThickness=4, borderPattern=BorderPattern.Raised, extent={{-100,-100},{100,100}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,110},{150,150}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end partialBooleanBlockIcon;

      partial block partialBooleanSource "partialBoolean source block"
        extends partialBooleanBlockIcon;
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={255,0,255}, fillColor={255,0,255}, fillPattern=FillPattern.Solid, points={{-80,88},{-88,66},{-72,66},{-80,88}}),Line(visible=true, points={{-80,66},{-80,-82}}, color={255,0,255}),Line(visible=true, points={{-90,-70},{72,-70}}, color={255,0,255}),Polygon(visible=true, lineColor={255,0,255}, fillColor={255,0,255}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Ellipse(visible=true, fillColor={235,235,235}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, extent={{71,-7},{85,7}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,80},{-88,58},{-72,58},{-80,80}}),Line(visible=true, points={{-80,58},{-80,-90}}),Line(visible=true, points={{-90,-70},{68,-70}}),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Text(visible=true, extent={{54,-96},{106,-84}}, textString="time", fontName="Arial"),Text(visible=true, extent={{-108,64},{-92,80}}, textString="y", fontName="Arial")}), Documentation(info="<html>
<p>
Basic block for Boolean sources of package Blocks.Sources.
This component has one continuous Boolean output signal y
and a 3D icon (e.g. used in Blocks.Logical library).
</p>
</html>"));
        Blocks.Interfaces.BooleanOutput y "Connector of Boolean output signal" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
      end partialBooleanSource;

    end Interfaces;

    package Continuous "Continuous control blocks with internal states"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
      extends Modelica.Icons.Library;
      annotation(preferedView="info", Documentation(info="<html>
<p>
This package contains basic <b>continuous</b> input/output blocks
described by differential equations.
</p>

<p>
All blocks of this package can be initialized in different
ways controlled by parameter <b>initType</b>. The possible
values of initType are defined in
<a href=\"Modelica://Modelica.Blocks.Types.Init\">Modelica.Blocks.Types.Init</a>:
</p>

<table border=1 cellspacing=0 cellpadding=2>
  <tr><td><b>Name</b></td>
      <td><b>Description</b></td></tr>

  <tr><td><b>Init.NoInit</b></td>
      <td>no initialization (start values are used as guess values with fixed=false)</td></tr>

  <tr><td><b>Init.SteadyState</b></td>
      <td>steady state initialization (derivatives of states are zero)</td></tr>

  <tr><td><b>Init.InitialState</b></td>
      <td>Initialization with initial states</td></tr>

  <tr><td><b>Init.InitialOutput</b></td>
      <td>Initialization with initial outputs (and steady state of the states if possibles)</td></tr>
</table>

<p>
For backward compatibility reasons the default of all blocks is
<b>Init.NoInit</b>, with the exception of Integrator and LimIntegrator
where the default is <b>Init.InitialState</b> (this was the initialization
defined in version 2.2 of the Modelica standard library).
</p>

<p>
In many cases, the most useful initial condition is
<b>Init.SteadyState</b> because initial transients are then no longer
present. The drawback is that in combination with a non-linear
plant, non-linear algebraic equations occur that might be
difficult to solve if appropriate guess values for the
iteration variables are not provided (i.e. start values with fixed=false).
However, it is often already useful to just initialize
the linear blocks from the Continuous blocks library in SteadyState.
This is uncritical, because only linear algebraic equations occur.
If Init.NoInit is set, then the start values for the states are
interpreted as <b>guess</b> values and are propagated to the
states with fixed=<b>false</b>.
</p>

<p>
Note, initialization with Init.SteadyState is usually difficult
for a block that contains an integrator
(Integrator, LimIntegrator, PI, PID, LimPID).
This is due to the basic equation of an integrator:
</p>

<pre>
  <b>initial equation</b>
     <b>der</b>(y) = 0;   // Init.SteadyState
  <b>equation</b>
     <b>der</b>(y) = k*u;
</pre>

<p>
The steady state equation leads to the condition that the input to the
integrator is zero. If the input u is already (directly or indirectly) defined
by another initial condition, then the initialization problem is <b>singular</b>
(has none or infinitely many solutions). This situation occurs often
for mechanical systems, where, e.g., u = desiredSpeed - measuredSpeed and
since speed is both a state and a derivative, it is always defined by
Init.InitialState or Init.SteadyState initializtion.
</p>

<p>
In such a case, <b>Init.NoInit</b> has to be selected for the integrator
and an additional initial equation has to be added to the system
to which the integrator is connected. E.g., useful initial conditions
for a 1-dim. rotational inertia controlled by a PI controller are that
<b>angle</b>, <b>speed</b>, and <b>acceleration</b> of the inertia are zero.
</p>

</html>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      block StateSpace "Linear state space system"
        import Modelica.Blocks.Types.Init;
        parameter Real A[:,size(A, 1)]=[1,0;0,1] "Matrix A of state space model";
        parameter Real B[size(A, 1),:]=[1;1] "Matrix B of state space model";
        parameter Real C[:,size(A, 1)]=[1,1] "Matrix C of state space model";
        parameter Real D[size(C, 1),size(B, 2)]=zeros(size(C, 1), size(B, 2)) "Matrix D of state space model";
        parameter Init.Temp initType=Modelica.Blocks.Types.Init.NoInit "Type of initialization" annotation(Dialog(group="Initialization"), Evaluate=true);
        parameter Real x_start[nx]=zeros(nx) "Initial or guess values of states" annotation(Dialog(group="Initialization"));
        parameter Real y_start[ny]=zeros(ny) "Initial values of outputs (remaining states are in steady state if possible)" annotation(Dialog(enable=initType == Init.InitialOutput, group="Initialization"));
        extends Interfaces.MIMO(final nin=size(B, 2), final nout=size(C, 1));
        output Real x[size(A, 1)](start=x_start) "State vector";
        annotation(Documentation(info="<HTML>
<p>
The State Space block defines the relation
between the input u and the output
y in state space form:
</p>
<pre>

    der(x) = A * x + B * u
        y  = C * x + D * u
</pre>
<p>
The input is a vector of length nu, the output is a vector
of length ny and nx is the number of states. Accordingly
</p>
<pre>
        A has the dimension: A(nx,nx),
        B has the dimension: B(nx,nu),
        C has the dimension: C(ny,nx),
        D has the dimension: D(ny,nu)
</pre>
<p>
Example:
</p>
<pre>
     parameter: A = [0.12, 2;3, 1.5]
     parameter: B = [2, 7;3, 1]
     parameter: C = [0.1, 2]
     parameter: D = zeros(ny,nu)
results in the following equations:
  [der(x[1])]   [0.12  2.00] [x[1]]   [2.0  7.0] [u[1]]
  [         ] = [          ]*[    ] + [        ]*[    ]
  [der(x[2])]   [3.00  1.50] [x[2]]   [0.1  2.0] [u[2]]
                             [x[1]]            [u[1]]
       y[1]   = [0.1  2.0] * [    ] + [0  0] * [    ]
                             [x[2]]            [u[2]]
</pre>
</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-90,10},{-10,90}}, textString="A", fontName="Arial"),Text(visible=true, extent={{10,10},{90,90}}, textString="B", fontName="Arial"),Text(visible=true, extent={{-90,-90},{-10,-10}}, textString="C", fontName="Arial"),Text(visible=true, extent={{10,-90},{90,-10}}, textString="D", fontName="Arial"),Line(visible=true, points={{0,-90},{0,90}}, color={192,192,192}),Line(visible=true, points={{-90,0},{90,0}}, color={192,192,192})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, extent={{-60,-60},{60,60}}),Text(visible=true, extent={{-60,0},{60,40}}, textString="sx=Ax+Bu", fontName="Arial"),Text(visible=true, extent={{-60,-40},{60,0}}, textString=" y=Cx+Du", fontName="Arial"),Line(visible=true, points={{-100,0},{-60,0}}),Line(visible=true, points={{60,0},{100,0}})}));
      protected
        parameter Integer nx=size(A, 1) "number of states";
        parameter Integer ny=size(C, 1) "number of outputs";
      initial equation
        if initType == Init.SteadyState then
          der(x)=zeros(nx);
        elseif initType == Init.InitialState then
          x=x_start;
        elseif initType == Init.InitialOutput then
          x=Modelica.Math.Matrices.equalityLeastSquares(A, -B*u, C, y_start - D*u);
        else
        end if;
      equation
        der(x)=A*x + B*u;
        y=C*x + D*u;
      end StateSpace;

    end Continuous;

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
    type Length= Real(final quantity="Length", final unit="m") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Position= Length annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Distance= Length(min=0) annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Radius= Length(min=0) annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Time= Real(final quantity="Time", final unit="s") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type AngularVelocity= Real(final quantity="AngularVelocity", final unit="rad/s", displayUnit="rev/min") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type AngularAcceleration= Real(final quantity="AngularAcceleration", final unit="rad/s2") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Velocity= Real(final quantity="Velocity", final unit="m/s") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Acceleration= Real(final quantity="Acceleration", final unit="m/s2") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Mass= Real(quantity="Mass", final unit="kg", min=0) annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type MomentOfInertia= Real(final quantity="MomentOfInertia", final unit="kg.m2") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Inertia= MomentOfInertia annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Force= Real(final quantity="Force", final unit="N") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Torque= Real(final quantity="Torque", final unit="N.m") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type ElectricCurrent= Real(final quantity="ElectricCurrent", final unit="A") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Current= ElectricCurrent annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type ElectricPotential= Real(final quantity="ElectricPotential", final unit="V") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Voltage= ElectricPotential annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Inductance= Real(final quantity="Inductance", final unit="H") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Resistance= Real(final quantity="Resistance", final unit="Ohm") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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

    partial function Function "Icon for a function"
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-140,102},{136,162}}, textString="%name", fontName="Arial"),Ellipse(visible=true, lineColor={255,127,0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Text(visible=true, fillColor={255,127,0}, extent={{-100,-100},{100,100}}, textString="f", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Function;

    partial class Enumeration "Icon for an enumeration (emulated by a package)"
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-138,104},{138,164}}, textString="%name", fontName="Arial"),Ellipse(visible=true, lineColor={255,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Text(visible=true, fillColor={255,0,127}, extent={{-100,-100},{100,100}}, textString="e", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Enumeration;

    type TypeInteger "Icon for an Integer type"
      extends Integer;
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Text(visible=true, extent={{-94,-94},{94,94}}, textString="I", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end TypeInteger;

    partial model TranslationalSensor "Icon representing translational measurement device"
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-60},{70,20}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{0,-40},{-10,-16},{10,-16},{0,-40}}),Line(visible=true, points={{0,0},{0,-16}}),Line(visible=true, points={{-70,0},{0,0}}),Line(visible=true, points={{-50,-40},{-50,-60}}),Line(visible=true, points={{-30,-40},{-30,-60}}),Line(visible=true, points={{-10,-40},{-10,-60}}),Line(visible=true, points={{10,-40},{10,-60}}),Line(visible=true, points={{30,-40},{30,-60}}),Line(visible=true, points={{50,-40},{50,-60}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-60},{70,20}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{0,-40},{-10,-16},{10,-16},{0,-40}}),Line(visible=true, points={{0,0},{0,-16}}),Line(visible=true, points={{-70,0},{0,0}}),Line(visible=true, points={{-50,-40},{-50,-60}}),Line(visible=true, points={{-30,-40},{-30,-60}}),Line(visible=true, points={{-10,-40},{-10,-60}}),Line(visible=true, points={{10,-40},{10,-60}}),Line(visible=true, points={{30,-40},{30,-60}}),Line(visible=true, points={{50,-40},{50,-60}})}));
    end TranslationalSensor;

    partial model RotationalSensor "Icon representing rotational measurement device"
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-70},{70,70}}),Line(visible=true, points={{0,70},{0,40}}),Line(visible=true, points={{22.9,32.8},{40.2,57.3}}),Line(visible=true, points={{-22.9,32.8},{-40.2,57.3}}),Line(visible=true, points={{37.6,13.7},{65.8,23.9}}),Line(visible=true, points={{-37.6,13.7},{-65.8,23.9}}),Line(visible=true, points={{0,0},{9.02,28.6}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-0.48,31.6},{18,26},{18,57.2},{-0.48,31.6}}),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{-5,-5},{5,5}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-70},{70,70}}),Line(visible=true, points={{0,70},{0,40}}),Line(visible=true, points={{22.9,32.8},{40.2,57.3}}),Line(visible=true, points={{-22.9,32.8},{-40.2,57.3}}),Line(visible=true, points={{37.6,13.7},{65.8,23.9}}),Line(visible=true, points={{-37.6,13.7},{-65.8,23.9}}),Line(visible=true, points={{0,0},{9.02,28.6}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-0.48,31.6},{18,26},{18,57.2},{-0.48,31.6}}),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{-5,-5},{5,5}})}));
    end RotationalSensor;

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
package MultiBody "Modelica library to model 3D mechanical systems"
  extends Modelica.Icons.Library;
  import SI = Modelica.SIunits;
  annotation(Documentation(info="<html>

<p>
This library is used to model <b>3-dimensional mechanical</b> systems, such as robots, satellites or vehicles. The components of the MultiBody library
can be combined with the 1D-mechanical libraries
Modelica.Mechanics.Rotational and Modelica.Mechanics.Translational.
A unique feature of the MultiBody library is the efficient treatment of
joint locking and unlocking. This allows e.g. easy modeling of friction or
brakes in the joints.

<p>
A first example to model a simple pendulum is given in the next figure:

<IMG SRC=\"Images/Pendulum1.png\" ALT=\"Pendulum1\">

<p>
This system is built up by the following components:

<ul>
<li> Component <b>inertial</b> is an instance of
     MultiBody.Parts.InertialSystem and defines the inertial
     system of the model as well as the gravity acceleration</li>
<li> Component <b>revolute</b> is an instance of
     MultiBody.Joints.Revolute and defines a revolute joint which
     is connected to the inertial system. The axis of rotation is
     defined to be vector {0,0,1}, i.e., a vector in z-direction
     resolved in the frame at the left side of the revolute joint.
     Since this frame is rigidly attached to the inertial frame, these
     two frames are identical. As a consequence, the revolute joint
     rotates around the z-axis of the inertial system.</li>
<li> Component <b>boxBody</b> is an instance of
     MultiBody.Parts.BoxBody and defines a box. The box is defined
     by lenght, width and height and some material properties, such
     as the density. The mass, center of mass and inertia tensor
     are calculated from this data. Additionally, the shape of the box
     is used for animation.</li>
<li> Component <b>damper</b> is an instance of
     Modelica.Mechanics.Rotational.Damper and defines the
     velocity dependent damping in the joint axis. It is connected
     between the driving flange <b>axis</b> of the joint and
     flange <b>bearing</b>. Both flanges are 1D mechanical connections.</li>
</ul>

<p>
The 3D-components are connected together at connectors <b>Frame_a</b>
or <b>Frame_b</b>. Both connectors define a coordinate system (a frame)
at a specific location of the component, which is fixed in the component.
The frame, i.e., the corresponding connector, is defined by the following
variables:

<pre>
  S[3,3]: Rotation matrix describing the frame with respect to the inertial
          frame, i.e. if ha is vector h resolved in frame_a and h0 is
          vector h resolved in the inertial frame, h0 = S*ha.
  r0[3] : Vector from the origin of the inertial frame to the origin
          of the frame, resolved in the inertial frame in [m] !!! (note,
          that all other vector quantities are resolved in frame_a!!!).
  v[3]  : Absolute (translational) velocity of the frame, resolved in
          the frame in [m/s]:  v = transpose(S)*der(r0)
  w[3]  : Absolute angular velocity of the frame, resolved in the frame,
          in [rad/s]:  w = vec(transpose(S)*der(S)), where
                      |   0   -w[3]  w[2] |
            skew(w) = |  w[3]   0   -w[1] | and w=vec(skew(w))
                      | -w[2]  w[1]   0   |
  a[3]  : Absolute translational acceleration of the frame minus gravity
          acceleration, resolved in the frame, in [m/s^2]:
             a = transpose(S)*( der(S*v) - ng*g )
          (ng,g are defined in model MultiBody.Parts.InertialSystem).
  z[3]  : Absolute angular acceleration of the frame, resolved in the
          frame, in [rad/s^2]:  z = transpose(S)*der(S*w)
  f[3]  : Resultant cut-force acting at the origin of the frame,
          resolved in the frame, in [N].
  t[3]  : Resultant cut-torque with respect to the origin of the frame,
          resolved in the frame, in [Nm].
</pre>

<p>
If two frame-connectors are connected together, the corresponding frames
are rigidly fixed together, i.e., they are identical. Usually, all vectors
of a component are expressed in <b>frame_a</b> of this component, i.e., in
a coordinate system fixed in the component. For example, the vector from
the origin of frame_a to the center-of-mass in component
MultiBody.Parts.Body is resolved in frame_a.

<p>
Similiarily to the pendulum example above, most local frames are
parallel to each other, if the generalized relative coordinates of the
joints are zero. This means that in this configuration all vectors
can be defined, as if the vectors would be expressed in the inertial frame
(since all frames are parallel to each other). This view simplifies
the definition. Only, if components
Parts.FrameRotation, Parts.FrameAxes or Parts.FrameAngles are used, the
frames are no longer parallel to each other in this nominal configuration.

<p>
A more advance example is shown in the next figure.
It is the definition of the mechanical structure of the robot r3,
defined in the MultiBody.Examples.Robots.r3 sublibrary. It consists
of a robot with 6 degrees-of-freedoms constructed with 6 revolutes
joints and 6 shape bodies (i.e., the mass and inertia data is computed
from shape data). The flanges of the driving axes of the joints
are defined as flanges external to the model (connectors axis1, axis2,
..., axis6).

<IMG SRC=\"Images/r3Robot1.png\" ALT=\"robot r3 (diagram layer)\">

<p>
After processing the r3 model with a Modelica translator and
simulating it, an animation can be performed:

<IMG SRC=\"Images/r3Robot2.png\" ALT=\"robot r3 (animation)\">

<p>
It is also possible to define multibody systems which have kinematic
loops. An example is given in the next two figures (as object diagram
and as animation view) where a mechanism with two coupled loops and
one degree of freedom is shown:

<IMG SRC=\"Images/TwoLoops1.png\" ALT=\"TwoLoops1\">
<IMG SRC=\"Images/TwoLoops2.png\" ALT=\"TwoLoops2\">

<p>
The ModelicaAdditions.MultiBody library consists of the following elements:

<ul>
<li><b>Inertial system</b> (in package MultiBody.Parts):<br>
    Exactly one inertial system must be present.</li>

<li><b>Rigid bodies</b> in package MultiBody.Parts (grey icons or
  brown icons if animation information included):<br>
  There are several model classes to define rigid bodies which have mass and
  inertia. Often it is most convienient to
  use the  BoxBody- and CylinderBody-model classes. Here, a box or a cylinder
  is defined. From the definition the mass, center of mass and inertia
  tensor is computed. Furthermore, the defined shape is used in the animation.
  All body objects have at most 2 frames where the body can be connected with
  other elements. If a rigid body has several attachment points where
  additional elements can be connected, it has to be built up by several
  body or (massless) frame elements (FrameTranslation, FrameRotationm ...)
  which are rigidly connected together.
  Presently, elastic bodies are not supported.</li>

<li><b>Joints</b> in the <b>spanning tree</b> in package MultiBody.Joints:<br>
  A general multibody system with closed kinematic loops is handeled by dividing
  the joints into two distinct sets: <b>Tree-Joints</b> and <b>Cut-Joints</b>.
  After removal of all of the Cut-Joints, the resulting system must have a
  tree-structure. All joints in subpackage <b>Joints</b>, are joints used
  in this spanning tree. The relative motion between the two cut-frames of a
  Joint is described by f (0 <= f <= 6) generalized minimal-coordinates q
  and their first and second derivatives qd, qdd. By default, q and qd are
  used as state variables. In a kinematic loop, 6-nc degrees-of-freedom
  have to be removed, when the cut-joints introduces nc constraints.
  The Modelica translator can perform this removal automatically. In order
  to guide the translator, every joint has a parameter <b>startValueFixed</b>
  which can be used to require, that a particular degree-of-freedom
  should be selected as a state, because the given start values
  for the generalized coordinates q and qd have to be taken literally
  (this is realized, by setting attribute <b>fixed</b> = startValueFixed
  for the corresponding potential state variables).
  The one-degree-of-freedom joints (Revolute,
  Prismatic, Screw) may have a <b>variable</b> structure. That is, the joint can
  be <b>locked</b> and <b>unlocked</b> during the movement of a multibody system.
  This feature can be used to model brakes, clutches, stops or sticking friction.
  Locking is modelled with elements of the Modelica.Mechanics.Rotational library,
  such as classes Clutch or Friction, which can be attached to flange <b>axis</b>
  of the joints.</li>

<li><b>Cut-Joints</b> in package MultiBody.CutJoints:<br>
  All  red  joints are cut joints. Cut joints are used to
  break closed kinematic loops (see previous paragraph).</li>

<li><b>Force</b> elements in package MultiBody.Forces:<br>
  Force elements, such as springs and dampers, can be attached between
  two points of distinct bodies or joints. However, it is <b>not possible
  to connect force elements with other force elements</b>. It is easy for an
  user to introduce new force elements as subclasses from already existing
  ones (e.g. from model class MultiBody.Interfaces.LineForce).
  One-dimensional force laws can be
  used from the MultiBody.Mechanics.Rotational library.
  Gravitational forces for <b>all</b> bodies are taken into account by setting
  the gravitational acceleration of the inertial system (= object of
  MultiBody.Parts.InertialSystem) to a nonzero value.</li>

<li><b>Sensor</b> elements in package MultiBody.Sensors (yellow icons):<br>
  Between two distinct points of bodies and joints a sensor element can be
  attached. A sensor is used to calculate relative kinematic quantities
  between the two points. In the libraries a general 3D sensor element
  (calculate all relative quantities) and a line-sensor element are
  present. </li>
</ul>

<p>
<b>Connection Rules</b>:<br>
The elements of the multibody library cannot be connected arbitrarily
together. Instead the following rules hold:

<ol>
<li><b>Tree joint</b> objects, <b>body</b> objects
    and the <b>inertial system</b> have to be connected together in such a way
    that a <b>frame_a</b> of an object (cut filled with blue color) is always connected
    to a <b>frame_b</b> of an object (non-filled cut). The connection structure
    has to form a <b>tree</b> with the inertial system as a root.</li>

<li><b>Cut-joint</b>, <b>force</b>, and <b>sensor</b> objects have to be
    always connected
    between two frames of a <b>tree joint</b>, <b>body</b> or
    <b>inertial system</b> object.
    E.g., it is not allowed to connect two force objects together.
    </li>

<li>By using the <b>input/output</b> prefixes of Modelica in the corresponding
    connectors of the MultiBody library, it is guaranteed that
    only connections can be carried out, for which the library is
    designed.</li>
</ol>


<p>
This package is not part of the Modelica standard library, because a
\"truely object-oriented\" 3D-mechanical library is under
development. The essential difference is that the new library
no longer has restrictions on connections and that the modeller
does not have to handle systems with kinematic loops in a different
way (as a consequence, sublibrary CutJoints will be removed; the
structure of the remaining library will be not changed, only the
implementation of the model classes).

<p>
Note, this library utilizes the non-standard function <b>constrain(..)</b>
and assumes that this function is supported by the Modelica translator:

<pre>
   Real r[:], rd[:], rdd[:];
      ...
   r   = ..
   rd  = ...
   rdd = ...
   constrain(r,rd,rdd);
</pre>

<p>
where r, rd and rdd are variables which need to be computed
somewhere else. Function constrain()
is used to explicitly inform the Modelica translator that
rd is the derivative of r and rdd is the derivative of rd
and that all derivatives need to be identical to zero.
The Modelica translator can utilize this information to use
rd and rdd whenever the Pantelides algorithm requires to compute
the derivatives of r. This enhances the efficiency considerably.
A simple, but inefficient, implementation of constrain() is:

<pre>
   r = 0;
</pre>

<p>
In the multibody library, function constrain() is used in the cut joints,
i.e., whenever kinematic loops are present.

<p>
<b>References</b>

<pre>
The following paper can be downloaded from:
 http://www.dynasim.se/publications.html

Algorithmic details of the multibody library are described in
 Otter M., Elmqvist H., and Cellier F.E:  Modeling of Multibody Systems
   with the Object-Oriented Modeling Language Dymola . Proceedings
   of the NATO-Advanced Study Institute on  Computer Aided
   Analysis of Rigid and Flexible Mechancial Systems , Volume II,
   pp. 91-110, Troia, Portugal, 27 June - 9 July, 1993. Also in:
   Nonlinear Dynamics, 9:91-112, 1996, Kluwer Academic Publishers.
</pre>

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

<p><b>Release Notes:</b>
<ul>
<li><i>June 20, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
<ul>
<li><i>August 21, 2009</i>
       by <a href=\"http://www.mathcore.com/\">MathCore Engineering AB</a>:<br>
This library has been moved out from the ModelicaAdditions library and updated. Below is a list of changes that have been made in order to be compatible with the current release of <i>MathModelica</i>. All changes are have been made in such a way that it should work the same as the older ModelicaAdditions.MultiBody library. Especially, no changes of equations or algorithms have been made from the original library.
<ul>
<li>
All graphical annotations have been updated to comply with Modelica 3.0.
</li>
<li>
Images available in the documentation have been changed to png format instead of gif format.
</li>
<li>
The following models have been changed so that the correct states are used during simulation:
<ul>
<li>
<b>MultiBody.Examples.Robots.r3.Components.GearType1:</b> Changed parameter stateSelection from <i>Default</i> to to <i>Avoid</i> for spring and Jmotor component.
</li>
<li>
<b>MultiBody.Interfaces.TwoNoTreeFrames:</b> Added start={1,1,1} to the parameter r0a.
</li>
<li>
<b>MultiBody.Joints.FreeMotion:</b> Added stateSelect=StateSelect.Prefer to the variable phi.
</li>
<li>
<b>MultiBody.Joints.Spherical:</b> Added stateSelect=StateSelect.Prefer to the variable phi.
</li>
</ul>
</li>
<li>Added experiment settings for all examples so that they simulate for the amount of time specified in the documentation.
</li>
<li>Removed function calls in calculation of S_rel in <b>MultiBody.Parts.FrameAngles</b> and <b>MultiBody.Parts.FrameRotation</b> due to index reduction problems in current version of <i>MathModelica</i>. Instead the calls are replaced with the equivalent calculations made inside the functions.
</li>
</ul>
 </li>
</ul>

<p><b>Copyright &copy; 2000-2002, DLR.</b>

<p><i>
The ModelicaAdditions.MultiBody package is <b>free</b> software;
it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i>

</HTML>
", revisions=""));
  package Interfaces "Connectors and partial models for 3D mechanical components"
    extends Modelica.Icons.Library;
    annotation(Documentation(info="<html>

<p>
This package contains connectors and partial models for 3D mechanical
components.

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

<p><b>Release Notes:</b></p>
<ul>
<li><i>April 5, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>

<p><b>Copyright &copy; 2000-2002, DLR.</b>

<p><i>
The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i>

</HTML>
", revisions=""));
    connector Frame_a "Frame a of a mechanical element"
      input SI.Position r0[3] "Position vector from inertial system to frame origin, resolved in inertial system";
      Real S[3,3] "Transformation matrix from frame_a to inertial system";
      SI.Velocity v[3] "Absolute velocity of frame origin, resolved in frame_a";
      SI.AngularVelocity w[3] "Absolute angular velocity of frame_a, resolved in frame_a";
      SI.Acceleration a[3] "Absolute acceleration of frame origin, resolved in frame_a";
      SI.AngularAcceleration z[3] "Absolute angular acceleration of frame_a, resolved in frame_a";
      flow SI.Force f[3];
      flow SI.Torque t[3];
      annotation(Documentation(info="<HTML>

<p>
Frame a  of a mechanical element.

<p>
All mechanical components are always connected together at frames.
A frame is a coordinate system in the (mechanical) cut-plane of the
connection point. The variables of the cut-plane are defined
with respect to the corresponding frame_a and have the following meaning:

<pre>
Potential variables:
  S : Rotation matrix describing frame_a with respect to the inertial
      frame, i.e. if ha is vector h resolved in frame_a and h0 is
      vector h resolved in the inertial frame, h0 = S*ha.
  r0: Vector from the origin of the inertial frame to the origin
      of frame_a, resolved in the inertial frame in [m] !!! (note,
      that all other vector quantities are resolved in frame_a!!!).
  v : Absolute (translational) velocity of frame_a, resolved in a,
      in [m/s]:  v = transpose(S)*der(r0)
  w : Absolute angular velocity of frame_a, resolved in a,
      in [rad/s]  :  w = vec(transpose(S)*der(S));  Note, that
                   |   0 -w3  w2 |
         skew(w) = |  w3   0 -w1 | and w=vec(skew(w))
                   | -w2  w1   0 |
  a : Absolute translational acceleration of frame_a - gravity
      acceleration, resolved in a, in [m/s^2]:
          a = transpose(S)*( der(S*v) - ng*g )
      (ng,g are defined in model MultiBody.Parts.InertialSystem).
  z : Absolute angular acceleration of frame_a, resolved in a,
      in [rad/s^2]:  z = transpose(S)*der(S*w)

Flow variables:
  f : Resultant cut-force acting at the origin of frame_a,
      resolved in a, in [N].
  t : Resultant cut-torque with respect to the origin of frame_a,
      resolved in a, in [Nm].
</pre>

</HTML>", revisions=""), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{0,0},{-100,-100},{100,-100},{100,100},{-100,100},{0,0}}, fillPattern=FillPattern.Solid, fillColor={0,0,255})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{0.0,0.0},{-100.0,-100.0},{100.0,-100.0},{100.0,100.0},{-100.0,100.0},{0.0,0.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,-220.0},{100.0,-120.0}}, textString="%name", fontName="Arial")}));
    end Frame_a;

    connector Frame_b "Frame b of a mechanical element"
      output SI.Position r0[3] "Position vector from inertial system to frame origin, resolved in inertial system";
      Real S[3,3] "Transformation matrix from frame_a to inertial system";
      SI.Velocity v[3] "Absolute velocity of frame origin, resolved in frame_a";
      SI.AngularVelocity w[3] "Absolute angular velocity of frame_a, resolved in frame_a";
      SI.Acceleration a[3] "Absolute acceleration of frame origin, resolved in frame_a";
      SI.AngularAcceleration z[3] "Absolute angular acceleration of frame_a, resolved in frame_a";
      flow SI.Force f[3];
      flow SI.Torque t[3];
      annotation(Documentation(info="<HTML>

<p>
Frame b  of a mechanical element.

<p>
All mechanical components are always connected together at frames.
A frame is a coordinate system in the (mechanical) cut-plane of the
connection point. The variables of the cut-plane are defined
with respect to the corresponding frame_b and have the following meaning:

<pre>
Potential variables:
  S : Rotation matrix describing frame_b with respect to the inertial
      frame, i.e. if ha is vector h resolved in frame_b and h0 is
      vector h resolved in the inertial frame, h0 = S*ha.
  r0: Vector from the origin of the inertial frame to the origin
      of frame_a, resolved in the inertial frame in [m] !!! (note,
      that all other vector quantities are resolved in frame_a!!!).
  v : Absolute (translational) velocity of frame_a, resolved in a,
      in [m/s]:  v = transpose(S)*der(r0)
  w : Absolute angular velocity of frame_a, resolved in a,
      in [rad/s]  :  w = vec(transpose(S)*der(S));  Note, that
                   |   0 -w3  w2 |
         skew(w) = |  w3   0 -w1 | and w=vec(skew(w))
                   | -w2  w1   0 |
  a : Absolute translational acceleration of frame_b - gravity
      acceleration, resolved in a, in [m/s^2]:
          a = transpose(S)*( der(S*v) - ng*g )
      (ng,g are defined in model MultiBody.Parts.InertialSystem).
  z : Absolute angular acceleration of frame_a, resolved in a,
      in [rad/s^2]:  z = transpose(S)*der(S*w)

Flow variables:
  f : Resultant cut-force acting at the origin of frame_a,
      resolved in a, in [N].
  t : Resultant cut-torque with respect to the origin of frame_a,
      resolved in a, in [Nm].
</pre>

</HTML>", revisions=""), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,-100},{0,-100},{100,0},{0,100},{-100,100},{-100,-100}}, fillPattern=FillPattern.Solid, fillColor={255,255,255})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-100.0,-100.0},{0.0,-100.0},{100.0,0.0},{0.0,100.0},{-100.0,100.0},{-100.0,-100.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,-220.0},{100.0,-110.0}}, textString="%name", fontName="Arial")}));
    end Frame_b;

    partial model OneFrame_a "Superclass of elements with ONE mechanical frame_a"
      annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      Frame_a frame_a(S=Sa, r0=r0a, v=va, w=wa, a=aa, z=za, f=fa, t=ta) annotation(Placement(visible=true, transformation(origin={-105.0,0.0}, extent={{-15.0,15.0},{15.0,-15.0}}, rotation=0), iconTransformation(origin={-105.0,0.0}, extent={{-15.0,15.0},{15.0,-15.0}}, rotation=0)));
    protected
      Real Sa[3,3](start=identity(3));
      SI.Position r0a[3];
      SI.Velocity va[3];
      SI.AngularVelocity wa[3];
      SI.Acceleration aa[3];
      SI.AngularAcceleration za[3];
      SI.Force fa[3];
      SI.Torque ta[3];
      annotation(Documentation(info="<HTML>
<p>
Superclass of elements which have <b>one</b> mechanical frame,
which is called frame_a.
</p>
</HTML>
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
    end OneFrame_a;

    partial model TwoTreeFrames "Superclass of elements of the spanning tree with TWO frames"
      constant Real pi=Modelica.Constants.pi;
      constant Real PI=Modelica.Constants.pi "Only for compatibility reasons";
      annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<HTML>

<p>
Superclass of elements which have <b>two</b> mechanical frames in the spanning
tree, which are called <b>frame_a</b> and <b>frame_b</b>, respectively.

<p>
<b>Important:</b><br>
frame_a of an element should <b>always</b> be connected to a frame_b.<br>
frame_b of an element should <b>always</b> be connected to a frame_a.

</HTML>

", revisions=""));
      Frame_a frame_a(S=Sa, r0=r0a, v=va, w=wa, a=aa, z=za, f=fa, t=ta) annotation(Placement(visible=true, transformation(origin={-105.0,0.0}, extent={{-15.0,-15.0},{15.0,15.0}}, rotation=0), iconTransformation(origin={-105.0,0.0}, extent={{-15.0,-15.0},{15.0,15.0}}, rotation=0)));
      Frame_b frame_b(S=Sb, r0=r0b, v=vb, w=wb, a=ab, z=zb, f=-fb, t=-tb) annotation(Placement(visible=true, transformation(origin={105.0,0.0}, extent={{-15.0,-15.0},{15.0,15.0}}, rotation=0), iconTransformation(origin={105.0,0.0}, extent={{-15.0,-15.0},{15.0,15.0}}, rotation=0)));
    protected
      Real Sa[3,3](start=identity(3));
      SI.Position r0a[3];
      SI.Velocity va[3];
      SI.AngularVelocity wa[3];
      SI.Acceleration aa[3];
      SI.AngularAcceleration za[3];
      SI.Force fa[3];
      SI.Torque ta[3];
      Real Sb[3,3](start=identity(3));
      SI.Position r0b[3];
      SI.Velocity vb[3];
      SI.AngularVelocity wb[3];
      SI.Acceleration ab[3];
      SI.AngularAcceleration zb[3];
      SI.Force fb[3];
      SI.Torque tb[3];
      annotation(Documentation(info="<HTML>
<p>
Superclass of elements which have <b>two</b> mechanical frames in the
spanning tree, which are called <b>frame_a</b> and
<b>frame_b</b>, respectively.

<p>
<b>Important</b><br>
frame_a of an element should <b>always</b> be connected to a frame_b.<br>
frame_b of an element should <b>always</b> be connected to a frame_a.
</p>
</HTML>

"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
    end TwoTreeFrames;

    model BodyBase "Inertia and mass properties of a rigid body"
      extends OneFrame_a;
      SI.Mass m;
      SI.Position rCM[3];
      SI.Inertia I[3,3];
      annotation(Documentation(info="<HTML>

<p>
This model should usually not be used directly, because the mass
properties have to be given as terminal variables and not as
parameters. This allows the computation of the mass properties
from other data, as well as the modification of the mass properties
at event points. The following variables have to be computed in
subclasses:

<pre>
  m     : Mass of body in [kg].
  rCM(3): Position vector from the origin of frame_a to the center
          of mass, resolved in frame_a in [m].
  I(3,3): Inertia tensor of the body with respect to the center of mass,
          resolved in frame_a in [kgm^2]. The matrix must be
          symmetric and positiv semi-definit.
</pre>

</HTML>
", revisions=""), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={127,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{-90.0,15.0},{0.0,-15.0}}),Rectangle(visible=true, fillColor={127,127,255}, fillPattern=FillPattern.Sphere, extent={{0.0,-50.0},{100.0,50.0}}),Text(visible=true, lineColor={0,0,255}, extent={{-100.0,60.0},{100.0,122.0}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={127,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{-90.0,15.0},{0.0,-15.0}}),Rectangle(visible=true, fillColor={127,127,255}, fillPattern=FillPattern.Sphere, extent={{0.0,-50.0},{100.0,50.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{22.0,-104.0},{82.0,-64.0}}, textString="center of mass", fontName="Arial"),Line(visible=true, points={{-90.0,-10.0},{-90.0,-72.0}}, color={0,0,255}),Line(visible=true, points={{50.0,0.0},{50.0,-72.0}}, color={0,0,255}),Line(visible=true, points={{-90.0,-66.0},{50.0,-66.0}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{36.0,-62.0},{36.0,-70.0},{50.0,-66.0},{36.0,-62.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-50.0,-62.0},{-24.0,-44.0}}, textString="rCM", fontName="Arial")}));
    equation
      fa=m*(aa + cross(za, rCM) + cross(wa, cross(wa, rCM)));
      ta=I*za + cross(wa, I*wa) + cross(rCM, fa);
    end BodyBase;

    partial model Interact "Superclass of joint, force and sensor elements"
      Real S_rel[3,3];
      SI.Position r_rela[3];
      SI.Velocity v_rela[3];
      SI.AngularVelocity w_rela[3];
      SI.Acceleration a_rela[3];
      SI.AngularAcceleration z_rela[3];
      annotation(Documentation(info="<HTML>

<p>
All relative kinematic quantities between frame_a and frame_b are
defined, i.e., relative position, relative velocity and
relative acceleration (resolved in frame_a).

<p>
For efficiency reasons, these calculations are performed in
subclasses (= the same equations are just solved for different
variables according to the usually needed causality).
The relative quantities, which are defined in this
model, have the following meaning:

<pre>
  S_rel : Rotation matrix relating frame_a and frame_b, i.e. if
          hb is vector h resoved in frame_b and ha is vector h resolved
          in frame_a, hb = S_rel*ha.
  r_rela: Vector from the origin of frame_a to the origin of frame_b,
          resolved in frame_a.
  v_rela: (Translational) velocity of frame_b with respect to frame_a,
          resolved in frame_a: v_rela = der(r_rela)
  w_rela: Angular velocity of frame_b with respect to frame_a,
          resolved in frame_a: w_rela = vec( der(S_rel)'*S_rel )
  a_rela: (Translational) acceleration of frame_b with respect to
          frame_a, resolved in frame_a: a_rela = der( v_rela )
  z_rela: Angular acceleration of frame_b with respect to frame_a,
          resolved in frame_a: z_rela = der( w_rela )
</pre>

<p>
If needed, all of the above quantities can also easily be resolved in
frame_b, according to  Xrelb = S_rel*Xrela . However note, that
v_relb is <b>not</b> der(r_relb)  (v_relb=S_rel*v_rela; r_relb=S_rel*r_rela).

</HTML>", revisions=""), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
    end Interact;

    partial model TreeJoint "Superclass of joints used in the spanning tree"
      extends TwoTreeFrames;
      extends Interact;
      annotation(Documentation(info="<HTML>

<p>
A joint has two mechanical cuts which may move relative to each other. In
every cut a coordinate system is rigidly attached, called frame_a and frame_b,
correspondingly. It is a massless element in which no energy is stored.
Mathematically, a joint transforms the kinematic properties of frame_a to
frame_b and at the same time transforms the force and torque acting on
frame_b to frame_a.

<p>
A general multibody system with closed kinematic loops is handeled by dividing
the joints into two distinct sets: <b>Tree-Joints</b> and <b>Cut-Joints</b>.
After removal of all of the Cut-Joints, the resulting system must have a
tree-structure. Class TreeJoint is used as a superclass for Tree-Joints.

<p>
The relative motion between the two cut-frames of a Tree-Joint is described
by f (0 <= f <= 6) generalized minimal-coordinates q and their first and
second derivatives qd, qdd. In subclasses of class TreeJoint the relative
kinematic quantities are given as functions of q, qd, qdd, according to the
specific joint type. In class TreeJoint the relationships are provided
between the kinematic and dynamic quantities of frame_a and frame_b and of the relative quantities.

<p>
In order to speedup the generation of the equations, the common equations of
TreeJoint classes are <b>not</b> stored in model TreeJoint, but in the
specific submodel. This has the advantage that special joint properties
(like S_rel=identity(3), i.e., the relative transformation matrix is a
unit matrix) are already utilized and the Modelica translator does not have
to waste time and space to find this out by symbolic formula transformation.
The common equations which could be stored in the TreeJoint
model are given as a comment below.

</HTML>
", revisions=""), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
    end TreeJoint;

  end Interfaces;

  package Joints "Joints in the spanning tree"
    extends Modelica.Icons.Library;
    annotation(Documentation(info="<html>

<p>
This package contains elements to model ideal joints.

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

<p><b>Release Notes:</b></p>
<ul>
<li><i>April 5, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>

<p><b>Copyright &copy; 2000-2002, DLR.</b></p>

<p><i>
The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i>

</HTML>
", revisions=""));
    model Revolute "Revolute joint (1 degree-of-freedom, used in spanning tree)"
      extends Interfaces.TreeJoint;
      parameter Real n[3]={0,0,1} "Axis of rotation resolved in frame_a (= same as in frame_b)";
      parameter Real q0=0 "Rotation angle offset (see info) [deg]";
      parameter Boolean startValueFixed=false "true, if start values of q, qd are fixed";
      SI.Angle q(final fixed=startValueFixed);
      SI.AngularVelocity qd(final fixed=startValueFixed);
      SI.AngularAcceleration qdd;
      SI.Angle qq;
      Real nn[3];
      Real sinq;
      Real cosq;
      annotation(Documentation(info="<HTML>

<p>
Joint where frame_b rotates around axis n which is fixed in frame_a.
The joint axis has an additional flange where it can be
driven with elements of the Modelica.Mechanics.Rotational library.
The relative angle q [rad] and the relative angular velocity
qd [rad/s] are used as state variables.

<p>
The following parameters are used to define the joint:

<pre>
  n : Axis of rotation resolved in frame_a (= same as in frame_b).
      n  must not necessarily be a unit vector. E.g.,
         n = {0, 0, 1} or n = {1, 0, 1}
  q0: Rotation angle offset in [deg].
      If q=q0, frame_a and frame_b are identical.
  startValueFixed: true, if start values of q, qd are fixed.
</pre>

</HTML>
", revisions=""), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-90.0,-60.0},{-30.0,60.0}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{30.0,-60.0},{90.0,60.0}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-30.0,-10.0},{10.0,10.0}}),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{10.0,30.0},{30.0,50.0},{30.0,-50.0},{10.0,-30.0},{10.0,30.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-220.0,-140.0},{220.0,-80.0}}, textString="%name=%n", fontName="Arial"),Line(visible=true, points={{-20.0,70.0},{-50.0,70.0}}),Line(visible=true, points={{-20.0,80.0},{-20.0,60.0}}),Line(visible=true, points={{20.0,80.0},{20.0,60.0}}),Line(visible=true, points={{20.0,70.0},{41.0,70.0}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.VerticalCylinder, extent={{-10.0,50.0},{10.0,60.0}}),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-10.0,30.0},{10.0,30.0},{30.0,50.0},{-30.0,50.0},{-10.0,30.0}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-90.0,-60.0},{-30.0,60.0}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{30.0,-60.0},{90.0,60.0}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-30.0,-10.0},{10.0,10.0}}),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{10.0,30.0},{30.0,50.0},{30.0,-50.0},{10.0,-30.0},{10.0,30.0}}),Line(visible=true, points={{-20.0,70.0},{-50.0,70.0}}),Line(visible=true, points={{-20.0,80.0},{-20.0,60.0}}),Line(visible=true, points={{20.0,80.0},{20.0,60.0}}),Line(visible=true, points={{20.0,70.0},{41.0,70.0}}),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-10.0,30.0},{10.0,30.0},{30.0,50.0},{-30.0,50.0},{-10.0,30.0}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.VerticalCylinder, extent={{-10.0,50.0},{10.0,60.0}})}));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a axis annotation(Placement(visible=true, transformation(origin={0.0,70.0}, extent={{10.0,10.0},{-10.0,-10.0}}, rotation=0), iconTransformation(origin={0.0,70.0}, extent={{10.0,10.0},{-10.0,-10.0}}, rotation=0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_b bearing annotation(Placement(visible=true, transformation(origin={-60.0,70.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0), iconTransformation(origin={-60.0,70.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0)));
    equation
      axis.phi=q;
      bearing.phi=0;
      qd=der(q) "define states";
      qdd=der(qd);
      nn=n/sqrt(n*n) "rotation matrix";
      qq=q - q0*pi/180;
      sinq=sin(qq);
      cosq=cos(qq);
      S_rel=[nn]*transpose([nn]) + (identity(3) - [nn]*transpose([nn]))*cosq - skew(nn)*sinq;
      r_rela=zeros(3) "other kinematic quantities";
      v_rela=zeros(3);
      a_rela=zeros(3);
      w_rela=nn*qd;
      z_rela=nn*qdd;
      Sb=Sa*transpose(S_rel);
      r0b=r0a;
      vb=S_rel*va;
      wb=S_rel*(wa + w_rela);
      ab=S_rel*aa;
      zb=S_rel*(za + z_rela + cross(wa, w_rela));
      fa=transpose(S_rel)*fb;
      ta=transpose(S_rel)*tb;
      axis.tau=nn*tb "d'Alemberts principle";
    end Revolute;

    model Prismatic "Prismatic joint (1 degree-of-freedom, used in spanning tree)"
      extends Interfaces.TreeJoint;
      parameter Real n[3]={1,0,0} "Axis of translation resolved in frame_a (= same as in frame_b)";
      parameter SI.Position q0=0 "Relative distance offset(see info)";
      parameter Boolean startValueFixed=false "true, if start values of q, qd are fixed";
      SI.Position q(final fixed=startValueFixed);
      SI.Velocity qd(final fixed=startValueFixed);
      SI.Acceleration qdd;
      SI.Position qq;
      Real nn[3];
      SI.Velocity vaux[3];
      annotation(Documentation(info="<HTML>

<p>
Joint where frame_b is translated around axis n which is fixed in frame_a.
The joint axis has an additional flange where it can be
driven with elements of the Modelica.Mechanics.Translational library.
The relative distance q [m] and the relative velocity qd [m] are
used as state variables.

<p>
The following parameters are used to define the joint:

<pre>
  n : Axis of translation resolved in frame_a (= same as in frame_b).
      n must not necessarily be a unit vector. E.g.,
         n = {0, 0, 1} or n = {1, 0, 1}
  q0: Relative distance offset in [m].
      (in the direction of n).
      If q=q0, frame_a and frame_b are identical.
  startValueFixed: true, if start values of q, qd are fixed.
</pre>

</HTML>
", revisions=""), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{80.0,30.0},{90.0,70.0}}),Rectangle(visible=true, lineColor={0,0,255}, fillColor={192,192,192}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, extent={{-90.0,-50.0},{-20.0,40.0}}),Rectangle(visible=true, lineColor={0,0,255}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, extent={{-90.0,40.0},{-20.0,50.0}}),Rectangle(visible=true, lineColor={0,0,255}, fillColor={192,192,192}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, extent={{-20.0,-30.0},{90.0,20.0}}),Rectangle(visible=true, lineColor={0,0,255}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, extent={{-20.0,20.0},{90.0,30.0}}),Line(visible=true, points={{-20.0,-50.0},{-20.0,50.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-220.0,-130.0},{220.0,-70.0}}, textString="%name=%n", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={192,192,192}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, extent={{-90.0,-50.0},{-20.0,40.0}}),Rectangle(visible=true, lineColor={0,0,255}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, extent={{-90.0,40.0},{-20.0,50.0}}),Rectangle(visible=true, lineColor={0,0,255}, fillColor={192,192,192}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, extent={{-20.0,-30.0},{90.0,20.0}}),Rectangle(visible=true, lineColor={0,0,255}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, extent={{-20.0,20.0},{90.0,30.0}}),Line(visible=true, points={{-20.0,-50.0},{-20.0,50.0}}),Rectangle(visible=true, lineColor={160,160,160}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{80.0,70.0},{90.0,30.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{32.0,65.0},{47.0,80.0}}, textString="f", fontName="Arial"),Line(visible=true, points={{30.0,65.0},{60.0,65.0}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{-10.0,68.0},{-20.0,65.0},{-10.0,62.0},{-10.0,68.0}}),Line(visible=true, points={{10.0,65.0},{-20.0,65.0}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-10.0,65.0},{5.0,80.0}}, textString="f", fontName="Arial"),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{50.0,68.0},{60.0,65.0},{50.0,62.0},{50.0,68.0}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{50.0,58.0},{60.0,55.0},{50.0,52.0},{50.0,58.0}}),Line(visible=true, points={{-19.0,55.0},{51.0,55.0}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{5.0,44.0},{36.0,54.0}}, textString="q = axis.s", fontName="Arial")}));
      Modelica.Mechanics.Translational.Interfaces.Flange_a axis annotation(Placement(visible=true, transformation(origin={70.0,60.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0), iconTransformation(origin={70.0,60.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0)));
      Modelica.Mechanics.Translational.Interfaces.Flange_b bearing annotation(Placement(visible=true, transformation(origin={-30.0,60.0}, extent={{10.0,10.0},{-10.0,-10.0}}, rotation=0), iconTransformation(origin={-30.0,60.0}, extent={{10.0,10.0},{-10.0,-10.0}}, rotation=0)));
    equation
      axis.s=q;
      bearing.s=0;
      qd=der(q) "define states";
      qdd=der(qd);
      nn=n/sqrt(n*n) "normalize axis vector";
      S_rel=identity(3) "kinematic quantities";
      qq=q - q0;
      r_rela=nn*qq;
      v_rela=nn*qd;
      a_rela=nn*qdd;
      w_rela=zeros(3);
      z_rela=zeros(3);
      Sb=Sa;
      r0b=r0a + Sa*r_rela;
      vaux=cross(wa, r_rela);
      vb=va + v_rela + vaux;
      wb=wa;
      ab=aa + a_rela + cross(za, r_rela) + cross(wa, vaux + 2*v_rela);
      zb=za;
      fa=fb;
      ta=tb + cross(r_rela, fa);
      axis.f=nn*fb "d'Alemberts principle";
    end Prismatic;

  end Joints;

  package Parts "Parts with and without mass for 3D mechanical components"
    extends Modelica.Icons.Library;
    annotation(Documentation(info="<html>

<p>
This package contains the inertial system and elements
which have mass and inertia.

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

<p><b>Release Notes:</b></p>
<ul>
<li><i>April 5, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>

<p><b>Copyright &copy; 2000-2002, DLR.</b>

<p><i>
The Modelica package is <b>free</b> software; it can be redistributed and/or
modified under the terms of the <b>Modelica license</b>, see the license
conditions and the accompanying <b>disclaimer</b> in the documentation of
package Modelica in file \"Modelica/package.mo\".
</i>

</HTML>
", revisions=""));
    model InertialSystem "Inertial system"
      parameter SI.Acceleration g=9.81 "Gravity constant";
      parameter Real ng[3]={0,-1,0} "Direction of gravity (gravity = g*ng)";
      parameter String label1="x" "Label of horizontal axis in icon";
      parameter String label2="y" "Label of vertical axis in icon";
      SI.Acceleration gravity[3] "Gravity acceleration vector";
      annotation(Documentation(info="<html>

<p>
An instance of this class defines a coordinate system: the inertial
frame. All parameter vectors and tensors (e.g. position vectors)
are given in the home position of the multibody system with respect
to the inertial frame.

<p>
One instance of class  InertialSystem <b>must</b> always be present for every
multibody model.

<p>
In order to identify the desired axes of the used inertial frame in
the icon, the labels of the two axes can be defined as string parameters.
", revisions=""), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,-0.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-80.0,-80.0},{90.0,70.0}}),Line(visible=true, points={{-80.0,-100.0},{-80.0,30.0}}, thickness=0.5),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-80.0,70.0},{-100.0,30.0},{-60.0,30.0},{-80.0,70.0},{-80.0,70.0}}),Line(visible=true, points={{-100.0,-80.0},{50.0,-80.0}}, thickness=0.5),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{90.0,-80.0},{50.0,-60.0},{50.0,-100.0},{90.0,-80.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,80.0},{100.0,150.0}}, textString="%name", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-10.0,-70.0},{50.0,-10.0}}, textString="%label1", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-60.0,0.0},{0.0,60.0}}, textString="%label2", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-80.0,-80.0},{90.0,70.0}}),Line(visible=true, points={{-80.0,-100.0},{-80.0,30.0}}, thickness=0.5),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-80.0,70.0},{-100.0,30.0},{-60.0,30.0},{-80.0,70.0},{-80.0,70.0}}),Line(visible=true, points={{-100.0,-80.0},{50.0,-80.0}}, thickness=0.5),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{90.0,-80.0},{50.0,-60.0},{50.0,-100.0},{90.0,-80.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,70.0},{100.0,110.0}}, textString="inertial system", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-10.0,-70.0},{50.0,-10.0}}, textString="%label1", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-60.0,0.0},{0.0,60.0}}, textString="%label2", fontName="Arial")}));
      Interfaces.Frame_b frame_b annotation(Placement(visible=true, transformation(origin={105.0,0.0}, extent={{-15.0,-15.0},{15.0,15.0}}, rotation=0), iconTransformation(origin={105.0,0.0}, extent={{-15.0,-15.0},{15.0,15.0}}, rotation=0)));
    equation
      gravity=g*ng;
      frame_b.S=identity(3);
      frame_b.r0=zeros(3);
      frame_b.v=zeros(3);
      frame_b.w=zeros(3);
      frame_b.a=-gravity;
      frame_b.z=zeros(3);
    end InertialSystem;

    model FrameTranslation "Fixed translation of frame_b with respect to frame_a"
      extends Interfaces.TwoTreeFrames;
      parameter SI.Position r[3]={0,0,0} "Vector from frame_a to frame_b resolved in frame_a";
      annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90.0,0.0},{-90.0,-65.0}}, color={0,0,255}),Line(visible=true, points={{90.0,0.0},{90.0,-65.0}}, color={0,0,255}),Line(visible=true, points={{-90.0,-60.0},{80.0,-60.0}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{80.0,-55.0},{80.0,-65.0},{90.0,-60.0},{80.0,-55.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-22.0,-60.0},{16.0,-36.0}}, textString="r", fontName="Arial"),Rectangle(visible=true, fillPattern=FillPattern.Solid, extent={{-90.0,-5.0},{90.0,5.0}}),Line(visible=true, points={{69.0,29.0},{106.0,29.0}}, color={0,0,255}, arrow={Arrow.None,Arrow.Filled}),Line(visible=true, points={{70.0,27.0},{70.0,59.0}}, color={0,0,255}, arrow={Arrow.None,Arrow.Filled}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{92.0,33.0},{106.0,44.0}}, textString="x", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{51.0,54.0},{66.0,66.0}}, textString="y", fontName="Arial"),Line(visible=true, points={{-103.0,29.0},{-66.0,29.0}}, color={0,0,255}, arrow={Arrow.None,Arrow.Filled}),Line(visible=true, points={{-102.0,27.0},{-102.0,59.0}}, color={0,0,255}, arrow={Arrow.None,Arrow.Filled}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-80.0,33.0},{-66.0,44.0}}, textString="x", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-121.0,54.0},{-106.0,66.0}}, textString="y", fontName="Arial")}), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, origin={8.0,0.0}, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-220.0,-100.0},{220.0,-40.0}}, textString="r=%r", fontName="Arial"),Rectangle(visible=true, fillPattern=FillPattern.Solid, extent={{-90.0,-5.0},{90.0,5.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,41.0},{100.0,101.0}}, textString="%name", fontName="Arial")}), Documentation(info="<html>

<p>
Fixed translation of frame_b with respect to frame_a, i.e.,
the frames of connectors a and b are parallel to each other.

<pre>
Parameters:
  r: Position vector from the origin of (connector) frame_a to the origin of
     (connector) frame_b, resolved in frame_a in [m].
</pre>

</html>", revisions=""));
    protected
      SI.Velocity vaux[3];
      annotation(Documentation(info="
Fixed translation of frame_b with respect to frame_a, i.e.,
the frames of connectors a and b are parallel to each other.

Parameters:
  r: Position vector from the origin of (connector) frame_a to the origin of
     (connector) frame_b, resolved in frame_a in [m].
"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-99,-100},{101,-40}}, textString="r=%r", fillColor={0,0,0}),Rectangle(extent={{-90,5},{90,-5}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-101,41},{99,101}}, textString="%name")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-90,0},{-90,-65}}),Line(color={0,0,255}, points={{90,0},{90,-65}}),Line(color={0,0,255}, points={{-90,-60},{80,-60}}),Polygon(lineColor={0,0,255}, points={{80,-55},{80,-65},{90,-60},{80,-55}}, fillColor={0,0,255}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-22,-36},{16,-60}}, textString="r"),Rectangle(extent={{-90,5},{90,-5}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={0,0,0}),Line(color={0,0,255}, points={{69,29},{106,29}}, arrow={Arrow.None,Arrow.Filled}),Line(color={0,0,255}, points={{70,27},{70,59}}, arrow={Arrow.None,Arrow.Filled}),Text(lineColor={0,0,255}, extent={{92,44},{106,33}}, textString="x"),Text(lineColor={0,0,255}, extent={{51,66},{66,54}}, textString="y"),Line(color={0,0,255}, points={{-103,29},{-66,29}}, arrow={Arrow.None,Arrow.Filled}),Line(color={0,0,255}, points={{-102,27},{-102,59}}, arrow={Arrow.None,Arrow.Filled}),Text(lineColor={0,0,255}, extent={{-80,44},{-66,33}}, textString="x"),Text(lineColor={0,0,255}, extent={{-121,66},{-106,54}}, textString="y")}));
    equation
      Sb=Sa;
      wb=wa;
      zb=za;
      r0b=r0a + Sa*r;
      vaux=cross(wa, r);
      vb=va + vaux;
      ab=aa + cross(za, r) + cross(wa, vaux);
      fa=fb "Transform the force and torque acting at frame_b to frame_a";
      ta=tb + cross(r, fa);
    end FrameTranslation;

    model BoxBody "Rigid body with box shape (also used for animation)"
      extends Interfaces.TwoTreeFrames;
      parameter SI.Position r[3]={0.1,0,0} "Vector from frame_a to frame_b, resolved in frame_a";
      parameter SI.Position r0[3]={0,0,0} "Vector from frame_a to left box plane, resolved in frame_a";
      parameter SI.Position LengthDirection[3]=r - r0 "Vector in length direction, resolved in frame_a";
      parameter SI.Position WidthDirection[3]={0,1,0} "Vector in width direction, resolved in frame_a";
      parameter SI.Length length=sqrt((r - r0)*(r - r0)) "Length of box";
      parameter SI.Length Width=0.1 "Width of box";
      parameter SI.Length Height=0.1 "Height of box";
      parameter SI.Length InnerWidth=0 "Width of inner box surface";
      parameter SI.Length InnerHeight=0 "Height of inner box surface";
      parameter Real rho=7.7 "Density of box material [g/cm^3]";
      parameter Real Material[4]={1,0,0,0.5} "Color and specular coefficient";
      SI.Mass mo;
      SI.Mass mi;
      Real Sbox[3,3];
      SI.Length l;
      SI.Length w;
      SI.Length h;
      SI.Length wi;
      SI.Length hi;
      annotation(Documentation(info="<html>

<p>
Rigid body with  box  shape. The mass properties of the body are computed
from the box data. Optionally, the box may be hollow.
The (outer) box shape is automatically used in animation.

<p>
Parameter vectors are defined with respect to frame_a in [m].

<pre>
Parameters:
  r[3]       : Position vector from the origin of frame_a to the
               origin of frame_b.
  r0[3]      : Position vector from frame_a to the mid-point of the  left
               box plane.
  LengthDirection[3]: Unit vector in direction of length (will be normalized).
  WidthDirection[3] : Unit vector in direction of width (will be normalized).
  Length     : Length of box in [m].
  Width      : Width of box in [m].
  Height     : Height of box in direction of a vector which is
               orthogonal to  LengthDirection  and  WidthDirection  in [m].
  InnerWidth : Width of inner box surface in [m] (0 <= InnerWidth < Width).
  InnerHeight: Height of inner box surface in [m] (0 <= InnerHeight < Height).
  rho        : Density of material in [g/cm^3], e.g.,
                    steel: 7.7 .. 7.9
                    wood : 0.4 .. 0.8
  Material[4]: = {r, g, b, specular}.
               Color and specular coefficient of the box.
               [r,g,b] affects the color of diffuse and ambient reflected
               light. Specular is a coefficient defining white specular
               reflection. What color that is reflected also depends on the
               color of the light sources. Note, r g, b and specular are
               given in the range 0-1. Specular=1 gives a metallic
               appearance.
</pre>

</html>", revisions=""), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={127,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{-90.0,-15.0},{-50.0,15.0}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={191,95,0}, fillPattern=FillPattern.Solid, extent={{-50.0,-45.0},{30.0,35.0}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={127,127,255}, fillPattern=FillPattern.Solid, points={{-50.0,35.0},{-30.0,55.0},{50.0,55.0},{30.0,35.0},{-50.0,35.0}}),Polygon(visible=true, lineColor={255,255,255}, fillColor={127,127,255}, fillPattern=FillPattern.Solid, points={{50.0,55.0},{50.0,-25.0},{30.0,-45.0},{30.0,35.0},{50.0,55.0}}),Rectangle(visible=true, fillColor={127,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{40.0,-15.0},{90.0,15.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,68.0},{100.0,130.0}}, textString="%name", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-99.0,-100.0},{99.0,-60.0}}, textString="r=%r", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      VisualShape box(Shape="box", r0=r0, LengthDirection=LengthDirection, WidthDirection=WidthDirection, length=length, Width=Width, Height=Height, Material=Material) annotation(extent=[-20,40;40,100]);
      FrameTranslation frameTranslation(r=r) annotation(Placement(visible=true, transformation(origin={0.0,0.0}, extent={{-60.0,-30.0},{60.0,30.0}}, rotation=0)));
      Interfaces.BodyBase body annotation(Placement(visible=true, transformation(origin={4.0,-77.0}, extent={{-29.0,-30.0},{29.0,30.0}}, rotation=0)));
    equation
      connect(frameTranslation.frame_b,frame_b) annotation(Line(visible=true, origin={84.0,0.0}, points={{-21.0,0.0},{21.0,0.0}}, color={0,0,255}));
      connect(frame_a,frameTranslation.frame_a) annotation(Line(visible=true, origin={-84.0,0.0}, points={{-21.0,0.0},{21.0,0.0}}, color={0,0,255}));
      connect(body.frame_a,frame_a) annotation(Line(visible=true, points={{-26.45,-77.0},{-105.0,0.0}}, color={0,0,255}));
      box.S=Sa;
      box.r=r0a;
      box.Sshape=Sbox;
      l=length;
      w=Width;
      h=Height;
      wi=InnerWidth;
      hi=InnerHeight;
      mo=1000*rho*l*w*h "Mass properties of box";
      mi=1000*rho*l*wi*hi;
      body.m=mo - mi;
      body.rCM=r0 + l/2*box.nLength;
      body.I=Sbox*diagonal({mo*(w*w + h*h) - mi*(wi*wi + hi*hi),mo*(l*l + h*h) - mi*(l*l + hi*hi),mo*(l*l + w*w) - mi*(l*l + wi*wi)}/12)*transpose(Sbox);
    end BoxBody;

    model CylinderBody "Rigid body with cylindrical shape (also used for animation)"
      extends Interfaces.TwoTreeFrames;
      parameter SI.Position r[3]={0.2,0,0} "Vector from frame_a to frame_b, resolved in frame_a";
      parameter SI.Position r0[3]={0,0,0} "Vector from frame_a to left circle center, resolved in frame_a";
      parameter SI.Position Axis[3]=r - r0 "Vector in direction of cylinder axis, resolved in frame_a";
      parameter SI.Length length=sqrt(Axis*Axis) "Length of cylinder";
      parameter SI.Length Radius(min=0)=0.1 "Radius of cylinder";
      parameter SI.Length InnerRadius(min=0, max=Radius)=0 "Inner radius of cylinder";
      parameter Real rho(min=0)=7.7 "Density of material [g/cm^3]";
      parameter Real Material[4]={1,0,0,0.5} "Color and specular coefficient";
      Real Scyl[3,3];
      SI.Mass mo;
      SI.Mass mi;
      SI.Inertia I22;
      annotation(Documentation(info="<html>

<p>
Rigid body with  cylindrical  shape. The mass properties of the body are
computed from the cylinder data. Optionally, the cylinder may be hollow.
The pipe shape is automatically used in animation.

<p>
Parameter vectors are defined with respect to frame_a in [m].

<pre>
Parameters:
  r[3]       : Position vector from the origin of frame_a to the origin of
               frame_b.
  r0[3]      : Position vector from the origin of frame_a to the center
               of the  left  cylinder circle.
  Axis[3]    : Unit vector in direction of the cylinder axis
               (will be normalized)
  Length     : Length of cylinder in [m].
  Radius     : Radius of cylinder in [m].
  InnerRadius: Inner radius of cylinder in [m].
  rho        : Density of material in [g/cm^3], e.g.
                  steel: 7.7 .. 7.9
                  wood : 0.4 .. 0.8
  Material(4): = {r, g, b, specular}.
               Color and specular coefficient of the box.
               [r,g,b] affects the color of diffuse and ambient reflected
               light. Specular is a coefficient defining white specular
               reflection. What color that is reflected also depends on the
               color of the light sources. Note, r g, b and specular are
               given in the range 0-1. Specular=1 gives a metallic appearance.
</pre>

</html>", revisions=""), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={127,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{-90.0,-15.0},{-50.0,15.0}}),Rectangle(visible=true, fillColor={127,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{50.0,-15.0},{90.0,15.0}}),Rectangle(visible=true, fillColor={191,95,0}, fillPattern=FillPattern.HorizontalCylinder, extent={{-50.0,-50.0},{50.0,50.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-102.0,60.0},{100.0,120.0}}, textString="%name", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,-100.0},{100.0,-60.0}}, textString="r=%r", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      VisualShape box(r0=r0, length=length, Width=2*Radius, Height=2*Radius, LengthDirection=Axis, WidthDirection={0,1,0}, Shape="pipe", Material=Material, Extra=InnerRadius/Radius) annotation(extent=[-20,40;40,100]);
      FrameTranslation frameTranslation(r=r) annotation(Placement(visible=true, transformation(origin={0.0,0.0}, extent={{-60.0,-30.0},{60.0,30.0}}, rotation=0)));
      Interfaces.BodyBase body annotation(Placement(visible=true, transformation(origin={0.0,-72.0}, extent={{-30.0,-29.0},{30.0,29.0}}, rotation=0)));
    equation
      connect(frameTranslation.frame_b,frame_b) annotation(Line(visible=true, origin={84.0,0.0}, points={{-21.0,0.0},{21.0,0.0}}, color={0,0,255}));
      connect(frame_a,frameTranslation.frame_a) annotation(Line(visible=true, origin={-84.0,0.0}, points={{-21.0,0.0},{21.0,0.0}}, color={0,0,255}));
      connect(frame_a,body.frame_a) annotation(Line(visible=true, points={{-105.0,0.0},{-31.5,-72.0}}, color={0,0,255}));
      box.S=Sa;
      box.r=r0a;
      box.Sshape=Scyl;
      mo=1000*rho*pi*length*Radius*Radius "Mass properties of cylinder";
      mi=1000*rho*pi*length*InnerRadius*InnerRadius;
      I22=(mo*(length*length + 3*Radius*Radius) - mi*(length*length + 3*InnerRadius*InnerRadius))/12;
      body.m=mo - mi;
      body.rCM=r0 + length/2*box.nLength;
      body.I=Scyl*diagonal({(mo*Radius*Radius - mi*InnerRadius*InnerRadius)/2,I22,I22})*transpose(Scyl);
    end CylinderBody;

  end Parts;

end MultiBody;
model MCVisualShape
  import SI = Modelica.SIunits;
  parameter String shapeType="box" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring)";
  input SI.Position r[3]={0.0,0.0,0.0} "Position vector from origin of world frame to origin of object frame, resolved in world frame";
  input SI.Position r_shape[3]={0.0,0.0,0.0} "Position vector from origin of object frame to shape origin, resolved in object frame";
  input Real lengthDirection[3]={1.0,0.0,0.0} "Vector in length direction, resolved in object frame";
  input Real widthDirection[3]={0.0,1.0,0.0} "Vector in width direction, resolved in object frame";
  input SI.Length length=0 "Length of visual object";
  input SI.Length width=0 "Width of visual object";
  input SI.Length height=0 "Height of visual object";
  input Real extra=0.0 "Additional size data for some of the shape types";
  input Real color[3]={255.0,0.0,0.0} "Color of shape";
  input Real specularCoefficient=0.7;
  input Real S[3,3] "3 x 3 transformation matrix.";
  Real Sshape[3,3] "local 3 x 3 transformation matrix.";
  output Real rxvisobj[3] "x-axis unit vector of shape, resolved in world frame";
  output Real ryvisobj[3] "y-axis unit vector of shape, resolved in world frame";
  output SI.Position rvisobj[3] "position vector from world frame to shape frame, resolved in world frame";
  Real abs_n_x=sqrt(lengthDirection*lengthDirection);
  Real e_x[3]=noEvent(if abs_n_x < 1e-10 then {1.0,0.0,0.0} else lengthDirection/abs_n_x);
  Real n_z_aux[3]=cross(e_x, widthDirection);
  Real e_y[3]=noEvent(cross(local_normalize(cross(e_x, if n_z_aux*n_z_aux > 1e-06 then widthDirection else if abs(e_x[1]) > 1e-06 then {0,1,0} else {1,0,0})), e_x));
  Real e_z[3]=cross(e_x, e_y);
protected
  function local_normalize
    input Real iv[3];
    output Real ov[3];
  protected
    Real length;
  algorithm
    length:=sqrt(iv*iv);
    ov:=iv/length;
  end local_normalize;

protected
  output Real Form;
  output SI.Length size[3] "{length,width,height} of shape";
  output Real Material;
  output Real Extra;
equation
  Form=(987000 + PackShape(shapeType))*1e+20;
  Material=PackMaterial(color[1]/255.0, color[2]/255.0, color[3]/255.0, specularCoefficient);
  Extra=extra;
  size={length,width,height};
  Sshape=[e_x,e_y,cross(e_x, e_y)];
  rxvisobj=S*e_x;
  ryvisobj=S*e_y;
  rvisobj=r + S*r_shape;
end MCVisualShape;
function PackMaterial
  input Real r;
  input Real g;
  input Real b;
  input Real spec;
  output Real packedMaterial;
protected
  Integer i1;
  Integer i2;
  Integer i3;
  Integer i4;
algorithm
  i1:=integer(floor(r*99));
  if i1 < 0 then
    i1:=0;
  end if;
  if i1 > 99 then
    i1:=99;
  end if;
  i2:=integer(floor(g*99));
  if i2 < 0 then
    i2:=0;
  end if;
  if i2 > 99 then
    i2:=99;
  end if;
  i3:=integer(floor(b*99));
  if i3 < 0 then
    i3:=0;
  end if;
  if i3 > 99 then
    i3:=99;
  end if;
  i4:=integer(floor(spec*9));
  if i4 < 0 then
    i4:=0;
  end if;
  if i4 > 99 then
    i4:=9;
  end if;
  packedMaterial:=((i1*100 + i2)*100 + i3)*10 + i4;
end PackMaterial;
function PackShape
  input String shape;
  output Real packedShape;
algorithm
  if shape == "box" then
    packedShape:=101.0;
  elseif shape == "sphere" then
    packedShape:=102.0;

  elseif shape == "cylinder" then
    packedShape:=103.0;

  elseif shape == "cone" then
    packedShape:=104.0;

  elseif shape == "pipe" then
    packedShape:=105.0;

  elseif shape == "beam" then
    packedShape:=106.0;

  elseif shape == "wirebox" then
    packedShape:=107.0;

  elseif shape == "gearwheel" then
    packedShape:=108.0;

  elseif shape == "spring" then
    packedShape:=111.0;
  else
    packedShape:=200;
  end if;
end PackShape;
model VisualShape
  parameter Real r0[3]={0.0,0.0,0.0} "Origin of visual object.";
  parameter Real length=1 "Length of visual object.";
  parameter Real Width=1 "Width of visual object.";
  parameter Real Height=1 "Height of visual object.";
  parameter Real LengthDirection[3]={1.0,0.0,0.0} "Vector in length direction.";
  parameter Real WidthDirection[3]={0.0,1.0,0.0} "Vector in width direction.";
  parameter String Shape="box" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring)";
  parameter Real Material[4]={1.0,0.0,0.0,0.5} "Color and specular coefficient.";
  parameter Real Extra=0.0 "Additional size data for some of the shape types";
  input Real S[3,3] "3 x 3 transformation matrix.";
  Real Sshape[3,3] "local 3 x 3 transformation matrix.";
  input Real r[3] "Position of visual object.";
  Real nLength[3];
  Real nWidth[3];
  Real nHeight[3];
  MCVisualShape mcShape(r=r, r_shape=r0, S=S, Sshape=Sshape, color=255*Material[1:3], specularCoefficient=Material[4], length=length, width=Width, height=Height, lengthDirection=LengthDirection, widthDirection=WidthDirection, shapeType=Shape, extra=Extra);
equation
  mcShape.e_x=nLength;
  mcShape.e_y=nWidth;
  mcShape.e_z=nHeight;
end VisualShape;
package IntroductoryExamples "This package contains small examples to help you get started with MathModelica system Designer"
  extends Icons.Library;
  annotation(preferredView="info", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, origin={3.1086,-1.33863}, lineColor={0,0,192}, fillColor={0,192,255}, fillPattern=FillPattern.Sphere, lineThickness=1, extent={{-68.8236,-78.6614},{42.6064,32.7786}}),Text(visible=true, origin={-1.20601,-3.47}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-61.5265,-85.9},{43.9385,43.47}}, textString="i", fontName="Times New Roman", textStyle={TextStyle.Bold})}));
  annotation(Documentation(info="<html>
<head>
<title>Introductory Examples</title>
</head>

<body lang=EN link=blue vlink=purple>

<h1>MathModelica® System Designer</h1>
<em><h2>Introductory Examples</h2></em>
<h4>© 2006 MathCore Engineering AB</h4>

<hr>
<p>
<table bgcolor=\"lightgrey\"><tr><td>
<P>This library contains a few examples that are will help you to get started with <em>MathModelica System Designer</em>. In the <a href=\"../../docs/introductory_examples.pdf\">Introductory Examples document</a> you can find  detailed step by step descriptions of how to build and simulate respective model, as well as some exercises that will help you learn <em>MathModelica System Designer</em>.</p>
</tr></td>
</table>
<p>
<hr>
<p>Below is a short description of the Introductory Examples models. Follow the links to read more about respective example.</p>

<h3><a href=\"Modelica://IntroductoryExamples.HelloWorld\">Hello World</a></h3>
<p>The most basic Modelica model is a differential equation. In this example a differential equation is implemented and simulated and it is also shown how to draw an icon for it.</p>

<h3><a href=\"Modelica://IntroductoryExamples.MultiDomain\">Multi domain example</a> </h3>
<p>The examples in this package show how to develop a servo mechanism model step by step. It illustrates the multi engineering capabilities and shows how you can use Simulation Center to analyze models created in the Model Editor, synthesize controllers, and do comparison studies. </p>

<h3><a href=\"Modelica://IntroductoryExamples.ComponentBased\">Block based versus component based modeling</a></h3>
<p>In this example an electric circuit is used to illustrate the difference between a block based and component based modeling approach.</p>

<h3><a href=\"Modelica://IntroductoryExamples.CustomComponent\">How to create custom components</a></h3>
<p>This example illustrates how to create custom components. A chain pendulum is developed with the help of custom chain link components.</p>

<h3><a href=\"Modelica://IntroductoryExamples.ExternalFunctions\">How to use external functions</a></h3>
<p>While it is easy to write Modelica functions, it is sometimes convenient to call a subroutine written in C or FORTAN. This example shows how to use an external function written in C. </p>

<h3><a href=\"Modelica://IntroductoryExamples.Hierarchical\">Developing a package</a></h3>
<p>A flat tank model is developed and compared with a component based model. The example illustrates the benefits of working with packages.</p>

<h3><a href=\"Modelica://IntroductoryExamples.Professional\">MathModelica System Designer Professional</a></h3>
<p>The examples in this package illustrate how the notebook interface of <em>Mathematica</em> can be used to simulate, analyze, and document models.</p>

</body>
</html>


", revisions=""), Diagram(coordinateSystem(extent={{-148.5,105},{148.5,-105}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(visible=true, lineColor={0,0,127}, fillColor={0,170,255}, fillPattern=FillPattern.Sphere, extent={{-100,-100},{100,100}}),Text(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}, textString="i", fontName="Times New Roman", textStyle={TextStyle.Bold})}));
  package Icons "Icons"
    extends Library;
    partial package Library
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-100,-100},{80,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>

<head>
<title>Hierachical modeling</title>

</head>

<body lang=EN link=blue vlink=purple>

<h1>MathModelica® System Designer</h1>
<em><h2>Hierarchical modeling - Library Icon</h2></em>
<h4>© 2006 MathCore Engineering AB</h4>

<p>
<hr>
<p>
<table bgcolor=\"lightgrey\"><tr><td>
<P>The <a href=\"Modelica://IntroductoryExamples\">IntroductoryExamples</a> library contains a few examples that are will help you to get started with <em>MathModelica System Designer</em>.
In the <a href=\"../../docs/introductory_examples.pdf\">Introductory Examples document</a> you can find  detailed step by step
descriptions of how to build and simulate respective model, as well as some exercises that will help you learn <em>MathModelica System Designer</em>.</p>
</tr></td>
</table>
<p>
<hr>

<p>Library icon used in the IntroductoryExamples library.</a>


</body>

</html>
", revisions=""));
    end Library;

    annotation(Documentation(info="<html>

<head>
<title>Hierachical modeling</title>

</head>

<body lang=EN link=blue vlink=purple>

<h1>MathModelica® System Designer</h1>
<em><h2>Hierarchical modeling - Icons</h2></em>
<h4>© 2006 MathCore Engineering AB</h4>

<p>
<hr>
<p>
<table bgcolor=\"lightgrey\"><tr><td>
<P>The <a href=\"Modelica://IntroductoryExamples\">IntroductoryExamples</a> library contains a few examples that are will help you to get started with <em>MathModelica System Designer</em>.
In the <a href=\"../../docs/introductory_examples.pdf\">Introductory Examples document</a> you can find  detailed step by step
descriptions of how to build and simulate respective model, as well as some exercises that will help you learn <em>MathModelica System Designer</em>.</p>
</tr></td>
</table>
<p>
<hr>

<p>Package containing icons used in the IntroductoryExamples library.</a>


</body>

</html>
", revisions=""));
  end Icons;

  package Systems "Package containing complete system models using different domains"
    extends IntroductoryExamples.Icons.Library;
    package Components "Components for the system models"
      extends IntroductoryExamples.Icons.Library;
      model Pendulum "An inverted pendulum connected to a cart"
        annotation(preferredView="info");
        import SI = Modelica.SIunits;
        parameter SI.Length l_pendulum=0.61 "Pendulum length";
        parameter SI.Radius r_pendulum=0.005 "Pendulum radius";
        parameter Real d_pendulum(final unit="N.m.s/rad", final min=0)=0.01 "Pendulum damper constant";
        parameter Real rho_pendulum(unit="g/cm3")=7.7 "Pendulum material density";
        parameter Real d_slider(final unit="N/(m/s)", final min=0)=2 "Pendulum slider constant";
        parameter Real rho_cart(unit="g/cm3")=0.445 "Cart material density";
        parameter SI.Length l_cart=0.1 "Cart length";
        parameter SI.Length h_cart=0.1 "Cart height";
        parameter SI.Length w_cart=0.1 "Cart width";
        MultiBody.Parts.InertialSystem inertialSystem annotation(Placement(visible=true, transformation(origin={-80.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        MultiBody.Parts.BoxBody cart(rho=rho_cart, Height=h_cart, r={l_cart,0,0}, Width=w_cart) annotation(Placement(visible=true, transformation(origin={-20.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        MultiBody.Parts.CylinderBody pendulum(r={0,l_pendulum,0}, Radius=r_pendulum, Material={0,0,1,0.5}, box(Shape="cylinder"), rho=rho_pendulum) annotation(Placement(visible=true, transformation(origin={80.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        MultiBody.Joints.Revolute pendulumJoint(qd(start=0.01)) annotation(Placement(visible=true, transformation(origin={50.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        MultiBody.Parts.FrameTranslation toMidCart(r={-cart.r[1]/2,cart.Height/2,0}) annotation(Placement(visible=true, transformation(origin={10.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        MultiBody.Joints.Prismatic sliderConstraint(q.stateSelect=StateSelect.prefer) annotation(Placement(visible=true, transformation(origin={-50.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Mechanics.Rotational.Damper pendulumDamper(d=d_pendulum) annotation(Placement(visible=true, transformation(origin={30.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Mechanics.Translational.Damper sliderDamper(d=d_slider) annotation(Placement(visible=true, transformation(origin={-60.0,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a annotation(Placement(visible=true, transformation(origin={-100.0,-20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100.0,-100.0},{100.0,100.0}}),Rectangle(visible=true, origin={-6.5248,25.9625}, rotation=5, fillColor={0,170,255}, fillPattern=FillPattern.VerticalCylinder, extent={{4.67,69.8256},{-4.67,-69.8256}}),Rectangle(visible=true, origin={0.0,-70.0}, fillColor={128,0,0}, fillPattern=FillPattern.Solid, extent={{-40.0,-20.0},{40.0,20.0}}),Text(visible=true, origin={0.0,125.0}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,-15.0},{100.0,15.0}}, textString="%name", fontName="Arial"),Ellipse(visible=true, origin={0.0,-45.0}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-5.0,-5.0},{5.0,5.0}}),Text(visible=true, origin={75.0,20.0}, fillPattern=FillPattern.Solid, extent={{-15.0,-20.0},{15.0,20.0}}, textString="x", fontName="Arial"),Text(visible=true, origin={70.0,-30.0}, fillPattern=FillPattern.Solid, extent={{-20.0,-20.0},{20.0,20.0}}, textString="phi", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100.0,-60.0},{100.0,60.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html><p>This pendulum system consists of a cart with a joint connected to the pendulum. Components from the <a href=\"Modelica://MultiBody\">MultiBody</a> library have been used for the cart and pendulum and components from the translational and rotational mechanical library have been used to model friction. The cart can only be moved in a fixed horizontal motion.</p>
<p>To be able to control the pendulum, the position of the cart, x, and the pendulum angle, phi, is measured. The movement of the cart can be controlled via a force, F, using the flange input.</p>
<p><center><img src=\"Systems/Pendulum2.png\"></center>
</p>
</html>", revisions=""));
        Modelica.Mechanics.Rotational.Sensors.AngleSensor angleSensor annotation(Placement(visible=true, transformation(origin={70.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Mechanics.Translational.Sensors.PositionSensor positionSensor annotation(Placement(visible=true, transformation(origin={70.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Interfaces.RealOutput position annotation(Placement(visible=true, transformation(origin={110.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Interfaces.RealOutput angle annotation(Placement(visible=true, transformation(origin={110.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={110.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      equation
        connect(pendulumJoint.frame_b,pendulum.frame_a) annotation(Line(visible=true, origin={65.0,-40.0}, points={{-4.5,0.0},{4.5,0.0}}));
        connect(pendulumDamper.flange_b,pendulumJoint.axis) annotation(Line(visible=true, origin={46.6667,-17.6667}, points={{-6.6667,7.6667},{3.3333,7.6667},{3.3333,-15.3333}}));
        connect(pendulumDamper.flange_a,pendulumJoint.bearing) annotation(Line(visible=true, origin={27.9995,-21.4}, points={{-7.9995,11.4},{-12.0008,11.4},{-12.0008,-5.6},{16.0005,-5.6},{16.0005,-11.6}}));
        connect(sliderDamper.flange_b,sliderConstraint.axis) annotation(Line(visible=true, origin={-45.3333,-11.3333}, points={{-4.6667,11.3333},{2.3333,11.3333},{2.3333,-22.6667}}));
        connect(sliderDamper.flange_a,sliderConstraint.bearing) annotation(Line(visible=true, origin={-64.8005,-17.6}, points={{-5.1995,17.6},{-9.2007,17.6},{-9.2007,-9.4},{11.8005,-9.4},{11.8005,-16.4}}));
        connect(toMidCart.frame_b,pendulumJoint.frame_a) annotation(Line(visible=true, origin={30.0,-40.0}, points={{-9.5,0.0},{9.5,0.0}}));
        connect(angleSensor.flange_a,pendulumJoint.axis) annotation(Line(visible=true, origin={53.3333,-4.3333}, points={{6.6667,14.3333},{-3.3333,14.3333},{-3.3333,-28.6667}}));
        connect(cart.frame_b,toMidCart.frame_a) annotation(Line(visible=true, origin={-5.0,-40.0}, points={{-4.5,0.0},{4.5,0.0}}));
        connect(sliderConstraint.frame_b,cart.frame_a) annotation(Line(visible=true, origin={-35.0,-40.0}, points={{-4.5,0.0},{4.5,0.0}}));
        connect(inertialSystem.frame_b,sliderConstraint.frame_a) annotation(Line(visible=true, origin={-65.0,-40.0}, points={{-4.5,0.0},{4.5,0.0}}));
        connect(flange_a,sliderConstraint.axis) annotation(Line(visible=true, origin={-62.0,-24.6667}, points={{-38.0,4.6667},{19.0,4.6667},{19.0,-9.3333}}));
        connect(positionSensor.flange_a,sliderConstraint.axis) annotation(Line(visible=true, origin={-8.6667,15.3333}, points={{68.6667,24.6667},{-34.3333,24.6667},{-34.3333,-49.3333}}));
        connect(angleSensor.phi,angle) annotation(Line(visible=true, origin={95.5,10.0}, points={{-14.5,0.0},{14.5,0.0}}));
        connect(positionSensor.s,position) annotation(Line(visible=true, origin={92.5118,39.2887}, points={{-11.5118,0.7113},{5.7559,0.7113},{17.4882,0.7113}}));
      end Pendulum;

      model GearBox "A gear system with a rotational gear coupled to a pinion and a rack"
        parameter Real ratio_rotational=3.7 "Rotational transmission ratio from input wheel to pinion";
        parameter Real ratio_translational(final unit="rad/m")=157.48 "Translational transmission ratio from pinion to gear rack";
        Modelica.Mechanics.Rotational.IdealGearR2T gearR2T(ratio=ratio_translational) annotation(Placement(visible=true, transformation(origin={7.5198,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Mechanics.Rotational.IdealGear idealGear(ratio=ratio_rotational) annotation(Placement(visible=true, transformation(origin={-30.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Mechanics.Translational.Interfaces.Flange_b flange_b annotation(Placement(visible=true, transformation(origin={50.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={100.0,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation(Placement(visible=true, transformation(origin={-70.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-100.0,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={53.8462,0.0}, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-73.8462,-10.0},{-53.8462,10.0}}),Text(visible=true, origin={0.0,125.0}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-120.0,-25.0},{120.0,25.0}}, textString="%name", fontName="Arial"),Ellipse(visible=true, origin={52.5,0.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-52.5,-30.0},{7.5,30.0}}),Ellipse(visible=true, origin={60.0,0.0}, fillPattern=FillPattern.Solid, extent={{-40.0,-10.0},{-20.0,10.0}}),Rectangle(visible=true, origin={23.4327,6.0}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, extent={{-57.6414,-80.0},{82.5673,-60.0}}),Rectangle(visible=true, origin={0.0,-1.2242}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, extent={{95.0,-52.6545},{106.0,-8.7758}}),Polygon(visible=true, origin={0.7306,6.0}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{6.0,-60.0},{26.0,-40.0},{46.0,-60.0},{66.0,-40.0},{86.0,-60.0}}),Rectangle(visible=true, origin={-40.0,0.0}, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40.0,-20.0},{-20.0,20.0}}),Rectangle(visible=true, origin={-66.6667,0.0}, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-33.3333,-10.0},{-13.3333,10.0}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40.0,-30.0},{-20.0,30.0}}),Rectangle(visible=true, origin={-40.0,50.0}, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40.0,-30.0},{-20.0,30.0}}),Rectangle(visible=true, origin={0.0,50.0}, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40.0,-20.0},{-20.0,20.0}}),Rectangle(visible=true, origin={-26.6666,50.0}, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-33.3334,-10.0},{-13.3334,10.0}}),Polygon(visible=true, origin={-39.1617,6.0}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{6.0,-60.0},{26.0,-40.0},{46.0,-60.0},{66.0,-40.0},{86.0,-60.0}})}), Diagram(coordinateSystem(extent={{-100.0,-40.0},{100.0,40.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html><p>This gear contains a rotational part connected to a pinion and the rotation is transferred to translational motion using a gear rack.</p></html>", revisions=""));
      equation
        connect(gearR2T.flange_a,idealGear.flange_b) annotation(Line(visible=true, origin={-11.2401,0.0}, points={{8.7599,0.0},{-8.7599,0.0}}));
        connect(idealGear.flange_a,flange_a) annotation(Line(visible=true, origin={-55.0,0.0}, points={{15.0,0.0},{-15.0,0.0}}));
        connect(flange_b,gearR2T.flange_b) annotation(Line(visible=true, origin={33.7599,0.0}, points={{16.2401,0.0},{-16.2401,0.0}}));
      end GearBox;

      model LQControlSystem "Controller based on LQ (Linear Quadratic) design for e.g. an inverted pendulum"
        parameter Real A[:,:]={{-1.80378,1.0,-0.301845,0.0},{-1.67236,-13.7653,-0.753808,0.0},{-0.301845,0.0,-7.83137,1.0},{-0.617197,-19.3623,-14.7496,0.0}} "Observer A matrix";
        parameter Real B[:,:]={{0.0,1.80378,0.301845},{2.69088,1.67236,2.29112},{0.0,0.301845,7.83137},{3.785,0.617197,30.7107}} "Observer B matrix";
        parameter Real C[:,:]={{1,0,0,0},{0,1,0,0},{0,0,1,0},{0,0,0,1}} "Observer C matrix";
        parameter Real D[:,:]={{0,0,0},{0,0,0},{0,0,0},{0,0,0}} "Observer D matrix";
        parameter Real K_L[:,:]={{-14.1421,-23.685,114.738,21.4806}} "L matrix such that eigenvalues for A-B*L is inside stability region";
        parameter Real k_Lr=-14.1421 "Static gain in order to make system gain equal to one";
        parameter Real uMax(final min=0)=10 "Maximum output value";
        parameter Real table[:,2]=[0,0;2,0;2.5,1;3,-1;3.5,1;4,0;4.5,0] "Table matrix (time = first column). Only if inputType=3";
        parameter Integer referenceType(final min=1, final max=3)=2 "Type of reference signal: 1=step, 2=pulse, 3=time table";
        Modelica.Blocks.Sources.Constant step annotation(Placement(visible=true, transformation(origin={-120.0,60.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Continuous.StateSpace observer(A=A, B=B, C=C, D=D) annotation(Placement(visible=true, transformation(origin={43.8675,-10.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Math.MatrixGain L(K=K_L) annotation(Placement(visible=true, transformation(origin={10.0,-10.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Math.Feedback feedback annotation(Placement(visible=true, transformation(origin={-10.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Math.Gain L_r(k=k_Lr) annotation(Placement(visible=true, transformation(origin={-40.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Routing.Multiplex3 mux annotation(Placement(visible=true, transformation(origin={80.0,-10.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Sources.Pulse pulse(period=10, offset=-0.5) annotation(Placement(visible=true, transformation(origin={-120.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Logical.Switch switch1 annotation(Placement(visible=true, transformation(origin={-80.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Sources.BooleanConstant ConstantQ(k=k1) annotation(Placement(visible=true, transformation(origin={-120.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Nonlinear.Limiter limiter(uMax=uMax) annotation(Placement(visible=true, transformation(origin={40.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Interfaces.RealInput angle annotation(Placement(visible=true, transformation(origin={140.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180), iconTransformation(origin={60.0,-110.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        Modelica.Blocks.Interfaces.RealInput xPos annotation(Placement(visible=true, transformation(origin={140.0,-10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-180), iconTransformation(origin={-60.0,-110.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-270)));
        Modelica.Blocks.Interfaces.RealOutput y annotation(Placement(visible=true, transformation(origin={140.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={105.0,0.0}, extent={{-5.0,-5.0},{5.0,5.0}}, rotation=0)));
        annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100.0,-100.0},{100.0,100.0}}),Text(visible=true, origin={85.0,0.0}, fillPattern=FillPattern.Solid, extent={{-15.0,-15.0},{15.0,15.0}}, textString="y", fontName="Arial"),Text(visible=true, origin={60.0,-85.0}, fillPattern=FillPattern.Solid, extent={{-15.0,-15.0},{15.0,15.0}}, textString="phi", fontName="Arial"),Text(visible=true, origin={-60.0,-85.0}, fillPattern=FillPattern.Solid, extent={{-15.0,-15.0},{15.0,15.0}}, textString="x", fontName="Arial"),Text(visible=true, origin={0.0,20.0}, fillPattern=FillPattern.Solid, extent={{-40.0,-20.0},{40.0,20.0}}, textString="LQ", fontName="Arial"),Text(visible=true, origin={0.0,-20.0}, fillPattern=FillPattern.Solid, extent={{-60.0,-20.0},{60.0,20.0}}, textString="controller", fontName="Arial"),Text(visible=true, origin={0.0,125.0}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,-15.0},{100.0,15.0}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-150.0,-100.0},{150.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-100.0,7.5644}, fillColor={255,255,127}, fillPattern=FillPattern.Solid, extent={{-40.0,-82.4356},{40.0,82.4356}}),Text(visible=true, origin={-100.0,80.0}, fillPattern=FillPattern.Solid, extent={{-40.0,-10.0},{40.0,10.0}}, textString="Reference input", fontName="Arial")}), Documentation(info="<html><p>This is a LQ (Linear Quadratic) design of a controller for an inverted pendulum. It contains a number of different reference inputs in order to change system behavior. The reference input type is changed with the parameter referenceType. The output signal is limited to get realistic response. </p>
<p>The observer has been implemented in a state space block and the position and angle is measured.</p></html>", revisions=""));
        Modelica.Blocks.Logical.Switch switch2 annotation(Placement(visible=true, transformation(origin={-80.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Sources.BooleanConstant ConstantQ1(k=k2) annotation(Placement(visible=true, transformation(origin={-120.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Sources.TimeTable timeTable(table=table) annotation(Placement(visible=true, transformation(origin={-120.0,-60.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      protected
        parameter Boolean k1=referenceType == 1 "Step signal";
        parameter Boolean k2=referenceType == 2 "Pulse signal";
        parameter Boolean k3=referenceType == 3 "Time table";
      equation
        connect(limiter.y,mux.u1[1]) annotation(Line(visible=true, origin={84.2512,13.5}, points={{-33.2512,16.5},{12.7512,16.5},{12.7512,-16.5},{7.7488,-16.5}}));
        connect(switch1.y,L_r.u) annotation(Line(visible=true, origin={-60.5,30.0}, points={{-8.5,0.0},{8.5,0.0}}));
        connect(ConstantQ.y,switch1.u2) annotation(Line(visible=true, origin={-100.5,30.0}, points={{-8.5,0.0},{8.5,0.0}}));
        connect(timeTable.y,switch2.u3) annotation(Line(visible=true, origin={-98.7512,-49.0}, points={{-10.2488,-11.0},{1.7488,-11.0},{1.7488,11.0},{6.7512,11.0}}));
        connect(ConstantQ1.y,switch2.u2) annotation(Line(visible=true, origin={-100.5,-30.0}, points={{-8.5,0.0},{8.5,0.0}}));
        connect(switch2.y,switch1.u3) annotation(Line(visible=true, origin={-77.4512,-4.8195}, points={{8.4512,-25.1805},{17.4512,-25.1805},{17.4512,4.8195},{-22.5488,4.8195},{-22.5488,26.8195},{-14.5488,26.8195}}));
        connect(switch2.u1,pulse.y) annotation(Line(visible=true, origin={-102.7494,-11.0}, points={{10.7494,-11.0},{-2.2494,-11.0},{-2.2494,11.0},{-6.2506,11.0}}));
        connect(xPos,mux.u2[1]) annotation(Line(visible=true, origin={116.0,-10.0}, points={{24.0,0.0},{-24.0,0.0}}));
        connect(angle,mux.u3[1]) annotation(Line(visible=true, origin={106.5012,-28.5}, points={{33.4988,-11.5},{-9.4988,-11.5},{-9.4988,11.5},{-14.5012,11.5}}));
        connect(feedback.y,limiter.u) annotation(Line(visible=true, origin={13.5,30.0}, points={{-14.5,0.0},{14.5,0.0}}));
        connect(y,limiter.y) annotation(Line(visible=true, origin={95.5,30.0}, points={{44.5,0.0},{-44.5,0.0}}));
        connect(step.y,switch1.u1) annotation(Line(visible=true, origin={-98.7512,49.0}, points={{-10.2488,11.0},{1.7488,11.0},{1.7488,-11.0},{6.7512,-11.0}}));
        connect(mux.y[:],observer.u[:]) annotation(Line(visible=true, origin={62.4338,-10.0}, points={{6.5662,0.0},{-6.5663,0.0}}));
        connect(L_r.y,feedback.u1) annotation(Line(visible=true, origin={-23.5,30.0}, points={{-5.5,0.0},{5.5,0.0}}));
        connect(L.y[1],feedback.u2) annotation(Line(visible=true, origin={-3.6667,0.6667}, points={{2.6667,-10.6667},{-6.3333,-10.6667},{-6.3333,21.3333}}));
        connect(observer.y[:],L.u[:]) annotation(Line(visible=true, origin={27.4337,-10.0}, points={{5.4337,0.0},{-5.4337,0.0}}));
      end LQControlSystem;

      model ElectricalMotor "A simplified voltage controlled motor"
        import SI = Modelica.SIunits;
        parameter SI.Resistance R=2.6 "Resistance";
        parameter SI.Inductance L=0.001 "Inductance";
        parameter Real k(final unit="N.m/A")=0.00767 "Transformation coefficient";
        Modelica.Electrical.Analog.Sources.SignalVoltage voltageSource annotation(Placement(visible=true, transformation(origin={-60.0,0.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=270)));
        Modelica.Electrical.Analog.Basic.Resistor resistor(R=R) annotation(Placement(visible=true, transformation(origin={-30.0,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Electrical.Analog.Basic.Inductor inductor(L=L) annotation(Placement(visible=true, transformation(origin={12.5813,30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Electrical.Analog.Basic.EMF eMF(k=k) annotation(Placement(visible=true, transformation(origin={50.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible=true, transformation(origin={-90.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-110.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        Modelica.Mechanics.Rotational.Interfaces.Flange_b flange annotation(Placement(visible=true, transformation(origin={80.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
        annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-15.0,0.0}, fillColor={0,0,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{-85.0,-50.0},{85.0,50.0}}),Rectangle(visible=true, origin={85.0,0.0}, fillColor={124,124,124}, fillPattern=FillPattern.HorizontalCylinder, extent={{-15.0,-10.0},{15.0,10.0}}),Text(visible=true, origin={0.0,125.0}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,-15.0},{100.0,15.0}}, textString="%name", fontName="Arial"),Polygon(visible=true, origin={-15.0,-70.0}, fillPattern=FillPattern.Solid, points={{-35.0,50.0},{-55.0,-10.0},{-85.0,-10.0},{-85.0,-30.0},{85.0,-30.0},{85.0,-10.0},{55.0,-10.0},{35.0,50.0}})}), Diagram(coordinateSystem(extent={{-100.0,-60.0},{100.0,60.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html><p>The electrical motor has a variable voltage input that can be connected to various sources from, e.g., the Modelica.Blocks library.</p><p>The switch from electrical to rotational power is modeled with a transformation coefficient, k.</p></html>", revisions=""));
        Modelica.Electrical.Analog.Basic.Ground ground annotation(Placement(visible=true, transformation(origin={0.0,-44.5274}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      equation
        connect(voltageSource.v,u) annotation(Line(visible=true, origin={-78.5,0.0}, points={{11.5,0.0},{-11.5,0.0}}));
        connect(eMF.flange_b,flange) annotation(Line(visible=true, origin={70.0,0.0}, points={{-10.0,0.0},{10.0,0.0}}));
        connect(eMF.n,ground.p) annotation(Line(visible=true, origin={25.0,-26.1319}, points={{25.0,16.1319},{25.0,-3.8681},{-25.0,-3.8681},{-25.0,-8.3955}}));
        connect(inductor.n,eMF.p) annotation(Line(visible=true, origin={40.8604,23.3333}, points={{-18.2791,6.6667},{9.1396,6.6667},{9.1396,-13.3333}}));
        connect(resistor.n,inductor.p) annotation(Line(visible=true, origin={-8.7094,30.0}, points={{-11.2906,0.0},{11.2907,0.0}}));
        connect(voltageSource.p,resistor.p) annotation(Line(visible=true, origin={-53.3333,23.3333}, points={{-6.6667,-13.3333},{-6.6667,6.6667},{13.3333,6.6667}}));
        connect(ground.p,voltageSource.n) annotation(Line(visible=true, origin={-30.0,-26.1319}, points={{30.0,-8.3955},{30.0,-3.8681},{-30.0,-3.8681},{-30.0,16.1319}}));
      end ElectricalMotor;

      annotation(Documentation(info="", revisions=""));
    end Components;

    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-4.1263,-1.4529}, rotation=5, fillColor={0,170,255}, fillPattern=FillPattern.VerticalCylinder, extent={{4.67,42.3055},{-4.67,-42.3055}}),Rectangle(visible=true, origin={-0.3207,-65.0}, fillColor={128,0,0}, fillPattern=FillPattern.Solid, extent={{-34.9571,-15.0},{34.9571,15.0}}),Ellipse(visible=true, origin={0.0,-45.0}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-5.0,-5.0},{5.0,5.0}})}), Documentation(info="<html>

<head>
<title>Exemples of Complete Systems</title>

</head>

<body lang=EN link=blue vlink=purple>

<h1>MathModelica® System Designer</h1>
<em><h2>Systems - Examples of System Models</h2></em>
<h4>© 2009 MathCore Engineering AB</h4>

<p>
<hr>
<p>
<table bgcolor=\"lightgrey\"><tr><td>
<P>The <a href=\"Modelica://IntroductoryExamples\">IntroductoryExamples</a> library contains a few examples that are will help you to get started with <em>MathModelica System Designer</em>. In the <a href=\"../../docs/introductory_examples.pdf\">Introductory Examples document</a> you can find  detailed step by step descriptions of how to build and simulate respective model, as well as some exercises that will help you learn <em>MathModelica System Designer</em>.</p>
</tr></td>
</table>
<p>
<hr>

<P>This package contains complete system models of various applications. Currently the following examples are available:</p>

<h3><a href=\"Modelica://IntroductoryExamples.Systems.InvertedPendulum\">Inverted Pendulum</a></h3>
<p>A classical engineering problem is to control an inverted pendulum.</p>
</body>

</html>



", revisions=""));
    model InvertedPendulum "A controlled inverted pendulum system"
      annotation(preferredView="info");
      parameter Integer referenceType(final min=1, final max=3)=2 "Type of reference signal: 1=step, 2=pulse, 3=time table";
      Components.ElectricalMotor motor annotation(Placement(visible=true, transformation(origin={-20.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      Components.LQControlSystem controller(referenceType=referenceType) annotation(Placement(visible=true, transformation(origin={-50.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      Components.Pendulum pendulum annotation(Placement(visible=true, transformation(origin={40.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      Components.GearBox gear annotation(Placement(visible=true, transformation(origin={10.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
      annotation(experiment(StartTime=0.0, StopTime=20, Algorithm="dassl", Tolerance=1e-06, Interval=0.01), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-6.5248,25.9625}, rotation=5, fillColor={0,170,255}, fillPattern=FillPattern.VerticalCylinder, extent={{4.67,69.8256},{-4.67,-69.8256}}),Rectangle(visible=true, origin={0.0,-70.0}, fillColor={128,0,0}, fillPattern=FillPattern.Solid, extent={{-40.0,-20.0},{40.0,20.0}}),Ellipse(visible=true, origin={0.0,-45.0}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-5.0,-5.0},{5.0,5.0}})}), Diagram(coordinateSystem(extent={{-80.0,-40.0},{80.0,40.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>

<head>
<title>System example</title>

</head>

<body lang=EN link=blue vlink=purple>

<h1>MathModelica® System Designer</h1>
<em><h2>Inverted Pendulum - A Classical Control Engineering Problem</h2></em>
<h4>© 2009 MathCore Engineering AB</h4>

<p>
<hr>
<p>
<table bgcolor=\"lightgrey\"><tr><td>
<P>The <a href=\"Modelica://IntroductoryExamples\">IntroductoryExamples</a> library contains a few examples that are will help you to get started with <em>MathModelica System Designer</em>. In the <a href=\"../../docs/introductory_examples.pdf\">Introductory Examples document</a> you can find  detailed step by step descriptions of how to build and simulate respective model, as well as some exercises that will help you learn <em>MathModelica System Designer</em>.</p>
</tr></td>
</table>
<p>
<hr>

<p>The pendulum system consists of an <a href=\"Modelica://IntroductoryExamples.Systems.Components.ElectricalMotor\">electrical motor</a>, a <a href=\"Modelica://IntroductoryExamples.Systems.Components.GearBox\">gear</a>, and a <a href=\"Modelica://IntroductoryExamples.Systems.Components.Pendulum\">pendulum connected to a cart</a>. The position of the cart is controlled using a <a href=\"Modelica://IntroductoryExamples.Systems.Components.LQControlSystem\">controller</a> with LQ (Linear Quadratic) design. The first priority of the controller is to make sure that the pendulum stays in upright position.</p>

<p>Simulate the system for 20s and view the result in an animation window. The figure below shows an animation at time 11.3s using the pulse reference signal (referenceType=2):</p>

<p><img src=\"Systems/Pendulum.png\">
</p>

<p>The position of the cart can be changed by the referenceType parameter. With the time table option (referenceType=3) you can create your own arbitrary signal. Change different parameters of the system, e.g., limit the maximum output signal from the controller (controller.uMax), length of pendulum (pendulum.l_pendulum) and see what happens.</p></body></html>", revisions=""));
    equation
      connect(gear.flange_b,pendulum.flange_a) annotation(Line(visible=true, origin={25.0,0.0}, points={{-5.0,0.0},{5.0,0.0}}));
      connect(motor.flange,gear.flange_a) annotation(Line(visible=true, origin={-5.0,0.0}, points={{-5.0,0.0},{5.0,0.0}}));
      connect(motor.u,controller.y) annotation(Line(visible=true, origin={-35.25,0.0}, points={{4.25,0.0},{-4.25,0.0}}));
      connect(pendulum.position,controller.xPos) annotation(Line(visible=true, origin={11.8,-9.0}, points={{39.2,12.0},{48.2,12.0},{48.2,-11.0},{-67.8,-11.0},{-67.8,-2.0}}));
      connect(pendulum.angle,controller.angle) annotation(Line(visible=true, origin={14.6005,-9.4005}, points={{36.3995,6.4005},{40.4008,6.4005},{40.4008,-5.6007},{-58.6005,-5.6007},{-58.6005,-1.5995}}));
    end InvertedPendulum;

  end Systems;

end IntroductoryExamples;
model IntroductoryExamples_Systems_InvertedPendulum
  extends IntroductoryExamples.Systems.InvertedPendulum;
end IntroductoryExamples_Systems_InvertedPendulum;
// Result:
// function MCVisualShape$pendulum$cart$box$mcShape.local_normalize
//   input Real[3] iv;
//   output Real[3] ov;
//   protected Real length;
// algorithm
//   length := sqrt(iv[1] ^ 2.0 + iv[2] ^ 2.0 + iv[3] ^ 2.0);
//   ov := {iv[1] / length, iv[2] / length, iv[3] / length};
// end MCVisualShape$pendulum$cart$box$mcShape.local_normalize;
//
// function MCVisualShape$pendulum$pendulum$box$mcShape.local_normalize
//   input Real[3] iv;
//   output Real[3] ov;
//   protected Real length;
// algorithm
//   length := sqrt(iv[1] ^ 2.0 + iv[2] ^ 2.0 + iv[3] ^ 2.0);
//   ov := {iv[1] / length, iv[2] / length, iv[3] / length};
// end MCVisualShape$pendulum$pendulum$box$mcShape.local_normalize;
//
// function Modelica.Blocks.Sources.TimeTable$controller$timeTable.getInterpolationCoefficients "Determine interpolation coefficients and next time event"
//   input Real[:, 2] table "Table for interpolation";
//   input Real offset "y-offset";
//   input Real startTime "time-offset";
//   input Real t "Actual time instant";
//   input Integer last "Last used lower grid index";
//   input Real TimeEps "Relative epsilon to check for identical time instants";
//   output Real a "Interpolation coefficients a (y=a*x + b)";
//   output Real b "Interpolation coefficients b (y=a*x + b)";
//   output Real nextEvent "Next event instant";
//   output Integer next "New lower grid index";
//   protected Integer columns = 2 "Column to be interpolated";
//   protected Integer ncol = 2 "Number of columns to be interpolated";
//   protected Integer next0;
//   protected Real tp;
//   protected Real dt;
//   protected Integer nrow = size(table, 1) "Number of table rows";
// algorithm
//   next := last;
//   nextEvent := t - TimeEps * abs(t);
//   tp := t + TimeEps * abs(t) - startTime;
//   if tp < 0.0 then
//     nextEvent := startTime;
//     a := 0.0;
//     b := offset;
//   elseif nrow < 2 then
//     a := 0.0;
//     b := offset + table[1,columns];
//   else
//     while next < nrow and tp >= table[next,1] loop
//       next := 1 + next;
//     end while;
//     if next < nrow then
//       nextEvent := startTime + table[next,1];
//     end if;
//     next0 := -1 + next;
//     dt := table[next,1] - table[next0,1];
//     if dt <= TimeEps * abs(table[next,1]) then
//       a := 0.0;
//       b := offset + table[next,columns];
//     else
//       a := (table[next,columns] - table[next0,columns]) / dt;
//       b := offset + table[next0,columns] - a * table[next0,1];
//     end if;
//   end if;
//   b := b - a * startTime;
// end Modelica.Blocks.Sources.TimeTable$controller$timeTable.getInterpolationCoefficients;
//
// function Modelica.Math.asin "inverse sine (-1 <= u <= 1)"
//   input Real u;
//   output Real y(quantity = "Angle", unit = "rad", displayUnit = "deg");
//
//   external "C" y = asin(u);
// end Modelica.Math.asin;
//
// function PackMaterial
//   input Real r;
//   input Real g;
//   input Real b;
//   input Real spec;
//   output Real packedMaterial;
//   protected Integer i1;
//   protected Integer i2;
//   protected Integer i3;
//   protected Integer i4;
// algorithm
//   i1 := integer(floor(99.0 * r));
//   if i1 < 0 then
//     i1 := 0;
//   end if;
//   if i1 > 99 then
//     i1 := 99;
//   end if;
//   i2 := integer(floor(99.0 * g));
//   if i2 < 0 then
//     i2 := 0;
//   end if;
//   if i2 > 99 then
//     i2 := 99;
//   end if;
//   i3 := integer(floor(99.0 * b));
//   if i3 < 0 then
//     i3 := 0;
//   end if;
//   if i3 > 99 then
//     i3 := 99;
//   end if;
//   i4 := integer(floor(9.0 * spec));
//   if i4 < 0 then
//     i4 := 0;
//   end if;
//   if i4 > 99 then
//     i4 := 9;
//   end if;
//   packedMaterial := /*Real*/(10 * (100 * (100 * i1 + i2) + i3) + i4);
// end PackMaterial;
//
// function PackShape
//   input String shape;
//   output Real packedShape;
// algorithm
//   if shape == "box" then
//     packedShape := 101.0;
//   elseif shape == "sphere" then
//     packedShape := 102.0;
//   elseif shape == "cylinder" then
//     packedShape := 103.0;
//   elseif shape == "cone" then
//     packedShape := 104.0;
//   elseif shape == "pipe" then
//     packedShape := 105.0;
//   elseif shape == "beam" then
//     packedShape := 106.0;
//   elseif shape == "wirebox" then
//     packedShape := 107.0;
//   elseif shape == "gearwheel" then
//     packedShape := 108.0;
//   elseif shape == "spring" then
//     packedShape := 111.0;
//   else
//     packedShape := 200.0;
//   end if;
// end PackShape;
//
// class IntroductoryExamples_Systems_InvertedPendulum
//   parameter Integer referenceType(min = 1, max = 3) = 2 "Type of reference signal: 1=step, 2=pulse, 3=time table";
//   parameter Real motor.R(quantity = "Resistance", unit = "Ohm") = 2.6 "Resistance";
//   parameter Real motor.L(quantity = "Inductance", unit = "H") = 0.001 "Inductance";
//   parameter Real motor.k(unit = "N.m/A") = 0.00767 "Transformation coefficient";
//   Real motor.voltageSource.i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
//   Real motor.voltageSource.p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
//   Real motor.voltageSource.p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
//   Real motor.voltageSource.n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
//   Real motor.voltageSource.n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
//   Real motor.voltageSource.v(quantity = "ElectricPotential", unit = "V") "Voltage between pin p and n (= p.v - n.v) as input signal";
//   Real motor.resistor.v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
//   Real motor.resistor.i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
//   Real motor.resistor.p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
//   Real motor.resistor.p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
//   Real motor.resistor.n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
//   Real motor.resistor.n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
//   parameter Real motor.resistor.R(quantity = "Resistance", unit = "Ohm") = motor.R "Resistance";
//   Real motor.inductor.v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
//   Real motor.inductor.i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
//   Real motor.inductor.p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
//   Real motor.inductor.p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
//   Real motor.inductor.n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
//   Real motor.inductor.n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
//   parameter Real motor.inductor.L(quantity = "Inductance", unit = "H") = motor.L "Inductance";
//   parameter Real motor.eMF.k(unit = "N.m/A") = motor.k "Transformation coefficient";
//   Real motor.eMF.v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins";
//   Real motor.eMF.i(quantity = "ElectricCurrent", unit = "A") "Current flowing from positive to negative pin";
//   Real motor.eMF.w(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Angular velocity of flange_b";
//   Real motor.eMF.p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
//   Real motor.eMF.p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
//   Real motor.eMF.n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
//   Real motor.eMF.n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
//   Real motor.eMF.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real motor.eMF.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real motor.u;
//   Real motor.flange.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real motor.flange.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real motor.ground.p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
//   Real motor.ground.p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
//   parameter Real controller.A[1,1] = -1.80378 "Observer A matrix";
//   parameter Real controller.A[1,2] = 1.0 "Observer A matrix";
//   parameter Real controller.A[1,3] = -0.301845 "Observer A matrix";
//   parameter Real controller.A[1,4] = 0.0 "Observer A matrix";
//   parameter Real controller.A[2,1] = -1.67236 "Observer A matrix";
//   parameter Real controller.A[2,2] = -13.7653 "Observer A matrix";
//   parameter Real controller.A[2,3] = -0.753808 "Observer A matrix";
//   parameter Real controller.A[2,4] = 0.0 "Observer A matrix";
//   parameter Real controller.A[3,1] = -0.301845 "Observer A matrix";
//   parameter Real controller.A[3,2] = 0.0 "Observer A matrix";
//   parameter Real controller.A[3,3] = -7.83137 "Observer A matrix";
//   parameter Real controller.A[3,4] = 1.0 "Observer A matrix";
//   parameter Real controller.A[4,1] = -0.617197 "Observer A matrix";
//   parameter Real controller.A[4,2] = -19.3623 "Observer A matrix";
//   parameter Real controller.A[4,3] = -14.7496 "Observer A matrix";
//   parameter Real controller.A[4,4] = 0.0 "Observer A matrix";
//   parameter Real controller.B[1,1] = 0.0 "Observer B matrix";
//   parameter Real controller.B[1,2] = 1.80378 "Observer B matrix";
//   parameter Real controller.B[1,3] = 0.301845 "Observer B matrix";
//   parameter Real controller.B[2,1] = 2.69088 "Observer B matrix";
//   parameter Real controller.B[2,2] = 1.67236 "Observer B matrix";
//   parameter Real controller.B[2,3] = 2.29112 "Observer B matrix";
//   parameter Real controller.B[3,1] = 0.0 "Observer B matrix";
//   parameter Real controller.B[3,2] = 0.301845 "Observer B matrix";
//   parameter Real controller.B[3,3] = 7.83137 "Observer B matrix";
//   parameter Real controller.B[4,1] = 3.785 "Observer B matrix";
//   parameter Real controller.B[4,2] = 0.617197 "Observer B matrix";
//   parameter Real controller.B[4,3] = 30.7107 "Observer B matrix";
//   parameter Real controller.C[1,1] = 1.0 "Observer C matrix";
//   parameter Real controller.C[1,2] = 0.0 "Observer C matrix";
//   parameter Real controller.C[1,3] = 0.0 "Observer C matrix";
//   parameter Real controller.C[1,4] = 0.0 "Observer C matrix";
//   parameter Real controller.C[2,1] = 0.0 "Observer C matrix";
//   parameter Real controller.C[2,2] = 1.0 "Observer C matrix";
//   parameter Real controller.C[2,3] = 0.0 "Observer C matrix";
//   parameter Real controller.C[2,4] = 0.0 "Observer C matrix";
//   parameter Real controller.C[3,1] = 0.0 "Observer C matrix";
//   parameter Real controller.C[3,2] = 0.0 "Observer C matrix";
//   parameter Real controller.C[3,3] = 1.0 "Observer C matrix";
//   parameter Real controller.C[3,4] = 0.0 "Observer C matrix";
//   parameter Real controller.C[4,1] = 0.0 "Observer C matrix";
//   parameter Real controller.C[4,2] = 0.0 "Observer C matrix";
//   parameter Real controller.C[4,3] = 0.0 "Observer C matrix";
//   parameter Real controller.C[4,4] = 1.0 "Observer C matrix";
//   parameter Real controller.D[1,1] = 0.0 "Observer D matrix";
//   parameter Real controller.D[1,2] = 0.0 "Observer D matrix";
//   parameter Real controller.D[1,3] = 0.0 "Observer D matrix";
//   parameter Real controller.D[2,1] = 0.0 "Observer D matrix";
//   parameter Real controller.D[2,2] = 0.0 "Observer D matrix";
//   parameter Real controller.D[2,3] = 0.0 "Observer D matrix";
//   parameter Real controller.D[3,1] = 0.0 "Observer D matrix";
//   parameter Real controller.D[3,2] = 0.0 "Observer D matrix";
//   parameter Real controller.D[3,3] = 0.0 "Observer D matrix";
//   parameter Real controller.D[4,1] = 0.0 "Observer D matrix";
//   parameter Real controller.D[4,2] = 0.0 "Observer D matrix";
//   parameter Real controller.D[4,3] = 0.0 "Observer D matrix";
//   parameter Real controller.K_L[1,1] = -14.1421 "L matrix such that eigenvalues for A-B*L is inside stability region";
//   parameter Real controller.K_L[1,2] = -23.685 "L matrix such that eigenvalues for A-B*L is inside stability region";
//   parameter Real controller.K_L[1,3] = 114.738 "L matrix such that eigenvalues for A-B*L is inside stability region";
//   parameter Real controller.K_L[1,4] = 21.4806 "L matrix such that eigenvalues for A-B*L is inside stability region";
//   parameter Real controller.k_Lr = -14.1421 "Static gain in order to make system gain equal to one";
//   parameter Real controller.uMax(min = 0.0) = 10.0 "Maximum output value";
//   parameter Real controller.table[1,1] = 0.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[1,2] = 0.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[2,1] = 2.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[2,2] = 0.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[3,1] = 2.5 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[3,2] = 1.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[4,1] = 3.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[4,2] = -1.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[5,1] = 3.5 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[5,2] = 1.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[6,1] = 4.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[6,2] = 0.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[7,1] = 4.5 "Table matrix (time = first column). Only if inputType=3";
//   parameter Real controller.table[7,2] = 0.0 "Table matrix (time = first column). Only if inputType=3";
//   parameter Integer controller.referenceType(min = 1, max = 3) = referenceType "Type of reference signal: 1=step, 2=pulse, 3=time table";
//   Real controller.step.y "Connector of Real output signal";
//   parameter Real controller.step.k = 1.0 "Constant output value";
//   parameter Integer controller.observer.nin = 3 "Number of inputs";
//   parameter Integer controller.observer.nout = 4 "Number of outputs";
//   Real controller.observer.u[1] "Connector of Real input signals";
//   Real controller.observer.u[2] "Connector of Real input signals";
//   Real controller.observer.u[3] "Connector of Real input signals";
//   Real controller.observer.y[1] "Connector of Real output signals";
//   Real controller.observer.y[2] "Connector of Real output signals";
//   Real controller.observer.y[3] "Connector of Real output signals";
//   Real controller.observer.y[4] "Connector of Real output signals";
//   parameter Real controller.observer.A[1,1] = controller.A[1,1] "Matrix A of state space model";
//   parameter Real controller.observer.A[1,2] = controller.A[1,2] "Matrix A of state space model";
//   parameter Real controller.observer.A[1,3] = controller.A[1,3] "Matrix A of state space model";
//   parameter Real controller.observer.A[1,4] = controller.A[1,4] "Matrix A of state space model";
//   parameter Real controller.observer.A[2,1] = controller.A[2,1] "Matrix A of state space model";
//   parameter Real controller.observer.A[2,2] = controller.A[2,2] "Matrix A of state space model";
//   parameter Real controller.observer.A[2,3] = controller.A[2,3] "Matrix A of state space model";
//   parameter Real controller.observer.A[2,4] = controller.A[2,4] "Matrix A of state space model";
//   parameter Real controller.observer.A[3,1] = controller.A[3,1] "Matrix A of state space model";
//   parameter Real controller.observer.A[3,2] = controller.A[3,2] "Matrix A of state space model";
//   parameter Real controller.observer.A[3,3] = controller.A[3,3] "Matrix A of state space model";
//   parameter Real controller.observer.A[3,4] = controller.A[3,4] "Matrix A of state space model";
//   parameter Real controller.observer.A[4,1] = controller.A[4,1] "Matrix A of state space model";
//   parameter Real controller.observer.A[4,2] = controller.A[4,2] "Matrix A of state space model";
//   parameter Real controller.observer.A[4,3] = controller.A[4,3] "Matrix A of state space model";
//   parameter Real controller.observer.A[4,4] = controller.A[4,4] "Matrix A of state space model";
//   parameter Real controller.observer.B[1,1] = controller.B[1,1] "Matrix B of state space model";
//   parameter Real controller.observer.B[1,2] = controller.B[1,2] "Matrix B of state space model";
//   parameter Real controller.observer.B[1,3] = controller.B[1,3] "Matrix B of state space model";
//   parameter Real controller.observer.B[2,1] = controller.B[2,1] "Matrix B of state space model";
//   parameter Real controller.observer.B[2,2] = controller.B[2,2] "Matrix B of state space model";
//   parameter Real controller.observer.B[2,3] = controller.B[2,3] "Matrix B of state space model";
//   parameter Real controller.observer.B[3,1] = controller.B[3,1] "Matrix B of state space model";
//   parameter Real controller.observer.B[3,2] = controller.B[3,2] "Matrix B of state space model";
//   parameter Real controller.observer.B[3,3] = controller.B[3,3] "Matrix B of state space model";
//   parameter Real controller.observer.B[4,1] = controller.B[4,1] "Matrix B of state space model";
//   parameter Real controller.observer.B[4,2] = controller.B[4,2] "Matrix B of state space model";
//   parameter Real controller.observer.B[4,3] = controller.B[4,3] "Matrix B of state space model";
//   parameter Real controller.observer.C[1,1] = controller.C[1,1] "Matrix C of state space model";
//   parameter Real controller.observer.C[1,2] = controller.C[1,2] "Matrix C of state space model";
//   parameter Real controller.observer.C[1,3] = controller.C[1,3] "Matrix C of state space model";
//   parameter Real controller.observer.C[1,4] = controller.C[1,4] "Matrix C of state space model";
//   parameter Real controller.observer.C[2,1] = controller.C[2,1] "Matrix C of state space model";
//   parameter Real controller.observer.C[2,2] = controller.C[2,2] "Matrix C of state space model";
//   parameter Real controller.observer.C[2,3] = controller.C[2,3] "Matrix C of state space model";
//   parameter Real controller.observer.C[2,4] = controller.C[2,4] "Matrix C of state space model";
//   parameter Real controller.observer.C[3,1] = controller.C[3,1] "Matrix C of state space model";
//   parameter Real controller.observer.C[3,2] = controller.C[3,2] "Matrix C of state space model";
//   parameter Real controller.observer.C[3,3] = controller.C[3,3] "Matrix C of state space model";
//   parameter Real controller.observer.C[3,4] = controller.C[3,4] "Matrix C of state space model";
//   parameter Real controller.observer.C[4,1] = controller.C[4,1] "Matrix C of state space model";
//   parameter Real controller.observer.C[4,2] = controller.C[4,2] "Matrix C of state space model";
//   parameter Real controller.observer.C[4,3] = controller.C[4,3] "Matrix C of state space model";
//   parameter Real controller.observer.C[4,4] = controller.C[4,4] "Matrix C of state space model";
//   parameter Real controller.observer.D[1,1] = controller.D[1,1] "Matrix D of state space model";
//   parameter Real controller.observer.D[1,2] = controller.D[1,2] "Matrix D of state space model";
//   parameter Real controller.observer.D[1,3] = controller.D[1,3] "Matrix D of state space model";
//   parameter Real controller.observer.D[2,1] = controller.D[2,1] "Matrix D of state space model";
//   parameter Real controller.observer.D[2,2] = controller.D[2,2] "Matrix D of state space model";
//   parameter Real controller.observer.D[2,3] = controller.D[2,3] "Matrix D of state space model";
//   parameter Real controller.observer.D[3,1] = controller.D[3,1] "Matrix D of state space model";
//   parameter Real controller.observer.D[3,2] = controller.D[3,2] "Matrix D of state space model";
//   parameter Real controller.observer.D[3,3] = controller.D[3,3] "Matrix D of state space model";
//   parameter Real controller.observer.D[4,1] = controller.D[4,1] "Matrix D of state space model";
//   parameter Real controller.observer.D[4,2] = controller.D[4,2] "Matrix D of state space model";
//   parameter Real controller.observer.D[4,3] = controller.D[4,3] "Matrix D of state space model";
//   parameter Integer controller.observer.initType(min = 1, max = 4) = 1 "Type of initialization";
//   parameter Real controller.observer.x_start[1] = 0.0 "Initial or guess values of states";
//   parameter Real controller.observer.x_start[2] = 0.0 "Initial or guess values of states";
//   parameter Real controller.observer.x_start[3] = 0.0 "Initial or guess values of states";
//   parameter Real controller.observer.x_start[4] = 0.0 "Initial or guess values of states";
//   parameter Real controller.observer.y_start[1] = 0.0 "Initial values of outputs (remaining states are in steady state if possible)";
//   parameter Real controller.observer.y_start[2] = 0.0 "Initial values of outputs (remaining states are in steady state if possible)";
//   parameter Real controller.observer.y_start[3] = 0.0 "Initial values of outputs (remaining states are in steady state if possible)";
//   parameter Real controller.observer.y_start[4] = 0.0 "Initial values of outputs (remaining states are in steady state if possible)";
//   Real controller.observer.x[1](start = controller.observer.x_start[1]) "State vector";
//   Real controller.observer.x[2](start = controller.observer.x_start[2]) "State vector";
//   Real controller.observer.x[3](start = controller.observer.x_start[3]) "State vector";
//   Real controller.observer.x[4](start = controller.observer.x_start[4]) "State vector";
//   protected parameter Integer controller.observer.nx = 4 "number of states";
//   protected parameter Integer controller.observer.ny = 4 "number of outputs";
//   parameter Integer controller.L.nin = 4 "Number of inputs";
//   parameter Integer controller.L.nout = 1 "Number of outputs";
//   Real controller.L.u[1] "Connector of Real input signals";
//   Real controller.L.u[2] "Connector of Real input signals";
//   Real controller.L.u[3] "Connector of Real input signals";
//   Real controller.L.u[4] "Connector of Real input signals";
//   Real controller.L.y[1] "Connector of Real output signals";
//   parameter Real controller.L.K[1,1] = controller.K_L[1,1] "Gain matrix which is multiplied with the input";
//   parameter Real controller.L.K[1,2] = controller.K_L[1,2] "Gain matrix which is multiplied with the input";
//   parameter Real controller.L.K[1,3] = controller.K_L[1,3] "Gain matrix which is multiplied with the input";
//   parameter Real controller.L.K[1,4] = controller.K_L[1,4] "Gain matrix which is multiplied with the input";
//   Real controller.feedback.u1;
//   Real controller.feedback.y;
//   Real controller.feedback.u2;
//   parameter Real controller.L_r.k = controller.k_Lr "Gain value multiplied with input signal";
//   Real controller.L_r.u "Input signal connector";
//   Real controller.L_r.y "Output signal connector";
//   parameter Integer controller.mux.n1 = 1 "dimension of input signal connector 1";
//   parameter Integer controller.mux.n2 = 1 "dimension of input signal connector 2";
//   parameter Integer controller.mux.n3 = 1 "dimension of input signal connector 3";
//   Real controller.mux.u1[1] "Connector of Real input signals 1";
//   Real controller.mux.u2[1] "Connector of Real input signals 2";
//   Real controller.mux.u3[1] "Connector of Real input signals 3";
//   Real controller.mux.y[1] "Connector of Real output signals";
//   Real controller.mux.y[2] "Connector of Real output signals";
//   Real controller.mux.y[3] "Connector of Real output signals";
//   Real controller.pulse.y "Connector of Real output signal";
//   parameter Real controller.pulse.amplitude = 1.0 "Amplitude of pulse";
//   parameter Real controller.pulse.width(min = 1e-60, max = 100.0) = 50.0 "Width of pulse in % of periods";
//   parameter Real controller.pulse.period(quantity = "Time", unit = "s", min = 1e-60) = 10.0 "Time for one period";
//   parameter Real controller.pulse.offset = -0.5 "Offset of output signals";
//   parameter Real controller.pulse.startTime(quantity = "Time", unit = "s") = 0.0 "Output = offset for time < startTime";
//   protected Real controller.pulse.T0(quantity = "Time", unit = "s", start = controller.pulse.startTime) "Start time of current period";
//   protected Real controller.pulse.T_width(quantity = "Time", unit = "s") = 0.01 * controller.pulse.period * controller.pulse.width;
//   Real controller.switch1.u1 "Connector of first Real input signal";
//   Boolean controller.switch1.u2 "Connector of Boolean input signal";
//   Real controller.switch1.u3 "Connector of second Real input signal";
//   Real controller.switch1.y "Connector of Real output signal";
//   Boolean controller.ConstantQ.y "Connector of Boolean output signal";
//   parameter Boolean controller.ConstantQ.k = controller.k1 "Constant output value";
//   Real controller.limiter.u "Connector of Real input signal";
//   Real controller.limiter.y "Connector of Real output signal";
//   parameter Real controller.limiter.uMax = controller.uMax "Upper limits of input signals";
//   parameter Real controller.limiter.uMin = -controller.limiter.uMax "Lower limits of input signals";
//   parameter Boolean controller.limiter.limitsAtInit = true "= false, if limits are ignored during initializiation (i.e., y=u)";
//   Real controller.angle;
//   Real controller.xPos;
//   Real controller.y;
//   Real controller.switch2.u1 "Connector of first Real input signal";
//   Boolean controller.switch2.u2 "Connector of Boolean input signal";
//   Real controller.switch2.u3 "Connector of second Real input signal";
//   Real controller.switch2.y "Connector of Real output signal";
//   Boolean controller.ConstantQ1.y "Connector of Boolean output signal";
//   parameter Boolean controller.ConstantQ1.k = controller.k2 "Constant output value";
//   Real controller.timeTable.y "Connector of Real output signal";
//   parameter Real controller.timeTable.table[1,1] = controller.table[1,1] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[1,2] = controller.table[1,2] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[2,1] = controller.table[2,1] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[2,2] = controller.table[2,2] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[3,1] = controller.table[3,1] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[3,2] = controller.table[3,2] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[4,1] = controller.table[4,1] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[4,2] = controller.table[4,2] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[5,1] = controller.table[5,1] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[5,2] = controller.table[5,2] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[6,1] = controller.table[6,1] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[6,2] = controller.table[6,2] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[7,1] = controller.table[7,1] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.table[7,2] = controller.table[7,2] "Table matrix (time = first column)";
//   parameter Real controller.timeTable.offset = 0.0 "Offset of output signal";
//   parameter Real controller.timeTable.startTime(quantity = "Time", unit = "s") = 0.0 "Output = offset for time < startTime";
//   protected Real controller.timeTable.a "Interpolation coefficients a of actual interval (y=a*x+b)";
//   protected Real controller.timeTable.b "Interpolation coefficients b of actual interval (y=a*x+b)";
//   protected Integer controller.timeTable.last(start = 1) "Last used lower grid index";
//   protected Real controller.timeTable.nextEvent(quantity = "Time", unit = "s", start = 0.0) "Next event instant";
//   protected parameter Boolean controller.k1 = controller.referenceType == 1 "Step signal";
//   protected parameter Boolean controller.k2 = controller.referenceType == 2 "Pulse signal";
//   protected parameter Boolean controller.k3 = controller.referenceType == 3 "Time table";
//   parameter Real pendulum.l_pendulum(quantity = "Length", unit = "m") = 0.61 "Pendulum length";
//   parameter Real pendulum.r_pendulum(quantity = "Length", unit = "m", min = 0.0) = 0.005 "Pendulum radius";
//   parameter Real pendulum.d_pendulum(unit = "N.m.s/rad", min = 0.0) = 0.01 "Pendulum damper constant";
//   parameter Real pendulum.rho_pendulum(unit = "g/cm3") = 7.7 "Pendulum material density";
//   parameter Real pendulum.d_slider(unit = "N/(m/s)", min = 0.0) = 2.0 "Pendulum slider constant";
//   parameter Real pendulum.rho_cart(unit = "g/cm3") = 0.445 "Cart material density";
//   parameter Real pendulum.l_cart(quantity = "Length", unit = "m") = 0.1 "Cart length";
//   parameter Real pendulum.h_cart(quantity = "Length", unit = "m") = 0.1 "Cart height";
//   parameter Real pendulum.w_cart(quantity = "Length", unit = "m") = 0.1 "Cart width";
//   parameter Real pendulum.inertialSystem.g(quantity = "Acceleration", unit = "m/s2") = 9.81 "Gravity constant";
//   parameter Real pendulum.inertialSystem.ng[1] = 0.0 "Direction of gravity (gravity = g*ng)";
//   parameter Real pendulum.inertialSystem.ng[2] = -1.0 "Direction of gravity (gravity = g*ng)";
//   parameter Real pendulum.inertialSystem.ng[3] = 0.0 "Direction of gravity (gravity = g*ng)";
//   parameter String pendulum.inertialSystem.label1 = "x" "Label of horizontal axis in icon";
//   parameter String pendulum.inertialSystem.label2 = "y" "Label of vertical axis in icon";
//   Real pendulum.inertialSystem.gravity[1](quantity = "Acceleration", unit = "m/s2") "Gravity acceleration vector";
//   Real pendulum.inertialSystem.gravity[2](quantity = "Acceleration", unit = "m/s2") "Gravity acceleration vector";
//   Real pendulum.inertialSystem.gravity[3](quantity = "Acceleration", unit = "m/s2") "Gravity acceleration vector";
//   Real pendulum.inertialSystem.frame_b.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.inertialSystem.frame_b.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.inertialSystem.frame_b.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.inertialSystem.frame_b.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.inertialSystem.frame_b.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.inertialSystem.frame_b.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.inertialSystem.frame_b.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.inertialSystem.frame_b.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.inertialSystem.frame_b.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.inertialSystem.frame_b.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.inertialSystem.frame_b.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.inertialSystem.frame_b.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.inertialSystem.frame_b.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.inertialSystem.frame_b.f[1](quantity = "Force", unit = "N");
//   Real pendulum.inertialSystem.frame_b.f[2](quantity = "Force", unit = "N");
//   Real pendulum.inertialSystem.frame_b.f[3](quantity = "Force", unit = "N");
//   Real pendulum.inertialSystem.frame_b.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.inertialSystem.frame_b.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.inertialSystem.frame_b.t[3](quantity = "Torque", unit = "N.m");
//   constant Real pendulum.cart.pi = 3.141592653589793;
//   Real pendulum.cart.frame_a.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frame_a.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frame_a.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frame_a.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_a.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_a.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_a.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_a.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_a.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_a.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_a.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_a.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_a.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_a.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_a.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_a.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_a.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_a.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_a.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_a.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_a.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_a.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_a.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_a.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_a.f[1](quantity = "Force", unit = "N");
//   Real pendulum.cart.frame_a.f[2](quantity = "Force", unit = "N");
//   Real pendulum.cart.frame_a.f[3](quantity = "Force", unit = "N");
//   Real pendulum.cart.frame_a.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frame_a.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frame_a.t[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frame_b.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frame_b.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frame_b.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frame_b.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_b.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_b.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_b.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_b.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_b.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_b.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_b.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_b.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frame_b.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_b.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_b.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_b.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_b.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_b.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_b.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_b.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_b.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frame_b.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_b.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_b.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frame_b.f[1](quantity = "Force", unit = "N");
//   Real pendulum.cart.frame_b.f[2](quantity = "Force", unit = "N");
//   Real pendulum.cart.frame_b.f[3](quantity = "Force", unit = "N");
//   Real pendulum.cart.frame_b.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frame_b.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frame_b.t[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.Sa[1,1](start = 1.0);
//   protected Real pendulum.cart.Sa[1,2](start = 0.0);
//   protected Real pendulum.cart.Sa[1,3](start = 0.0);
//   protected Real pendulum.cart.Sa[2,1](start = 0.0);
//   protected Real pendulum.cart.Sa[2,2](start = 1.0);
//   protected Real pendulum.cart.Sa[2,3](start = 0.0);
//   protected Real pendulum.cart.Sa[3,1](start = 0.0);
//   protected Real pendulum.cart.Sa[3,2](start = 0.0);
//   protected Real pendulum.cart.Sa[3,3](start = 1.0);
//   protected Real pendulum.cart.r0a[1](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.r0a[2](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.r0a[3](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.va[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.va[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.va[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.wa[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.wa[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.wa[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.aa[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.aa[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.aa[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.za[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.za[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.za[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.fa[1](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.fa[2](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.fa[3](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.ta[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.ta[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.ta[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.Sb[1,1](start = 1.0);
//   protected Real pendulum.cart.Sb[1,2](start = 0.0);
//   protected Real pendulum.cart.Sb[1,3](start = 0.0);
//   protected Real pendulum.cart.Sb[2,1](start = 0.0);
//   protected Real pendulum.cart.Sb[2,2](start = 1.0);
//   protected Real pendulum.cart.Sb[2,3](start = 0.0);
//   protected Real pendulum.cart.Sb[3,1](start = 0.0);
//   protected Real pendulum.cart.Sb[3,2](start = 0.0);
//   protected Real pendulum.cart.Sb[3,3](start = 1.0);
//   protected Real pendulum.cart.r0b[1](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.r0b[2](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.r0b[3](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.vb[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.vb[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.vb[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.wb[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.wb[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.wb[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.ab[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.ab[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.ab[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.zb[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.zb[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.zb[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.fb[1](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.fb[2](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.fb[3](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.tb[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.tb[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.tb[3](quantity = "Torque", unit = "N.m");
//   parameter Real pendulum.cart.r[1](quantity = "Length", unit = "m") = pendulum.l_cart "Vector from frame_a to frame_b, resolved in frame_a";
//   parameter Real pendulum.cart.r[2](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to frame_b, resolved in frame_a";
//   parameter Real pendulum.cart.r[3](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to frame_b, resolved in frame_a";
//   parameter Real pendulum.cart.r0[1](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to left box plane, resolved in frame_a";
//   parameter Real pendulum.cart.r0[2](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to left box plane, resolved in frame_a";
//   parameter Real pendulum.cart.r0[3](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to left box plane, resolved in frame_a";
//   parameter Real pendulum.cart.LengthDirection[1](quantity = "Length", unit = "m") = pendulum.cart.r[1] - pendulum.cart.r0[1] "Vector in length direction, resolved in frame_a";
//   parameter Real pendulum.cart.LengthDirection[2](quantity = "Length", unit = "m") = pendulum.cart.r[2] - pendulum.cart.r0[2] "Vector in length direction, resolved in frame_a";
//   parameter Real pendulum.cart.LengthDirection[3](quantity = "Length", unit = "m") = pendulum.cart.r[3] - pendulum.cart.r0[3] "Vector in length direction, resolved in frame_a";
//   parameter Real pendulum.cart.WidthDirection[1](quantity = "Length", unit = "m") = 0.0 "Vector in width direction, resolved in frame_a";
//   parameter Real pendulum.cart.WidthDirection[2](quantity = "Length", unit = "m") = 1.0 "Vector in width direction, resolved in frame_a";
//   parameter Real pendulum.cart.WidthDirection[3](quantity = "Length", unit = "m") = 0.0 "Vector in width direction, resolved in frame_a";
//   parameter Real pendulum.cart.length(quantity = "Length", unit = "m") = sqrt((pendulum.cart.r[1] - pendulum.cart.r0[1]) ^ 2.0 + (pendulum.cart.r[2] - pendulum.cart.r0[2]) ^ 2.0 + (pendulum.cart.r[3] - pendulum.cart.r0[3]) ^ 2.0) "Length of box";
//   parameter Real pendulum.cart.Width(quantity = "Length", unit = "m") = pendulum.w_cart "Width of box";
//   parameter Real pendulum.cart.Height(quantity = "Length", unit = "m") = pendulum.h_cart "Height of box";
//   parameter Real pendulum.cart.InnerWidth(quantity = "Length", unit = "m") = 0.0 "Width of inner box surface";
//   parameter Real pendulum.cart.InnerHeight(quantity = "Length", unit = "m") = 0.0 "Height of inner box surface";
//   parameter Real pendulum.cart.rho = pendulum.rho_cart "Density of box material [g/cm^3]";
//   parameter Real pendulum.cart.Material[1] = 1.0 "Color and specular coefficient";
//   parameter Real pendulum.cart.Material[2] = 0.0 "Color and specular coefficient";
//   parameter Real pendulum.cart.Material[3] = 0.0 "Color and specular coefficient";
//   parameter Real pendulum.cart.Material[4] = 0.5 "Color and specular coefficient";
//   Real pendulum.cart.mo(quantity = "Mass", unit = "kg", min = 0.0);
//   Real pendulum.cart.mi(quantity = "Mass", unit = "kg", min = 0.0);
//   Real pendulum.cart.Sbox[1,1];
//   Real pendulum.cart.Sbox[1,2];
//   Real pendulum.cart.Sbox[1,3];
//   Real pendulum.cart.Sbox[2,1];
//   Real pendulum.cart.Sbox[2,2];
//   Real pendulum.cart.Sbox[2,3];
//   Real pendulum.cart.Sbox[3,1];
//   Real pendulum.cart.Sbox[3,2];
//   Real pendulum.cart.Sbox[3,3];
//   Real pendulum.cart.l(quantity = "Length", unit = "m");
//   Real pendulum.cart.w(quantity = "Length", unit = "m");
//   Real pendulum.cart.h(quantity = "Length", unit = "m");
//   Real pendulum.cart.wi(quantity = "Length", unit = "m");
//   Real pendulum.cart.hi(quantity = "Length", unit = "m");
//   parameter Real pendulum.cart.box.r0[1] = pendulum.cart.r0[1] "Origin of visual object.";
//   parameter Real pendulum.cart.box.r0[2] = pendulum.cart.r0[2] "Origin of visual object.";
//   parameter Real pendulum.cart.box.r0[3] = pendulum.cart.r0[3] "Origin of visual object.";
//   parameter Real pendulum.cart.box.length = pendulum.cart.length "Length of visual object.";
//   parameter Real pendulum.cart.box.Width = pendulum.cart.Width "Width of visual object.";
//   parameter Real pendulum.cart.box.Height = pendulum.cart.Height "Height of visual object.";
//   parameter Real pendulum.cart.box.LengthDirection[1] = pendulum.cart.LengthDirection[1] "Vector in length direction.";
//   parameter Real pendulum.cart.box.LengthDirection[2] = pendulum.cart.LengthDirection[2] "Vector in length direction.";
//   parameter Real pendulum.cart.box.LengthDirection[3] = pendulum.cart.LengthDirection[3] "Vector in length direction.";
//   parameter Real pendulum.cart.box.WidthDirection[1] = pendulum.cart.WidthDirection[1] "Vector in width direction.";
//   parameter Real pendulum.cart.box.WidthDirection[2] = pendulum.cart.WidthDirection[2] "Vector in width direction.";
//   parameter Real pendulum.cart.box.WidthDirection[3] = pendulum.cart.WidthDirection[3] "Vector in width direction.";
//   parameter String pendulum.cart.box.Shape = "box" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring)";
//   parameter Real pendulum.cart.box.Material[1] = pendulum.cart.Material[1] "Color and specular coefficient.";
//   parameter Real pendulum.cart.box.Material[2] = pendulum.cart.Material[2] "Color and specular coefficient.";
//   parameter Real pendulum.cart.box.Material[3] = pendulum.cart.Material[3] "Color and specular coefficient.";
//   parameter Real pendulum.cart.box.Material[4] = pendulum.cart.Material[4] "Color and specular coefficient.";
//   parameter Real pendulum.cart.box.Extra = 0.0 "Additional size data for some of the shape types";
//   Real pendulum.cart.box.S[1,1] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.S[1,2] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.S[1,3] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.S[2,1] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.S[2,2] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.S[2,3] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.S[3,1] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.S[3,2] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.S[3,3] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.Sshape[1,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.Sshape[1,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.Sshape[1,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.Sshape[2,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.Sshape[2,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.Sshape[2,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.Sshape[3,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.Sshape[3,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.Sshape[3,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.r[1] "Position of visual object.";
//   Real pendulum.cart.box.r[2] "Position of visual object.";
//   Real pendulum.cart.box.r[3] "Position of visual object.";
//   Real pendulum.cart.box.nLength[1];
//   Real pendulum.cart.box.nLength[2];
//   Real pendulum.cart.box.nLength[3];
//   Real pendulum.cart.box.nWidth[1];
//   Real pendulum.cart.box.nWidth[2];
//   Real pendulum.cart.box.nWidth[3];
//   Real pendulum.cart.box.nHeight[1];
//   Real pendulum.cart.box.nHeight[2];
//   Real pendulum.cart.box.nHeight[3];
//   parameter String pendulum.cart.box.mcShape.shapeType = pendulum.cart.box.Shape "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring)";
//   Real pendulum.cart.box.mcShape.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   Real pendulum.cart.box.mcShape.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   Real pendulum.cart.box.mcShape.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   Real pendulum.cart.box.mcShape.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   Real pendulum.cart.box.mcShape.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   Real pendulum.cart.box.mcShape.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   Real pendulum.cart.box.mcShape.lengthDirection[1] "Vector in length direction, resolved in object frame";
//   Real pendulum.cart.box.mcShape.lengthDirection[2] "Vector in length direction, resolved in object frame";
//   Real pendulum.cart.box.mcShape.lengthDirection[3] "Vector in length direction, resolved in object frame";
//   Real pendulum.cart.box.mcShape.widthDirection[1] "Vector in width direction, resolved in object frame";
//   Real pendulum.cart.box.mcShape.widthDirection[2] "Vector in width direction, resolved in object frame";
//   Real pendulum.cart.box.mcShape.widthDirection[3] "Vector in width direction, resolved in object frame";
//   Real pendulum.cart.box.mcShape.length(quantity = "Length", unit = "m") = pendulum.cart.box.length "Length of visual object";
//   Real pendulum.cart.box.mcShape.width(quantity = "Length", unit = "m") = pendulum.cart.box.Width "Width of visual object";
//   Real pendulum.cart.box.mcShape.height(quantity = "Length", unit = "m") = pendulum.cart.box.Height "Height of visual object";
//   Real pendulum.cart.box.mcShape.extra = pendulum.cart.box.Extra "Additional size data for some of the shape types";
//   Real pendulum.cart.box.mcShape.color[1] "Color of shape";
//   Real pendulum.cart.box.mcShape.color[2] "Color of shape";
//   Real pendulum.cart.box.mcShape.color[3] "Color of shape";
//   Real pendulum.cart.box.mcShape.specularCoefficient = pendulum.cart.box.Material[4];
//   Real pendulum.cart.box.mcShape.S[1,1] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.S[1,2] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.S[1,3] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.S[2,1] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.S[2,2] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.S[2,3] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.S[3,1] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.S[3,2] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.S[3,3] "3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.Sshape[1,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.Sshape[1,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.Sshape[1,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.Sshape[2,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.Sshape[2,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.Sshape[2,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.Sshape[3,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.Sshape[3,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.Sshape[3,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.cart.box.mcShape.rxvisobj[1] "x-axis unit vector of shape, resolved in world frame";
//   Real pendulum.cart.box.mcShape.rxvisobj[2] "x-axis unit vector of shape, resolved in world frame";
//   Real pendulum.cart.box.mcShape.rxvisobj[3] "x-axis unit vector of shape, resolved in world frame";
//   Real pendulum.cart.box.mcShape.ryvisobj[1] "y-axis unit vector of shape, resolved in world frame";
//   Real pendulum.cart.box.mcShape.ryvisobj[2] "y-axis unit vector of shape, resolved in world frame";
//   Real pendulum.cart.box.mcShape.ryvisobj[3] "y-axis unit vector of shape, resolved in world frame";
//   Real pendulum.cart.box.mcShape.rvisobj[1](quantity = "Length", unit = "m") "position vector from world frame to shape frame, resolved in world frame";
//   Real pendulum.cart.box.mcShape.rvisobj[2](quantity = "Length", unit = "m") "position vector from world frame to shape frame, resolved in world frame";
//   Real pendulum.cart.box.mcShape.rvisobj[3](quantity = "Length", unit = "m") "position vector from world frame to shape frame, resolved in world frame";
//   Real pendulum.cart.box.mcShape.abs_n_x = sqrt(pendulum.cart.box.mcShape.lengthDirection[1] ^ 2.0 + pendulum.cart.box.mcShape.lengthDirection[2] ^ 2.0 + pendulum.cart.box.mcShape.lengthDirection[3] ^ 2.0);
//   Real pendulum.cart.box.mcShape.e_x[1];
//   Real pendulum.cart.box.mcShape.e_x[2];
//   Real pendulum.cart.box.mcShape.e_x[3];
//   Real pendulum.cart.box.mcShape.n_z_aux[1];
//   Real pendulum.cart.box.mcShape.n_z_aux[2];
//   Real pendulum.cart.box.mcShape.n_z_aux[3];
//   Real pendulum.cart.box.mcShape.e_y[1];
//   Real pendulum.cart.box.mcShape.e_y[2];
//   Real pendulum.cart.box.mcShape.e_y[3];
//   Real pendulum.cart.box.mcShape.e_z[1];
//   Real pendulum.cart.box.mcShape.e_z[2];
//   Real pendulum.cart.box.mcShape.e_z[3];
//   protected Real pendulum.cart.box.mcShape.Form;
//   protected Real pendulum.cart.box.mcShape.size[1](quantity = "Length", unit = "m") "{length,width,height} of shape";
//   protected Real pendulum.cart.box.mcShape.size[2](quantity = "Length", unit = "m") "{length,width,height} of shape";
//   protected Real pendulum.cart.box.mcShape.size[3](quantity = "Length", unit = "m") "{length,width,height} of shape";
//   protected Real pendulum.cart.box.mcShape.Material;
//   protected Real pendulum.cart.box.mcShape.Extra;
//   constant Real pendulum.cart.frameTranslation.pi = 3.141592653589793;
//   Real pendulum.cart.frameTranslation.frame_a.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_a.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_a.f[1](quantity = "Force", unit = "N");
//   Real pendulum.cart.frameTranslation.frame_a.f[2](quantity = "Force", unit = "N");
//   Real pendulum.cart.frameTranslation.frame_a.f[3](quantity = "Force", unit = "N");
//   Real pendulum.cart.frameTranslation.frame_a.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frameTranslation.frame_a.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frameTranslation.frame_a.t[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frameTranslation.frame_b.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.frameTranslation.frame_b.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.frameTranslation.frame_b.f[1](quantity = "Force", unit = "N");
//   Real pendulum.cart.frameTranslation.frame_b.f[2](quantity = "Force", unit = "N");
//   Real pendulum.cart.frameTranslation.frame_b.f[3](quantity = "Force", unit = "N");
//   Real pendulum.cart.frameTranslation.frame_b.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frameTranslation.frame_b.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.frameTranslation.frame_b.t[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.frameTranslation.Sa[1,1](start = 1.0);
//   protected Real pendulum.cart.frameTranslation.Sa[1,2](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sa[1,3](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sa[2,1](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sa[2,2](start = 1.0);
//   protected Real pendulum.cart.frameTranslation.Sa[2,3](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sa[3,1](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sa[3,2](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sa[3,3](start = 1.0);
//   protected Real pendulum.cart.frameTranslation.r0a[1](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.frameTranslation.r0a[2](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.frameTranslation.r0a[3](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.frameTranslation.va[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.frameTranslation.va[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.frameTranslation.va[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.frameTranslation.wa[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.frameTranslation.wa[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.frameTranslation.wa[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.frameTranslation.aa[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.frameTranslation.aa[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.frameTranslation.aa[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.frameTranslation.za[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.frameTranslation.za[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.frameTranslation.za[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.frameTranslation.fa[1](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.frameTranslation.fa[2](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.frameTranslation.fa[3](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.frameTranslation.ta[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.frameTranslation.ta[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.frameTranslation.ta[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.frameTranslation.Sb[1,1](start = 1.0);
//   protected Real pendulum.cart.frameTranslation.Sb[1,2](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sb[1,3](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sb[2,1](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sb[2,2](start = 1.0);
//   protected Real pendulum.cart.frameTranslation.Sb[2,3](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sb[3,1](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sb[3,2](start = 0.0);
//   protected Real pendulum.cart.frameTranslation.Sb[3,3](start = 1.0);
//   protected Real pendulum.cart.frameTranslation.r0b[1](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.frameTranslation.r0b[2](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.frameTranslation.r0b[3](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.frameTranslation.vb[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.frameTranslation.vb[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.frameTranslation.vb[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.frameTranslation.wb[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.frameTranslation.wb[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.frameTranslation.wb[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.frameTranslation.ab[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.frameTranslation.ab[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.frameTranslation.ab[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.frameTranslation.zb[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.frameTranslation.zb[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.frameTranslation.zb[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.frameTranslation.fb[1](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.frameTranslation.fb[2](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.frameTranslation.fb[3](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.frameTranslation.tb[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.frameTranslation.tb[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.frameTranslation.tb[3](quantity = "Torque", unit = "N.m");
//   parameter Real pendulum.cart.frameTranslation.r[1](quantity = "Length", unit = "m") = pendulum.cart.r[1] "Vector from frame_a to frame_b resolved in frame_a";
//   parameter Real pendulum.cart.frameTranslation.r[2](quantity = "Length", unit = "m") = pendulum.cart.r[2] "Vector from frame_a to frame_b resolved in frame_a";
//   parameter Real pendulum.cart.frameTranslation.r[3](quantity = "Length", unit = "m") = pendulum.cart.r[3] "Vector from frame_a to frame_b resolved in frame_a";
//   protected Real pendulum.cart.frameTranslation.vaux[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.frameTranslation.vaux[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.frameTranslation.vaux[3](quantity = "Velocity", unit = "m/s");
//   Real pendulum.cart.body.frame_a.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.body.frame_a.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.body.frame_a.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.cart.body.frame_a.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.body.frame_a.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.body.frame_a.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.body.frame_a.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.body.frame_a.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.body.frame_a.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.body.frame_a.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.body.frame_a.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.body.frame_a.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.cart.body.frame_a.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.cart.body.frame_a.f[1](quantity = "Force", unit = "N");
//   Real pendulum.cart.body.frame_a.f[2](quantity = "Force", unit = "N");
//   Real pendulum.cart.body.frame_a.f[3](quantity = "Force", unit = "N");
//   Real pendulum.cart.body.frame_a.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.body.frame_a.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.body.frame_a.t[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.body.Sa[1,1](start = 1.0);
//   protected Real pendulum.cart.body.Sa[1,2](start = 0.0);
//   protected Real pendulum.cart.body.Sa[1,3](start = 0.0);
//   protected Real pendulum.cart.body.Sa[2,1](start = 0.0);
//   protected Real pendulum.cart.body.Sa[2,2](start = 1.0);
//   protected Real pendulum.cart.body.Sa[2,3](start = 0.0);
//   protected Real pendulum.cart.body.Sa[3,1](start = 0.0);
//   protected Real pendulum.cart.body.Sa[3,2](start = 0.0);
//   protected Real pendulum.cart.body.Sa[3,3](start = 1.0);
//   protected Real pendulum.cart.body.r0a[1](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.body.r0a[2](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.body.r0a[3](quantity = "Length", unit = "m");
//   protected Real pendulum.cart.body.va[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.body.va[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.body.va[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.cart.body.wa[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.body.wa[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.body.wa[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.cart.body.aa[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.body.aa[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.body.aa[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.cart.body.za[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.body.za[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.body.za[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.cart.body.fa[1](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.body.fa[2](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.body.fa[3](quantity = "Force", unit = "N");
//   protected Real pendulum.cart.body.ta[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.body.ta[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.cart.body.ta[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.cart.body.m(quantity = "Mass", unit = "kg", min = 0.0);
//   Real pendulum.cart.body.rCM[1](quantity = "Length", unit = "m");
//   Real pendulum.cart.body.rCM[2](quantity = "Length", unit = "m");
//   Real pendulum.cart.body.rCM[3](quantity = "Length", unit = "m");
//   Real pendulum.cart.body.I[1,1](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.cart.body.I[1,2](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.cart.body.I[1,3](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.cart.body.I[2,1](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.cart.body.I[2,2](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.cart.body.I[2,3](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.cart.body.I[3,1](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.cart.body.I[3,2](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.cart.body.I[3,3](quantity = "MomentOfInertia", unit = "kg.m2");
//   constant Real pendulum.pendulum.pi = 3.141592653589793;
//   Real pendulum.pendulum.frame_a.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frame_a.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frame_a.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frame_a.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_a.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_a.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_a.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_a.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_a.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_a.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_a.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_a.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_a.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_a.f[1](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frame_a.f[2](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frame_a.f[3](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frame_a.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frame_a.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frame_a.t[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frame_b.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frame_b.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frame_b.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frame_b.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_b.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_b.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_b.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_b.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_b.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_b.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_b.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_b.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frame_b.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frame_b.f[1](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frame_b.f[2](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frame_b.f[3](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frame_b.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frame_b.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frame_b.t[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.Sa[1,1](start = 1.0);
//   protected Real pendulum.pendulum.Sa[1,2](start = 0.0);
//   protected Real pendulum.pendulum.Sa[1,3](start = 0.0);
//   protected Real pendulum.pendulum.Sa[2,1](start = 0.0);
//   protected Real pendulum.pendulum.Sa[2,2](start = 1.0);
//   protected Real pendulum.pendulum.Sa[2,3](start = 0.0);
//   protected Real pendulum.pendulum.Sa[3,1](start = 0.0);
//   protected Real pendulum.pendulum.Sa[3,2](start = 0.0);
//   protected Real pendulum.pendulum.Sa[3,3](start = 1.0);
//   protected Real pendulum.pendulum.r0a[1](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.r0a[2](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.r0a[3](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.va[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.va[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.va[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.wa[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.wa[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.wa[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.aa[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.aa[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.aa[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.za[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.za[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.za[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.fa[1](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.fa[2](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.fa[3](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.ta[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.ta[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.ta[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.Sb[1,1](start = 1.0);
//   protected Real pendulum.pendulum.Sb[1,2](start = 0.0);
//   protected Real pendulum.pendulum.Sb[1,3](start = 0.0);
//   protected Real pendulum.pendulum.Sb[2,1](start = 0.0);
//   protected Real pendulum.pendulum.Sb[2,2](start = 1.0);
//   protected Real pendulum.pendulum.Sb[2,3](start = 0.0);
//   protected Real pendulum.pendulum.Sb[3,1](start = 0.0);
//   protected Real pendulum.pendulum.Sb[3,2](start = 0.0);
//   protected Real pendulum.pendulum.Sb[3,3](start = 1.0);
//   protected Real pendulum.pendulum.r0b[1](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.r0b[2](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.r0b[3](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.vb[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.vb[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.vb[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.wb[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.wb[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.wb[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.ab[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.ab[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.ab[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.zb[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.zb[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.zb[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.fb[1](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.fb[2](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.fb[3](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.tb[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.tb[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.tb[3](quantity = "Torque", unit = "N.m");
//   parameter Real pendulum.pendulum.r[1](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to frame_b, resolved in frame_a";
//   parameter Real pendulum.pendulum.r[2](quantity = "Length", unit = "m") = pendulum.l_pendulum "Vector from frame_a to frame_b, resolved in frame_a";
//   parameter Real pendulum.pendulum.r[3](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to frame_b, resolved in frame_a";
//   parameter Real pendulum.pendulum.r0[1](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to left circle center, resolved in frame_a";
//   parameter Real pendulum.pendulum.r0[2](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to left circle center, resolved in frame_a";
//   parameter Real pendulum.pendulum.r0[3](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to left circle center, resolved in frame_a";
//   parameter Real pendulum.pendulum.Axis[1](quantity = "Length", unit = "m") = pendulum.pendulum.r[1] - pendulum.pendulum.r0[1] "Vector in direction of cylinder axis, resolved in frame_a";
//   parameter Real pendulum.pendulum.Axis[2](quantity = "Length", unit = "m") = pendulum.pendulum.r[2] - pendulum.pendulum.r0[2] "Vector in direction of cylinder axis, resolved in frame_a";
//   parameter Real pendulum.pendulum.Axis[3](quantity = "Length", unit = "m") = pendulum.pendulum.r[3] - pendulum.pendulum.r0[3] "Vector in direction of cylinder axis, resolved in frame_a";
//   parameter Real pendulum.pendulum.length(quantity = "Length", unit = "m") = sqrt(pendulum.pendulum.Axis[1] ^ 2.0 + pendulum.pendulum.Axis[2] ^ 2.0 + pendulum.pendulum.Axis[3] ^ 2.0) "Length of cylinder";
//   parameter Real pendulum.pendulum.Radius(quantity = "Length", unit = "m", min = 0.0) = pendulum.r_pendulum "Radius of cylinder";
//   parameter Real pendulum.pendulum.InnerRadius(quantity = "Length", unit = "m", min = 0.0, max = pendulum.pendulum.Radius) = 0.0 "Inner radius of cylinder";
//   parameter Real pendulum.pendulum.rho(min = 0.0) = pendulum.rho_pendulum "Density of material [g/cm^3]";
//   parameter Real pendulum.pendulum.Material[1] = 0.0 "Color and specular coefficient";
//   parameter Real pendulum.pendulum.Material[2] = 0.0 "Color and specular coefficient";
//   parameter Real pendulum.pendulum.Material[3] = 1.0 "Color and specular coefficient";
//   parameter Real pendulum.pendulum.Material[4] = 0.5 "Color and specular coefficient";
//   Real pendulum.pendulum.Scyl[1,1];
//   Real pendulum.pendulum.Scyl[1,2];
//   Real pendulum.pendulum.Scyl[1,3];
//   Real pendulum.pendulum.Scyl[2,1];
//   Real pendulum.pendulum.Scyl[2,2];
//   Real pendulum.pendulum.Scyl[2,3];
//   Real pendulum.pendulum.Scyl[3,1];
//   Real pendulum.pendulum.Scyl[3,2];
//   Real pendulum.pendulum.Scyl[3,3];
//   Real pendulum.pendulum.mo(quantity = "Mass", unit = "kg", min = 0.0);
//   Real pendulum.pendulum.mi(quantity = "Mass", unit = "kg", min = 0.0);
//   Real pendulum.pendulum.I22(quantity = "MomentOfInertia", unit = "kg.m2");
//   parameter Real pendulum.pendulum.box.r0[1] = pendulum.pendulum.r0[1] "Origin of visual object.";
//   parameter Real pendulum.pendulum.box.r0[2] = pendulum.pendulum.r0[2] "Origin of visual object.";
//   parameter Real pendulum.pendulum.box.r0[3] = pendulum.pendulum.r0[3] "Origin of visual object.";
//   parameter Real pendulum.pendulum.box.length = pendulum.pendulum.length "Length of visual object.";
//   parameter Real pendulum.pendulum.box.Width = 2.0 * pendulum.pendulum.Radius "Width of visual object.";
//   parameter Real pendulum.pendulum.box.Height = 2.0 * pendulum.pendulum.Radius "Height of visual object.";
//   parameter Real pendulum.pendulum.box.LengthDirection[1] = pendulum.pendulum.Axis[1] "Vector in length direction.";
//   parameter Real pendulum.pendulum.box.LengthDirection[2] = pendulum.pendulum.Axis[2] "Vector in length direction.";
//   parameter Real pendulum.pendulum.box.LengthDirection[3] = pendulum.pendulum.Axis[3] "Vector in length direction.";
//   parameter Real pendulum.pendulum.box.WidthDirection[1] = 0.0 "Vector in width direction.";
//   parameter Real pendulum.pendulum.box.WidthDirection[2] = 1.0 "Vector in width direction.";
//   parameter Real pendulum.pendulum.box.WidthDirection[3] = 0.0 "Vector in width direction.";
//   parameter String pendulum.pendulum.box.Shape = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring)";
//   parameter Real pendulum.pendulum.box.Material[1] = pendulum.pendulum.Material[1] "Color and specular coefficient.";
//   parameter Real pendulum.pendulum.box.Material[2] = pendulum.pendulum.Material[2] "Color and specular coefficient.";
//   parameter Real pendulum.pendulum.box.Material[3] = pendulum.pendulum.Material[3] "Color and specular coefficient.";
//   parameter Real pendulum.pendulum.box.Material[4] = pendulum.pendulum.Material[4] "Color and specular coefficient.";
//   parameter Real pendulum.pendulum.box.Extra = pendulum.pendulum.InnerRadius / pendulum.pendulum.Radius "Additional size data for some of the shape types";
//   Real pendulum.pendulum.box.S[1,1] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.S[1,2] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.S[1,3] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.S[2,1] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.S[2,2] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.S[2,3] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.S[3,1] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.S[3,2] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.S[3,3] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.Sshape[1,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.Sshape[1,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.Sshape[1,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.Sshape[2,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.Sshape[2,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.Sshape[2,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.Sshape[3,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.Sshape[3,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.Sshape[3,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.r[1] "Position of visual object.";
//   Real pendulum.pendulum.box.r[2] "Position of visual object.";
//   Real pendulum.pendulum.box.r[3] "Position of visual object.";
//   Real pendulum.pendulum.box.nLength[1];
//   Real pendulum.pendulum.box.nLength[2];
//   Real pendulum.pendulum.box.nLength[3];
//   Real pendulum.pendulum.box.nWidth[1];
//   Real pendulum.pendulum.box.nWidth[2];
//   Real pendulum.pendulum.box.nWidth[3];
//   Real pendulum.pendulum.box.nHeight[1];
//   Real pendulum.pendulum.box.nHeight[2];
//   Real pendulum.pendulum.box.nHeight[3];
//   parameter String pendulum.pendulum.box.mcShape.shapeType = pendulum.pendulum.box.Shape "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring)";
//   Real pendulum.pendulum.box.mcShape.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   Real pendulum.pendulum.box.mcShape.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   Real pendulum.pendulum.box.mcShape.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   Real pendulum.pendulum.box.mcShape.lengthDirection[1] "Vector in length direction, resolved in object frame";
//   Real pendulum.pendulum.box.mcShape.lengthDirection[2] "Vector in length direction, resolved in object frame";
//   Real pendulum.pendulum.box.mcShape.lengthDirection[3] "Vector in length direction, resolved in object frame";
//   Real pendulum.pendulum.box.mcShape.widthDirection[1] "Vector in width direction, resolved in object frame";
//   Real pendulum.pendulum.box.mcShape.widthDirection[2] "Vector in width direction, resolved in object frame";
//   Real pendulum.pendulum.box.mcShape.widthDirection[3] "Vector in width direction, resolved in object frame";
//   Real pendulum.pendulum.box.mcShape.length(quantity = "Length", unit = "m") = pendulum.pendulum.box.length "Length of visual object";
//   Real pendulum.pendulum.box.mcShape.width(quantity = "Length", unit = "m") = pendulum.pendulum.box.Width "Width of visual object";
//   Real pendulum.pendulum.box.mcShape.height(quantity = "Length", unit = "m") = pendulum.pendulum.box.Height "Height of visual object";
//   Real pendulum.pendulum.box.mcShape.extra = pendulum.pendulum.box.Extra "Additional size data for some of the shape types";
//   Real pendulum.pendulum.box.mcShape.color[1] "Color of shape";
//   Real pendulum.pendulum.box.mcShape.color[2] "Color of shape";
//   Real pendulum.pendulum.box.mcShape.color[3] "Color of shape";
//   Real pendulum.pendulum.box.mcShape.specularCoefficient = pendulum.pendulum.box.Material[4];
//   Real pendulum.pendulum.box.mcShape.S[1,1] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.S[1,2] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.S[1,3] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.S[2,1] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.S[2,2] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.S[2,3] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.S[3,1] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.S[3,2] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.S[3,3] "3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.Sshape[1,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.Sshape[1,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.Sshape[1,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.Sshape[2,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.Sshape[2,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.Sshape[2,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.Sshape[3,1] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.Sshape[3,2] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.Sshape[3,3] "local 3 x 3 transformation matrix.";
//   Real pendulum.pendulum.box.mcShape.rxvisobj[1] "x-axis unit vector of shape, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.rxvisobj[2] "x-axis unit vector of shape, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.rxvisobj[3] "x-axis unit vector of shape, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.ryvisobj[1] "y-axis unit vector of shape, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.ryvisobj[2] "y-axis unit vector of shape, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.ryvisobj[3] "y-axis unit vector of shape, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.rvisobj[1](quantity = "Length", unit = "m") "position vector from world frame to shape frame, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.rvisobj[2](quantity = "Length", unit = "m") "position vector from world frame to shape frame, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.rvisobj[3](quantity = "Length", unit = "m") "position vector from world frame to shape frame, resolved in world frame";
//   Real pendulum.pendulum.box.mcShape.abs_n_x = sqrt(pendulum.pendulum.box.mcShape.lengthDirection[1] ^ 2.0 + pendulum.pendulum.box.mcShape.lengthDirection[2] ^ 2.0 + pendulum.pendulum.box.mcShape.lengthDirection[3] ^ 2.0);
//   Real pendulum.pendulum.box.mcShape.e_x[1];
//   Real pendulum.pendulum.box.mcShape.e_x[2];
//   Real pendulum.pendulum.box.mcShape.e_x[3];
//   Real pendulum.pendulum.box.mcShape.n_z_aux[1];
//   Real pendulum.pendulum.box.mcShape.n_z_aux[2];
//   Real pendulum.pendulum.box.mcShape.n_z_aux[3];
//   Real pendulum.pendulum.box.mcShape.e_y[1];
//   Real pendulum.pendulum.box.mcShape.e_y[2];
//   Real pendulum.pendulum.box.mcShape.e_y[3];
//   Real pendulum.pendulum.box.mcShape.e_z[1];
//   Real pendulum.pendulum.box.mcShape.e_z[2];
//   Real pendulum.pendulum.box.mcShape.e_z[3];
//   protected Real pendulum.pendulum.box.mcShape.Form;
//   protected Real pendulum.pendulum.box.mcShape.size[1](quantity = "Length", unit = "m") "{length,width,height} of shape";
//   protected Real pendulum.pendulum.box.mcShape.size[2](quantity = "Length", unit = "m") "{length,width,height} of shape";
//   protected Real pendulum.pendulum.box.mcShape.size[3](quantity = "Length", unit = "m") "{length,width,height} of shape";
//   protected Real pendulum.pendulum.box.mcShape.Material;
//   protected Real pendulum.pendulum.box.mcShape.Extra;
//   constant Real pendulum.pendulum.frameTranslation.pi = 3.141592653589793;
//   Real pendulum.pendulum.frameTranslation.frame_a.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_a.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_a.f[1](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frameTranslation.frame_a.f[2](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frameTranslation.frame_a.f[3](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frameTranslation.frame_a.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frameTranslation.frame_a.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frameTranslation.frame_a.t[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frameTranslation.frame_b.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.frameTranslation.frame_b.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.frameTranslation.frame_b.f[1](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frameTranslation.frame_b.f[2](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frameTranslation.frame_b.f[3](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.frameTranslation.frame_b.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frameTranslation.frame_b.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.frameTranslation.frame_b.t[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.frameTranslation.Sa[1,1](start = 1.0);
//   protected Real pendulum.pendulum.frameTranslation.Sa[1,2](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sa[1,3](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sa[2,1](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sa[2,2](start = 1.0);
//   protected Real pendulum.pendulum.frameTranslation.Sa[2,3](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sa[3,1](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sa[3,2](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sa[3,3](start = 1.0);
//   protected Real pendulum.pendulum.frameTranslation.r0a[1](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.frameTranslation.r0a[2](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.frameTranslation.r0a[3](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.frameTranslation.va[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.frameTranslation.va[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.frameTranslation.va[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.frameTranslation.wa[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.frameTranslation.wa[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.frameTranslation.wa[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.frameTranslation.aa[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.frameTranslation.aa[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.frameTranslation.aa[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.frameTranslation.za[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.frameTranslation.za[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.frameTranslation.za[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.frameTranslation.fa[1](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.frameTranslation.fa[2](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.frameTranslation.fa[3](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.frameTranslation.ta[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.frameTranslation.ta[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.frameTranslation.ta[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.frameTranslation.Sb[1,1](start = 1.0);
//   protected Real pendulum.pendulum.frameTranslation.Sb[1,2](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sb[1,3](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sb[2,1](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sb[2,2](start = 1.0);
//   protected Real pendulum.pendulum.frameTranslation.Sb[2,3](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sb[3,1](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sb[3,2](start = 0.0);
//   protected Real pendulum.pendulum.frameTranslation.Sb[3,3](start = 1.0);
//   protected Real pendulum.pendulum.frameTranslation.r0b[1](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.frameTranslation.r0b[2](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.frameTranslation.r0b[3](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.frameTranslation.vb[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.frameTranslation.vb[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.frameTranslation.vb[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.frameTranslation.wb[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.frameTranslation.wb[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.frameTranslation.wb[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.frameTranslation.ab[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.frameTranslation.ab[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.frameTranslation.ab[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.frameTranslation.zb[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.frameTranslation.zb[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.frameTranslation.zb[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.frameTranslation.fb[1](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.frameTranslation.fb[2](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.frameTranslation.fb[3](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.frameTranslation.tb[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.frameTranslation.tb[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.frameTranslation.tb[3](quantity = "Torque", unit = "N.m");
//   parameter Real pendulum.pendulum.frameTranslation.r[1](quantity = "Length", unit = "m") = pendulum.pendulum.r[1] "Vector from frame_a to frame_b resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.r[2](quantity = "Length", unit = "m") = pendulum.pendulum.r[2] "Vector from frame_a to frame_b resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.r[3](quantity = "Length", unit = "m") = pendulum.pendulum.r[3] "Vector from frame_a to frame_b resolved in frame_a";
//   protected Real pendulum.pendulum.frameTranslation.vaux[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.frameTranslation.vaux[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.frameTranslation.vaux[3](quantity = "Velocity", unit = "m/s");
//   Real pendulum.pendulum.body.frame_a.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.body.frame_a.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.body.frame_a.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulum.body.frame_a.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.body.frame_a.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.body.frame_a.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.body.frame_a.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.body.frame_a.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.body.frame_a.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.body.frame_a.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.body.frame_a.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.body.frame_a.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulum.body.frame_a.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulum.body.frame_a.f[1](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.body.frame_a.f[2](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.body.frame_a.f[3](quantity = "Force", unit = "N");
//   Real pendulum.pendulum.body.frame_a.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.body.frame_a.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.body.frame_a.t[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.body.Sa[1,1](start = 1.0);
//   protected Real pendulum.pendulum.body.Sa[1,2](start = 0.0);
//   protected Real pendulum.pendulum.body.Sa[1,3](start = 0.0);
//   protected Real pendulum.pendulum.body.Sa[2,1](start = 0.0);
//   protected Real pendulum.pendulum.body.Sa[2,2](start = 1.0);
//   protected Real pendulum.pendulum.body.Sa[2,3](start = 0.0);
//   protected Real pendulum.pendulum.body.Sa[3,1](start = 0.0);
//   protected Real pendulum.pendulum.body.Sa[3,2](start = 0.0);
//   protected Real pendulum.pendulum.body.Sa[3,3](start = 1.0);
//   protected Real pendulum.pendulum.body.r0a[1](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.body.r0a[2](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.body.r0a[3](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulum.body.va[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.body.va[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.body.va[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulum.body.wa[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.body.wa[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.body.wa[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulum.body.aa[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.body.aa[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.body.aa[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulum.body.za[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.body.za[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.body.za[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulum.body.fa[1](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.body.fa[2](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.body.fa[3](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulum.body.ta[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.body.ta[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulum.body.ta[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulum.body.m(quantity = "Mass", unit = "kg", min = 0.0);
//   Real pendulum.pendulum.body.rCM[1](quantity = "Length", unit = "m");
//   Real pendulum.pendulum.body.rCM[2](quantity = "Length", unit = "m");
//   Real pendulum.pendulum.body.rCM[3](quantity = "Length", unit = "m");
//   Real pendulum.pendulum.body.I[1,1](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.pendulum.body.I[1,2](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.pendulum.body.I[1,3](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.pendulum.body.I[2,1](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.pendulum.body.I[2,2](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.pendulum.body.I[2,3](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.pendulum.body.I[3,1](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.pendulum.body.I[3,2](quantity = "MomentOfInertia", unit = "kg.m2");
//   Real pendulum.pendulum.body.I[3,3](quantity = "MomentOfInertia", unit = "kg.m2");
//   constant Real pendulum.pendulumJoint.pi = 3.141592653589793;
//   Real pendulum.pendulumJoint.frame_a.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulumJoint.frame_a.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulumJoint.frame_a.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulumJoint.frame_a.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_a.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_a.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_a.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_a.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_a.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_a.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_a.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_a.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_a.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_a.f[1](quantity = "Force", unit = "N");
//   Real pendulum.pendulumJoint.frame_a.f[2](quantity = "Force", unit = "N");
//   Real pendulum.pendulumJoint.frame_a.f[3](quantity = "Force", unit = "N");
//   Real pendulum.pendulumJoint.frame_a.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulumJoint.frame_a.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulumJoint.frame_a.t[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulumJoint.frame_b.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulumJoint.frame_b.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulumJoint.frame_b.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.pendulumJoint.frame_b.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_b.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_b.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_b.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_b.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_b.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_b.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_b.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_b.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.pendulumJoint.frame_b.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.pendulumJoint.frame_b.f[1](quantity = "Force", unit = "N");
//   Real pendulum.pendulumJoint.frame_b.f[2](quantity = "Force", unit = "N");
//   Real pendulum.pendulumJoint.frame_b.f[3](quantity = "Force", unit = "N");
//   Real pendulum.pendulumJoint.frame_b.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulumJoint.frame_b.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulumJoint.frame_b.t[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulumJoint.Sa[1,1](start = 1.0);
//   protected Real pendulum.pendulumJoint.Sa[1,2](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sa[1,3](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sa[2,1](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sa[2,2](start = 1.0);
//   protected Real pendulum.pendulumJoint.Sa[2,3](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sa[3,1](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sa[3,2](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sa[3,3](start = 1.0);
//   protected Real pendulum.pendulumJoint.r0a[1](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulumJoint.r0a[2](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulumJoint.r0a[3](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulumJoint.va[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulumJoint.va[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulumJoint.va[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulumJoint.wa[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulumJoint.wa[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulumJoint.wa[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulumJoint.aa[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulumJoint.aa[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulumJoint.aa[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulumJoint.za[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulumJoint.za[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulumJoint.za[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulumJoint.fa[1](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulumJoint.fa[2](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulumJoint.fa[3](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulumJoint.ta[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulumJoint.ta[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulumJoint.ta[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulumJoint.Sb[1,1](start = 1.0);
//   protected Real pendulum.pendulumJoint.Sb[1,2](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sb[1,3](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sb[2,1](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sb[2,2](start = 1.0);
//   protected Real pendulum.pendulumJoint.Sb[2,3](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sb[3,1](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sb[3,2](start = 0.0);
//   protected Real pendulum.pendulumJoint.Sb[3,3](start = 1.0);
//   protected Real pendulum.pendulumJoint.r0b[1](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulumJoint.r0b[2](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulumJoint.r0b[3](quantity = "Length", unit = "m");
//   protected Real pendulum.pendulumJoint.vb[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulumJoint.vb[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulumJoint.vb[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.pendulumJoint.wb[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulumJoint.wb[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulumJoint.wb[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.pendulumJoint.ab[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulumJoint.ab[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulumJoint.ab[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.pendulumJoint.zb[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulumJoint.zb[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulumJoint.zb[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.pendulumJoint.fb[1](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulumJoint.fb[2](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulumJoint.fb[3](quantity = "Force", unit = "N");
//   protected Real pendulum.pendulumJoint.tb[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulumJoint.tb[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.pendulumJoint.tb[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.pendulumJoint.S_rel[1,1];
//   Real pendulum.pendulumJoint.S_rel[1,2];
//   Real pendulum.pendulumJoint.S_rel[1,3];
//   Real pendulum.pendulumJoint.S_rel[2,1];
//   Real pendulum.pendulumJoint.S_rel[2,2];
//   Real pendulum.pendulumJoint.S_rel[2,3];
//   Real pendulum.pendulumJoint.S_rel[3,1];
//   Real pendulum.pendulumJoint.S_rel[3,2];
//   Real pendulum.pendulumJoint.S_rel[3,3];
//   Real pendulum.pendulumJoint.r_rela[1](quantity = "Length", unit = "m");
//   Real pendulum.pendulumJoint.r_rela[2](quantity = "Length", unit = "m");
//   Real pendulum.pendulumJoint.r_rela[3](quantity = "Length", unit = "m");
//   Real pendulum.pendulumJoint.v_rela[1](quantity = "Velocity", unit = "m/s");
//   Real pendulum.pendulumJoint.v_rela[2](quantity = "Velocity", unit = "m/s");
//   Real pendulum.pendulumJoint.v_rela[3](quantity = "Velocity", unit = "m/s");
//   Real pendulum.pendulumJoint.w_rela[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   Real pendulum.pendulumJoint.w_rela[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   Real pendulum.pendulumJoint.w_rela[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   Real pendulum.pendulumJoint.a_rela[1](quantity = "Acceleration", unit = "m/s2");
//   Real pendulum.pendulumJoint.a_rela[2](quantity = "Acceleration", unit = "m/s2");
//   Real pendulum.pendulumJoint.a_rela[3](quantity = "Acceleration", unit = "m/s2");
//   Real pendulum.pendulumJoint.z_rela[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   Real pendulum.pendulumJoint.z_rela[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   Real pendulum.pendulumJoint.z_rela[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   parameter Real pendulum.pendulumJoint.n[1] = 0.0 "Axis of rotation resolved in frame_a (= same as in frame_b)";
//   parameter Real pendulum.pendulumJoint.n[2] = 0.0 "Axis of rotation resolved in frame_a (= same as in frame_b)";
//   parameter Real pendulum.pendulumJoint.n[3] = 1.0 "Axis of rotation resolved in frame_a (= same as in frame_b)";
//   parameter Real pendulum.pendulumJoint.q0 = 0.0 "Rotation angle offset (see info) [deg]";
//   parameter Boolean pendulum.pendulumJoint.startValueFixed = false "true, if start values of q, qd are fixed";
//   Real pendulum.pendulumJoint.q(quantity = "Angle", unit = "rad", displayUnit = "deg", fixed = false);
//   Real pendulum.pendulumJoint.qd(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min", start = 0.01, fixed = false);
//   Real pendulum.pendulumJoint.qdd(quantity = "AngularAcceleration", unit = "rad/s2");
//   Real pendulum.pendulumJoint.qq(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   Real pendulum.pendulumJoint.nn[1];
//   Real pendulum.pendulumJoint.nn[2];
//   Real pendulum.pendulumJoint.nn[3];
//   Real pendulum.pendulumJoint.sinq;
//   Real pendulum.pendulumJoint.cosq;
//   Real pendulum.pendulumJoint.axis.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real pendulum.pendulumJoint.axis.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real pendulum.pendulumJoint.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real pendulum.pendulumJoint.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   constant Real pendulum.toMidCart.pi = 3.141592653589793;
//   Real pendulum.toMidCart.frame_a.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.toMidCart.frame_a.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.toMidCart.frame_a.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.toMidCart.frame_a.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_a.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_a.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_a.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_a.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_a.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_a.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_a.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_a.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_a.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_a.f[1](quantity = "Force", unit = "N");
//   Real pendulum.toMidCart.frame_a.f[2](quantity = "Force", unit = "N");
//   Real pendulum.toMidCart.frame_a.f[3](quantity = "Force", unit = "N");
//   Real pendulum.toMidCart.frame_a.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.toMidCart.frame_a.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.toMidCart.frame_a.t[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.toMidCart.frame_b.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.toMidCart.frame_b.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.toMidCart.frame_b.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.toMidCart.frame_b.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_b.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_b.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_b.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_b.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_b.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_b.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_b.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_b.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.toMidCart.frame_b.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.toMidCart.frame_b.f[1](quantity = "Force", unit = "N");
//   Real pendulum.toMidCart.frame_b.f[2](quantity = "Force", unit = "N");
//   Real pendulum.toMidCart.frame_b.f[3](quantity = "Force", unit = "N");
//   Real pendulum.toMidCart.frame_b.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.toMidCart.frame_b.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.toMidCart.frame_b.t[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.toMidCart.Sa[1,1](start = 1.0);
//   protected Real pendulum.toMidCart.Sa[1,2](start = 0.0);
//   protected Real pendulum.toMidCart.Sa[1,3](start = 0.0);
//   protected Real pendulum.toMidCart.Sa[2,1](start = 0.0);
//   protected Real pendulum.toMidCart.Sa[2,2](start = 1.0);
//   protected Real pendulum.toMidCart.Sa[2,3](start = 0.0);
//   protected Real pendulum.toMidCart.Sa[3,1](start = 0.0);
//   protected Real pendulum.toMidCart.Sa[3,2](start = 0.0);
//   protected Real pendulum.toMidCart.Sa[3,3](start = 1.0);
//   protected Real pendulum.toMidCart.r0a[1](quantity = "Length", unit = "m");
//   protected Real pendulum.toMidCart.r0a[2](quantity = "Length", unit = "m");
//   protected Real pendulum.toMidCart.r0a[3](quantity = "Length", unit = "m");
//   protected Real pendulum.toMidCart.va[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.toMidCart.va[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.toMidCart.va[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.toMidCart.wa[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.toMidCart.wa[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.toMidCart.wa[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.toMidCart.aa[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.toMidCart.aa[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.toMidCart.aa[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.toMidCart.za[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.toMidCart.za[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.toMidCart.za[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.toMidCart.fa[1](quantity = "Force", unit = "N");
//   protected Real pendulum.toMidCart.fa[2](quantity = "Force", unit = "N");
//   protected Real pendulum.toMidCart.fa[3](quantity = "Force", unit = "N");
//   protected Real pendulum.toMidCart.ta[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.toMidCart.ta[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.toMidCart.ta[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.toMidCart.Sb[1,1](start = 1.0);
//   protected Real pendulum.toMidCart.Sb[1,2](start = 0.0);
//   protected Real pendulum.toMidCart.Sb[1,3](start = 0.0);
//   protected Real pendulum.toMidCart.Sb[2,1](start = 0.0);
//   protected Real pendulum.toMidCart.Sb[2,2](start = 1.0);
//   protected Real pendulum.toMidCart.Sb[2,3](start = 0.0);
//   protected Real pendulum.toMidCart.Sb[3,1](start = 0.0);
//   protected Real pendulum.toMidCart.Sb[3,2](start = 0.0);
//   protected Real pendulum.toMidCart.Sb[3,3](start = 1.0);
//   protected Real pendulum.toMidCart.r0b[1](quantity = "Length", unit = "m");
//   protected Real pendulum.toMidCart.r0b[2](quantity = "Length", unit = "m");
//   protected Real pendulum.toMidCart.r0b[3](quantity = "Length", unit = "m");
//   protected Real pendulum.toMidCart.vb[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.toMidCart.vb[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.toMidCart.vb[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.toMidCart.wb[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.toMidCart.wb[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.toMidCart.wb[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.toMidCart.ab[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.toMidCart.ab[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.toMidCart.ab[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.toMidCart.zb[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.toMidCart.zb[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.toMidCart.zb[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.toMidCart.fb[1](quantity = "Force", unit = "N");
//   protected Real pendulum.toMidCart.fb[2](quantity = "Force", unit = "N");
//   protected Real pendulum.toMidCart.fb[3](quantity = "Force", unit = "N");
//   protected Real pendulum.toMidCart.tb[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.toMidCart.tb[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.toMidCart.tb[3](quantity = "Torque", unit = "N.m");
//   parameter Real pendulum.toMidCart.r[1](quantity = "Length", unit = "m") = (-0.5) * pendulum.cart.r[1] "Vector from frame_a to frame_b resolved in frame_a";
//   parameter Real pendulum.toMidCart.r[2](quantity = "Length", unit = "m") = 0.5 * pendulum.cart.Height "Vector from frame_a to frame_b resolved in frame_a";
//   parameter Real pendulum.toMidCart.r[3](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to frame_b resolved in frame_a";
//   protected Real pendulum.toMidCart.vaux[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.toMidCart.vaux[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.toMidCart.vaux[3](quantity = "Velocity", unit = "m/s");
//   constant Real pendulum.sliderConstraint.pi = 3.141592653589793;
//   Real pendulum.sliderConstraint.frame_a.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.sliderConstraint.frame_a.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.sliderConstraint.frame_a.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.sliderConstraint.frame_a.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_a.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_a.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_a.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_a.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_a.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_a.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_a.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_a.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_a.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_a.f[1](quantity = "Force", unit = "N");
//   Real pendulum.sliderConstraint.frame_a.f[2](quantity = "Force", unit = "N");
//   Real pendulum.sliderConstraint.frame_a.f[3](quantity = "Force", unit = "N");
//   Real pendulum.sliderConstraint.frame_a.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.sliderConstraint.frame_a.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.sliderConstraint.frame_a.t[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.sliderConstraint.frame_b.r0[1](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.sliderConstraint.frame_b.r0[2](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.sliderConstraint.frame_b.r0[3](quantity = "Length", unit = "m") "Position vector from inertial system to frame origin, resolved in inertial system";
//   Real pendulum.sliderConstraint.frame_b.S[1,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_b.S[1,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_b.S[1,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_b.S[2,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_b.S[2,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_b.S[2,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_b.S[3,1] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_b.S[3,2] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_b.S[3,3] "Transformation matrix from frame_a to inertial system";
//   Real pendulum.sliderConstraint.frame_b.v[1](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.v[2](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.v[3](quantity = "Velocity", unit = "m/s") "Absolute velocity of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.w[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.w[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.w[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.a[1](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.a[2](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.a[3](quantity = "Acceleration", unit = "m/s2") "Absolute acceleration of frame origin, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.z[1](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.z[2](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.z[3](quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of frame_a, resolved in frame_a";
//   Real pendulum.sliderConstraint.frame_b.f[1](quantity = "Force", unit = "N");
//   Real pendulum.sliderConstraint.frame_b.f[2](quantity = "Force", unit = "N");
//   Real pendulum.sliderConstraint.frame_b.f[3](quantity = "Force", unit = "N");
//   Real pendulum.sliderConstraint.frame_b.t[1](quantity = "Torque", unit = "N.m");
//   Real pendulum.sliderConstraint.frame_b.t[2](quantity = "Torque", unit = "N.m");
//   Real pendulum.sliderConstraint.frame_b.t[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.sliderConstraint.Sa[1,1](start = 1.0);
//   protected Real pendulum.sliderConstraint.Sa[1,2](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sa[1,3](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sa[2,1](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sa[2,2](start = 1.0);
//   protected Real pendulum.sliderConstraint.Sa[2,3](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sa[3,1](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sa[3,2](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sa[3,3](start = 1.0);
//   protected Real pendulum.sliderConstraint.r0a[1](quantity = "Length", unit = "m");
//   protected Real pendulum.sliderConstraint.r0a[2](quantity = "Length", unit = "m");
//   protected Real pendulum.sliderConstraint.r0a[3](quantity = "Length", unit = "m");
//   protected Real pendulum.sliderConstraint.va[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.sliderConstraint.va[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.sliderConstraint.va[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.sliderConstraint.wa[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.sliderConstraint.wa[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.sliderConstraint.wa[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.sliderConstraint.aa[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.sliderConstraint.aa[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.sliderConstraint.aa[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.sliderConstraint.za[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.sliderConstraint.za[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.sliderConstraint.za[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.sliderConstraint.fa[1](quantity = "Force", unit = "N");
//   protected Real pendulum.sliderConstraint.fa[2](quantity = "Force", unit = "N");
//   protected Real pendulum.sliderConstraint.fa[3](quantity = "Force", unit = "N");
//   protected Real pendulum.sliderConstraint.ta[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.sliderConstraint.ta[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.sliderConstraint.ta[3](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.sliderConstraint.Sb[1,1](start = 1.0);
//   protected Real pendulum.sliderConstraint.Sb[1,2](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sb[1,3](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sb[2,1](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sb[2,2](start = 1.0);
//   protected Real pendulum.sliderConstraint.Sb[2,3](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sb[3,1](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sb[3,2](start = 0.0);
//   protected Real pendulum.sliderConstraint.Sb[3,3](start = 1.0);
//   protected Real pendulum.sliderConstraint.r0b[1](quantity = "Length", unit = "m");
//   protected Real pendulum.sliderConstraint.r0b[2](quantity = "Length", unit = "m");
//   protected Real pendulum.sliderConstraint.r0b[3](quantity = "Length", unit = "m");
//   protected Real pendulum.sliderConstraint.vb[1](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.sliderConstraint.vb[2](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.sliderConstraint.vb[3](quantity = "Velocity", unit = "m/s");
//   protected Real pendulum.sliderConstraint.wb[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.sliderConstraint.wb[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.sliderConstraint.wb[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   protected Real pendulum.sliderConstraint.ab[1](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.sliderConstraint.ab[2](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.sliderConstraint.ab[3](quantity = "Acceleration", unit = "m/s2");
//   protected Real pendulum.sliderConstraint.zb[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.sliderConstraint.zb[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.sliderConstraint.zb[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   protected Real pendulum.sliderConstraint.fb[1](quantity = "Force", unit = "N");
//   protected Real pendulum.sliderConstraint.fb[2](quantity = "Force", unit = "N");
//   protected Real pendulum.sliderConstraint.fb[3](quantity = "Force", unit = "N");
//   protected Real pendulum.sliderConstraint.tb[1](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.sliderConstraint.tb[2](quantity = "Torque", unit = "N.m");
//   protected Real pendulum.sliderConstraint.tb[3](quantity = "Torque", unit = "N.m");
//   Real pendulum.sliderConstraint.S_rel[1,1];
//   Real pendulum.sliderConstraint.S_rel[1,2];
//   Real pendulum.sliderConstraint.S_rel[1,3];
//   Real pendulum.sliderConstraint.S_rel[2,1];
//   Real pendulum.sliderConstraint.S_rel[2,2];
//   Real pendulum.sliderConstraint.S_rel[2,3];
//   Real pendulum.sliderConstraint.S_rel[3,1];
//   Real pendulum.sliderConstraint.S_rel[3,2];
//   Real pendulum.sliderConstraint.S_rel[3,3];
//   Real pendulum.sliderConstraint.r_rela[1](quantity = "Length", unit = "m");
//   Real pendulum.sliderConstraint.r_rela[2](quantity = "Length", unit = "m");
//   Real pendulum.sliderConstraint.r_rela[3](quantity = "Length", unit = "m");
//   Real pendulum.sliderConstraint.v_rela[1](quantity = "Velocity", unit = "m/s");
//   Real pendulum.sliderConstraint.v_rela[2](quantity = "Velocity", unit = "m/s");
//   Real pendulum.sliderConstraint.v_rela[3](quantity = "Velocity", unit = "m/s");
//   Real pendulum.sliderConstraint.w_rela[1](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   Real pendulum.sliderConstraint.w_rela[2](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   Real pendulum.sliderConstraint.w_rela[3](quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min");
//   Real pendulum.sliderConstraint.a_rela[1](quantity = "Acceleration", unit = "m/s2");
//   Real pendulum.sliderConstraint.a_rela[2](quantity = "Acceleration", unit = "m/s2");
//   Real pendulum.sliderConstraint.a_rela[3](quantity = "Acceleration", unit = "m/s2");
//   Real pendulum.sliderConstraint.z_rela[1](quantity = "AngularAcceleration", unit = "rad/s2");
//   Real pendulum.sliderConstraint.z_rela[2](quantity = "AngularAcceleration", unit = "rad/s2");
//   Real pendulum.sliderConstraint.z_rela[3](quantity = "AngularAcceleration", unit = "rad/s2");
//   parameter Real pendulum.sliderConstraint.n[1] = 1.0 "Axis of translation resolved in frame_a (= same as in frame_b)";
//   parameter Real pendulum.sliderConstraint.n[2] = 0.0 "Axis of translation resolved in frame_a (= same as in frame_b)";
//   parameter Real pendulum.sliderConstraint.n[3] = 0.0 "Axis of translation resolved in frame_a (= same as in frame_b)";
//   parameter Real pendulum.sliderConstraint.q0(quantity = "Length", unit = "m") = 0.0 "Relative distance offset(see info)";
//   parameter Boolean pendulum.sliderConstraint.startValueFixed = false "true, if start values of q, qd are fixed";
//   Real pendulum.sliderConstraint.q(quantity = "Length", unit = "m", fixed = false, stateSelect = StateSelect.prefer);
//   Real pendulum.sliderConstraint.qd(quantity = "Velocity", unit = "m/s", fixed = false);
//   Real pendulum.sliderConstraint.qdd(quantity = "Acceleration", unit = "m/s2");
//   Real pendulum.sliderConstraint.qq(quantity = "Length", unit = "m");
//   Real pendulum.sliderConstraint.nn[1];
//   Real pendulum.sliderConstraint.nn[2];
//   Real pendulum.sliderConstraint.nn[3];
//   Real pendulum.sliderConstraint.vaux[1](quantity = "Velocity", unit = "m/s");
//   Real pendulum.sliderConstraint.vaux[2](quantity = "Velocity", unit = "m/s");
//   Real pendulum.sliderConstraint.vaux[3](quantity = "Velocity", unit = "m/s");
//   Real pendulum.sliderConstraint.axis.s(quantity = "Length", unit = "m") "absolute position of flange";
//   Real pendulum.sliderConstraint.axis.f(quantity = "Force", unit = "N") "cut force directed into flange";
//   Real pendulum.sliderConstraint.bearing.s(quantity = "Length", unit = "m") "absolute position of flange";
//   Real pendulum.sliderConstraint.bearing.f(quantity = "Force", unit = "N") "cut force directed into flange";
//   Real pendulum.pendulumDamper.phi_rel(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
//   Real pendulum.pendulumDamper.tau(quantity = "Torque", unit = "N.m") "Torque between flanges (= flange_b.tau)";
//   Real pendulum.pendulumDamper.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real pendulum.pendulumDamper.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real pendulum.pendulumDamper.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real pendulum.pendulumDamper.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real pendulum.pendulumDamper.d(unit = "N.m.s/rad", min = 0.0) = pendulum.d_pendulum "Damping constant";
//   Real pendulum.pendulumDamper.w_rel(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between flange_b and flange_a";
//   Real pendulum.sliderDamper.s_rel(quantity = "Length", unit = "m", min = 0.0) "relative distance (= flange_b.s - flange_a.s)";
//   Real pendulum.sliderDamper.f(quantity = "Force", unit = "N") "forcee between flanges (positive in direction of flange axis R)";
//   Real pendulum.sliderDamper.flange_a.s(quantity = "Length", unit = "m") "absolute position of flange";
//   Real pendulum.sliderDamper.flange_a.f(quantity = "Force", unit = "N") "cut force directed into flange";
//   Real pendulum.sliderDamper.flange_b.s(quantity = "Length", unit = "m") "absolute position of flange";
//   Real pendulum.sliderDamper.flange_b.f(quantity = "Force", unit = "N") "cut force directed into flange";
//   parameter Real pendulum.sliderDamper.d(unit = "N/ (m/s)", min = 0.0) = pendulum.d_slider "damping constant [N/ (m/s)]";
//   Real pendulum.sliderDamper.v_rel(quantity = "Velocity", unit = "m/s") "relative velocity between flange_a and flange_b";
//   Real pendulum.flange_a.s(quantity = "Length", unit = "m") "absolute position of flange";
//   Real pendulum.flange_a.f(quantity = "Force", unit = "N") "cut force directed into flange";
//   Real pendulum.angleSensor.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real pendulum.angleSensor.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real pendulum.angleSensor.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute angle of flange";
//   Real pendulum.positionSensor.flange_a.s(quantity = "Length", unit = "m") "absolute position of flange";
//   Real pendulum.positionSensor.flange_a.f(quantity = "Force", unit = "N") "cut force directed into flange";
//   Real pendulum.positionSensor.s(quantity = "Length", unit = "m") "Absolute position of flange as output signal";
//   Real pendulum.position;
//   Real pendulum.angle;
//   parameter Real gear.ratio_rotational = 3.7 "Rotational transmission ratio from input wheel to pinion";
//   parameter Real gear.ratio_translational(unit = "rad/m") = 157.48 "Translational transmission ratio from pinion to gear rack";
//   parameter Real gear.gearR2T.ratio(unit = "rad/m") = gear.ratio_translational "transmission ratio (flange_a.phi/flange_b.s)";
//   Real gear.gearR2T.tau_support(quantity = "Torque", unit = "N.m");
//   Real gear.gearR2T.f_support(quantity = "Force", unit = "N");
//   Real gear.gearR2T.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear.gearR2T.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear.gearR2T.flange_b.s(quantity = "Length", unit = "m") "absolute position of flange";
//   Real gear.gearR2T.flange_b.f(quantity = "Force", unit = "N") "cut force directed into flange";
//   Real gear.gearR2T.bearingR.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear.gearR2T.bearingR.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear.gearR2T.bearingT.s(quantity = "Length", unit = "m") "absolute position of flange";
//   Real gear.gearR2T.bearingT.f(quantity = "Force", unit = "N") "cut force directed into flange";
//   Real gear.idealGear.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear.idealGear.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear.idealGear.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear.idealGear.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear.idealGear.tau_support(quantity = "Torque", unit = "N.m");
//   Real gear.idealGear.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear.idealGear.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear.idealGear.phi_a(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   Real gear.idealGear.phi_b(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   parameter Real gear.idealGear.ratio = gear.ratio_rotational "Transmission ratio (flange_a.phi/flange_b.phi)";
//   Real gear.flange_b.s(quantity = "Length", unit = "m") "absolute position of flange";
//   Real gear.flange_b.f(quantity = "Force", unit = "N") "cut force directed into flange";
//   Real gear.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// equation
//   motor.voltageSource.v = motor.voltageSource.p.v - motor.voltageSource.n.v;
//   0.0 = motor.voltageSource.p.i + motor.voltageSource.n.i;
//   motor.voltageSource.i = motor.voltageSource.p.i;
//   motor.resistor.R * motor.resistor.i = motor.resistor.v;
//   motor.resistor.v = motor.resistor.p.v - motor.resistor.n.v;
//   0.0 = motor.resistor.p.i + motor.resistor.n.i;
//   motor.resistor.i = motor.resistor.p.i;
//   motor.inductor.L * der(motor.inductor.i) = motor.inductor.v;
//   motor.inductor.v = motor.inductor.p.v - motor.inductor.n.v;
//   0.0 = motor.inductor.p.i + motor.inductor.n.i;
//   motor.inductor.i = motor.inductor.p.i;
//   motor.eMF.v = motor.eMF.p.v - motor.eMF.n.v;
//   0.0 = motor.eMF.p.i + motor.eMF.n.i;
//   motor.eMF.i = motor.eMF.p.i;
//   motor.eMF.w = der(motor.eMF.flange_b.phi);
//   motor.eMF.k * motor.eMF.w = motor.eMF.v;
//   motor.eMF.flange_b.tau = (-motor.eMF.k) * motor.eMF.i;
//   motor.ground.p.v = 0.0;
//   controller.step.y = controller.step.k;
//   der(controller.observer.x[1]) = controller.observer.A[1,1] * controller.observer.x[1] + controller.observer.A[1,2] * controller.observer.x[2] + controller.observer.A[1,3] * controller.observer.x[3] + controller.observer.A[1,4] * controller.observer.x[4] + controller.observer.B[1,1] * controller.observer.u[1] + controller.observer.B[1,2] * controller.observer.u[2] + controller.observer.B[1,3] * controller.observer.u[3];
//   der(controller.observer.x[2]) = controller.observer.A[2,1] * controller.observer.x[1] + controller.observer.A[2,2] * controller.observer.x[2] + controller.observer.A[2,3] * controller.observer.x[3] + controller.observer.A[2,4] * controller.observer.x[4] + controller.observer.B[2,1] * controller.observer.u[1] + controller.observer.B[2,2] * controller.observer.u[2] + controller.observer.B[2,3] * controller.observer.u[3];
//   der(controller.observer.x[3]) = controller.observer.A[3,1] * controller.observer.x[1] + controller.observer.A[3,2] * controller.observer.x[2] + controller.observer.A[3,3] * controller.observer.x[3] + controller.observer.A[3,4] * controller.observer.x[4] + controller.observer.B[3,1] * controller.observer.u[1] + controller.observer.B[3,2] * controller.observer.u[2] + controller.observer.B[3,3] * controller.observer.u[3];
//   der(controller.observer.x[4]) = controller.observer.A[4,1] * controller.observer.x[1] + controller.observer.A[4,2] * controller.observer.x[2] + controller.observer.A[4,3] * controller.observer.x[3] + controller.observer.A[4,4] * controller.observer.x[4] + controller.observer.B[4,1] * controller.observer.u[1] + controller.observer.B[4,2] * controller.observer.u[2] + controller.observer.B[4,3] * controller.observer.u[3];
//   controller.observer.y[1] = controller.observer.C[1,1] * controller.observer.x[1] + controller.observer.C[1,2] * controller.observer.x[2] + controller.observer.C[1,3] * controller.observer.x[3] + controller.observer.C[1,4] * controller.observer.x[4] + controller.observer.D[1,1] * controller.observer.u[1] + controller.observer.D[1,2] * controller.observer.u[2] + controller.observer.D[1,3] * controller.observer.u[3];
//   controller.observer.y[2] = controller.observer.C[2,1] * controller.observer.x[1] + controller.observer.C[2,2] * controller.observer.x[2] + controller.observer.C[2,3] * controller.observer.x[3] + controller.observer.C[2,4] * controller.observer.x[4] + controller.observer.D[2,1] * controller.observer.u[1] + controller.observer.D[2,2] * controller.observer.u[2] + controller.observer.D[2,3] * controller.observer.u[3];
//   controller.observer.y[3] = controller.observer.C[3,1] * controller.observer.x[1] + controller.observer.C[3,2] * controller.observer.x[2] + controller.observer.C[3,3] * controller.observer.x[3] + controller.observer.C[3,4] * controller.observer.x[4] + controller.observer.D[3,1] * controller.observer.u[1] + controller.observer.D[3,2] * controller.observer.u[2] + controller.observer.D[3,3] * controller.observer.u[3];
//   controller.observer.y[4] = controller.observer.C[4,1] * controller.observer.x[1] + controller.observer.C[4,2] * controller.observer.x[2] + controller.observer.C[4,3] * controller.observer.x[3] + controller.observer.C[4,4] * controller.observer.x[4] + controller.observer.D[4,1] * controller.observer.u[1] + controller.observer.D[4,2] * controller.observer.u[2] + controller.observer.D[4,3] * controller.observer.u[3];
//   controller.L.y[1] = controller.L.K[1,1] * controller.L.u[1] + controller.L.K[1,2] * controller.L.u[2] + controller.L.K[1,3] * controller.L.u[3] + controller.L.K[1,4] * controller.L.u[4];
//   controller.feedback.y = controller.feedback.u1 - controller.feedback.u2;
//   controller.L_r.y = controller.L_r.k * controller.L_r.u;
//   controller.mux.y[1] = controller.mux.u1[1];
//   controller.mux.y[2] = controller.mux.u2[1];
//   controller.mux.y[3] = controller.mux.u3[1];
//   when sample(controller.pulse.startTime, controller.pulse.period) then
//     controller.pulse.T0 = time;
//   end when;
//   controller.pulse.y = controller.pulse.offset + (if time < controller.pulse.startTime or time >= controller.pulse.T0 + controller.pulse.T_width then 0.0 else controller.pulse.amplitude);
//   controller.switch1.y = if controller.switch1.u2 then controller.switch1.u1 else controller.switch1.u3;
//   controller.ConstantQ.y = controller.ConstantQ.k;
//   assert(controller.limiter.uMax >= controller.limiter.uMin, "Limiter: Limits must be consistent. However, uMax (=" + String(controller.limiter.uMax, 6, 0, true) + ") < uMin (=" + String(controller.limiter.uMin, 6, 0, true) + ")");
//   if initial() and not controller.limiter.limitsAtInit then
//     controller.limiter.y = controller.limiter.u;
//     assert(controller.limiter.u >= controller.limiter.uMin + (-0.01) * abs(controller.limiter.uMin) and controller.limiter.u <= controller.limiter.uMax + 0.01 * abs(controller.limiter.uMax), "Limiter: During initialization the limits have been ignored.
//     However, the result is that the input u is not within the required limits:
//       u = " + String(controller.limiter.u, 6, 0, true) + ", uMin = " + String(controller.limiter.uMin, 6, 0, true) + ", uMax = " + String(controller.limiter.uMax, 6, 0, true));
//   else
//     controller.limiter.y = smooth(0, if controller.limiter.u > controller.limiter.uMax then controller.limiter.uMax else if controller.limiter.u < controller.limiter.uMin then controller.limiter.uMin else controller.limiter.u);
//   end if;
//   controller.switch2.y = if controller.switch2.u2 then controller.switch2.u1 else controller.switch2.u3;
//   controller.ConstantQ1.y = controller.ConstantQ1.k;
//   controller.timeTable.y = controller.timeTable.a * time + controller.timeTable.b;
//   pendulum.inertialSystem.gravity[1] = pendulum.inertialSystem.ng[1] * pendulum.inertialSystem.g;
//   pendulum.inertialSystem.gravity[2] = pendulum.inertialSystem.ng[2] * pendulum.inertialSystem.g;
//   pendulum.inertialSystem.gravity[3] = pendulum.inertialSystem.ng[3] * pendulum.inertialSystem.g;
//   pendulum.inertialSystem.frame_b.S[1,1] = 1.0;
//   pendulum.inertialSystem.frame_b.S[1,2] = 0.0;
//   pendulum.inertialSystem.frame_b.S[1,3] = 0.0;
//   pendulum.inertialSystem.frame_b.S[2,1] = 0.0;
//   pendulum.inertialSystem.frame_b.S[2,2] = 1.0;
//   pendulum.inertialSystem.frame_b.S[2,3] = 0.0;
//   pendulum.inertialSystem.frame_b.S[3,1] = 0.0;
//   pendulum.inertialSystem.frame_b.S[3,2] = 0.0;
//   pendulum.inertialSystem.frame_b.S[3,3] = 1.0;
//   pendulum.inertialSystem.frame_b.r0[1] = 0.0;
//   pendulum.inertialSystem.frame_b.r0[2] = 0.0;
//   pendulum.inertialSystem.frame_b.r0[3] = 0.0;
//   pendulum.inertialSystem.frame_b.v[1] = 0.0;
//   pendulum.inertialSystem.frame_b.v[2] = 0.0;
//   pendulum.inertialSystem.frame_b.v[3] = 0.0;
//   pendulum.inertialSystem.frame_b.w[1] = 0.0;
//   pendulum.inertialSystem.frame_b.w[2] = 0.0;
//   pendulum.inertialSystem.frame_b.w[3] = 0.0;
//   pendulum.inertialSystem.frame_b.a[1] = -pendulum.inertialSystem.gravity[1];
//   pendulum.inertialSystem.frame_b.a[2] = -pendulum.inertialSystem.gravity[2];
//   pendulum.inertialSystem.frame_b.a[3] = -pendulum.inertialSystem.gravity[3];
//   pendulum.inertialSystem.frame_b.z[1] = 0.0;
//   pendulum.inertialSystem.frame_b.z[2] = 0.0;
//   pendulum.inertialSystem.frame_b.z[3] = 0.0;
//   pendulum.cart.frame_a.r0 = {pendulum.cart.r0a[1], pendulum.cart.r0a[2], pendulum.cart.r0a[3]};
//   pendulum.cart.frame_a.S = {{pendulum.cart.Sa[1,1], pendulum.cart.Sa[1,2], pendulum.cart.Sa[1,3]}, {pendulum.cart.Sa[2,1], pendulum.cart.Sa[2,2], pendulum.cart.Sa[2,3]}, {pendulum.cart.Sa[3,1], pendulum.cart.Sa[3,2], pendulum.cart.Sa[3,3]}};
//   pendulum.cart.frame_a.v = {pendulum.cart.va[1], pendulum.cart.va[2], pendulum.cart.va[3]};
//   pendulum.cart.frame_a.w = {pendulum.cart.wa[1], pendulum.cart.wa[2], pendulum.cart.wa[3]};
//   pendulum.cart.frame_a.a = {pendulum.cart.aa[1], pendulum.cart.aa[2], pendulum.cart.aa[3]};
//   pendulum.cart.frame_a.z = {pendulum.cart.za[1], pendulum.cart.za[2], pendulum.cart.za[3]};
//   pendulum.cart.frame_a.f = {pendulum.cart.fa[1], pendulum.cart.fa[2], pendulum.cart.fa[3]};
//   pendulum.cart.frame_a.t = {pendulum.cart.ta[1], pendulum.cart.ta[2], pendulum.cart.ta[3]};
//   pendulum.cart.frame_b.r0 = {pendulum.cart.r0b[1], pendulum.cart.r0b[2], pendulum.cart.r0b[3]};
//   pendulum.cart.frame_b.S = {{pendulum.cart.Sb[1,1], pendulum.cart.Sb[1,2], pendulum.cart.Sb[1,3]}, {pendulum.cart.Sb[2,1], pendulum.cart.Sb[2,2], pendulum.cart.Sb[2,3]}, {pendulum.cart.Sb[3,1], pendulum.cart.Sb[3,2], pendulum.cart.Sb[3,3]}};
//   pendulum.cart.frame_b.v = {pendulum.cart.vb[1], pendulum.cart.vb[2], pendulum.cart.vb[3]};
//   pendulum.cart.frame_b.w = {pendulum.cart.wb[1], pendulum.cart.wb[2], pendulum.cart.wb[3]};
//   pendulum.cart.frame_b.a = {pendulum.cart.ab[1], pendulum.cart.ab[2], pendulum.cart.ab[3]};
//   pendulum.cart.frame_b.z = {pendulum.cart.zb[1], pendulum.cart.zb[2], pendulum.cart.zb[3]};
//   pendulum.cart.frame_b.f = {-pendulum.cart.fb[1], -pendulum.cart.fb[2], -pendulum.cart.fb[3]};
//   pendulum.cart.frame_b.t = {-pendulum.cart.tb[1], -pendulum.cart.tb[2], -pendulum.cart.tb[3]};
//   pendulum.cart.box.mcShape.r = {pendulum.cart.box.r[1], pendulum.cart.box.r[2], pendulum.cart.box.r[3]};
//   pendulum.cart.box.mcShape.r_shape = {pendulum.cart.box.r0[1], pendulum.cart.box.r0[2], pendulum.cart.box.r0[3]};
//   pendulum.cart.box.mcShape.lengthDirection = {pendulum.cart.box.LengthDirection[1], pendulum.cart.box.LengthDirection[2], pendulum.cart.box.LengthDirection[3]};
//   pendulum.cart.box.mcShape.widthDirection = {pendulum.cart.box.WidthDirection[1], pendulum.cart.box.WidthDirection[2], pendulum.cart.box.WidthDirection[3]};
//   pendulum.cart.box.mcShape.color = {pendulum.cart.box.Material[1] * 255.0, pendulum.cart.box.Material[2] * 255.0, pendulum.cart.box.Material[3] * 255.0};
//   pendulum.cart.box.mcShape.S = {{pendulum.cart.box.S[1,1], pendulum.cart.box.S[1,2], pendulum.cart.box.S[1,3]}, {pendulum.cart.box.S[2,1], pendulum.cart.box.S[2,2], pendulum.cart.box.S[2,3]}, {pendulum.cart.box.S[3,1], pendulum.cart.box.S[3,2], pendulum.cart.box.S[3,3]}};
//   pendulum.cart.box.mcShape.Sshape = {{pendulum.cart.box.Sshape[1,1], pendulum.cart.box.Sshape[1,2], pendulum.cart.box.Sshape[1,3]}, {pendulum.cart.box.Sshape[2,1], pendulum.cart.box.Sshape[2,2], pendulum.cart.box.Sshape[2,3]}, {pendulum.cart.box.Sshape[3,1], pendulum.cart.box.Sshape[3,2], pendulum.cart.box.Sshape[3,3]}};
//   pendulum.cart.box.mcShape.e_x = if noEvent(pendulum.cart.box.mcShape.abs_n_x < 1e-10) then {1.0, 0.0, 0.0} else {pendulum.cart.box.mcShape.lengthDirection[1] / pendulum.cart.box.mcShape.abs_n_x, pendulum.cart.box.mcShape.lengthDirection[2] / pendulum.cart.box.mcShape.abs_n_x, pendulum.cart.box.mcShape.lengthDirection[3] / pendulum.cart.box.mcShape.abs_n_x};
//   pendulum.cart.box.mcShape.n_z_aux = {pendulum.cart.box.mcShape.e_x[2] * pendulum.cart.box.mcShape.widthDirection[3] - pendulum.cart.box.mcShape.e_x[3] * pendulum.cart.box.mcShape.widthDirection[2], pendulum.cart.box.mcShape.e_x[3] * pendulum.cart.box.mcShape.widthDirection[1] - pendulum.cart.box.mcShape.e_x[1] * pendulum.cart.box.mcShape.widthDirection[3], pendulum.cart.box.mcShape.e_x[1] * pendulum.cart.box.mcShape.widthDirection[2] - pendulum.cart.box.mcShape.e_x[2] * pendulum.cart.box.mcShape.widthDirection[1]};
//   pendulum.cart.box.mcShape.e_y = cross(MCVisualShape$pendulum$cart$box$mcShape.local_normalize(cross({pendulum.cart.box.mcShape.e_x[1], pendulum.cart.box.mcShape.e_x[2], pendulum.cart.box.mcShape.e_x[3]}, if noEvent(pendulum.cart.box.mcShape.n_z_aux[1] ^ 2.0 + pendulum.cart.box.mcShape.n_z_aux[2] ^ 2.0 + pendulum.cart.box.mcShape.n_z_aux[3] ^ 2.0 > 1e-06) then {pendulum.cart.box.mcShape.widthDirection[1], pendulum.cart.box.mcShape.widthDirection[2], pendulum.cart.box.mcShape.widthDirection[3]} else if noEvent(abs(pendulum.cart.box.mcShape.e_x[1]) > 1e-06) then {0.0, 1.0, 0.0} else {1.0, 0.0, 0.0})), {pendulum.cart.box.mcShape.e_x[1], pendulum.cart.box.mcShape.e_x[2], pendulum.cart.box.mcShape.e_x[3]});
//   pendulum.cart.box.mcShape.e_z = {pendulum.cart.box.mcShape.e_x[2] * pendulum.cart.box.mcShape.e_y[3] - pendulum.cart.box.mcShape.e_x[3] * pendulum.cart.box.mcShape.e_y[2], pendulum.cart.box.mcShape.e_x[3] * pendulum.cart.box.mcShape.e_y[1] - pendulum.cart.box.mcShape.e_x[1] * pendulum.cart.box.mcShape.e_y[3], pendulum.cart.box.mcShape.e_x[1] * pendulum.cart.box.mcShape.e_y[2] - pendulum.cart.box.mcShape.e_x[2] * pendulum.cart.box.mcShape.e_y[1]};
//   pendulum.cart.box.mcShape.Form = 1e+20 * (987000.0 + PackShape(pendulum.cart.box.mcShape.shapeType));
//   pendulum.cart.box.mcShape.Material = PackMaterial(0.00392156862745098 * pendulum.cart.box.mcShape.color[1], 0.00392156862745098 * pendulum.cart.box.mcShape.color[2], 0.00392156862745098 * pendulum.cart.box.mcShape.color[3], pendulum.cart.box.mcShape.specularCoefficient);
//   pendulum.cart.box.mcShape.Extra = pendulum.cart.box.mcShape.extra;
//   pendulum.cart.box.mcShape.size[1] = pendulum.cart.box.mcShape.length;
//   pendulum.cart.box.mcShape.size[2] = pendulum.cart.box.mcShape.width;
//   pendulum.cart.box.mcShape.size[3] = pendulum.cart.box.mcShape.height;
//   pendulum.cart.box.mcShape.Sshape[1,1] = pendulum.cart.box.mcShape.e_x[1];
//   pendulum.cart.box.mcShape.Sshape[1,2] = pendulum.cart.box.mcShape.e_y[1];
//   pendulum.cart.box.mcShape.Sshape[1,3] = pendulum.cart.box.mcShape.e_x[2] * pendulum.cart.box.mcShape.e_y[3] - pendulum.cart.box.mcShape.e_x[3] * pendulum.cart.box.mcShape.e_y[2];
//   pendulum.cart.box.mcShape.Sshape[2,1] = pendulum.cart.box.mcShape.e_x[2];
//   pendulum.cart.box.mcShape.Sshape[2,2] = pendulum.cart.box.mcShape.e_y[2];
//   pendulum.cart.box.mcShape.Sshape[2,3] = pendulum.cart.box.mcShape.e_x[3] * pendulum.cart.box.mcShape.e_y[1] - pendulum.cart.box.mcShape.e_x[1] * pendulum.cart.box.mcShape.e_y[3];
//   pendulum.cart.box.mcShape.Sshape[3,1] = pendulum.cart.box.mcShape.e_x[3];
//   pendulum.cart.box.mcShape.Sshape[3,2] = pendulum.cart.box.mcShape.e_y[3];
//   pendulum.cart.box.mcShape.Sshape[3,3] = pendulum.cart.box.mcShape.e_x[1] * pendulum.cart.box.mcShape.e_y[2] - pendulum.cart.box.mcShape.e_x[2] * pendulum.cart.box.mcShape.e_y[1];
//   pendulum.cart.box.mcShape.rxvisobj[1] = pendulum.cart.box.mcShape.S[1,1] * pendulum.cart.box.mcShape.e_x[1] + pendulum.cart.box.mcShape.S[1,2] * pendulum.cart.box.mcShape.e_x[2] + pendulum.cart.box.mcShape.S[1,3] * pendulum.cart.box.mcShape.e_x[3];
//   pendulum.cart.box.mcShape.rxvisobj[2] = pendulum.cart.box.mcShape.S[2,1] * pendulum.cart.box.mcShape.e_x[1] + pendulum.cart.box.mcShape.S[2,2] * pendulum.cart.box.mcShape.e_x[2] + pendulum.cart.box.mcShape.S[2,3] * pendulum.cart.box.mcShape.e_x[3];
//   pendulum.cart.box.mcShape.rxvisobj[3] = pendulum.cart.box.mcShape.S[3,1] * pendulum.cart.box.mcShape.e_x[1] + pendulum.cart.box.mcShape.S[3,2] * pendulum.cart.box.mcShape.e_x[2] + pendulum.cart.box.mcShape.S[3,3] * pendulum.cart.box.mcShape.e_x[3];
//   pendulum.cart.box.mcShape.ryvisobj[1] = pendulum.cart.box.mcShape.S[1,1] * pendulum.cart.box.mcShape.e_y[1] + pendulum.cart.box.mcShape.S[1,2] * pendulum.cart.box.mcShape.e_y[2] + pendulum.cart.box.mcShape.S[1,3] * pendulum.cart.box.mcShape.e_y[3];
//   pendulum.cart.box.mcShape.ryvisobj[2] = pendulum.cart.box.mcShape.S[2,1] * pendulum.cart.box.mcShape.e_y[1] + pendulum.cart.box.mcShape.S[2,2] * pendulum.cart.box.mcShape.e_y[2] + pendulum.cart.box.mcShape.S[2,3] * pendulum.cart.box.mcShape.e_y[3];
//   pendulum.cart.box.mcShape.ryvisobj[3] = pendulum.cart.box.mcShape.S[3,1] * pendulum.cart.box.mcShape.e_y[1] + pendulum.cart.box.mcShape.S[3,2] * pendulum.cart.box.mcShape.e_y[2] + pendulum.cart.box.mcShape.S[3,3] * pendulum.cart.box.mcShape.e_y[3];
//   pendulum.cart.box.mcShape.rvisobj[1] = pendulum.cart.box.mcShape.r[1] + pendulum.cart.box.mcShape.S[1,1] * pendulum.cart.box.mcShape.r_shape[1] + pendulum.cart.box.mcShape.S[1,2] * pendulum.cart.box.mcShape.r_shape[2] + pendulum.cart.box.mcShape.S[1,3] * pendulum.cart.box.mcShape.r_shape[3];
//   pendulum.cart.box.mcShape.rvisobj[2] = pendulum.cart.box.mcShape.r[2] + pendulum.cart.box.mcShape.S[2,1] * pendulum.cart.box.mcShape.r_shape[1] + pendulum.cart.box.mcShape.S[2,2] * pendulum.cart.box.mcShape.r_shape[2] + pendulum.cart.box.mcShape.S[2,3] * pendulum.cart.box.mcShape.r_shape[3];
//   pendulum.cart.box.mcShape.rvisobj[3] = pendulum.cart.box.mcShape.r[3] + pendulum.cart.box.mcShape.S[3,1] * pendulum.cart.box.mcShape.r_shape[1] + pendulum.cart.box.mcShape.S[3,2] * pendulum.cart.box.mcShape.r_shape[2] + pendulum.cart.box.mcShape.S[3,3] * pendulum.cart.box.mcShape.r_shape[3];
//   pendulum.cart.box.mcShape.e_x[1] = pendulum.cart.box.nLength[1];
//   pendulum.cart.box.mcShape.e_x[2] = pendulum.cart.box.nLength[2];
//   pendulum.cart.box.mcShape.e_x[3] = pendulum.cart.box.nLength[3];
//   pendulum.cart.box.mcShape.e_y[1] = pendulum.cart.box.nWidth[1];
//   pendulum.cart.box.mcShape.e_y[2] = pendulum.cart.box.nWidth[2];
//   pendulum.cart.box.mcShape.e_y[3] = pendulum.cart.box.nWidth[3];
//   pendulum.cart.box.mcShape.e_z[1] = pendulum.cart.box.nHeight[1];
//   pendulum.cart.box.mcShape.e_z[2] = pendulum.cart.box.nHeight[2];
//   pendulum.cart.box.mcShape.e_z[3] = pendulum.cart.box.nHeight[3];
//   pendulum.cart.frameTranslation.frame_a.r0 = {pendulum.cart.frameTranslation.r0a[1], pendulum.cart.frameTranslation.r0a[2], pendulum.cart.frameTranslation.r0a[3]};
//   pendulum.cart.frameTranslation.frame_a.S = {{pendulum.cart.frameTranslation.Sa[1,1], pendulum.cart.frameTranslation.Sa[1,2], pendulum.cart.frameTranslation.Sa[1,3]}, {pendulum.cart.frameTranslation.Sa[2,1], pendulum.cart.frameTranslation.Sa[2,2], pendulum.cart.frameTranslation.Sa[2,3]}, {pendulum.cart.frameTranslation.Sa[3,1], pendulum.cart.frameTranslation.Sa[3,2], pendulum.cart.frameTranslation.Sa[3,3]}};
//   pendulum.cart.frameTranslation.frame_a.v = {pendulum.cart.frameTranslation.va[1], pendulum.cart.frameTranslation.va[2], pendulum.cart.frameTranslation.va[3]};
//   pendulum.cart.frameTranslation.frame_a.w = {pendulum.cart.frameTranslation.wa[1], pendulum.cart.frameTranslation.wa[2], pendulum.cart.frameTranslation.wa[3]};
//   pendulum.cart.frameTranslation.frame_a.a = {pendulum.cart.frameTranslation.aa[1], pendulum.cart.frameTranslation.aa[2], pendulum.cart.frameTranslation.aa[3]};
//   pendulum.cart.frameTranslation.frame_a.z = {pendulum.cart.frameTranslation.za[1], pendulum.cart.frameTranslation.za[2], pendulum.cart.frameTranslation.za[3]};
//   pendulum.cart.frameTranslation.frame_a.f = {pendulum.cart.frameTranslation.fa[1], pendulum.cart.frameTranslation.fa[2], pendulum.cart.frameTranslation.fa[3]};
//   pendulum.cart.frameTranslation.frame_a.t = {pendulum.cart.frameTranslation.ta[1], pendulum.cart.frameTranslation.ta[2], pendulum.cart.frameTranslation.ta[3]};
//   pendulum.cart.frameTranslation.frame_b.r0 = {pendulum.cart.frameTranslation.r0b[1], pendulum.cart.frameTranslation.r0b[2], pendulum.cart.frameTranslation.r0b[3]};
//   pendulum.cart.frameTranslation.frame_b.S = {{pendulum.cart.frameTranslation.Sb[1,1], pendulum.cart.frameTranslation.Sb[1,2], pendulum.cart.frameTranslation.Sb[1,3]}, {pendulum.cart.frameTranslation.Sb[2,1], pendulum.cart.frameTranslation.Sb[2,2], pendulum.cart.frameTranslation.Sb[2,3]}, {pendulum.cart.frameTranslation.Sb[3,1], pendulum.cart.frameTranslation.Sb[3,2], pendulum.cart.frameTranslation.Sb[3,3]}};
//   pendulum.cart.frameTranslation.frame_b.v = {pendulum.cart.frameTranslation.vb[1], pendulum.cart.frameTranslation.vb[2], pendulum.cart.frameTranslation.vb[3]};
//   pendulum.cart.frameTranslation.frame_b.w = {pendulum.cart.frameTranslation.wb[1], pendulum.cart.frameTranslation.wb[2], pendulum.cart.frameTranslation.wb[3]};
//   pendulum.cart.frameTranslation.frame_b.a = {pendulum.cart.frameTranslation.ab[1], pendulum.cart.frameTranslation.ab[2], pendulum.cart.frameTranslation.ab[3]};
//   pendulum.cart.frameTranslation.frame_b.z = {pendulum.cart.frameTranslation.zb[1], pendulum.cart.frameTranslation.zb[2], pendulum.cart.frameTranslation.zb[3]};
//   pendulum.cart.frameTranslation.frame_b.f = {-pendulum.cart.frameTranslation.fb[1], -pendulum.cart.frameTranslation.fb[2], -pendulum.cart.frameTranslation.fb[3]};
//   pendulum.cart.frameTranslation.frame_b.t = {-pendulum.cart.frameTranslation.tb[1], -pendulum.cart.frameTranslation.tb[2], -pendulum.cart.frameTranslation.tb[3]};
//   pendulum.cart.frameTranslation.Sb[1,1] = pendulum.cart.frameTranslation.Sa[1,1];
//   pendulum.cart.frameTranslation.Sb[1,2] = pendulum.cart.frameTranslation.Sa[1,2];
//   pendulum.cart.frameTranslation.Sb[1,3] = pendulum.cart.frameTranslation.Sa[1,3];
//   pendulum.cart.frameTranslation.Sb[2,1] = pendulum.cart.frameTranslation.Sa[2,1];
//   pendulum.cart.frameTranslation.Sb[2,2] = pendulum.cart.frameTranslation.Sa[2,2];
//   pendulum.cart.frameTranslation.Sb[2,3] = pendulum.cart.frameTranslation.Sa[2,3];
//   pendulum.cart.frameTranslation.Sb[3,1] = pendulum.cart.frameTranslation.Sa[3,1];
//   pendulum.cart.frameTranslation.Sb[3,2] = pendulum.cart.frameTranslation.Sa[3,2];
//   pendulum.cart.frameTranslation.Sb[3,3] = pendulum.cart.frameTranslation.Sa[3,3];
//   pendulum.cart.frameTranslation.wb[1] = pendulum.cart.frameTranslation.wa[1];
//   pendulum.cart.frameTranslation.wb[2] = pendulum.cart.frameTranslation.wa[2];
//   pendulum.cart.frameTranslation.wb[3] = pendulum.cart.frameTranslation.wa[3];
//   pendulum.cart.frameTranslation.zb[1] = pendulum.cart.frameTranslation.za[1];
//   pendulum.cart.frameTranslation.zb[2] = pendulum.cart.frameTranslation.za[2];
//   pendulum.cart.frameTranslation.zb[3] = pendulum.cart.frameTranslation.za[3];
//   pendulum.cart.frameTranslation.r0b[1] = pendulum.cart.frameTranslation.r0a[1] + pendulum.cart.frameTranslation.Sa[1,1] * pendulum.cart.frameTranslation.r[1] + pendulum.cart.frameTranslation.Sa[1,2] * pendulum.cart.frameTranslation.r[2] + pendulum.cart.frameTranslation.Sa[1,3] * pendulum.cart.frameTranslation.r[3];
//   pendulum.cart.frameTranslation.r0b[2] = pendulum.cart.frameTranslation.r0a[2] + pendulum.cart.frameTranslation.Sa[2,1] * pendulum.cart.frameTranslation.r[1] + pendulum.cart.frameTranslation.Sa[2,2] * pendulum.cart.frameTranslation.r[2] + pendulum.cart.frameTranslation.Sa[2,3] * pendulum.cart.frameTranslation.r[3];
//   pendulum.cart.frameTranslation.r0b[3] = pendulum.cart.frameTranslation.r0a[3] + pendulum.cart.frameTranslation.Sa[3,1] * pendulum.cart.frameTranslation.r[1] + pendulum.cart.frameTranslation.Sa[3,2] * pendulum.cart.frameTranslation.r[2] + pendulum.cart.frameTranslation.Sa[3,3] * pendulum.cart.frameTranslation.r[3];
//   pendulum.cart.frameTranslation.vaux[1] = pendulum.cart.frameTranslation.wa[2] * pendulum.cart.frameTranslation.r[3] - pendulum.cart.frameTranslation.wa[3] * pendulum.cart.frameTranslation.r[2];
//   pendulum.cart.frameTranslation.vaux[2] = pendulum.cart.frameTranslation.wa[3] * pendulum.cart.frameTranslation.r[1] - pendulum.cart.frameTranslation.wa[1] * pendulum.cart.frameTranslation.r[3];
//   pendulum.cart.frameTranslation.vaux[3] = pendulum.cart.frameTranslation.wa[1] * pendulum.cart.frameTranslation.r[2] - pendulum.cart.frameTranslation.wa[2] * pendulum.cart.frameTranslation.r[1];
//   pendulum.cart.frameTranslation.vb[1] = pendulum.cart.frameTranslation.va[1] + pendulum.cart.frameTranslation.vaux[1];
//   pendulum.cart.frameTranslation.vb[2] = pendulum.cart.frameTranslation.va[2] + pendulum.cart.frameTranslation.vaux[2];
//   pendulum.cart.frameTranslation.vb[3] = pendulum.cart.frameTranslation.va[3] + pendulum.cart.frameTranslation.vaux[3];
//   pendulum.cart.frameTranslation.ab[1] = pendulum.cart.frameTranslation.aa[1] + pendulum.cart.frameTranslation.za[2] * pendulum.cart.frameTranslation.r[3] - pendulum.cart.frameTranslation.za[3] * pendulum.cart.frameTranslation.r[2] + pendulum.cart.frameTranslation.wa[2] * pendulum.cart.frameTranslation.vaux[3] - pendulum.cart.frameTranslation.wa[3] * pendulum.cart.frameTranslation.vaux[2];
//   pendulum.cart.frameTranslation.ab[2] = pendulum.cart.frameTranslation.aa[2] + pendulum.cart.frameTranslation.za[3] * pendulum.cart.frameTranslation.r[1] - pendulum.cart.frameTranslation.za[1] * pendulum.cart.frameTranslation.r[3] + pendulum.cart.frameTranslation.wa[3] * pendulum.cart.frameTranslation.vaux[1] - pendulum.cart.frameTranslation.wa[1] * pendulum.cart.frameTranslation.vaux[3];
//   pendulum.cart.frameTranslation.ab[3] = pendulum.cart.frameTranslation.aa[3] + pendulum.cart.frameTranslation.za[1] * pendulum.cart.frameTranslation.r[2] - pendulum.cart.frameTranslation.za[2] * pendulum.cart.frameTranslation.r[1] + pendulum.cart.frameTranslation.wa[1] * pendulum.cart.frameTranslation.vaux[2] - pendulum.cart.frameTranslation.wa[2] * pendulum.cart.frameTranslation.vaux[1];
//   pendulum.cart.frameTranslation.fa[1] = pendulum.cart.frameTranslation.fb[1] "Transform the force and torque acting at frame_b to frame_a";
//   pendulum.cart.frameTranslation.fa[2] = pendulum.cart.frameTranslation.fb[2] "Transform the force and torque acting at frame_b to frame_a";
//   pendulum.cart.frameTranslation.fa[3] = pendulum.cart.frameTranslation.fb[3] "Transform the force and torque acting at frame_b to frame_a";
//   pendulum.cart.frameTranslation.ta[1] = pendulum.cart.frameTranslation.tb[1] + pendulum.cart.frameTranslation.r[2] * pendulum.cart.frameTranslation.fa[3] - pendulum.cart.frameTranslation.r[3] * pendulum.cart.frameTranslation.fa[2];
//   pendulum.cart.frameTranslation.ta[2] = pendulum.cart.frameTranslation.tb[2] + pendulum.cart.frameTranslation.r[3] * pendulum.cart.frameTranslation.fa[1] - pendulum.cart.frameTranslation.r[1] * pendulum.cart.frameTranslation.fa[3];
//   pendulum.cart.frameTranslation.ta[3] = pendulum.cart.frameTranslation.tb[3] + pendulum.cart.frameTranslation.r[1] * pendulum.cart.frameTranslation.fa[2] - pendulum.cart.frameTranslation.r[2] * pendulum.cart.frameTranslation.fa[1];
//   pendulum.cart.body.frame_a.r0 = {pendulum.cart.body.r0a[1], pendulum.cart.body.r0a[2], pendulum.cart.body.r0a[3]};
//   pendulum.cart.body.frame_a.S = {{pendulum.cart.body.Sa[1,1], pendulum.cart.body.Sa[1,2], pendulum.cart.body.Sa[1,3]}, {pendulum.cart.body.Sa[2,1], pendulum.cart.body.Sa[2,2], pendulum.cart.body.Sa[2,3]}, {pendulum.cart.body.Sa[3,1], pendulum.cart.body.Sa[3,2], pendulum.cart.body.Sa[3,3]}};
//   pendulum.cart.body.frame_a.v = {pendulum.cart.body.va[1], pendulum.cart.body.va[2], pendulum.cart.body.va[3]};
//   pendulum.cart.body.frame_a.w = {pendulum.cart.body.wa[1], pendulum.cart.body.wa[2], pendulum.cart.body.wa[3]};
//   pendulum.cart.body.frame_a.a = {pendulum.cart.body.aa[1], pendulum.cart.body.aa[2], pendulum.cart.body.aa[3]};
//   pendulum.cart.body.frame_a.z = {pendulum.cart.body.za[1], pendulum.cart.body.za[2], pendulum.cart.body.za[3]};
//   pendulum.cart.body.frame_a.f = {pendulum.cart.body.fa[1], pendulum.cart.body.fa[2], pendulum.cart.body.fa[3]};
//   pendulum.cart.body.frame_a.t = {pendulum.cart.body.ta[1], pendulum.cart.body.ta[2], pendulum.cart.body.ta[3]};
//   pendulum.cart.body.fa[1] = (pendulum.cart.body.aa[1] + pendulum.cart.body.za[2] * pendulum.cart.body.rCM[3] - pendulum.cart.body.za[3] * pendulum.cart.body.rCM[2] + pendulum.cart.body.wa[2] * (pendulum.cart.body.wa[1] * pendulum.cart.body.rCM[2] - pendulum.cart.body.wa[2] * pendulum.cart.body.rCM[1]) - pendulum.cart.body.wa[3] * (pendulum.cart.body.wa[3] * pendulum.cart.body.rCM[1] - pendulum.cart.body.wa[1] * pendulum.cart.body.rCM[3])) * pendulum.cart.body.m;
//   pendulum.cart.body.fa[2] = (pendulum.cart.body.aa[2] + pendulum.cart.body.za[3] * pendulum.cart.body.rCM[1] - pendulum.cart.body.za[1] * pendulum.cart.body.rCM[3] + pendulum.cart.body.wa[3] * (pendulum.cart.body.wa[2] * pendulum.cart.body.rCM[3] - pendulum.cart.body.wa[3] * pendulum.cart.body.rCM[2]) - pendulum.cart.body.wa[1] * (pendulum.cart.body.wa[1] * pendulum.cart.body.rCM[2] - pendulum.cart.body.wa[2] * pendulum.cart.body.rCM[1])) * pendulum.cart.body.m;
//   pendulum.cart.body.fa[3] = (pendulum.cart.body.aa[3] + pendulum.cart.body.za[1] * pendulum.cart.body.rCM[2] - pendulum.cart.body.za[2] * pendulum.cart.body.rCM[1] + pendulum.cart.body.wa[1] * (pendulum.cart.body.wa[3] * pendulum.cart.body.rCM[1] - pendulum.cart.body.wa[1] * pendulum.cart.body.rCM[3]) - pendulum.cart.body.wa[2] * (pendulum.cart.body.wa[2] * pendulum.cart.body.rCM[3] - pendulum.cart.body.wa[3] * pendulum.cart.body.rCM[2])) * pendulum.cart.body.m;
//   pendulum.cart.body.ta[1] = pendulum.cart.body.I[1,1] * pendulum.cart.body.za[1] + pendulum.cart.body.I[1,2] * pendulum.cart.body.za[2] + pendulum.cart.body.I[1,3] * pendulum.cart.body.za[3] + pendulum.cart.body.wa[2] * (pendulum.cart.body.I[3,1] * pendulum.cart.body.wa[1] + pendulum.cart.body.I[3,2] * pendulum.cart.body.wa[2] + pendulum.cart.body.I[3,3] * pendulum.cart.body.wa[3]) - pendulum.cart.body.wa[3] * (pendulum.cart.body.I[2,1] * pendulum.cart.body.wa[1] + pendulum.cart.body.I[2,2] * pendulum.cart.body.wa[2] + pendulum.cart.body.I[2,3] * pendulum.cart.body.wa[3]) + pendulum.cart.body.rCM[2] * pendulum.cart.body.fa[3] - pendulum.cart.body.rCM[3] * pendulum.cart.body.fa[2];
//   pendulum.cart.body.ta[2] = pendulum.cart.body.I[2,1] * pendulum.cart.body.za[1] + pendulum.cart.body.I[2,2] * pendulum.cart.body.za[2] + pendulum.cart.body.I[2,3] * pendulum.cart.body.za[3] + pendulum.cart.body.wa[3] * (pendulum.cart.body.I[1,1] * pendulum.cart.body.wa[1] + pendulum.cart.body.I[1,2] * pendulum.cart.body.wa[2] + pendulum.cart.body.I[1,3] * pendulum.cart.body.wa[3]) - pendulum.cart.body.wa[1] * (pendulum.cart.body.I[3,1] * pendulum.cart.body.wa[1] + pendulum.cart.body.I[3,2] * pendulum.cart.body.wa[2] + pendulum.cart.body.I[3,3] * pendulum.cart.body.wa[3]) + pendulum.cart.body.rCM[3] * pendulum.cart.body.fa[1] - pendulum.cart.body.rCM[1] * pendulum.cart.body.fa[3];
//   pendulum.cart.body.ta[3] = pendulum.cart.body.I[3,1] * pendulum.cart.body.za[1] + pendulum.cart.body.I[3,2] * pendulum.cart.body.za[2] + pendulum.cart.body.I[3,3] * pendulum.cart.body.za[3] + pendulum.cart.body.wa[1] * (pendulum.cart.body.I[2,1] * pendulum.cart.body.wa[1] + pendulum.cart.body.I[2,2] * pendulum.cart.body.wa[2] + pendulum.cart.body.I[2,3] * pendulum.cart.body.wa[3]) - pendulum.cart.body.wa[2] * (pendulum.cart.body.I[1,1] * pendulum.cart.body.wa[1] + pendulum.cart.body.I[1,2] * pendulum.cart.body.wa[2] + pendulum.cart.body.I[1,3] * pendulum.cart.body.wa[3]) + pendulum.cart.body.rCM[1] * pendulum.cart.body.fa[2] - pendulum.cart.body.rCM[2] * pendulum.cart.body.fa[1];
//   pendulum.cart.box.S[1,1] = pendulum.cart.Sa[1,1];
//   pendulum.cart.box.S[1,2] = pendulum.cart.Sa[1,2];
//   pendulum.cart.box.S[1,3] = pendulum.cart.Sa[1,3];
//   pendulum.cart.box.S[2,1] = pendulum.cart.Sa[2,1];
//   pendulum.cart.box.S[2,2] = pendulum.cart.Sa[2,2];
//   pendulum.cart.box.S[2,3] = pendulum.cart.Sa[2,3];
//   pendulum.cart.box.S[3,1] = pendulum.cart.Sa[3,1];
//   pendulum.cart.box.S[3,2] = pendulum.cart.Sa[3,2];
//   pendulum.cart.box.S[3,3] = pendulum.cart.Sa[3,3];
//   pendulum.cart.box.r[1] = pendulum.cart.r0a[1];
//   pendulum.cart.box.r[2] = pendulum.cart.r0a[2];
//   pendulum.cart.box.r[3] = pendulum.cart.r0a[3];
//   pendulum.cart.box.Sshape[1,1] = pendulum.cart.Sbox[1,1];
//   pendulum.cart.box.Sshape[1,2] = pendulum.cart.Sbox[1,2];
//   pendulum.cart.box.Sshape[1,3] = pendulum.cart.Sbox[1,3];
//   pendulum.cart.box.Sshape[2,1] = pendulum.cart.Sbox[2,1];
//   pendulum.cart.box.Sshape[2,2] = pendulum.cart.Sbox[2,2];
//   pendulum.cart.box.Sshape[2,3] = pendulum.cart.Sbox[2,3];
//   pendulum.cart.box.Sshape[3,1] = pendulum.cart.Sbox[3,1];
//   pendulum.cart.box.Sshape[3,2] = pendulum.cart.Sbox[3,2];
//   pendulum.cart.box.Sshape[3,3] = pendulum.cart.Sbox[3,3];
//   pendulum.cart.l = pendulum.cart.length;
//   pendulum.cart.w = pendulum.cart.Width;
//   pendulum.cart.h = pendulum.cart.Height;
//   pendulum.cart.wi = pendulum.cart.InnerWidth;
//   pendulum.cart.hi = pendulum.cart.InnerHeight;
//   pendulum.cart.mo = 1000.0 * pendulum.cart.rho * pendulum.cart.l * pendulum.cart.w * pendulum.cart.h "Mass properties of box";
//   pendulum.cart.mi = 1000.0 * pendulum.cart.rho * pendulum.cart.l * pendulum.cart.wi * pendulum.cart.hi;
//   pendulum.cart.body.m = pendulum.cart.mo - pendulum.cart.mi;
//   pendulum.cart.body.rCM[1] = pendulum.cart.r0[1] + pendulum.cart.box.nLength[1] * 0.5 * pendulum.cart.l;
//   pendulum.cart.body.rCM[2] = pendulum.cart.r0[2] + pendulum.cart.box.nLength[2] * 0.5 * pendulum.cart.l;
//   pendulum.cart.body.rCM[3] = pendulum.cart.r0[3] + pendulum.cart.box.nLength[3] * 0.5 * pendulum.cart.l;
//   pendulum.cart.body.I[1,1] = (pendulum.cart.mo * (pendulum.cart.w ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.wi ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[1,1] ^ 2.0 + (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[1,2] ^ 2.0 + (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.w ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.wi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[1,3] ^ 2.0;
//   pendulum.cart.body.I[1,2] = pendulum.cart.Sbox[1,1] * (pendulum.cart.mo * (pendulum.cart.w ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.wi ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[2,1] + pendulum.cart.Sbox[1,2] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[2,2] + pendulum.cart.Sbox[1,3] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.w ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.wi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[2,3];
//   pendulum.cart.body.I[1,3] = pendulum.cart.Sbox[1,1] * (pendulum.cart.mo * (pendulum.cart.w ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.wi ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[3,1] + pendulum.cart.Sbox[1,2] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[3,2] + pendulum.cart.Sbox[1,3] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.w ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.wi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[3,3];
//   pendulum.cart.body.I[2,1] = pendulum.cart.Sbox[2,1] * (pendulum.cart.mo * (pendulum.cart.w ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.wi ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[1,1] + pendulum.cart.Sbox[2,2] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[1,2] + pendulum.cart.Sbox[2,3] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.w ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.wi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[1,3];
//   pendulum.cart.body.I[2,2] = (pendulum.cart.mo * (pendulum.cart.w ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.wi ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[2,1] ^ 2.0 + (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[2,2] ^ 2.0 + (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.w ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.wi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[2,3] ^ 2.0;
//   pendulum.cart.body.I[2,3] = pendulum.cart.Sbox[2,1] * (pendulum.cart.mo * (pendulum.cart.w ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.wi ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[3,1] + pendulum.cart.Sbox[2,2] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[3,2] + pendulum.cart.Sbox[2,3] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.w ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.wi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[3,3];
//   pendulum.cart.body.I[3,1] = pendulum.cart.Sbox[3,1] * (pendulum.cart.mo * (pendulum.cart.w ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.wi ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[1,1] + pendulum.cart.Sbox[3,2] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[1,2] + pendulum.cart.Sbox[3,3] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.w ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.wi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[1,3];
//   pendulum.cart.body.I[3,2] = pendulum.cart.Sbox[3,1] * (pendulum.cart.mo * (pendulum.cart.w ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.wi ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[2,1] + pendulum.cart.Sbox[3,2] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[2,2] + pendulum.cart.Sbox[3,3] * (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.w ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.wi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[2,3];
//   pendulum.cart.body.I[3,3] = (pendulum.cart.mo * (pendulum.cart.w ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.wi ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[3,1] ^ 2.0 + (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.h ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.hi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[3,2] ^ 2.0 + (pendulum.cart.mo * (pendulum.cart.l ^ 2.0 + pendulum.cart.w ^ 2.0) - pendulum.cart.mi * (pendulum.cart.l ^ 2.0 + pendulum.cart.wi ^ 2.0)) / 12.0 * pendulum.cart.Sbox[3,3] ^ 2.0;
//   pendulum.pendulum.frame_a.r0 = {pendulum.pendulum.r0a[1], pendulum.pendulum.r0a[2], pendulum.pendulum.r0a[3]};
//   pendulum.pendulum.frame_a.S = {{pendulum.pendulum.Sa[1,1], pendulum.pendulum.Sa[1,2], pendulum.pendulum.Sa[1,3]}, {pendulum.pendulum.Sa[2,1], pendulum.pendulum.Sa[2,2], pendulum.pendulum.Sa[2,3]}, {pendulum.pendulum.Sa[3,1], pendulum.pendulum.Sa[3,2], pendulum.pendulum.Sa[3,3]}};
//   pendulum.pendulum.frame_a.v = {pendulum.pendulum.va[1], pendulum.pendulum.va[2], pendulum.pendulum.va[3]};
//   pendulum.pendulum.frame_a.w = {pendulum.pendulum.wa[1], pendulum.pendulum.wa[2], pendulum.pendulum.wa[3]};
//   pendulum.pendulum.frame_a.a = {pendulum.pendulum.aa[1], pendulum.pendulum.aa[2], pendulum.pendulum.aa[3]};
//   pendulum.pendulum.frame_a.z = {pendulum.pendulum.za[1], pendulum.pendulum.za[2], pendulum.pendulum.za[3]};
//   pendulum.pendulum.frame_a.f = {pendulum.pendulum.fa[1], pendulum.pendulum.fa[2], pendulum.pendulum.fa[3]};
//   pendulum.pendulum.frame_a.t = {pendulum.pendulum.ta[1], pendulum.pendulum.ta[2], pendulum.pendulum.ta[3]};
//   pendulum.pendulum.frame_b.r0 = {pendulum.pendulum.r0b[1], pendulum.pendulum.r0b[2], pendulum.pendulum.r0b[3]};
//   pendulum.pendulum.frame_b.S = {{pendulum.pendulum.Sb[1,1], pendulum.pendulum.Sb[1,2], pendulum.pendulum.Sb[1,3]}, {pendulum.pendulum.Sb[2,1], pendulum.pendulum.Sb[2,2], pendulum.pendulum.Sb[2,3]}, {pendulum.pendulum.Sb[3,1], pendulum.pendulum.Sb[3,2], pendulum.pendulum.Sb[3,3]}};
//   pendulum.pendulum.frame_b.v = {pendulum.pendulum.vb[1], pendulum.pendulum.vb[2], pendulum.pendulum.vb[3]};
//   pendulum.pendulum.frame_b.w = {pendulum.pendulum.wb[1], pendulum.pendulum.wb[2], pendulum.pendulum.wb[3]};
//   pendulum.pendulum.frame_b.a = {pendulum.pendulum.ab[1], pendulum.pendulum.ab[2], pendulum.pendulum.ab[3]};
//   pendulum.pendulum.frame_b.z = {pendulum.pendulum.zb[1], pendulum.pendulum.zb[2], pendulum.pendulum.zb[3]};
//   pendulum.pendulum.frame_b.f = {-pendulum.pendulum.fb[1], -pendulum.pendulum.fb[2], -pendulum.pendulum.fb[3]};
//   pendulum.pendulum.frame_b.t = {-pendulum.pendulum.tb[1], -pendulum.pendulum.tb[2], -pendulum.pendulum.tb[3]};
//   pendulum.pendulum.box.mcShape.r = {pendulum.pendulum.box.r[1], pendulum.pendulum.box.r[2], pendulum.pendulum.box.r[3]};
//   pendulum.pendulum.box.mcShape.r_shape = {pendulum.pendulum.box.r0[1], pendulum.pendulum.box.r0[2], pendulum.pendulum.box.r0[3]};
//   pendulum.pendulum.box.mcShape.lengthDirection = {pendulum.pendulum.box.LengthDirection[1], pendulum.pendulum.box.LengthDirection[2], pendulum.pendulum.box.LengthDirection[3]};
//   pendulum.pendulum.box.mcShape.widthDirection = {pendulum.pendulum.box.WidthDirection[1], pendulum.pendulum.box.WidthDirection[2], pendulum.pendulum.box.WidthDirection[3]};
//   pendulum.pendulum.box.mcShape.color = {pendulum.pendulum.box.Material[1] * 255.0, pendulum.pendulum.box.Material[2] * 255.0, pendulum.pendulum.box.Material[3] * 255.0};
//   pendulum.pendulum.box.mcShape.S = {{pendulum.pendulum.box.S[1,1], pendulum.pendulum.box.S[1,2], pendulum.pendulum.box.S[1,3]}, {pendulum.pendulum.box.S[2,1], pendulum.pendulum.box.S[2,2], pendulum.pendulum.box.S[2,3]}, {pendulum.pendulum.box.S[3,1], pendulum.pendulum.box.S[3,2], pendulum.pendulum.box.S[3,3]}};
//   pendulum.pendulum.box.mcShape.Sshape = {{pendulum.pendulum.box.Sshape[1,1], pendulum.pendulum.box.Sshape[1,2], pendulum.pendulum.box.Sshape[1,3]}, {pendulum.pendulum.box.Sshape[2,1], pendulum.pendulum.box.Sshape[2,2], pendulum.pendulum.box.Sshape[2,3]}, {pendulum.pendulum.box.Sshape[3,1], pendulum.pendulum.box.Sshape[3,2], pendulum.pendulum.box.Sshape[3,3]}};
//   pendulum.pendulum.box.mcShape.e_x = if noEvent(pendulum.pendulum.box.mcShape.abs_n_x < 1e-10) then {1.0, 0.0, 0.0} else {pendulum.pendulum.box.mcShape.lengthDirection[1] / pendulum.pendulum.box.mcShape.abs_n_x, pendulum.pendulum.box.mcShape.lengthDirection[2] / pendulum.pendulum.box.mcShape.abs_n_x, pendulum.pendulum.box.mcShape.lengthDirection[3] / pendulum.pendulum.box.mcShape.abs_n_x};
//   pendulum.pendulum.box.mcShape.n_z_aux = {pendulum.pendulum.box.mcShape.e_x[2] * pendulum.pendulum.box.mcShape.widthDirection[3] - pendulum.pendulum.box.mcShape.e_x[3] * pendulum.pendulum.box.mcShape.widthDirection[2], pendulum.pendulum.box.mcShape.e_x[3] * pendulum.pendulum.box.mcShape.widthDirection[1] - pendulum.pendulum.box.mcShape.e_x[1] * pendulum.pendulum.box.mcShape.widthDirection[3], pendulum.pendulum.box.mcShape.e_x[1] * pendulum.pendulum.box.mcShape.widthDirection[2] - pendulum.pendulum.box.mcShape.e_x[2] * pendulum.pendulum.box.mcShape.widthDirection[1]};
//   pendulum.pendulum.box.mcShape.e_y = cross(MCVisualShape$pendulum$pendulum$box$mcShape.local_normalize(cross({pendulum.pendulum.box.mcShape.e_x[1], pendulum.pendulum.box.mcShape.e_x[2], pendulum.pendulum.box.mcShape.e_x[3]}, if noEvent(pendulum.pendulum.box.mcShape.n_z_aux[1] ^ 2.0 + pendulum.pendulum.box.mcShape.n_z_aux[2] ^ 2.0 + pendulum.pendulum.box.mcShape.n_z_aux[3] ^ 2.0 > 1e-06) then {pendulum.pendulum.box.mcShape.widthDirection[1], pendulum.pendulum.box.mcShape.widthDirection[2], pendulum.pendulum.box.mcShape.widthDirection[3]} else if noEvent(abs(pendulum.pendulum.box.mcShape.e_x[1]) > 1e-06) then {0.0, 1.0, 0.0} else {1.0, 0.0, 0.0})), {pendulum.pendulum.box.mcShape.e_x[1], pendulum.pendulum.box.mcShape.e_x[2], pendulum.pendulum.box.mcShape.e_x[3]});
//   pendulum.pendulum.box.mcShape.e_z = {pendulum.pendulum.box.mcShape.e_x[2] * pendulum.pendulum.box.mcShape.e_y[3] - pendulum.pendulum.box.mcShape.e_x[3] * pendulum.pendulum.box.mcShape.e_y[2], pendulum.pendulum.box.mcShape.e_x[3] * pendulum.pendulum.box.mcShape.e_y[1] - pendulum.pendulum.box.mcShape.e_x[1] * pendulum.pendulum.box.mcShape.e_y[3], pendulum.pendulum.box.mcShape.e_x[1] * pendulum.pendulum.box.mcShape.e_y[2] - pendulum.pendulum.box.mcShape.e_x[2] * pendulum.pendulum.box.mcShape.e_y[1]};
//   pendulum.pendulum.box.mcShape.Form = 1e+20 * (987000.0 + PackShape(pendulum.pendulum.box.mcShape.shapeType));
//   pendulum.pendulum.box.mcShape.Material = PackMaterial(0.00392156862745098 * pendulum.pendulum.box.mcShape.color[1], 0.00392156862745098 * pendulum.pendulum.box.mcShape.color[2], 0.00392156862745098 * pendulum.pendulum.box.mcShape.color[3], pendulum.pendulum.box.mcShape.specularCoefficient);
//   pendulum.pendulum.box.mcShape.Extra = pendulum.pendulum.box.mcShape.extra;
//   pendulum.pendulum.box.mcShape.size[1] = pendulum.pendulum.box.mcShape.length;
//   pendulum.pendulum.box.mcShape.size[2] = pendulum.pendulum.box.mcShape.width;
//   pendulum.pendulum.box.mcShape.size[3] = pendulum.pendulum.box.mcShape.height;
//   pendulum.pendulum.box.mcShape.Sshape[1,1] = pendulum.pendulum.box.mcShape.e_x[1];
//   pendulum.pendulum.box.mcShape.Sshape[1,2] = pendulum.pendulum.box.mcShape.e_y[1];
//   pendulum.pendulum.box.mcShape.Sshape[1,3] = pendulum.pendulum.box.mcShape.e_x[2] * pendulum.pendulum.box.mcShape.e_y[3] - pendulum.pendulum.box.mcShape.e_x[3] * pendulum.pendulum.box.mcShape.e_y[2];
//   pendulum.pendulum.box.mcShape.Sshape[2,1] = pendulum.pendulum.box.mcShape.e_x[2];
//   pendulum.pendulum.box.mcShape.Sshape[2,2] = pendulum.pendulum.box.mcShape.e_y[2];
//   pendulum.pendulum.box.mcShape.Sshape[2,3] = pendulum.pendulum.box.mcShape.e_x[3] * pendulum.pendulum.box.mcShape.e_y[1] - pendulum.pendulum.box.mcShape.e_x[1] * pendulum.pendulum.box.mcShape.e_y[3];
//   pendulum.pendulum.box.mcShape.Sshape[3,1] = pendulum.pendulum.box.mcShape.e_x[3];
//   pendulum.pendulum.box.mcShape.Sshape[3,2] = pendulum.pendulum.box.mcShape.e_y[3];
//   pendulum.pendulum.box.mcShape.Sshape[3,3] = pendulum.pendulum.box.mcShape.e_x[1] * pendulum.pendulum.box.mcShape.e_y[2] - pendulum.pendulum.box.mcShape.e_x[2] * pendulum.pendulum.box.mcShape.e_y[1];
//   pendulum.pendulum.box.mcShape.rxvisobj[1] = pendulum.pendulum.box.mcShape.S[1,1] * pendulum.pendulum.box.mcShape.e_x[1] + pendulum.pendulum.box.mcShape.S[1,2] * pendulum.pendulum.box.mcShape.e_x[2] + pendulum.pendulum.box.mcShape.S[1,3] * pendulum.pendulum.box.mcShape.e_x[3];
//   pendulum.pendulum.box.mcShape.rxvisobj[2] = pendulum.pendulum.box.mcShape.S[2,1] * pendulum.pendulum.box.mcShape.e_x[1] + pendulum.pendulum.box.mcShape.S[2,2] * pendulum.pendulum.box.mcShape.e_x[2] + pendulum.pendulum.box.mcShape.S[2,3] * pendulum.pendulum.box.mcShape.e_x[3];
//   pendulum.pendulum.box.mcShape.rxvisobj[3] = pendulum.pendulum.box.mcShape.S[3,1] * pendulum.pendulum.box.mcShape.e_x[1] + pendulum.pendulum.box.mcShape.S[3,2] * pendulum.pendulum.box.mcShape.e_x[2] + pendulum.pendulum.box.mcShape.S[3,3] * pendulum.pendulum.box.mcShape.e_x[3];
//   pendulum.pendulum.box.mcShape.ryvisobj[1] = pendulum.pendulum.box.mcShape.S[1,1] * pendulum.pendulum.box.mcShape.e_y[1] + pendulum.pendulum.box.mcShape.S[1,2] * pendulum.pendulum.box.mcShape.e_y[2] + pendulum.pendulum.box.mcShape.S[1,3] * pendulum.pendulum.box.mcShape.e_y[3];
//   pendulum.pendulum.box.mcShape.ryvisobj[2] = pendulum.pendulum.box.mcShape.S[2,1] * pendulum.pendulum.box.mcShape.e_y[1] + pendulum.pendulum.box.mcShape.S[2,2] * pendulum.pendulum.box.mcShape.e_y[2] + pendulum.pendulum.box.mcShape.S[2,3] * pendulum.pendulum.box.mcShape.e_y[3];
//   pendulum.pendulum.box.mcShape.ryvisobj[3] = pendulum.pendulum.box.mcShape.S[3,1] * pendulum.pendulum.box.mcShape.e_y[1] + pendulum.pendulum.box.mcShape.S[3,2] * pendulum.pendulum.box.mcShape.e_y[2] + pendulum.pendulum.box.mcShape.S[3,3] * pendulum.pendulum.box.mcShape.e_y[3];
//   pendulum.pendulum.box.mcShape.rvisobj[1] = pendulum.pendulum.box.mcShape.r[1] + pendulum.pendulum.box.mcShape.S[1,1] * pendulum.pendulum.box.mcShape.r_shape[1] + pendulum.pendulum.box.mcShape.S[1,2] * pendulum.pendulum.box.mcShape.r_shape[2] + pendulum.pendulum.box.mcShape.S[1,3] * pendulum.pendulum.box.mcShape.r_shape[3];
//   pendulum.pendulum.box.mcShape.rvisobj[2] = pendulum.pendulum.box.mcShape.r[2] + pendulum.pendulum.box.mcShape.S[2,1] * pendulum.pendulum.box.mcShape.r_shape[1] + pendulum.pendulum.box.mcShape.S[2,2] * pendulum.pendulum.box.mcShape.r_shape[2] + pendulum.pendulum.box.mcShape.S[2,3] * pendulum.pendulum.box.mcShape.r_shape[3];
//   pendulum.pendulum.box.mcShape.rvisobj[3] = pendulum.pendulum.box.mcShape.r[3] + pendulum.pendulum.box.mcShape.S[3,1] * pendulum.pendulum.box.mcShape.r_shape[1] + pendulum.pendulum.box.mcShape.S[3,2] * pendulum.pendulum.box.mcShape.r_shape[2] + pendulum.pendulum.box.mcShape.S[3,3] * pendulum.pendulum.box.mcShape.r_shape[3];
//   pendulum.pendulum.box.mcShape.e_x[1] = pendulum.pendulum.box.nLength[1];
//   pendulum.pendulum.box.mcShape.e_x[2] = pendulum.pendulum.box.nLength[2];
//   pendulum.pendulum.box.mcShape.e_x[3] = pendulum.pendulum.box.nLength[3];
//   pendulum.pendulum.box.mcShape.e_y[1] = pendulum.pendulum.box.nWidth[1];
//   pendulum.pendulum.box.mcShape.e_y[2] = pendulum.pendulum.box.nWidth[2];
//   pendulum.pendulum.box.mcShape.e_y[3] = pendulum.pendulum.box.nWidth[3];
//   pendulum.pendulum.box.mcShape.e_z[1] = pendulum.pendulum.box.nHeight[1];
//   pendulum.pendulum.box.mcShape.e_z[2] = pendulum.pendulum.box.nHeight[2];
//   pendulum.pendulum.box.mcShape.e_z[3] = pendulum.pendulum.box.nHeight[3];
//   pendulum.pendulum.frameTranslation.frame_a.r0 = {pendulum.pendulum.frameTranslation.r0a[1], pendulum.pendulum.frameTranslation.r0a[2], pendulum.pendulum.frameTranslation.r0a[3]};
//   pendulum.pendulum.frameTranslation.frame_a.S = {{pendulum.pendulum.frameTranslation.Sa[1,1], pendulum.pendulum.frameTranslation.Sa[1,2], pendulum.pendulum.frameTranslation.Sa[1,3]}, {pendulum.pendulum.frameTranslation.Sa[2,1], pendulum.pendulum.frameTranslation.Sa[2,2], pendulum.pendulum.frameTranslation.Sa[2,3]}, {pendulum.pendulum.frameTranslation.Sa[3,1], pendulum.pendulum.frameTranslation.Sa[3,2], pendulum.pendulum.frameTranslation.Sa[3,3]}};
//   pendulum.pendulum.frameTranslation.frame_a.v = {pendulum.pendulum.frameTranslation.va[1], pendulum.pendulum.frameTranslation.va[2], pendulum.pendulum.frameTranslation.va[3]};
//   pendulum.pendulum.frameTranslation.frame_a.w = {pendulum.pendulum.frameTranslation.wa[1], pendulum.pendulum.frameTranslation.wa[2], pendulum.pendulum.frameTranslation.wa[3]};
//   pendulum.pendulum.frameTranslation.frame_a.a = {pendulum.pendulum.frameTranslation.aa[1], pendulum.pendulum.frameTranslation.aa[2], pendulum.pendulum.frameTranslation.aa[3]};
//   pendulum.pendulum.frameTranslation.frame_a.z = {pendulum.pendulum.frameTranslation.za[1], pendulum.pendulum.frameTranslation.za[2], pendulum.pendulum.frameTranslation.za[3]};
//   pendulum.pendulum.frameTranslation.frame_a.f = {pendulum.pendulum.frameTranslation.fa[1], pendulum.pendulum.frameTranslation.fa[2], pendulum.pendulum.frameTranslation.fa[3]};
//   pendulum.pendulum.frameTranslation.frame_a.t = {pendulum.pendulum.frameTranslation.ta[1], pendulum.pendulum.frameTranslation.ta[2], pendulum.pendulum.frameTranslation.ta[3]};
//   pendulum.pendulum.frameTranslation.frame_b.r0 = {pendulum.pendulum.frameTranslation.r0b[1], pendulum.pendulum.frameTranslation.r0b[2], pendulum.pendulum.frameTranslation.r0b[3]};
//   pendulum.pendulum.frameTranslation.frame_b.S = {{pendulum.pendulum.frameTranslation.Sb[1,1], pendulum.pendulum.frameTranslation.Sb[1,2], pendulum.pendulum.frameTranslation.Sb[1,3]}, {pendulum.pendulum.frameTranslation.Sb[2,1], pendulum.pendulum.frameTranslation.Sb[2,2], pendulum.pendulum.frameTranslation.Sb[2,3]}, {pendulum.pendulum.frameTranslation.Sb[3,1], pendulum.pendulum.frameTranslation.Sb[3,2], pendulum.pendulum.frameTranslation.Sb[3,3]}};
//   pendulum.pendulum.frameTranslation.frame_b.v = {pendulum.pendulum.frameTranslation.vb[1], pendulum.pendulum.frameTranslation.vb[2], pendulum.pendulum.frameTranslation.vb[3]};
//   pendulum.pendulum.frameTranslation.frame_b.w = {pendulum.pendulum.frameTranslation.wb[1], pendulum.pendulum.frameTranslation.wb[2], pendulum.pendulum.frameTranslation.wb[3]};
//   pendulum.pendulum.frameTranslation.frame_b.a = {pendulum.pendulum.frameTranslation.ab[1], pendulum.pendulum.frameTranslation.ab[2], pendulum.pendulum.frameTranslation.ab[3]};
//   pendulum.pendulum.frameTranslation.frame_b.z = {pendulum.pendulum.frameTranslation.zb[1], pendulum.pendulum.frameTranslation.zb[2], pendulum.pendulum.frameTranslation.zb[3]};
//   pendulum.pendulum.frameTranslation.frame_b.f = {-pendulum.pendulum.frameTranslation.fb[1], -pendulum.pendulum.frameTranslation.fb[2], -pendulum.pendulum.frameTranslation.fb[3]};
//   pendulum.pendulum.frameTranslation.frame_b.t = {-pendulum.pendulum.frameTranslation.tb[1], -pendulum.pendulum.frameTranslation.tb[2], -pendulum.pendulum.frameTranslation.tb[3]};
//   pendulum.pendulum.frameTranslation.Sb[1,1] = pendulum.pendulum.frameTranslation.Sa[1,1];
//   pendulum.pendulum.frameTranslation.Sb[1,2] = pendulum.pendulum.frameTranslation.Sa[1,2];
//   pendulum.pendulum.frameTranslation.Sb[1,3] = pendulum.pendulum.frameTranslation.Sa[1,3];
//   pendulum.pendulum.frameTranslation.Sb[2,1] = pendulum.pendulum.frameTranslation.Sa[2,1];
//   pendulum.pendulum.frameTranslation.Sb[2,2] = pendulum.pendulum.frameTranslation.Sa[2,2];
//   pendulum.pendulum.frameTranslation.Sb[2,3] = pendulum.pendulum.frameTranslation.Sa[2,3];
//   pendulum.pendulum.frameTranslation.Sb[3,1] = pendulum.pendulum.frameTranslation.Sa[3,1];
//   pendulum.pendulum.frameTranslation.Sb[3,2] = pendulum.pendulum.frameTranslation.Sa[3,2];
//   pendulum.pendulum.frameTranslation.Sb[3,3] = pendulum.pendulum.frameTranslation.Sa[3,3];
//   pendulum.pendulum.frameTranslation.wb[1] = pendulum.pendulum.frameTranslation.wa[1];
//   pendulum.pendulum.frameTranslation.wb[2] = pendulum.pendulum.frameTranslation.wa[2];
//   pendulum.pendulum.frameTranslation.wb[3] = pendulum.pendulum.frameTranslation.wa[3];
//   pendulum.pendulum.frameTranslation.zb[1] = pendulum.pendulum.frameTranslation.za[1];
//   pendulum.pendulum.frameTranslation.zb[2] = pendulum.pendulum.frameTranslation.za[2];
//   pendulum.pendulum.frameTranslation.zb[3] = pendulum.pendulum.frameTranslation.za[3];
//   pendulum.pendulum.frameTranslation.r0b[1] = pendulum.pendulum.frameTranslation.r0a[1] + pendulum.pendulum.frameTranslation.Sa[1,1] * pendulum.pendulum.frameTranslation.r[1] + pendulum.pendulum.frameTranslation.Sa[1,2] * pendulum.pendulum.frameTranslation.r[2] + pendulum.pendulum.frameTranslation.Sa[1,3] * pendulum.pendulum.frameTranslation.r[3];
//   pendulum.pendulum.frameTranslation.r0b[2] = pendulum.pendulum.frameTranslation.r0a[2] + pendulum.pendulum.frameTranslation.Sa[2,1] * pendulum.pendulum.frameTranslation.r[1] + pendulum.pendulum.frameTranslation.Sa[2,2] * pendulum.pendulum.frameTranslation.r[2] + pendulum.pendulum.frameTranslation.Sa[2,3] * pendulum.pendulum.frameTranslation.r[3];
//   pendulum.pendulum.frameTranslation.r0b[3] = pendulum.pendulum.frameTranslation.r0a[3] + pendulum.pendulum.frameTranslation.Sa[3,1] * pendulum.pendulum.frameTranslation.r[1] + pendulum.pendulum.frameTranslation.Sa[3,2] * pendulum.pendulum.frameTranslation.r[2] + pendulum.pendulum.frameTranslation.Sa[3,3] * pendulum.pendulum.frameTranslation.r[3];
//   pendulum.pendulum.frameTranslation.vaux[1] = pendulum.pendulum.frameTranslation.wa[2] * pendulum.pendulum.frameTranslation.r[3] - pendulum.pendulum.frameTranslation.wa[3] * pendulum.pendulum.frameTranslation.r[2];
//   pendulum.pendulum.frameTranslation.vaux[2] = pendulum.pendulum.frameTranslation.wa[3] * pendulum.pendulum.frameTranslation.r[1] - pendulum.pendulum.frameTranslation.wa[1] * pendulum.pendulum.frameTranslation.r[3];
//   pendulum.pendulum.frameTranslation.vaux[3] = pendulum.pendulum.frameTranslation.wa[1] * pendulum.pendulum.frameTranslation.r[2] - pendulum.pendulum.frameTranslation.wa[2] * pendulum.pendulum.frameTranslation.r[1];
//   pendulum.pendulum.frameTranslation.vb[1] = pendulum.pendulum.frameTranslation.va[1] + pendulum.pendulum.frameTranslation.vaux[1];
//   pendulum.pendulum.frameTranslation.vb[2] = pendulum.pendulum.frameTranslation.va[2] + pendulum.pendulum.frameTranslation.vaux[2];
//   pendulum.pendulum.frameTranslation.vb[3] = pendulum.pendulum.frameTranslation.va[3] + pendulum.pendulum.frameTranslation.vaux[3];
//   pendulum.pendulum.frameTranslation.ab[1] = pendulum.pendulum.frameTranslation.aa[1] + pendulum.pendulum.frameTranslation.za[2] * pendulum.pendulum.frameTranslation.r[3] - pendulum.pendulum.frameTranslation.za[3] * pendulum.pendulum.frameTranslation.r[2] + pendulum.pendulum.frameTranslation.wa[2] * pendulum.pendulum.frameTranslation.vaux[3] - pendulum.pendulum.frameTranslation.wa[3] * pendulum.pendulum.frameTranslation.vaux[2];
//   pendulum.pendulum.frameTranslation.ab[2] = pendulum.pendulum.frameTranslation.aa[2] + pendulum.pendulum.frameTranslation.za[3] * pendulum.pendulum.frameTranslation.r[1] - pendulum.pendulum.frameTranslation.za[1] * pendulum.pendulum.frameTranslation.r[3] + pendulum.pendulum.frameTranslation.wa[3] * pendulum.pendulum.frameTranslation.vaux[1] - pendulum.pendulum.frameTranslation.wa[1] * pendulum.pendulum.frameTranslation.vaux[3];
//   pendulum.pendulum.frameTranslation.ab[3] = pendulum.pendulum.frameTranslation.aa[3] + pendulum.pendulum.frameTranslation.za[1] * pendulum.pendulum.frameTranslation.r[2] - pendulum.pendulum.frameTranslation.za[2] * pendulum.pendulum.frameTranslation.r[1] + pendulum.pendulum.frameTranslation.wa[1] * pendulum.pendulum.frameTranslation.vaux[2] - pendulum.pendulum.frameTranslation.wa[2] * pendulum.pendulum.frameTranslation.vaux[1];
//   pendulum.pendulum.frameTranslation.fa[1] = pendulum.pendulum.frameTranslation.fb[1] "Transform the force and torque acting at frame_b to frame_a";
//   pendulum.pendulum.frameTranslation.fa[2] = pendulum.pendulum.frameTranslation.fb[2] "Transform the force and torque acting at frame_b to frame_a";
//   pendulum.pendulum.frameTranslation.fa[3] = pendulum.pendulum.frameTranslation.fb[3] "Transform the force and torque acting at frame_b to frame_a";
//   pendulum.pendulum.frameTranslation.ta[1] = pendulum.pendulum.frameTranslation.tb[1] + pendulum.pendulum.frameTranslation.r[2] * pendulum.pendulum.frameTranslation.fa[3] - pendulum.pendulum.frameTranslation.r[3] * pendulum.pendulum.frameTranslation.fa[2];
//   pendulum.pendulum.frameTranslation.ta[2] = pendulum.pendulum.frameTranslation.tb[2] + pendulum.pendulum.frameTranslation.r[3] * pendulum.pendulum.frameTranslation.fa[1] - pendulum.pendulum.frameTranslation.r[1] * pendulum.pendulum.frameTranslation.fa[3];
//   pendulum.pendulum.frameTranslation.ta[3] = pendulum.pendulum.frameTranslation.tb[3] + pendulum.pendulum.frameTranslation.r[1] * pendulum.pendulum.frameTranslation.fa[2] - pendulum.pendulum.frameTranslation.r[2] * pendulum.pendulum.frameTranslation.fa[1];
//   pendulum.pendulum.body.frame_a.r0 = {pendulum.pendulum.body.r0a[1], pendulum.pendulum.body.r0a[2], pendulum.pendulum.body.r0a[3]};
//   pendulum.pendulum.body.frame_a.S = {{pendulum.pendulum.body.Sa[1,1], pendulum.pendulum.body.Sa[1,2], pendulum.pendulum.body.Sa[1,3]}, {pendulum.pendulum.body.Sa[2,1], pendulum.pendulum.body.Sa[2,2], pendulum.pendulum.body.Sa[2,3]}, {pendulum.pendulum.body.Sa[3,1], pendulum.pendulum.body.Sa[3,2], pendulum.pendulum.body.Sa[3,3]}};
//   pendulum.pendulum.body.frame_a.v = {pendulum.pendulum.body.va[1], pendulum.pendulum.body.va[2], pendulum.pendulum.body.va[3]};
//   pendulum.pendulum.body.frame_a.w = {pendulum.pendulum.body.wa[1], pendulum.pendulum.body.wa[2], pendulum.pendulum.body.wa[3]};
//   pendulum.pendulum.body.frame_a.a = {pendulum.pendulum.body.aa[1], pendulum.pendulum.body.aa[2], pendulum.pendulum.body.aa[3]};
//   pendulum.pendulum.body.frame_a.z = {pendulum.pendulum.body.za[1], pendulum.pendulum.body.za[2], pendulum.pendulum.body.za[3]};
//   pendulum.pendulum.body.frame_a.f = {pendulum.pendulum.body.fa[1], pendulum.pendulum.body.fa[2], pendulum.pendulum.body.fa[3]};
//   pendulum.pendulum.body.frame_a.t = {pendulum.pendulum.body.ta[1], pendulum.pendulum.body.ta[2], pendulum.pendulum.body.ta[3]};
//   pendulum.pendulum.body.fa[1] = (pendulum.pendulum.body.aa[1] + pendulum.pendulum.body.za[2] * pendulum.pendulum.body.rCM[3] - pendulum.pendulum.body.za[3] * pendulum.pendulum.body.rCM[2] + pendulum.pendulum.body.wa[2] * (pendulum.pendulum.body.wa[1] * pendulum.pendulum.body.rCM[2] - pendulum.pendulum.body.wa[2] * pendulum.pendulum.body.rCM[1]) - pendulum.pendulum.body.wa[3] * (pendulum.pendulum.body.wa[3] * pendulum.pendulum.body.rCM[1] - pendulum.pendulum.body.wa[1] * pendulum.pendulum.body.rCM[3])) * pendulum.pendulum.body.m;
//   pendulum.pendulum.body.fa[2] = (pendulum.pendulum.body.aa[2] + pendulum.pendulum.body.za[3] * pendulum.pendulum.body.rCM[1] - pendulum.pendulum.body.za[1] * pendulum.pendulum.body.rCM[3] + pendulum.pendulum.body.wa[3] * (pendulum.pendulum.body.wa[2] * pendulum.pendulum.body.rCM[3] - pendulum.pendulum.body.wa[3] * pendulum.pendulum.body.rCM[2]) - pendulum.pendulum.body.wa[1] * (pendulum.pendulum.body.wa[1] * pendulum.pendulum.body.rCM[2] - pendulum.pendulum.body.wa[2] * pendulum.pendulum.body.rCM[1])) * pendulum.pendulum.body.m;
//   pendulum.pendulum.body.fa[3] = (pendulum.pendulum.body.aa[3] + pendulum.pendulum.body.za[1] * pendulum.pendulum.body.rCM[2] - pendulum.pendulum.body.za[2] * pendulum.pendulum.body.rCM[1] + pendulum.pendulum.body.wa[1] * (pendulum.pendulum.body.wa[3] * pendulum.pendulum.body.rCM[1] - pendulum.pendulum.body.wa[1] * pendulum.pendulum.body.rCM[3]) - pendulum.pendulum.body.wa[2] * (pendulum.pendulum.body.wa[2] * pendulum.pendulum.body.rCM[3] - pendulum.pendulum.body.wa[3] * pendulum.pendulum.body.rCM[2])) * pendulum.pendulum.body.m;
//   pendulum.pendulum.body.ta[1] = pendulum.pendulum.body.I[1,1] * pendulum.pendulum.body.za[1] + pendulum.pendulum.body.I[1,2] * pendulum.pendulum.body.za[2] + pendulum.pendulum.body.I[1,3] * pendulum.pendulum.body.za[3] + pendulum.pendulum.body.wa[2] * (pendulum.pendulum.body.I[3,1] * pendulum.pendulum.body.wa[1] + pendulum.pendulum.body.I[3,2] * pendulum.pendulum.body.wa[2] + pendulum.pendulum.body.I[3,3] * pendulum.pendulum.body.wa[3]) - pendulum.pendulum.body.wa[3] * (pendulum.pendulum.body.I[2,1] * pendulum.pendulum.body.wa[1] + pendulum.pendulum.body.I[2,2] * pendulum.pendulum.body.wa[2] + pendulum.pendulum.body.I[2,3] * pendulum.pendulum.body.wa[3]) + pendulum.pendulum.body.rCM[2] * pendulum.pendulum.body.fa[3] - pendulum.pendulum.body.rCM[3] * pendulum.pendulum.body.fa[2];
//   pendulum.pendulum.body.ta[2] = pendulum.pendulum.body.I[2,1] * pendulum.pendulum.body.za[1] + pendulum.pendulum.body.I[2,2] * pendulum.pendulum.body.za[2] + pendulum.pendulum.body.I[2,3] * pendulum.pendulum.body.za[3] + pendulum.pendulum.body.wa[3] * (pendulum.pendulum.body.I[1,1] * pendulum.pendulum.body.wa[1] + pendulum.pendulum.body.I[1,2] * pendulum.pendulum.body.wa[2] + pendulum.pendulum.body.I[1,3] * pendulum.pendulum.body.wa[3]) - pendulum.pendulum.body.wa[1] * (pendulum.pendulum.body.I[3,1] * pendulum.pendulum.body.wa[1] + pendulum.pendulum.body.I[3,2] * pendulum.pendulum.body.wa[2] + pendulum.pendulum.body.I[3,3] * pendulum.pendulum.body.wa[3]) + pendulum.pendulum.body.rCM[3] * pendulum.pendulum.body.fa[1] - pendulum.pendulum.body.rCM[1] * pendulum.pendulum.body.fa[3];
//   pendulum.pendulum.body.ta[3] = pendulum.pendulum.body.I[3,1] * pendulum.pendulum.body.za[1] + pendulum.pendulum.body.I[3,2] * pendulum.pendulum.body.za[2] + pendulum.pendulum.body.I[3,3] * pendulum.pendulum.body.za[3] + pendulum.pendulum.body.wa[1] * (pendulum.pendulum.body.I[2,1] * pendulum.pendulum.body.wa[1] + pendulum.pendulum.body.I[2,2] * pendulum.pendulum.body.wa[2] + pendulum.pendulum.body.I[2,3] * pendulum.pendulum.body.wa[3]) - pendulum.pendulum.body.wa[2] * (pendulum.pendulum.body.I[1,1] * pendulum.pendulum.body.wa[1] + pendulum.pendulum.body.I[1,2] * pendulum.pendulum.body.wa[2] + pendulum.pendulum.body.I[1,3] * pendulum.pendulum.body.wa[3]) + pendulum.pendulum.body.rCM[1] * pendulum.pendulum.body.fa[2] - pendulum.pendulum.body.rCM[2] * pendulum.pendulum.body.fa[1];
//   pendulum.pendulum.box.S[1,1] = pendulum.pendulum.Sa[1,1];
//   pendulum.pendulum.box.S[1,2] = pendulum.pendulum.Sa[1,2];
//   pendulum.pendulum.box.S[1,3] = pendulum.pendulum.Sa[1,3];
//   pendulum.pendulum.box.S[2,1] = pendulum.pendulum.Sa[2,1];
//   pendulum.pendulum.box.S[2,2] = pendulum.pendulum.Sa[2,2];
//   pendulum.pendulum.box.S[2,3] = pendulum.pendulum.Sa[2,3];
//   pendulum.pendulum.box.S[3,1] = pendulum.pendulum.Sa[3,1];
//   pendulum.pendulum.box.S[3,2] = pendulum.pendulum.Sa[3,2];
//   pendulum.pendulum.box.S[3,3] = pendulum.pendulum.Sa[3,3];
//   pendulum.pendulum.box.r[1] = pendulum.pendulum.r0a[1];
//   pendulum.pendulum.box.r[2] = pendulum.pendulum.r0a[2];
//   pendulum.pendulum.box.r[3] = pendulum.pendulum.r0a[3];
//   pendulum.pendulum.box.Sshape[1,1] = pendulum.pendulum.Scyl[1,1];
//   pendulum.pendulum.box.Sshape[1,2] = pendulum.pendulum.Scyl[1,2];
//   pendulum.pendulum.box.Sshape[1,3] = pendulum.pendulum.Scyl[1,3];
//   pendulum.pendulum.box.Sshape[2,1] = pendulum.pendulum.Scyl[2,1];
//   pendulum.pendulum.box.Sshape[2,2] = pendulum.pendulum.Scyl[2,2];
//   pendulum.pendulum.box.Sshape[2,3] = pendulum.pendulum.Scyl[2,3];
//   pendulum.pendulum.box.Sshape[3,1] = pendulum.pendulum.Scyl[3,1];
//   pendulum.pendulum.box.Sshape[3,2] = pendulum.pendulum.Scyl[3,2];
//   pendulum.pendulum.box.Sshape[3,3] = pendulum.pendulum.Scyl[3,3];
//   pendulum.pendulum.mo = 3141.592653589793 * pendulum.pendulum.rho * pendulum.pendulum.length * pendulum.pendulum.Radius ^ 2.0 "Mass properties of cylinder";
//   pendulum.pendulum.mi = 3141.592653589793 * pendulum.pendulum.rho * pendulum.pendulum.length * pendulum.pendulum.InnerRadius ^ 2.0;
//   pendulum.pendulum.I22 = 0.08333333333333333 * (pendulum.pendulum.mo * (pendulum.pendulum.length ^ 2.0 + 3.0 * pendulum.pendulum.Radius ^ 2.0) - pendulum.pendulum.mi * (pendulum.pendulum.length ^ 2.0 + 3.0 * pendulum.pendulum.InnerRadius ^ 2.0));
//   pendulum.pendulum.body.m = pendulum.pendulum.mo - pendulum.pendulum.mi;
//   pendulum.pendulum.body.rCM[1] = pendulum.pendulum.r0[1] + pendulum.pendulum.box.nLength[1] * 0.5 * pendulum.pendulum.length;
//   pendulum.pendulum.body.rCM[2] = pendulum.pendulum.r0[2] + pendulum.pendulum.box.nLength[2] * 0.5 * pendulum.pendulum.length;
//   pendulum.pendulum.body.rCM[3] = pendulum.pendulum.r0[3] + pendulum.pendulum.box.nLength[3] * 0.5 * pendulum.pendulum.length;
//   pendulum.pendulum.body.I[1,1] = 0.5 * (pendulum.pendulum.mo * pendulum.pendulum.Radius ^ 2.0 - pendulum.pendulum.mi * pendulum.pendulum.InnerRadius ^ 2.0) * pendulum.pendulum.Scyl[1,1] ^ 2.0 + pendulum.pendulum.I22 * pendulum.pendulum.Scyl[1,2] ^ 2.0 + pendulum.pendulum.I22 * pendulum.pendulum.Scyl[1,3] ^ 2.0;
//   pendulum.pendulum.body.I[1,2] = pendulum.pendulum.Scyl[1,1] * 0.5 * (pendulum.pendulum.mo * pendulum.pendulum.Radius ^ 2.0 - pendulum.pendulum.mi * pendulum.pendulum.InnerRadius ^ 2.0) * pendulum.pendulum.Scyl[2,1] + pendulum.pendulum.Scyl[1,2] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[2,2] + pendulum.pendulum.Scyl[1,3] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[2,3];
//   pendulum.pendulum.body.I[1,3] = pendulum.pendulum.Scyl[1,1] * 0.5 * (pendulum.pendulum.mo * pendulum.pendulum.Radius ^ 2.0 - pendulum.pendulum.mi * pendulum.pendulum.InnerRadius ^ 2.0) * pendulum.pendulum.Scyl[3,1] + pendulum.pendulum.Scyl[1,2] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[3,2] + pendulum.pendulum.Scyl[1,3] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[3,3];
//   pendulum.pendulum.body.I[2,1] = pendulum.pendulum.Scyl[2,1] * 0.5 * (pendulum.pendulum.mo * pendulum.pendulum.Radius ^ 2.0 - pendulum.pendulum.mi * pendulum.pendulum.InnerRadius ^ 2.0) * pendulum.pendulum.Scyl[1,1] + pendulum.pendulum.Scyl[2,2] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[1,2] + pendulum.pendulum.Scyl[2,3] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[1,3];
//   pendulum.pendulum.body.I[2,2] = 0.5 * (pendulum.pendulum.mo * pendulum.pendulum.Radius ^ 2.0 - pendulum.pendulum.mi * pendulum.pendulum.InnerRadius ^ 2.0) * pendulum.pendulum.Scyl[2,1] ^ 2.0 + pendulum.pendulum.I22 * pendulum.pendulum.Scyl[2,2] ^ 2.0 + pendulum.pendulum.I22 * pendulum.pendulum.Scyl[2,3] ^ 2.0;
//   pendulum.pendulum.body.I[2,3] = pendulum.pendulum.Scyl[2,1] * 0.5 * (pendulum.pendulum.mo * pendulum.pendulum.Radius ^ 2.0 - pendulum.pendulum.mi * pendulum.pendulum.InnerRadius ^ 2.0) * pendulum.pendulum.Scyl[3,1] + pendulum.pendulum.Scyl[2,2] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[3,2] + pendulum.pendulum.Scyl[2,3] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[3,3];
//   pendulum.pendulum.body.I[3,1] = pendulum.pendulum.Scyl[3,1] * 0.5 * (pendulum.pendulum.mo * pendulum.pendulum.Radius ^ 2.0 - pendulum.pendulum.mi * pendulum.pendulum.InnerRadius ^ 2.0) * pendulum.pendulum.Scyl[1,1] + pendulum.pendulum.Scyl[3,2] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[1,2] + pendulum.pendulum.Scyl[3,3] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[1,3];
//   pendulum.pendulum.body.I[3,2] = pendulum.pendulum.Scyl[3,1] * 0.5 * (pendulum.pendulum.mo * pendulum.pendulum.Radius ^ 2.0 - pendulum.pendulum.mi * pendulum.pendulum.InnerRadius ^ 2.0) * pendulum.pendulum.Scyl[2,1] + pendulum.pendulum.Scyl[3,2] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[2,2] + pendulum.pendulum.Scyl[3,3] * pendulum.pendulum.I22 * pendulum.pendulum.Scyl[2,3];
//   pendulum.pendulum.body.I[3,3] = 0.5 * (pendulum.pendulum.mo * pendulum.pendulum.Radius ^ 2.0 - pendulum.pendulum.mi * pendulum.pendulum.InnerRadius ^ 2.0) * pendulum.pendulum.Scyl[3,1] ^ 2.0 + pendulum.pendulum.I22 * pendulum.pendulum.Scyl[3,2] ^ 2.0 + pendulum.pendulum.I22 * pendulum.pendulum.Scyl[3,3] ^ 2.0;
//   pendulum.pendulumJoint.frame_a.r0 = {pendulum.pendulumJoint.r0a[1], pendulum.pendulumJoint.r0a[2], pendulum.pendulumJoint.r0a[3]};
//   pendulum.pendulumJoint.frame_a.S = {{pendulum.pendulumJoint.Sa[1,1], pendulum.pendulumJoint.Sa[1,2], pendulum.pendulumJoint.Sa[1,3]}, {pendulum.pendulumJoint.Sa[2,1], pendulum.pendulumJoint.Sa[2,2], pendulum.pendulumJoint.Sa[2,3]}, {pendulum.pendulumJoint.Sa[3,1], pendulum.pendulumJoint.Sa[3,2], pendulum.pendulumJoint.Sa[3,3]}};
//   pendulum.pendulumJoint.frame_a.v = {pendulum.pendulumJoint.va[1], pendulum.pendulumJoint.va[2], pendulum.pendulumJoint.va[3]};
//   pendulum.pendulumJoint.frame_a.w = {pendulum.pendulumJoint.wa[1], pendulum.pendulumJoint.wa[2], pendulum.pendulumJoint.wa[3]};
//   pendulum.pendulumJoint.frame_a.a = {pendulum.pendulumJoint.aa[1], pendulum.pendulumJoint.aa[2], pendulum.pendulumJoint.aa[3]};
//   pendulum.pendulumJoint.frame_a.z = {pendulum.pendulumJoint.za[1], pendulum.pendulumJoint.za[2], pendulum.pendulumJoint.za[3]};
//   pendulum.pendulumJoint.frame_a.f = {pendulum.pendulumJoint.fa[1], pendulum.pendulumJoint.fa[2], pendulum.pendulumJoint.fa[3]};
//   pendulum.pendulumJoint.frame_a.t = {pendulum.pendulumJoint.ta[1], pendulum.pendulumJoint.ta[2], pendulum.pendulumJoint.ta[3]};
//   pendulum.pendulumJoint.frame_b.r0 = {pendulum.pendulumJoint.r0b[1], pendulum.pendulumJoint.r0b[2], pendulum.pendulumJoint.r0b[3]};
//   pendulum.pendulumJoint.frame_b.S = {{pendulum.pendulumJoint.Sb[1,1], pendulum.pendulumJoint.Sb[1,2], pendulum.pendulumJoint.Sb[1,3]}, {pendulum.pendulumJoint.Sb[2,1], pendulum.pendulumJoint.Sb[2,2], pendulum.pendulumJoint.Sb[2,3]}, {pendulum.pendulumJoint.Sb[3,1], pendulum.pendulumJoint.Sb[3,2], pendulum.pendulumJoint.Sb[3,3]}};
//   pendulum.pendulumJoint.frame_b.v = {pendulum.pendulumJoint.vb[1], pendulum.pendulumJoint.vb[2], pendulum.pendulumJoint.vb[3]};
//   pendulum.pendulumJoint.frame_b.w = {pendulum.pendulumJoint.wb[1], pendulum.pendulumJoint.wb[2], pendulum.pendulumJoint.wb[3]};
//   pendulum.pendulumJoint.frame_b.a = {pendulum.pendulumJoint.ab[1], pendulum.pendulumJoint.ab[2], pendulum.pendulumJoint.ab[3]};
//   pendulum.pendulumJoint.frame_b.z = {pendulum.pendulumJoint.zb[1], pendulum.pendulumJoint.zb[2], pendulum.pendulumJoint.zb[3]};
//   pendulum.pendulumJoint.frame_b.f = {-pendulum.pendulumJoint.fb[1], -pendulum.pendulumJoint.fb[2], -pendulum.pendulumJoint.fb[3]};
//   pendulum.pendulumJoint.frame_b.t = {-pendulum.pendulumJoint.tb[1], -pendulum.pendulumJoint.tb[2], -pendulum.pendulumJoint.tb[3]};
//   pendulum.pendulumJoint.axis.phi = pendulum.pendulumJoint.q;
//   pendulum.pendulumJoint.bearing.phi = 0.0;
//   pendulum.pendulumJoint.qd = der(pendulum.pendulumJoint.q) "define states";
//   pendulum.pendulumJoint.qdd = der(pendulum.pendulumJoint.qd);
//   pendulum.pendulumJoint.nn[1] = pendulum.pendulumJoint.n[1] / sqrt(pendulum.pendulumJoint.n[1] ^ 2.0 + pendulum.pendulumJoint.n[2] ^ 2.0 + pendulum.pendulumJoint.n[3] ^ 2.0) "rotation matrix";
//   pendulum.pendulumJoint.nn[2] = pendulum.pendulumJoint.n[2] / sqrt(pendulum.pendulumJoint.n[1] ^ 2.0 + pendulum.pendulumJoint.n[2] ^ 2.0 + pendulum.pendulumJoint.n[3] ^ 2.0) "rotation matrix";
//   pendulum.pendulumJoint.nn[3] = pendulum.pendulumJoint.n[3] / sqrt(pendulum.pendulumJoint.n[1] ^ 2.0 + pendulum.pendulumJoint.n[2] ^ 2.0 + pendulum.pendulumJoint.n[3] ^ 2.0) "rotation matrix";
//   pendulum.pendulumJoint.qq = pendulum.pendulumJoint.q + (-0.0174532925199433) * pendulum.pendulumJoint.q0;
//   pendulum.pendulumJoint.sinq = sin(pendulum.pendulumJoint.qq);
//   pendulum.pendulumJoint.cosq = cos(pendulum.pendulumJoint.qq);
//   pendulum.pendulumJoint.S_rel[1,1] = pendulum.pendulumJoint.nn[1] ^ 2.0 + (1.0 - pendulum.pendulumJoint.nn[1] ^ 2.0) * pendulum.pendulumJoint.cosq;
//   pendulum.pendulumJoint.S_rel[1,2] = (pendulum.pendulumJoint.nn[1] - pendulum.pendulumJoint.nn[1] * pendulum.pendulumJoint.cosq) * pendulum.pendulumJoint.nn[2] + pendulum.pendulumJoint.nn[3] * pendulum.pendulumJoint.sinq;
//   pendulum.pendulumJoint.S_rel[1,3] = (pendulum.pendulumJoint.nn[1] - pendulum.pendulumJoint.nn[1] * pendulum.pendulumJoint.cosq) * pendulum.pendulumJoint.nn[3] - pendulum.pendulumJoint.nn[2] * pendulum.pendulumJoint.sinq;
//   pendulum.pendulumJoint.S_rel[2,1] = (pendulum.pendulumJoint.nn[2] - pendulum.pendulumJoint.nn[2] * pendulum.pendulumJoint.cosq) * pendulum.pendulumJoint.nn[1] - pendulum.pendulumJoint.nn[3] * pendulum.pendulumJoint.sinq;
//   pendulum.pendulumJoint.S_rel[2,2] = pendulum.pendulumJoint.nn[2] ^ 2.0 + (1.0 - pendulum.pendulumJoint.nn[2] ^ 2.0) * pendulum.pendulumJoint.cosq;
//   pendulum.pendulumJoint.S_rel[2,3] = (pendulum.pendulumJoint.nn[2] - pendulum.pendulumJoint.nn[2] * pendulum.pendulumJoint.cosq) * pendulum.pendulumJoint.nn[3] + pendulum.pendulumJoint.nn[1] * pendulum.pendulumJoint.sinq;
//   pendulum.pendulumJoint.S_rel[3,1] = (pendulum.pendulumJoint.nn[3] - pendulum.pendulumJoint.nn[3] * pendulum.pendulumJoint.cosq) * pendulum.pendulumJoint.nn[1] + pendulum.pendulumJoint.nn[2] * pendulum.pendulumJoint.sinq;
//   pendulum.pendulumJoint.S_rel[3,2] = (pendulum.pendulumJoint.nn[3] - pendulum.pendulumJoint.nn[3] * pendulum.pendulumJoint.cosq) * pendulum.pendulumJoint.nn[2] - pendulum.pendulumJoint.nn[1] * pendulum.pendulumJoint.sinq;
//   pendulum.pendulumJoint.S_rel[3,3] = pendulum.pendulumJoint.nn[3] ^ 2.0 + (1.0 - pendulum.pendulumJoint.nn[3] ^ 2.0) * pendulum.pendulumJoint.cosq;
//   pendulum.pendulumJoint.r_rela[1] = 0.0 "other kinematic quantities";
//   pendulum.pendulumJoint.r_rela[2] = 0.0 "other kinematic quantities";
//   pendulum.pendulumJoint.r_rela[3] = 0.0 "other kinematic quantities";
//   pendulum.pendulumJoint.v_rela[1] = 0.0;
//   pendulum.pendulumJoint.v_rela[2] = 0.0;
//   pendulum.pendulumJoint.v_rela[3] = 0.0;
//   pendulum.pendulumJoint.a_rela[1] = 0.0;
//   pendulum.pendulumJoint.a_rela[2] = 0.0;
//   pendulum.pendulumJoint.a_rela[3] = 0.0;
//   pendulum.pendulumJoint.w_rela[1] = pendulum.pendulumJoint.nn[1] * pendulum.pendulumJoint.qd;
//   pendulum.pendulumJoint.w_rela[2] = pendulum.pendulumJoint.nn[2] * pendulum.pendulumJoint.qd;
//   pendulum.pendulumJoint.w_rela[3] = pendulum.pendulumJoint.nn[3] * pendulum.pendulumJoint.qd;
//   pendulum.pendulumJoint.z_rela[1] = pendulum.pendulumJoint.nn[1] * pendulum.pendulumJoint.qdd;
//   pendulum.pendulumJoint.z_rela[2] = pendulum.pendulumJoint.nn[2] * pendulum.pendulumJoint.qdd;
//   pendulum.pendulumJoint.z_rela[3] = pendulum.pendulumJoint.nn[3] * pendulum.pendulumJoint.qdd;
//   pendulum.pendulumJoint.Sb[1,1] = pendulum.pendulumJoint.Sa[1,1] * pendulum.pendulumJoint.S_rel[1,1] + pendulum.pendulumJoint.Sa[1,2] * pendulum.pendulumJoint.S_rel[1,2] + pendulum.pendulumJoint.Sa[1,3] * pendulum.pendulumJoint.S_rel[1,3];
//   pendulum.pendulumJoint.Sb[1,2] = pendulum.pendulumJoint.Sa[1,1] * pendulum.pendulumJoint.S_rel[2,1] + pendulum.pendulumJoint.Sa[1,2] * pendulum.pendulumJoint.S_rel[2,2] + pendulum.pendulumJoint.Sa[1,3] * pendulum.pendulumJoint.S_rel[2,3];
//   pendulum.pendulumJoint.Sb[1,3] = pendulum.pendulumJoint.Sa[1,1] * pendulum.pendulumJoint.S_rel[3,1] + pendulum.pendulumJoint.Sa[1,2] * pendulum.pendulumJoint.S_rel[3,2] + pendulum.pendulumJoint.Sa[1,3] * pendulum.pendulumJoint.S_rel[3,3];
//   pendulum.pendulumJoint.Sb[2,1] = pendulum.pendulumJoint.Sa[2,1] * pendulum.pendulumJoint.S_rel[1,1] + pendulum.pendulumJoint.Sa[2,2] * pendulum.pendulumJoint.S_rel[1,2] + pendulum.pendulumJoint.Sa[2,3] * pendulum.pendulumJoint.S_rel[1,3];
//   pendulum.pendulumJoint.Sb[2,2] = pendulum.pendulumJoint.Sa[2,1] * pendulum.pendulumJoint.S_rel[2,1] + pendulum.pendulumJoint.Sa[2,2] * pendulum.pendulumJoint.S_rel[2,2] + pendulum.pendulumJoint.Sa[2,3] * pendulum.pendulumJoint.S_rel[2,3];
//   pendulum.pendulumJoint.Sb[2,3] = pendulum.pendulumJoint.Sa[2,1] * pendulum.pendulumJoint.S_rel[3,1] + pendulum.pendulumJoint.Sa[2,2] * pendulum.pendulumJoint.S_rel[3,2] + pendulum.pendulumJoint.Sa[2,3] * pendulum.pendulumJoint.S_rel[3,3];
//   pendulum.pendulumJoint.Sb[3,1] = pendulum.pendulumJoint.Sa[3,1] * pendulum.pendulumJoint.S_rel[1,1] + pendulum.pendulumJoint.Sa[3,2] * pendulum.pendulumJoint.S_rel[1,2] + pendulum.pendulumJoint.Sa[3,3] * pendulum.pendulumJoint.S_rel[1,3];
//   pendulum.pendulumJoint.Sb[3,2] = pendulum.pendulumJoint.Sa[3,1] * pendulum.pendulumJoint.S_rel[2,1] + pendulum.pendulumJoint.Sa[3,2] * pendulum.pendulumJoint.S_rel[2,2] + pendulum.pendulumJoint.Sa[3,3] * pendulum.pendulumJoint.S_rel[2,3];
//   pendulum.pendulumJoint.Sb[3,3] = pendulum.pendulumJoint.Sa[3,1] * pendulum.pendulumJoint.S_rel[3,1] + pendulum.pendulumJoint.Sa[3,2] * pendulum.pendulumJoint.S_rel[3,2] + pendulum.pendulumJoint.Sa[3,3] * pendulum.pendulumJoint.S_rel[3,3];
//   pendulum.pendulumJoint.r0b[1] = pendulum.pendulumJoint.r0a[1];
//   pendulum.pendulumJoint.r0b[2] = pendulum.pendulumJoint.r0a[2];
//   pendulum.pendulumJoint.r0b[3] = pendulum.pendulumJoint.r0a[3];
//   pendulum.pendulumJoint.vb[1] = pendulum.pendulumJoint.S_rel[1,1] * pendulum.pendulumJoint.va[1] + pendulum.pendulumJoint.S_rel[1,2] * pendulum.pendulumJoint.va[2] + pendulum.pendulumJoint.S_rel[1,3] * pendulum.pendulumJoint.va[3];
//   pendulum.pendulumJoint.vb[2] = pendulum.pendulumJoint.S_rel[2,1] * pendulum.pendulumJoint.va[1] + pendulum.pendulumJoint.S_rel[2,2] * pendulum.pendulumJoint.va[2] + pendulum.pendulumJoint.S_rel[2,3] * pendulum.pendulumJoint.va[3];
//   pendulum.pendulumJoint.vb[3] = pendulum.pendulumJoint.S_rel[3,1] * pendulum.pendulumJoint.va[1] + pendulum.pendulumJoint.S_rel[3,2] * pendulum.pendulumJoint.va[2] + pendulum.pendulumJoint.S_rel[3,3] * pendulum.pendulumJoint.va[3];
//   pendulum.pendulumJoint.wb[1] = pendulum.pendulumJoint.S_rel[1,1] * (pendulum.pendulumJoint.wa[1] + pendulum.pendulumJoint.w_rela[1]) + pendulum.pendulumJoint.S_rel[1,2] * (pendulum.pendulumJoint.wa[2] + pendulum.pendulumJoint.w_rela[2]) + pendulum.pendulumJoint.S_rel[1,3] * (pendulum.pendulumJoint.wa[3] + pendulum.pendulumJoint.w_rela[3]);
//   pendulum.pendulumJoint.wb[2] = pendulum.pendulumJoint.S_rel[2,1] * (pendulum.pendulumJoint.wa[1] + pendulum.pendulumJoint.w_rela[1]) + pendulum.pendulumJoint.S_rel[2,2] * (pendulum.pendulumJoint.wa[2] + pendulum.pendulumJoint.w_rela[2]) + pendulum.pendulumJoint.S_rel[2,3] * (pendulum.pendulumJoint.wa[3] + pendulum.pendulumJoint.w_rela[3]);
//   pendulum.pendulumJoint.wb[3] = pendulum.pendulumJoint.S_rel[3,1] * (pendulum.pendulumJoint.wa[1] + pendulum.pendulumJoint.w_rela[1]) + pendulum.pendulumJoint.S_rel[3,2] * (pendulum.pendulumJoint.wa[2] + pendulum.pendulumJoint.w_rela[2]) + pendulum.pendulumJoint.S_rel[3,3] * (pendulum.pendulumJoint.wa[3] + pendulum.pendulumJoint.w_rela[3]);
//   pendulum.pendulumJoint.ab[1] = pendulum.pendulumJoint.S_rel[1,1] * pendulum.pendulumJoint.aa[1] + pendulum.pendulumJoint.S_rel[1,2] * pendulum.pendulumJoint.aa[2] + pendulum.pendulumJoint.S_rel[1,3] * pendulum.pendulumJoint.aa[3];
//   pendulum.pendulumJoint.ab[2] = pendulum.pendulumJoint.S_rel[2,1] * pendulum.pendulumJoint.aa[1] + pendulum.pendulumJoint.S_rel[2,2] * pendulum.pendulumJoint.aa[2] + pendulum.pendulumJoint.S_rel[2,3] * pendulum.pendulumJoint.aa[3];
//   pendulum.pendulumJoint.ab[3] = pendulum.pendulumJoint.S_rel[3,1] * pendulum.pendulumJoint.aa[1] + pendulum.pendulumJoint.S_rel[3,2] * pendulum.pendulumJoint.aa[2] + pendulum.pendulumJoint.S_rel[3,3] * pendulum.pendulumJoint.aa[3];
//   pendulum.pendulumJoint.zb[1] = pendulum.pendulumJoint.S_rel[1,1] * (pendulum.pendulumJoint.za[1] + pendulum.pendulumJoint.z_rela[1] + pendulum.pendulumJoint.wa[2] * pendulum.pendulumJoint.w_rela[3] - pendulum.pendulumJoint.wa[3] * pendulum.pendulumJoint.w_rela[2]) + pendulum.pendulumJoint.S_rel[1,2] * (pendulum.pendulumJoint.za[2] + pendulum.pendulumJoint.z_rela[2] + pendulum.pendulumJoint.wa[3] * pendulum.pendulumJoint.w_rela[1] - pendulum.pendulumJoint.wa[1] * pendulum.pendulumJoint.w_rela[3]) + pendulum.pendulumJoint.S_rel[1,3] * (pendulum.pendulumJoint.za[3] + pendulum.pendulumJoint.z_rela[3] + pendulum.pendulumJoint.wa[1] * pendulum.pendulumJoint.w_rela[2] - pendulum.pendulumJoint.wa[2] * pendulum.pendulumJoint.w_rela[1]);
//   pendulum.pendulumJoint.zb[2] = pendulum.pendulumJoint.S_rel[2,1] * (pendulum.pendulumJoint.za[1] + pendulum.pendulumJoint.z_rela[1] + pendulum.pendulumJoint.wa[2] * pendulum.pendulumJoint.w_rela[3] - pendulum.pendulumJoint.wa[3] * pendulum.pendulumJoint.w_rela[2]) + pendulum.pendulumJoint.S_rel[2,2] * (pendulum.pendulumJoint.za[2] + pendulum.pendulumJoint.z_rela[2] + pendulum.pendulumJoint.wa[3] * pendulum.pendulumJoint.w_rela[1] - pendulum.pendulumJoint.wa[1] * pendulum.pendulumJoint.w_rela[3]) + pendulum.pendulumJoint.S_rel[2,3] * (pendulum.pendulumJoint.za[3] + pendulum.pendulumJoint.z_rela[3] + pendulum.pendulumJoint.wa[1] * pendulum.pendulumJoint.w_rela[2] - pendulum.pendulumJoint.wa[2] * pendulum.pendulumJoint.w_rela[1]);
//   pendulum.pendulumJoint.zb[3] = pendulum.pendulumJoint.S_rel[3,1] * (pendulum.pendulumJoint.za[1] + pendulum.pendulumJoint.z_rela[1] + pendulum.pendulumJoint.wa[2] * pendulum.pendulumJoint.w_rela[3] - pendulum.pendulumJoint.wa[3] * pendulum.pendulumJoint.w_rela[2]) + pendulum.pendulumJoint.S_rel[3,2] * (pendulum.pendulumJoint.za[2] + pendulum.pendulumJoint.z_rela[2] + pendulum.pendulumJoint.wa[3] * pendulum.pendulumJoint.w_rela[1] - pendulum.pendulumJoint.wa[1] * pendulum.pendulumJoint.w_rela[3]) + pendulum.pendulumJoint.S_rel[3,3] * (pendulum.pendulumJoint.za[3] + pendulum.pendulumJoint.z_rela[3] + pendulum.pendulumJoint.wa[1] * pendulum.pendulumJoint.w_rela[2] - pendulum.pendulumJoint.wa[2] * pendulum.pendulumJoint.w_rela[1]);
//   pendulum.pendulumJoint.fa[1] = pendulum.pendulumJoint.S_rel[1,1] * pendulum.pendulumJoint.fb[1] + pendulum.pendulumJoint.S_rel[2,1] * pendulum.pendulumJoint.fb[2] + pendulum.pendulumJoint.S_rel[3,1] * pendulum.pendulumJoint.fb[3];
//   pendulum.pendulumJoint.fa[2] = pendulum.pendulumJoint.S_rel[1,2] * pendulum.pendulumJoint.fb[1] + pendulum.pendulumJoint.S_rel[2,2] * pendulum.pendulumJoint.fb[2] + pendulum.pendulumJoint.S_rel[3,2] * pendulum.pendulumJoint.fb[3];
//   pendulum.pendulumJoint.fa[3] = pendulum.pendulumJoint.S_rel[1,3] * pendulum.pendulumJoint.fb[1] + pendulum.pendulumJoint.S_rel[2,3] * pendulum.pendulumJoint.fb[2] + pendulum.pendulumJoint.S_rel[3,3] * pendulum.pendulumJoint.fb[3];
//   pendulum.pendulumJoint.ta[1] = pendulum.pendulumJoint.S_rel[1,1] * pendulum.pendulumJoint.tb[1] + pendulum.pendulumJoint.S_rel[2,1] * pendulum.pendulumJoint.tb[2] + pendulum.pendulumJoint.S_rel[3,1] * pendulum.pendulumJoint.tb[3];
//   pendulum.pendulumJoint.ta[2] = pendulum.pendulumJoint.S_rel[1,2] * pendulum.pendulumJoint.tb[1] + pendulum.pendulumJoint.S_rel[2,2] * pendulum.pendulumJoint.tb[2] + pendulum.pendulumJoint.S_rel[3,2] * pendulum.pendulumJoint.tb[3];
//   pendulum.pendulumJoint.ta[3] = pendulum.pendulumJoint.S_rel[1,3] * pendulum.pendulumJoint.tb[1] + pendulum.pendulumJoint.S_rel[2,3] * pendulum.pendulumJoint.tb[2] + pendulum.pendulumJoint.S_rel[3,3] * pendulum.pendulumJoint.tb[3];
//   pendulum.pendulumJoint.axis.tau = pendulum.pendulumJoint.nn[1] * pendulum.pendulumJoint.tb[1] + pendulum.pendulumJoint.nn[2] * pendulum.pendulumJoint.tb[2] + pendulum.pendulumJoint.nn[3] * pendulum.pendulumJoint.tb[3] "d'Alemberts principle";
//   pendulum.toMidCart.frame_a.r0 = {pendulum.toMidCart.r0a[1], pendulum.toMidCart.r0a[2], pendulum.toMidCart.r0a[3]};
//   pendulum.toMidCart.frame_a.S = {{pendulum.toMidCart.Sa[1,1], pendulum.toMidCart.Sa[1,2], pendulum.toMidCart.Sa[1,3]}, {pendulum.toMidCart.Sa[2,1], pendulum.toMidCart.Sa[2,2], pendulum.toMidCart.Sa[2,3]}, {pendulum.toMidCart.Sa[3,1], pendulum.toMidCart.Sa[3,2], pendulum.toMidCart.Sa[3,3]}};
//   pendulum.toMidCart.frame_a.v = {pendulum.toMidCart.va[1], pendulum.toMidCart.va[2], pendulum.toMidCart.va[3]};
//   pendulum.toMidCart.frame_a.w = {pendulum.toMidCart.wa[1], pendulum.toMidCart.wa[2], pendulum.toMidCart.wa[3]};
//   pendulum.toMidCart.frame_a.a = {pendulum.toMidCart.aa[1], pendulum.toMidCart.aa[2], pendulum.toMidCart.aa[3]};
//   pendulum.toMidCart.frame_a.z = {pendulum.toMidCart.za[1], pendulum.toMidCart.za[2], pendulum.toMidCart.za[3]};
//   pendulum.toMidCart.frame_a.f = {pendulum.toMidCart.fa[1], pendulum.toMidCart.fa[2], pendulum.toMidCart.fa[3]};
//   pendulum.toMidCart.frame_a.t = {pendulum.toMidCart.ta[1], pendulum.toMidCart.ta[2], pendulum.toMidCart.ta[3]};
//   pendulum.toMidCart.frame_b.r0 = {pendulum.toMidCart.r0b[1], pendulum.toMidCart.r0b[2], pendulum.toMidCart.r0b[3]};
//   pendulum.toMidCart.frame_b.S = {{pendulum.toMidCart.Sb[1,1], pendulum.toMidCart.Sb[1,2], pendulum.toMidCart.Sb[1,3]}, {pendulum.toMidCart.Sb[2,1], pendulum.toMidCart.Sb[2,2], pendulum.toMidCart.Sb[2,3]}, {pendulum.toMidCart.Sb[3,1], pendulum.toMidCart.Sb[3,2], pendulum.toMidCart.Sb[3,3]}};
//   pendulum.toMidCart.frame_b.v = {pendulum.toMidCart.vb[1], pendulum.toMidCart.vb[2], pendulum.toMidCart.vb[3]};
//   pendulum.toMidCart.frame_b.w = {pendulum.toMidCart.wb[1], pendulum.toMidCart.wb[2], pendulum.toMidCart.wb[3]};
//   pendulum.toMidCart.frame_b.a = {pendulum.toMidCart.ab[1], pendulum.toMidCart.ab[2], pendulum.toMidCart.ab[3]};
//   pendulum.toMidCart.frame_b.z = {pendulum.toMidCart.zb[1], pendulum.toMidCart.zb[2], pendulum.toMidCart.zb[3]};
//   pendulum.toMidCart.frame_b.f = {-pendulum.toMidCart.fb[1], -pendulum.toMidCart.fb[2], -pendulum.toMidCart.fb[3]};
//   pendulum.toMidCart.frame_b.t = {-pendulum.toMidCart.tb[1], -pendulum.toMidCart.tb[2], -pendulum.toMidCart.tb[3]};
//   pendulum.toMidCart.Sb[1,1] = pendulum.toMidCart.Sa[1,1];
//   pendulum.toMidCart.Sb[1,2] = pendulum.toMidCart.Sa[1,2];
//   pendulum.toMidCart.Sb[1,3] = pendulum.toMidCart.Sa[1,3];
//   pendulum.toMidCart.Sb[2,1] = pendulum.toMidCart.Sa[2,1];
//   pendulum.toMidCart.Sb[2,2] = pendulum.toMidCart.Sa[2,2];
//   pendulum.toMidCart.Sb[2,3] = pendulum.toMidCart.Sa[2,3];
//   pendulum.toMidCart.Sb[3,1] = pendulum.toMidCart.Sa[3,1];
//   pendulum.toMidCart.Sb[3,2] = pendulum.toMidCart.Sa[3,2];
//   pendulum.toMidCart.Sb[3,3] = pendulum.toMidCart.Sa[3,3];
//   pendulum.toMidCart.wb[1] = pendulum.toMidCart.wa[1];
//   pendulum.toMidCart.wb[2] = pendulum.toMidCart.wa[2];
//   pendulum.toMidCart.wb[3] = pendulum.toMidCart.wa[3];
//   pendulum.toMidCart.zb[1] = pendulum.toMidCart.za[1];
//   pendulum.toMidCart.zb[2] = pendulum.toMidCart.za[2];
//   pendulum.toMidCart.zb[3] = pendulum.toMidCart.za[3];
//   pendulum.toMidCart.r0b[1] = pendulum.toMidCart.r0a[1] + pendulum.toMidCart.Sa[1,1] * pendulum.toMidCart.r[1] + pendulum.toMidCart.Sa[1,2] * pendulum.toMidCart.r[2] + pendulum.toMidCart.Sa[1,3] * pendulum.toMidCart.r[3];
//   pendulum.toMidCart.r0b[2] = pendulum.toMidCart.r0a[2] + pendulum.toMidCart.Sa[2,1] * pendulum.toMidCart.r[1] + pendulum.toMidCart.Sa[2,2] * pendulum.toMidCart.r[2] + pendulum.toMidCart.Sa[2,3] * pendulum.toMidCart.r[3];
//   pendulum.toMidCart.r0b[3] = pendulum.toMidCart.r0a[3] + pendulum.toMidCart.Sa[3,1] * pendulum.toMidCart.r[1] + pendulum.toMidCart.Sa[3,2] * pendulum.toMidCart.r[2] + pendulum.toMidCart.Sa[3,3] * pendulum.toMidCart.r[3];
//   pendulum.toMidCart.vaux[1] = pendulum.toMidCart.wa[2] * pendulum.toMidCart.r[3] - pendulum.toMidCart.wa[3] * pendulum.toMidCart.r[2];
//   pendulum.toMidCart.vaux[2] = pendulum.toMidCart.wa[3] * pendulum.toMidCart.r[1] - pendulum.toMidCart.wa[1] * pendulum.toMidCart.r[3];
//   pendulum.toMidCart.vaux[3] = pendulum.toMidCart.wa[1] * pendulum.toMidCart.r[2] - pendulum.toMidCart.wa[2] * pendulum.toMidCart.r[1];
//   pendulum.toMidCart.vb[1] = pendulum.toMidCart.va[1] + pendulum.toMidCart.vaux[1];
//   pendulum.toMidCart.vb[2] = pendulum.toMidCart.va[2] + pendulum.toMidCart.vaux[2];
//   pendulum.toMidCart.vb[3] = pendulum.toMidCart.va[3] + pendulum.toMidCart.vaux[3];
//   pendulum.toMidCart.ab[1] = pendulum.toMidCart.aa[1] + pendulum.toMidCart.za[2] * pendulum.toMidCart.r[3] - pendulum.toMidCart.za[3] * pendulum.toMidCart.r[2] + pendulum.toMidCart.wa[2] * pendulum.toMidCart.vaux[3] - pendulum.toMidCart.wa[3] * pendulum.toMidCart.vaux[2];
//   pendulum.toMidCart.ab[2] = pendulum.toMidCart.aa[2] + pendulum.toMidCart.za[3] * pendulum.toMidCart.r[1] - pendulum.toMidCart.za[1] * pendulum.toMidCart.r[3] + pendulum.toMidCart.wa[3] * pendulum.toMidCart.vaux[1] - pendulum.toMidCart.wa[1] * pendulum.toMidCart.vaux[3];
//   pendulum.toMidCart.ab[3] = pendulum.toMidCart.aa[3] + pendulum.toMidCart.za[1] * pendulum.toMidCart.r[2] - pendulum.toMidCart.za[2] * pendulum.toMidCart.r[1] + pendulum.toMidCart.wa[1] * pendulum.toMidCart.vaux[2] - pendulum.toMidCart.wa[2] * pendulum.toMidCart.vaux[1];
//   pendulum.toMidCart.fa[1] = pendulum.toMidCart.fb[1] "Transform the force and torque acting at frame_b to frame_a";
//   pendulum.toMidCart.fa[2] = pendulum.toMidCart.fb[2] "Transform the force and torque acting at frame_b to frame_a";
//   pendulum.toMidCart.fa[3] = pendulum.toMidCart.fb[3] "Transform the force and torque acting at frame_b to frame_a";
//   pendulum.toMidCart.ta[1] = pendulum.toMidCart.tb[1] + pendulum.toMidCart.r[2] * pendulum.toMidCart.fa[3] - pendulum.toMidCart.r[3] * pendulum.toMidCart.fa[2];
//   pendulum.toMidCart.ta[2] = pendulum.toMidCart.tb[2] + pendulum.toMidCart.r[3] * pendulum.toMidCart.fa[1] - pendulum.toMidCart.r[1] * pendulum.toMidCart.fa[3];
//   pendulum.toMidCart.ta[3] = pendulum.toMidCart.tb[3] + pendulum.toMidCart.r[1] * pendulum.toMidCart.fa[2] - pendulum.toMidCart.r[2] * pendulum.toMidCart.fa[1];
//   pendulum.sliderConstraint.frame_a.r0 = {pendulum.sliderConstraint.r0a[1], pendulum.sliderConstraint.r0a[2], pendulum.sliderConstraint.r0a[3]};
//   pendulum.sliderConstraint.frame_a.S = {{pendulum.sliderConstraint.Sa[1,1], pendulum.sliderConstraint.Sa[1,2], pendulum.sliderConstraint.Sa[1,3]}, {pendulum.sliderConstraint.Sa[2,1], pendulum.sliderConstraint.Sa[2,2], pendulum.sliderConstraint.Sa[2,3]}, {pendulum.sliderConstraint.Sa[3,1], pendulum.sliderConstraint.Sa[3,2], pendulum.sliderConstraint.Sa[3,3]}};
//   pendulum.sliderConstraint.frame_a.v = {pendulum.sliderConstraint.va[1], pendulum.sliderConstraint.va[2], pendulum.sliderConstraint.va[3]};
//   pendulum.sliderConstraint.frame_a.w = {pendulum.sliderConstraint.wa[1], pendulum.sliderConstraint.wa[2], pendulum.sliderConstraint.wa[3]};
//   pendulum.sliderConstraint.frame_a.a = {pendulum.sliderConstraint.aa[1], pendulum.sliderConstraint.aa[2], pendulum.sliderConstraint.aa[3]};
//   pendulum.sliderConstraint.frame_a.z = {pendulum.sliderConstraint.za[1], pendulum.sliderConstraint.za[2], pendulum.sliderConstraint.za[3]};
//   pendulum.sliderConstraint.frame_a.f = {pendulum.sliderConstraint.fa[1], pendulum.sliderConstraint.fa[2], pendulum.sliderConstraint.fa[3]};
//   pendulum.sliderConstraint.frame_a.t = {pendulum.sliderConstraint.ta[1], pendulum.sliderConstraint.ta[2], pendulum.sliderConstraint.ta[3]};
//   pendulum.sliderConstraint.frame_b.r0 = {pendulum.sliderConstraint.r0b[1], pendulum.sliderConstraint.r0b[2], pendulum.sliderConstraint.r0b[3]};
//   pendulum.sliderConstraint.frame_b.S = {{pendulum.sliderConstraint.Sb[1,1], pendulum.sliderConstraint.Sb[1,2], pendulum.sliderConstraint.Sb[1,3]}, {pendulum.sliderConstraint.Sb[2,1], pendulum.sliderConstraint.Sb[2,2], pendulum.sliderConstraint.Sb[2,3]}, {pendulum.sliderConstraint.Sb[3,1], pendulum.sliderConstraint.Sb[3,2], pendulum.sliderConstraint.Sb[3,3]}};
//   pendulum.sliderConstraint.frame_b.v = {pendulum.sliderConstraint.vb[1], pendulum.sliderConstraint.vb[2], pendulum.sliderConstraint.vb[3]};
//   pendulum.sliderConstraint.frame_b.w = {pendulum.sliderConstraint.wb[1], pendulum.sliderConstraint.wb[2], pendulum.sliderConstraint.wb[3]};
//   pendulum.sliderConstraint.frame_b.a = {pendulum.sliderConstraint.ab[1], pendulum.sliderConstraint.ab[2], pendulum.sliderConstraint.ab[3]};
//   pendulum.sliderConstraint.frame_b.z = {pendulum.sliderConstraint.zb[1], pendulum.sliderConstraint.zb[2], pendulum.sliderConstraint.zb[3]};
//   pendulum.sliderConstraint.frame_b.f = {-pendulum.sliderConstraint.fb[1], -pendulum.sliderConstraint.fb[2], -pendulum.sliderConstraint.fb[3]};
//   pendulum.sliderConstraint.frame_b.t = {-pendulum.sliderConstraint.tb[1], -pendulum.sliderConstraint.tb[2], -pendulum.sliderConstraint.tb[3]};
//   pendulum.sliderConstraint.axis.s = pendulum.sliderConstraint.q;
//   pendulum.sliderConstraint.bearing.s = 0.0;
//   pendulum.sliderConstraint.qd = der(pendulum.sliderConstraint.q) "define states";
//   pendulum.sliderConstraint.qdd = der(pendulum.sliderConstraint.qd);
//   pendulum.sliderConstraint.nn[1] = pendulum.sliderConstraint.n[1] / sqrt(pendulum.sliderConstraint.n[1] ^ 2.0 + pendulum.sliderConstraint.n[2] ^ 2.0 + pendulum.sliderConstraint.n[3] ^ 2.0) "normalize axis vector";
//   pendulum.sliderConstraint.nn[2] = pendulum.sliderConstraint.n[2] / sqrt(pendulum.sliderConstraint.n[1] ^ 2.0 + pendulum.sliderConstraint.n[2] ^ 2.0 + pendulum.sliderConstraint.n[3] ^ 2.0) "normalize axis vector";
//   pendulum.sliderConstraint.nn[3] = pendulum.sliderConstraint.n[3] / sqrt(pendulum.sliderConstraint.n[1] ^ 2.0 + pendulum.sliderConstraint.n[2] ^ 2.0 + pendulum.sliderConstraint.n[3] ^ 2.0) "normalize axis vector";
//   pendulum.sliderConstraint.S_rel[1,1] = 1.0 "kinematic quantities";
//   pendulum.sliderConstraint.S_rel[1,2] = 0.0 "kinematic quantities";
//   pendulum.sliderConstraint.S_rel[1,3] = 0.0 "kinematic quantities";
//   pendulum.sliderConstraint.S_rel[2,1] = 0.0 "kinematic quantities";
//   pendulum.sliderConstraint.S_rel[2,2] = 1.0 "kinematic quantities";
//   pendulum.sliderConstraint.S_rel[2,3] = 0.0 "kinematic quantities";
//   pendulum.sliderConstraint.S_rel[3,1] = 0.0 "kinematic quantities";
//   pendulum.sliderConstraint.S_rel[3,2] = 0.0 "kinematic quantities";
//   pendulum.sliderConstraint.S_rel[3,3] = 1.0 "kinematic quantities";
//   pendulum.sliderConstraint.qq = pendulum.sliderConstraint.q - pendulum.sliderConstraint.q0;
//   pendulum.sliderConstraint.r_rela[1] = pendulum.sliderConstraint.nn[1] * pendulum.sliderConstraint.qq;
//   pendulum.sliderConstraint.r_rela[2] = pendulum.sliderConstraint.nn[2] * pendulum.sliderConstraint.qq;
//   pendulum.sliderConstraint.r_rela[3] = pendulum.sliderConstraint.nn[3] * pendulum.sliderConstraint.qq;
//   pendulum.sliderConstraint.v_rela[1] = pendulum.sliderConstraint.nn[1] * pendulum.sliderConstraint.qd;
//   pendulum.sliderConstraint.v_rela[2] = pendulum.sliderConstraint.nn[2] * pendulum.sliderConstraint.qd;
//   pendulum.sliderConstraint.v_rela[3] = pendulum.sliderConstraint.nn[3] * pendulum.sliderConstraint.qd;
//   pendulum.sliderConstraint.a_rela[1] = pendulum.sliderConstraint.nn[1] * pendulum.sliderConstraint.qdd;
//   pendulum.sliderConstraint.a_rela[2] = pendulum.sliderConstraint.nn[2] * pendulum.sliderConstraint.qdd;
//   pendulum.sliderConstraint.a_rela[3] = pendulum.sliderConstraint.nn[3] * pendulum.sliderConstraint.qdd;
//   pendulum.sliderConstraint.w_rela[1] = 0.0;
//   pendulum.sliderConstraint.w_rela[2] = 0.0;
//   pendulum.sliderConstraint.w_rela[3] = 0.0;
//   pendulum.sliderConstraint.z_rela[1] = 0.0;
//   pendulum.sliderConstraint.z_rela[2] = 0.0;
//   pendulum.sliderConstraint.z_rela[3] = 0.0;
//   pendulum.sliderConstraint.Sb[1,1] = pendulum.sliderConstraint.Sa[1,1];
//   pendulum.sliderConstraint.Sb[1,2] = pendulum.sliderConstraint.Sa[1,2];
//   pendulum.sliderConstraint.Sb[1,3] = pendulum.sliderConstraint.Sa[1,3];
//   pendulum.sliderConstraint.Sb[2,1] = pendulum.sliderConstraint.Sa[2,1];
//   pendulum.sliderConstraint.Sb[2,2] = pendulum.sliderConstraint.Sa[2,2];
//   pendulum.sliderConstraint.Sb[2,3] = pendulum.sliderConstraint.Sa[2,3];
//   pendulum.sliderConstraint.Sb[3,1] = pendulum.sliderConstraint.Sa[3,1];
//   pendulum.sliderConstraint.Sb[3,2] = pendulum.sliderConstraint.Sa[3,2];
//   pendulum.sliderConstraint.Sb[3,3] = pendulum.sliderConstraint.Sa[3,3];
//   pendulum.sliderConstraint.r0b[1] = pendulum.sliderConstraint.r0a[1] + pendulum.sliderConstraint.Sa[1,1] * pendulum.sliderConstraint.r_rela[1] + pendulum.sliderConstraint.Sa[1,2] * pendulum.sliderConstraint.r_rela[2] + pendulum.sliderConstraint.Sa[1,3] * pendulum.sliderConstraint.r_rela[3];
//   pendulum.sliderConstraint.r0b[2] = pendulum.sliderConstraint.r0a[2] + pendulum.sliderConstraint.Sa[2,1] * pendulum.sliderConstraint.r_rela[1] + pendulum.sliderConstraint.Sa[2,2] * pendulum.sliderConstraint.r_rela[2] + pendulum.sliderConstraint.Sa[2,3] * pendulum.sliderConstraint.r_rela[3];
//   pendulum.sliderConstraint.r0b[3] = pendulum.sliderConstraint.r0a[3] + pendulum.sliderConstraint.Sa[3,1] * pendulum.sliderConstraint.r_rela[1] + pendulum.sliderConstraint.Sa[3,2] * pendulum.sliderConstraint.r_rela[2] + pendulum.sliderConstraint.Sa[3,3] * pendulum.sliderConstraint.r_rela[3];
//   pendulum.sliderConstraint.vaux[1] = pendulum.sliderConstraint.wa[2] * pendulum.sliderConstraint.r_rela[3] - pendulum.sliderConstraint.wa[3] * pendulum.sliderConstraint.r_rela[2];
//   pendulum.sliderConstraint.vaux[2] = pendulum.sliderConstraint.wa[3] * pendulum.sliderConstraint.r_rela[1] - pendulum.sliderConstraint.wa[1] * pendulum.sliderConstraint.r_rela[3];
//   pendulum.sliderConstraint.vaux[3] = pendulum.sliderConstraint.wa[1] * pendulum.sliderConstraint.r_rela[2] - pendulum.sliderConstraint.wa[2] * pendulum.sliderConstraint.r_rela[1];
//   pendulum.sliderConstraint.vb[1] = pendulum.sliderConstraint.va[1] + pendulum.sliderConstraint.v_rela[1] + pendulum.sliderConstraint.vaux[1];
//   pendulum.sliderConstraint.vb[2] = pendulum.sliderConstraint.va[2] + pendulum.sliderConstraint.v_rela[2] + pendulum.sliderConstraint.vaux[2];
//   pendulum.sliderConstraint.vb[3] = pendulum.sliderConstraint.va[3] + pendulum.sliderConstraint.v_rela[3] + pendulum.sliderConstraint.vaux[3];
//   pendulum.sliderConstraint.wb[1] = pendulum.sliderConstraint.wa[1];
//   pendulum.sliderConstraint.wb[2] = pendulum.sliderConstraint.wa[2];
//   pendulum.sliderConstraint.wb[3] = pendulum.sliderConstraint.wa[3];
//   pendulum.sliderConstraint.ab[1] = pendulum.sliderConstraint.aa[1] + pendulum.sliderConstraint.a_rela[1] + pendulum.sliderConstraint.za[2] * pendulum.sliderConstraint.r_rela[3] - pendulum.sliderConstraint.za[3] * pendulum.sliderConstraint.r_rela[2] + pendulum.sliderConstraint.wa[2] * (pendulum.sliderConstraint.vaux[3] + pendulum.sliderConstraint.v_rela[3] * 2.0) - pendulum.sliderConstraint.wa[3] * (pendulum.sliderConstraint.vaux[2] + pendulum.sliderConstraint.v_rela[2] * 2.0);
//   pendulum.sliderConstraint.ab[2] = pendulum.sliderConstraint.aa[2] + pendulum.sliderConstraint.a_rela[2] + pendulum.sliderConstraint.za[3] * pendulum.sliderConstraint.r_rela[1] - pendulum.sliderConstraint.za[1] * pendulum.sliderConstraint.r_rela[3] + pendulum.sliderConstraint.wa[3] * (pendulum.sliderConstraint.vaux[1] + pendulum.sliderConstraint.v_rela[1] * 2.0) - pendulum.sliderConstraint.wa[1] * (pendulum.sliderConstraint.vaux[3] + pendulum.sliderConstraint.v_rela[3] * 2.0);
//   pendulum.sliderConstraint.ab[3] = pendulum.sliderConstraint.aa[3] + pendulum.sliderConstraint.a_rela[3] + pendulum.sliderConstraint.za[1] * pendulum.sliderConstraint.r_rela[2] - pendulum.sliderConstraint.za[2] * pendulum.sliderConstraint.r_rela[1] + pendulum.sliderConstraint.wa[1] * (pendulum.sliderConstraint.vaux[2] + pendulum.sliderConstraint.v_rela[2] * 2.0) - pendulum.sliderConstraint.wa[2] * (pendulum.sliderConstraint.vaux[1] + pendulum.sliderConstraint.v_rela[1] * 2.0);
//   pendulum.sliderConstraint.zb[1] = pendulum.sliderConstraint.za[1];
//   pendulum.sliderConstraint.zb[2] = pendulum.sliderConstraint.za[2];
//   pendulum.sliderConstraint.zb[3] = pendulum.sliderConstraint.za[3];
//   pendulum.sliderConstraint.fa[1] = pendulum.sliderConstraint.fb[1];
//   pendulum.sliderConstraint.fa[2] = pendulum.sliderConstraint.fb[2];
//   pendulum.sliderConstraint.fa[3] = pendulum.sliderConstraint.fb[3];
//   pendulum.sliderConstraint.ta[1] = pendulum.sliderConstraint.tb[1] + pendulum.sliderConstraint.r_rela[2] * pendulum.sliderConstraint.fa[3] - pendulum.sliderConstraint.r_rela[3] * pendulum.sliderConstraint.fa[2];
//   pendulum.sliderConstraint.ta[2] = pendulum.sliderConstraint.tb[2] + pendulum.sliderConstraint.r_rela[3] * pendulum.sliderConstraint.fa[1] - pendulum.sliderConstraint.r_rela[1] * pendulum.sliderConstraint.fa[3];
//   pendulum.sliderConstraint.ta[3] = pendulum.sliderConstraint.tb[3] + pendulum.sliderConstraint.r_rela[1] * pendulum.sliderConstraint.fa[2] - pendulum.sliderConstraint.r_rela[2] * pendulum.sliderConstraint.fa[1];
//   pendulum.sliderConstraint.axis.f = pendulum.sliderConstraint.nn[1] * pendulum.sliderConstraint.fb[1] + pendulum.sliderConstraint.nn[2] * pendulum.sliderConstraint.fb[2] + pendulum.sliderConstraint.nn[3] * pendulum.sliderConstraint.fb[3] "d'Alemberts principle";
//   pendulum.pendulumDamper.w_rel = der(pendulum.pendulumDamper.phi_rel);
//   pendulum.pendulumDamper.tau = pendulum.pendulumDamper.d * pendulum.pendulumDamper.w_rel;
//   pendulum.pendulumDamper.phi_rel = pendulum.pendulumDamper.flange_b.phi - pendulum.pendulumDamper.flange_a.phi;
//   pendulum.pendulumDamper.flange_b.tau = pendulum.pendulumDamper.tau;
//   pendulum.pendulumDamper.flange_a.tau = -pendulum.pendulumDamper.tau;
//   pendulum.sliderDamper.v_rel = der(pendulum.sliderDamper.s_rel);
//   pendulum.sliderDamper.f = pendulum.sliderDamper.d * pendulum.sliderDamper.v_rel;
//   pendulum.sliderDamper.s_rel = pendulum.sliderDamper.flange_b.s - pendulum.sliderDamper.flange_a.s;
//   pendulum.sliderDamper.flange_b.f = pendulum.sliderDamper.f;
//   pendulum.sliderDamper.flange_a.f = -pendulum.sliderDamper.f;
//   pendulum.angleSensor.phi = pendulum.angleSensor.flange_a.phi;
//   0.0 = pendulum.angleSensor.flange_a.tau;
//   pendulum.positionSensor.s = pendulum.positionSensor.flange_a.s;
//   0.0 = pendulum.positionSensor.flange_a.f;
//   gear.gearR2T.flange_a.phi - gear.gearR2T.bearingR.phi = gear.gearR2T.ratio * (gear.gearR2T.flange_b.s - gear.gearR2T.bearingT.s);
//   0.0 = gear.gearR2T.ratio * gear.gearR2T.flange_a.tau + gear.gearR2T.flange_b.f;
//   0.0 = gear.gearR2T.flange_a.tau + gear.gearR2T.tau_support;
//   0.0 = gear.gearR2T.flange_b.f + gear.gearR2T.f_support;
//   gear.gearR2T.bearingR.phi = 0.0;
//   gear.gearR2T.bearingT.s = 0.0;
//   gear.idealGear.phi_a = gear.idealGear.ratio * gear.idealGear.phi_b;
//   0.0 = gear.idealGear.ratio * gear.idealGear.flange_a.tau + gear.idealGear.flange_b.tau;
//   gear.idealGear.bearing.phi = 0.0;
//   0.0 = gear.idealGear.flange_a.tau + gear.idealGear.flange_b.tau + gear.idealGear.tau_support;
//   gear.idealGear.phi_a = gear.idealGear.flange_a.phi - gear.idealGear.bearing.phi;
//   gear.idealGear.phi_b = gear.idealGear.flange_b.phi - gear.idealGear.bearing.phi;
//   motor.voltageSource.p.i + motor.resistor.p.i = 0.0;
//   motor.voltageSource.n.i + motor.ground.p.i + motor.eMF.n.i = 0.0;
//   motor.flange.tau + gear.flange_a.tau = 0.0;
//   motor.resistor.n.i + motor.inductor.p.i = 0.0;
//   motor.inductor.n.i + motor.eMF.p.i = 0.0;
//   (-motor.flange.tau) + motor.eMF.flange_b.tau = 0.0;
//   motor.u = motor.voltageSource.v;
//   motor.eMF.flange_b.phi = motor.flange.phi;
//   motor.eMF.n.v = motor.ground.p.v;
//   motor.eMF.n.v = motor.voltageSource.n.v;
//   motor.eMF.p.v = motor.inductor.n.v;
//   motor.inductor.p.v = motor.resistor.n.v;
//   motor.resistor.p.v = motor.voltageSource.p.v;
//   pendulum.inertialSystem.frame_b.t[1] + pendulum.sliderConstraint.frame_a.t[1] = 0.0;
//   pendulum.inertialSystem.frame_b.t[2] + pendulum.sliderConstraint.frame_a.t[2] = 0.0;
//   pendulum.inertialSystem.frame_b.t[3] + pendulum.sliderConstraint.frame_a.t[3] = 0.0;
//   pendulum.inertialSystem.frame_b.f[1] + pendulum.sliderConstraint.frame_a.f[1] = 0.0;
//   pendulum.inertialSystem.frame_b.f[2] + pendulum.sliderConstraint.frame_a.f[2] = 0.0;
//   pendulum.inertialSystem.frame_b.f[3] + pendulum.sliderConstraint.frame_a.f[3] = 0.0;
//   pendulum.pendulumJoint.axis.tau + pendulum.angleSensor.flange_a.tau + pendulum.pendulumDamper.flange_b.tau = 0.0;
//   pendulum.pendulumJoint.bearing.tau + pendulum.pendulumDamper.flange_a.tau = 0.0;
//   pendulum.pendulumJoint.frame_a.t[1] + pendulum.toMidCart.frame_b.t[1] = 0.0;
//   pendulum.pendulumJoint.frame_a.t[2] + pendulum.toMidCart.frame_b.t[2] = 0.0;
//   pendulum.pendulumJoint.frame_a.t[3] + pendulum.toMidCart.frame_b.t[3] = 0.0;
//   pendulum.pendulumJoint.frame_a.f[1] + pendulum.toMidCart.frame_b.f[1] = 0.0;
//   pendulum.pendulumJoint.frame_a.f[2] + pendulum.toMidCart.frame_b.f[2] = 0.0;
//   pendulum.pendulumJoint.frame_a.f[3] + pendulum.toMidCart.frame_b.f[3] = 0.0;
//   pendulum.pendulumJoint.frame_b.t[1] + pendulum.pendulum.frame_a.t[1] = 0.0;
//   pendulum.pendulumJoint.frame_b.t[2] + pendulum.pendulum.frame_a.t[2] = 0.0;
//   pendulum.pendulumJoint.frame_b.t[3] + pendulum.pendulum.frame_a.t[3] = 0.0;
//   pendulum.pendulumJoint.frame_b.f[1] + pendulum.pendulum.frame_a.f[1] = 0.0;
//   pendulum.pendulumJoint.frame_b.f[2] + pendulum.pendulum.frame_a.f[2] = 0.0;
//   pendulum.pendulumJoint.frame_b.f[3] + pendulum.pendulum.frame_a.f[3] = 0.0;
//   pendulum.sliderConstraint.axis.f + (-pendulum.flange_a.f) + pendulum.positionSensor.flange_a.f + pendulum.sliderDamper.flange_b.f = 0.0;
//   pendulum.sliderConstraint.bearing.f + pendulum.sliderDamper.flange_a.f = 0.0;
//   pendulum.sliderConstraint.frame_b.t[1] + pendulum.cart.frame_a.t[1] = 0.0;
//   pendulum.sliderConstraint.frame_b.t[2] + pendulum.cart.frame_a.t[2] = 0.0;
//   pendulum.sliderConstraint.frame_b.t[3] + pendulum.cart.frame_a.t[3] = 0.0;
//   pendulum.sliderConstraint.frame_b.f[1] + pendulum.cart.frame_a.f[1] = 0.0;
//   pendulum.sliderConstraint.frame_b.f[2] + pendulum.cart.frame_a.f[2] = 0.0;
//   pendulum.sliderConstraint.frame_b.f[3] + pendulum.cart.frame_a.f[3] = 0.0;
//   pendulum.flange_a.f + gear.flange_b.f = 0.0;
//   pendulum.pendulum.body.frame_a.t[1] + (-pendulum.pendulum.frame_a.t[1]) + pendulum.pendulum.frameTranslation.frame_a.t[1] = 0.0;
//   pendulum.pendulum.body.frame_a.t[2] + (-pendulum.pendulum.frame_a.t[2]) + pendulum.pendulum.frameTranslation.frame_a.t[2] = 0.0;
//   pendulum.pendulum.body.frame_a.t[3] + (-pendulum.pendulum.frame_a.t[3]) + pendulum.pendulum.frameTranslation.frame_a.t[3] = 0.0;
//   pendulum.pendulum.body.frame_a.f[1] + (-pendulum.pendulum.frame_a.f[1]) + pendulum.pendulum.frameTranslation.frame_a.f[1] = 0.0;
//   pendulum.pendulum.body.frame_a.f[2] + (-pendulum.pendulum.frame_a.f[2]) + pendulum.pendulum.frameTranslation.frame_a.f[2] = 0.0;
//   pendulum.pendulum.body.frame_a.f[3] + (-pendulum.pendulum.frame_a.f[3]) + pendulum.pendulum.frameTranslation.frame_a.f[3] = 0.0;
//   pendulum.pendulum.frame_b.t[1] = 0.0;
//   pendulum.pendulum.frame_b.t[2] = 0.0;
//   pendulum.pendulum.frame_b.t[3] = 0.0;
//   pendulum.pendulum.frame_b.f[1] = 0.0;
//   pendulum.pendulum.frame_b.f[2] = 0.0;
//   pendulum.pendulum.frame_b.f[3] = 0.0;
//   (-pendulum.pendulum.frame_b.t[1]) + pendulum.pendulum.frameTranslation.frame_b.t[1] = 0.0;
//   (-pendulum.pendulum.frame_b.t[2]) + pendulum.pendulum.frameTranslation.frame_b.t[2] = 0.0;
//   (-pendulum.pendulum.frame_b.t[3]) + pendulum.pendulum.frameTranslation.frame_b.t[3] = 0.0;
//   (-pendulum.pendulum.frame_b.f[1]) + pendulum.pendulum.frameTranslation.frame_b.f[1] = 0.0;
//   (-pendulum.pendulum.frame_b.f[2]) + pendulum.pendulum.frameTranslation.frame_b.f[2] = 0.0;
//   (-pendulum.pendulum.frame_b.f[3]) + pendulum.pendulum.frameTranslation.frame_b.f[3] = 0.0;
//   pendulum.pendulum.frameTranslation.frame_b.S[1,1] = pendulum.pendulum.frame_b.S[1,1];
//   pendulum.pendulum.frameTranslation.frame_b.S[1,2] = pendulum.pendulum.frame_b.S[1,2];
//   pendulum.pendulum.frameTranslation.frame_b.S[1,3] = pendulum.pendulum.frame_b.S[1,3];
//   pendulum.pendulum.frameTranslation.frame_b.S[2,1] = pendulum.pendulum.frame_b.S[2,1];
//   pendulum.pendulum.frameTranslation.frame_b.S[2,2] = pendulum.pendulum.frame_b.S[2,2];
//   pendulum.pendulum.frameTranslation.frame_b.S[2,3] = pendulum.pendulum.frame_b.S[2,3];
//   pendulum.pendulum.frameTranslation.frame_b.S[3,1] = pendulum.pendulum.frame_b.S[3,1];
//   pendulum.pendulum.frameTranslation.frame_b.S[3,2] = pendulum.pendulum.frame_b.S[3,2];
//   pendulum.pendulum.frameTranslation.frame_b.S[3,3] = pendulum.pendulum.frame_b.S[3,3];
//   pendulum.pendulum.frameTranslation.frame_b.a[1] = pendulum.pendulum.frame_b.a[1];
//   pendulum.pendulum.frameTranslation.frame_b.a[2] = pendulum.pendulum.frame_b.a[2];
//   pendulum.pendulum.frameTranslation.frame_b.a[3] = pendulum.pendulum.frame_b.a[3];
//   pendulum.pendulum.frameTranslation.frame_b.r0[1] = pendulum.pendulum.frame_b.r0[1];
//   pendulum.pendulum.frameTranslation.frame_b.r0[2] = pendulum.pendulum.frame_b.r0[2];
//   pendulum.pendulum.frameTranslation.frame_b.r0[3] = pendulum.pendulum.frame_b.r0[3];
//   pendulum.pendulum.frameTranslation.frame_b.v[1] = pendulum.pendulum.frame_b.v[1];
//   pendulum.pendulum.frameTranslation.frame_b.v[2] = pendulum.pendulum.frame_b.v[2];
//   pendulum.pendulum.frameTranslation.frame_b.v[3] = pendulum.pendulum.frame_b.v[3];
//   pendulum.pendulum.frameTranslation.frame_b.w[1] = pendulum.pendulum.frame_b.w[1];
//   pendulum.pendulum.frameTranslation.frame_b.w[2] = pendulum.pendulum.frame_b.w[2];
//   pendulum.pendulum.frameTranslation.frame_b.w[3] = pendulum.pendulum.frame_b.w[3];
//   pendulum.pendulum.frameTranslation.frame_b.z[1] = pendulum.pendulum.frame_b.z[1];
//   pendulum.pendulum.frameTranslation.frame_b.z[2] = pendulum.pendulum.frame_b.z[2];
//   pendulum.pendulum.frameTranslation.frame_b.z[3] = pendulum.pendulum.frame_b.z[3];
//   pendulum.pendulum.body.frame_a.S[1,1] = pendulum.pendulum.frameTranslation.frame_a.S[1,1];
//   pendulum.pendulum.body.frame_a.S[1,1] = pendulum.pendulum.frame_a.S[1,1];
//   pendulum.pendulum.body.frame_a.S[1,2] = pendulum.pendulum.frameTranslation.frame_a.S[1,2];
//   pendulum.pendulum.body.frame_a.S[1,2] = pendulum.pendulum.frame_a.S[1,2];
//   pendulum.pendulum.body.frame_a.S[1,3] = pendulum.pendulum.frameTranslation.frame_a.S[1,3];
//   pendulum.pendulum.body.frame_a.S[1,3] = pendulum.pendulum.frame_a.S[1,3];
//   pendulum.pendulum.body.frame_a.S[2,1] = pendulum.pendulum.frameTranslation.frame_a.S[2,1];
//   pendulum.pendulum.body.frame_a.S[2,1] = pendulum.pendulum.frame_a.S[2,1];
//   pendulum.pendulum.body.frame_a.S[2,2] = pendulum.pendulum.frameTranslation.frame_a.S[2,2];
//   pendulum.pendulum.body.frame_a.S[2,2] = pendulum.pendulum.frame_a.S[2,2];
//   pendulum.pendulum.body.frame_a.S[2,3] = pendulum.pendulum.frameTranslation.frame_a.S[2,3];
//   pendulum.pendulum.body.frame_a.S[2,3] = pendulum.pendulum.frame_a.S[2,3];
//   pendulum.pendulum.body.frame_a.S[3,1] = pendulum.pendulum.frameTranslation.frame_a.S[3,1];
//   pendulum.pendulum.body.frame_a.S[3,1] = pendulum.pendulum.frame_a.S[3,1];
//   pendulum.pendulum.body.frame_a.S[3,2] = pendulum.pendulum.frameTranslation.frame_a.S[3,2];
//   pendulum.pendulum.body.frame_a.S[3,2] = pendulum.pendulum.frame_a.S[3,2];
//   pendulum.pendulum.body.frame_a.S[3,3] = pendulum.pendulum.frameTranslation.frame_a.S[3,3];
//   pendulum.pendulum.body.frame_a.S[3,3] = pendulum.pendulum.frame_a.S[3,3];
//   pendulum.pendulum.body.frame_a.a[1] = pendulum.pendulum.frameTranslation.frame_a.a[1];
//   pendulum.pendulum.body.frame_a.a[1] = pendulum.pendulum.frame_a.a[1];
//   pendulum.pendulum.body.frame_a.a[2] = pendulum.pendulum.frameTranslation.frame_a.a[2];
//   pendulum.pendulum.body.frame_a.a[2] = pendulum.pendulum.frame_a.a[2];
//   pendulum.pendulum.body.frame_a.a[3] = pendulum.pendulum.frameTranslation.frame_a.a[3];
//   pendulum.pendulum.body.frame_a.a[3] = pendulum.pendulum.frame_a.a[3];
//   pendulum.pendulum.body.frame_a.r0[1] = pendulum.pendulum.frameTranslation.frame_a.r0[1];
//   pendulum.pendulum.body.frame_a.r0[1] = pendulum.pendulum.frame_a.r0[1];
//   pendulum.pendulum.body.frame_a.r0[2] = pendulum.pendulum.frameTranslation.frame_a.r0[2];
//   pendulum.pendulum.body.frame_a.r0[2] = pendulum.pendulum.frame_a.r0[2];
//   pendulum.pendulum.body.frame_a.r0[3] = pendulum.pendulum.frameTranslation.frame_a.r0[3];
//   pendulum.pendulum.body.frame_a.r0[3] = pendulum.pendulum.frame_a.r0[3];
//   pendulum.pendulum.body.frame_a.v[1] = pendulum.pendulum.frameTranslation.frame_a.v[1];
//   pendulum.pendulum.body.frame_a.v[1] = pendulum.pendulum.frame_a.v[1];
//   pendulum.pendulum.body.frame_a.v[2] = pendulum.pendulum.frameTranslation.frame_a.v[2];
//   pendulum.pendulum.body.frame_a.v[2] = pendulum.pendulum.frame_a.v[2];
//   pendulum.pendulum.body.frame_a.v[3] = pendulum.pendulum.frameTranslation.frame_a.v[3];
//   pendulum.pendulum.body.frame_a.v[3] = pendulum.pendulum.frame_a.v[3];
//   pendulum.pendulum.body.frame_a.w[1] = pendulum.pendulum.frameTranslation.frame_a.w[1];
//   pendulum.pendulum.body.frame_a.w[1] = pendulum.pendulum.frame_a.w[1];
//   pendulum.pendulum.body.frame_a.w[2] = pendulum.pendulum.frameTranslation.frame_a.w[2];
//   pendulum.pendulum.body.frame_a.w[2] = pendulum.pendulum.frame_a.w[2];
//   pendulum.pendulum.body.frame_a.w[3] = pendulum.pendulum.frameTranslation.frame_a.w[3];
//   pendulum.pendulum.body.frame_a.w[3] = pendulum.pendulum.frame_a.w[3];
//   pendulum.pendulum.body.frame_a.z[1] = pendulum.pendulum.frameTranslation.frame_a.z[1];
//   pendulum.pendulum.body.frame_a.z[1] = pendulum.pendulum.frame_a.z[1];
//   pendulum.pendulum.body.frame_a.z[2] = pendulum.pendulum.frameTranslation.frame_a.z[2];
//   pendulum.pendulum.body.frame_a.z[2] = pendulum.pendulum.frame_a.z[2];
//   pendulum.pendulum.body.frame_a.z[3] = pendulum.pendulum.frameTranslation.frame_a.z[3];
//   pendulum.pendulum.body.frame_a.z[3] = pendulum.pendulum.frame_a.z[3];
//   pendulum.cart.body.frame_a.t[1] + (-pendulum.cart.frame_a.t[1]) + pendulum.cart.frameTranslation.frame_a.t[1] = 0.0;
//   pendulum.cart.body.frame_a.t[2] + (-pendulum.cart.frame_a.t[2]) + pendulum.cart.frameTranslation.frame_a.t[2] = 0.0;
//   pendulum.cart.body.frame_a.t[3] + (-pendulum.cart.frame_a.t[3]) + pendulum.cart.frameTranslation.frame_a.t[3] = 0.0;
//   pendulum.cart.body.frame_a.f[1] + (-pendulum.cart.frame_a.f[1]) + pendulum.cart.frameTranslation.frame_a.f[1] = 0.0;
//   pendulum.cart.body.frame_a.f[2] + (-pendulum.cart.frame_a.f[2]) + pendulum.cart.frameTranslation.frame_a.f[2] = 0.0;
//   pendulum.cart.body.frame_a.f[3] + (-pendulum.cart.frame_a.f[3]) + pendulum.cart.frameTranslation.frame_a.f[3] = 0.0;
//   pendulum.cart.frame_b.t[1] + pendulum.toMidCart.frame_a.t[1] = 0.0;
//   pendulum.cart.frame_b.t[2] + pendulum.toMidCart.frame_a.t[2] = 0.0;
//   pendulum.cart.frame_b.t[3] + pendulum.toMidCart.frame_a.t[3] = 0.0;
//   pendulum.cart.frame_b.f[1] + pendulum.toMidCart.frame_a.f[1] = 0.0;
//   pendulum.cart.frame_b.f[2] + pendulum.toMidCart.frame_a.f[2] = 0.0;
//   pendulum.cart.frame_b.f[3] + pendulum.toMidCart.frame_a.f[3] = 0.0;
//   (-pendulum.cart.frame_b.t[1]) + pendulum.cart.frameTranslation.frame_b.t[1] = 0.0;
//   (-pendulum.cart.frame_b.t[2]) + pendulum.cart.frameTranslation.frame_b.t[2] = 0.0;
//   (-pendulum.cart.frame_b.t[3]) + pendulum.cart.frameTranslation.frame_b.t[3] = 0.0;
//   (-pendulum.cart.frame_b.f[1]) + pendulum.cart.frameTranslation.frame_b.f[1] = 0.0;
//   (-pendulum.cart.frame_b.f[2]) + pendulum.cart.frameTranslation.frame_b.f[2] = 0.0;
//   (-pendulum.cart.frame_b.f[3]) + pendulum.cart.frameTranslation.frame_b.f[3] = 0.0;
//   pendulum.cart.frameTranslation.frame_b.S[1,1] = pendulum.cart.frame_b.S[1,1];
//   pendulum.cart.frameTranslation.frame_b.S[1,2] = pendulum.cart.frame_b.S[1,2];
//   pendulum.cart.frameTranslation.frame_b.S[1,3] = pendulum.cart.frame_b.S[1,3];
//   pendulum.cart.frameTranslation.frame_b.S[2,1] = pendulum.cart.frame_b.S[2,1];
//   pendulum.cart.frameTranslation.frame_b.S[2,2] = pendulum.cart.frame_b.S[2,2];
//   pendulum.cart.frameTranslation.frame_b.S[2,3] = pendulum.cart.frame_b.S[2,3];
//   pendulum.cart.frameTranslation.frame_b.S[3,1] = pendulum.cart.frame_b.S[3,1];
//   pendulum.cart.frameTranslation.frame_b.S[3,2] = pendulum.cart.frame_b.S[3,2];
//   pendulum.cart.frameTranslation.frame_b.S[3,3] = pendulum.cart.frame_b.S[3,3];
//   pendulum.cart.frameTranslation.frame_b.a[1] = pendulum.cart.frame_b.a[1];
//   pendulum.cart.frameTranslation.frame_b.a[2] = pendulum.cart.frame_b.a[2];
//   pendulum.cart.frameTranslation.frame_b.a[3] = pendulum.cart.frame_b.a[3];
//   pendulum.cart.frameTranslation.frame_b.r0[1] = pendulum.cart.frame_b.r0[1];
//   pendulum.cart.frameTranslation.frame_b.r0[2] = pendulum.cart.frame_b.r0[2];
//   pendulum.cart.frameTranslation.frame_b.r0[3] = pendulum.cart.frame_b.r0[3];
//   pendulum.cart.frameTranslation.frame_b.v[1] = pendulum.cart.frame_b.v[1];
//   pendulum.cart.frameTranslation.frame_b.v[2] = pendulum.cart.frame_b.v[2];
//   pendulum.cart.frameTranslation.frame_b.v[3] = pendulum.cart.frame_b.v[3];
//   pendulum.cart.frameTranslation.frame_b.w[1] = pendulum.cart.frame_b.w[1];
//   pendulum.cart.frameTranslation.frame_b.w[2] = pendulum.cart.frame_b.w[2];
//   pendulum.cart.frameTranslation.frame_b.w[3] = pendulum.cart.frame_b.w[3];
//   pendulum.cart.frameTranslation.frame_b.z[1] = pendulum.cart.frame_b.z[1];
//   pendulum.cart.frameTranslation.frame_b.z[2] = pendulum.cart.frame_b.z[2];
//   pendulum.cart.frameTranslation.frame_b.z[3] = pendulum.cart.frame_b.z[3];
//   pendulum.cart.body.frame_a.S[1,1] = pendulum.cart.frameTranslation.frame_a.S[1,1];
//   pendulum.cart.body.frame_a.S[1,1] = pendulum.cart.frame_a.S[1,1];
//   pendulum.cart.body.frame_a.S[1,2] = pendulum.cart.frameTranslation.frame_a.S[1,2];
//   pendulum.cart.body.frame_a.S[1,2] = pendulum.cart.frame_a.S[1,2];
//   pendulum.cart.body.frame_a.S[1,3] = pendulum.cart.frameTranslation.frame_a.S[1,3];
//   pendulum.cart.body.frame_a.S[1,3] = pendulum.cart.frame_a.S[1,3];
//   pendulum.cart.body.frame_a.S[2,1] = pendulum.cart.frameTranslation.frame_a.S[2,1];
//   pendulum.cart.body.frame_a.S[2,1] = pendulum.cart.frame_a.S[2,1];
//   pendulum.cart.body.frame_a.S[2,2] = pendulum.cart.frameTranslation.frame_a.S[2,2];
//   pendulum.cart.body.frame_a.S[2,2] = pendulum.cart.frame_a.S[2,2];
//   pendulum.cart.body.frame_a.S[2,3] = pendulum.cart.frameTranslation.frame_a.S[2,3];
//   pendulum.cart.body.frame_a.S[2,3] = pendulum.cart.frame_a.S[2,3];
//   pendulum.cart.body.frame_a.S[3,1] = pendulum.cart.frameTranslation.frame_a.S[3,1];
//   pendulum.cart.body.frame_a.S[3,1] = pendulum.cart.frame_a.S[3,1];
//   pendulum.cart.body.frame_a.S[3,2] = pendulum.cart.frameTranslation.frame_a.S[3,2];
//   pendulum.cart.body.frame_a.S[3,2] = pendulum.cart.frame_a.S[3,2];
//   pendulum.cart.body.frame_a.S[3,3] = pendulum.cart.frameTranslation.frame_a.S[3,3];
//   pendulum.cart.body.frame_a.S[3,3] = pendulum.cart.frame_a.S[3,3];
//   pendulum.cart.body.frame_a.a[1] = pendulum.cart.frameTranslation.frame_a.a[1];
//   pendulum.cart.body.frame_a.a[1] = pendulum.cart.frame_a.a[1];
//   pendulum.cart.body.frame_a.a[2] = pendulum.cart.frameTranslation.frame_a.a[2];
//   pendulum.cart.body.frame_a.a[2] = pendulum.cart.frame_a.a[2];
//   pendulum.cart.body.frame_a.a[3] = pendulum.cart.frameTranslation.frame_a.a[3];
//   pendulum.cart.body.frame_a.a[3] = pendulum.cart.frame_a.a[3];
//   pendulum.cart.body.frame_a.r0[1] = pendulum.cart.frameTranslation.frame_a.r0[1];
//   pendulum.cart.body.frame_a.r0[1] = pendulum.cart.frame_a.r0[1];
//   pendulum.cart.body.frame_a.r0[2] = pendulum.cart.frameTranslation.frame_a.r0[2];
//   pendulum.cart.body.frame_a.r0[2] = pendulum.cart.frame_a.r0[2];
//   pendulum.cart.body.frame_a.r0[3] = pendulum.cart.frameTranslation.frame_a.r0[3];
//   pendulum.cart.body.frame_a.r0[3] = pendulum.cart.frame_a.r0[3];
//   pendulum.cart.body.frame_a.v[1] = pendulum.cart.frameTranslation.frame_a.v[1];
//   pendulum.cart.body.frame_a.v[1] = pendulum.cart.frame_a.v[1];
//   pendulum.cart.body.frame_a.v[2] = pendulum.cart.frameTranslation.frame_a.v[2];
//   pendulum.cart.body.frame_a.v[2] = pendulum.cart.frame_a.v[2];
//   pendulum.cart.body.frame_a.v[3] = pendulum.cart.frameTranslation.frame_a.v[3];
//   pendulum.cart.body.frame_a.v[3] = pendulum.cart.frame_a.v[3];
//   pendulum.cart.body.frame_a.w[1] = pendulum.cart.frameTranslation.frame_a.w[1];
//   pendulum.cart.body.frame_a.w[1] = pendulum.cart.frame_a.w[1];
//   pendulum.cart.body.frame_a.w[2] = pendulum.cart.frameTranslation.frame_a.w[2];
//   pendulum.cart.body.frame_a.w[2] = pendulum.cart.frame_a.w[2];
//   pendulum.cart.body.frame_a.w[3] = pendulum.cart.frameTranslation.frame_a.w[3];
//   pendulum.cart.body.frame_a.w[3] = pendulum.cart.frame_a.w[3];
//   pendulum.cart.body.frame_a.z[1] = pendulum.cart.frameTranslation.frame_a.z[1];
//   pendulum.cart.body.frame_a.z[1] = pendulum.cart.frame_a.z[1];
//   pendulum.cart.body.frame_a.z[2] = pendulum.cart.frameTranslation.frame_a.z[2];
//   pendulum.cart.body.frame_a.z[2] = pendulum.cart.frame_a.z[2];
//   pendulum.cart.body.frame_a.z[3] = pendulum.cart.frameTranslation.frame_a.z[3];
//   pendulum.cart.body.frame_a.z[3] = pendulum.cart.frame_a.z[3];
//   pendulum.pendulum.frame_a.S[1,1] = pendulum.pendulumJoint.frame_b.S[1,1];
//   pendulum.pendulum.frame_a.S[1,2] = pendulum.pendulumJoint.frame_b.S[1,2];
//   pendulum.pendulum.frame_a.S[1,3] = pendulum.pendulumJoint.frame_b.S[1,3];
//   pendulum.pendulum.frame_a.S[2,1] = pendulum.pendulumJoint.frame_b.S[2,1];
//   pendulum.pendulum.frame_a.S[2,2] = pendulum.pendulumJoint.frame_b.S[2,2];
//   pendulum.pendulum.frame_a.S[2,3] = pendulum.pendulumJoint.frame_b.S[2,3];
//   pendulum.pendulum.frame_a.S[3,1] = pendulum.pendulumJoint.frame_b.S[3,1];
//   pendulum.pendulum.frame_a.S[3,2] = pendulum.pendulumJoint.frame_b.S[3,2];
//   pendulum.pendulum.frame_a.S[3,3] = pendulum.pendulumJoint.frame_b.S[3,3];
//   pendulum.pendulum.frame_a.a[1] = pendulum.pendulumJoint.frame_b.a[1];
//   pendulum.pendulum.frame_a.a[2] = pendulum.pendulumJoint.frame_b.a[2];
//   pendulum.pendulum.frame_a.a[3] = pendulum.pendulumJoint.frame_b.a[3];
//   pendulum.pendulum.frame_a.r0[1] = pendulum.pendulumJoint.frame_b.r0[1];
//   pendulum.pendulum.frame_a.r0[2] = pendulum.pendulumJoint.frame_b.r0[2];
//   pendulum.pendulum.frame_a.r0[3] = pendulum.pendulumJoint.frame_b.r0[3];
//   pendulum.pendulum.frame_a.v[1] = pendulum.pendulumJoint.frame_b.v[1];
//   pendulum.pendulum.frame_a.v[2] = pendulum.pendulumJoint.frame_b.v[2];
//   pendulum.pendulum.frame_a.v[3] = pendulum.pendulumJoint.frame_b.v[3];
//   pendulum.pendulum.frame_a.w[1] = pendulum.pendulumJoint.frame_b.w[1];
//   pendulum.pendulum.frame_a.w[2] = pendulum.pendulumJoint.frame_b.w[2];
//   pendulum.pendulum.frame_a.w[3] = pendulum.pendulumJoint.frame_b.w[3];
//   pendulum.pendulum.frame_a.z[1] = pendulum.pendulumJoint.frame_b.z[1];
//   pendulum.pendulum.frame_a.z[2] = pendulum.pendulumJoint.frame_b.z[2];
//   pendulum.pendulum.frame_a.z[3] = pendulum.pendulumJoint.frame_b.z[3];
//   pendulum.angleSensor.flange_a.phi = pendulum.pendulumDamper.flange_b.phi;
//   pendulum.angleSensor.flange_a.phi = pendulum.pendulumJoint.axis.phi;
//   pendulum.pendulumDamper.flange_a.phi = pendulum.pendulumJoint.bearing.phi;
//   pendulum.flange_a.s = pendulum.positionSensor.flange_a.s;
//   pendulum.flange_a.s = pendulum.sliderConstraint.axis.s;
//   pendulum.flange_a.s = pendulum.sliderDamper.flange_b.s;
//   pendulum.sliderConstraint.bearing.s = pendulum.sliderDamper.flange_a.s;
//   pendulum.pendulumJoint.frame_a.S[1,1] = pendulum.toMidCart.frame_b.S[1,1];
//   pendulum.pendulumJoint.frame_a.S[1,2] = pendulum.toMidCart.frame_b.S[1,2];
//   pendulum.pendulumJoint.frame_a.S[1,3] = pendulum.toMidCart.frame_b.S[1,3];
//   pendulum.pendulumJoint.frame_a.S[2,1] = pendulum.toMidCart.frame_b.S[2,1];
//   pendulum.pendulumJoint.frame_a.S[2,2] = pendulum.toMidCart.frame_b.S[2,2];
//   pendulum.pendulumJoint.frame_a.S[2,3] = pendulum.toMidCart.frame_b.S[2,3];
//   pendulum.pendulumJoint.frame_a.S[3,1] = pendulum.toMidCart.frame_b.S[3,1];
//   pendulum.pendulumJoint.frame_a.S[3,2] = pendulum.toMidCart.frame_b.S[3,2];
//   pendulum.pendulumJoint.frame_a.S[3,3] = pendulum.toMidCart.frame_b.S[3,3];
//   pendulum.pendulumJoint.frame_a.a[1] = pendulum.toMidCart.frame_b.a[1];
//   pendulum.pendulumJoint.frame_a.a[2] = pendulum.toMidCart.frame_b.a[2];
//   pendulum.pendulumJoint.frame_a.a[3] = pendulum.toMidCart.frame_b.a[3];
//   pendulum.pendulumJoint.frame_a.r0[1] = pendulum.toMidCart.frame_b.r0[1];
//   pendulum.pendulumJoint.frame_a.r0[2] = pendulum.toMidCart.frame_b.r0[2];
//   pendulum.pendulumJoint.frame_a.r0[3] = pendulum.toMidCart.frame_b.r0[3];
//   pendulum.pendulumJoint.frame_a.v[1] = pendulum.toMidCart.frame_b.v[1];
//   pendulum.pendulumJoint.frame_a.v[2] = pendulum.toMidCart.frame_b.v[2];
//   pendulum.pendulumJoint.frame_a.v[3] = pendulum.toMidCart.frame_b.v[3];
//   pendulum.pendulumJoint.frame_a.w[1] = pendulum.toMidCart.frame_b.w[1];
//   pendulum.pendulumJoint.frame_a.w[2] = pendulum.toMidCart.frame_b.w[2];
//   pendulum.pendulumJoint.frame_a.w[3] = pendulum.toMidCart.frame_b.w[3];
//   pendulum.pendulumJoint.frame_a.z[1] = pendulum.toMidCart.frame_b.z[1];
//   pendulum.pendulumJoint.frame_a.z[2] = pendulum.toMidCart.frame_b.z[2];
//   pendulum.pendulumJoint.frame_a.z[3] = pendulum.toMidCart.frame_b.z[3];
//   pendulum.cart.frame_b.S[1,1] = pendulum.toMidCart.frame_a.S[1,1];
//   pendulum.cart.frame_b.S[1,2] = pendulum.toMidCart.frame_a.S[1,2];
//   pendulum.cart.frame_b.S[1,3] = pendulum.toMidCart.frame_a.S[1,3];
//   pendulum.cart.frame_b.S[2,1] = pendulum.toMidCart.frame_a.S[2,1];
//   pendulum.cart.frame_b.S[2,2] = pendulum.toMidCart.frame_a.S[2,2];
//   pendulum.cart.frame_b.S[2,3] = pendulum.toMidCart.frame_a.S[2,3];
//   pendulum.cart.frame_b.S[3,1] = pendulum.toMidCart.frame_a.S[3,1];
//   pendulum.cart.frame_b.S[3,2] = pendulum.toMidCart.frame_a.S[3,2];
//   pendulum.cart.frame_b.S[3,3] = pendulum.toMidCart.frame_a.S[3,3];
//   pendulum.cart.frame_b.a[1] = pendulum.toMidCart.frame_a.a[1];
//   pendulum.cart.frame_b.a[2] = pendulum.toMidCart.frame_a.a[2];
//   pendulum.cart.frame_b.a[3] = pendulum.toMidCart.frame_a.a[3];
//   pendulum.cart.frame_b.r0[1] = pendulum.toMidCart.frame_a.r0[1];
//   pendulum.cart.frame_b.r0[2] = pendulum.toMidCart.frame_a.r0[2];
//   pendulum.cart.frame_b.r0[3] = pendulum.toMidCart.frame_a.r0[3];
//   pendulum.cart.frame_b.v[1] = pendulum.toMidCart.frame_a.v[1];
//   pendulum.cart.frame_b.v[2] = pendulum.toMidCart.frame_a.v[2];
//   pendulum.cart.frame_b.v[3] = pendulum.toMidCart.frame_a.v[3];
//   pendulum.cart.frame_b.w[1] = pendulum.toMidCart.frame_a.w[1];
//   pendulum.cart.frame_b.w[2] = pendulum.toMidCart.frame_a.w[2];
//   pendulum.cart.frame_b.w[3] = pendulum.toMidCart.frame_a.w[3];
//   pendulum.cart.frame_b.z[1] = pendulum.toMidCart.frame_a.z[1];
//   pendulum.cart.frame_b.z[2] = pendulum.toMidCart.frame_a.z[2];
//   pendulum.cart.frame_b.z[3] = pendulum.toMidCart.frame_a.z[3];
//   pendulum.cart.frame_a.S[1,1] = pendulum.sliderConstraint.frame_b.S[1,1];
//   pendulum.cart.frame_a.S[1,2] = pendulum.sliderConstraint.frame_b.S[1,2];
//   pendulum.cart.frame_a.S[1,3] = pendulum.sliderConstraint.frame_b.S[1,3];
//   pendulum.cart.frame_a.S[2,1] = pendulum.sliderConstraint.frame_b.S[2,1];
//   pendulum.cart.frame_a.S[2,2] = pendulum.sliderConstraint.frame_b.S[2,2];
//   pendulum.cart.frame_a.S[2,3] = pendulum.sliderConstraint.frame_b.S[2,3];
//   pendulum.cart.frame_a.S[3,1] = pendulum.sliderConstraint.frame_b.S[3,1];
//   pendulum.cart.frame_a.S[3,2] = pendulum.sliderConstraint.frame_b.S[3,2];
//   pendulum.cart.frame_a.S[3,3] = pendulum.sliderConstraint.frame_b.S[3,3];
//   pendulum.cart.frame_a.a[1] = pendulum.sliderConstraint.frame_b.a[1];
//   pendulum.cart.frame_a.a[2] = pendulum.sliderConstraint.frame_b.a[2];
//   pendulum.cart.frame_a.a[3] = pendulum.sliderConstraint.frame_b.a[3];
//   pendulum.cart.frame_a.r0[1] = pendulum.sliderConstraint.frame_b.r0[1];
//   pendulum.cart.frame_a.r0[2] = pendulum.sliderConstraint.frame_b.r0[2];
//   pendulum.cart.frame_a.r0[3] = pendulum.sliderConstraint.frame_b.r0[3];
//   pendulum.cart.frame_a.v[1] = pendulum.sliderConstraint.frame_b.v[1];
//   pendulum.cart.frame_a.v[2] = pendulum.sliderConstraint.frame_b.v[2];
//   pendulum.cart.frame_a.v[3] = pendulum.sliderConstraint.frame_b.v[3];
//   pendulum.cart.frame_a.w[1] = pendulum.sliderConstraint.frame_b.w[1];
//   pendulum.cart.frame_a.w[2] = pendulum.sliderConstraint.frame_b.w[2];
//   pendulum.cart.frame_a.w[3] = pendulum.sliderConstraint.frame_b.w[3];
//   pendulum.cart.frame_a.z[1] = pendulum.sliderConstraint.frame_b.z[1];
//   pendulum.cart.frame_a.z[2] = pendulum.sliderConstraint.frame_b.z[2];
//   pendulum.cart.frame_a.z[3] = pendulum.sliderConstraint.frame_b.z[3];
//   pendulum.inertialSystem.frame_b.S[1,1] = pendulum.sliderConstraint.frame_a.S[1,1];
//   pendulum.inertialSystem.frame_b.S[1,2] = pendulum.sliderConstraint.frame_a.S[1,2];
//   pendulum.inertialSystem.frame_b.S[1,3] = pendulum.sliderConstraint.frame_a.S[1,3];
//   pendulum.inertialSystem.frame_b.S[2,1] = pendulum.sliderConstraint.frame_a.S[2,1];
//   pendulum.inertialSystem.frame_b.S[2,2] = pendulum.sliderConstraint.frame_a.S[2,2];
//   pendulum.inertialSystem.frame_b.S[2,3] = pendulum.sliderConstraint.frame_a.S[2,3];
//   pendulum.inertialSystem.frame_b.S[3,1] = pendulum.sliderConstraint.frame_a.S[3,1];
//   pendulum.inertialSystem.frame_b.S[3,2] = pendulum.sliderConstraint.frame_a.S[3,2];
//   pendulum.inertialSystem.frame_b.S[3,3] = pendulum.sliderConstraint.frame_a.S[3,3];
//   pendulum.inertialSystem.frame_b.a[1] = pendulum.sliderConstraint.frame_a.a[1];
//   pendulum.inertialSystem.frame_b.a[2] = pendulum.sliderConstraint.frame_a.a[2];
//   pendulum.inertialSystem.frame_b.a[3] = pendulum.sliderConstraint.frame_a.a[3];
//   pendulum.inertialSystem.frame_b.r0[1] = pendulum.sliderConstraint.frame_a.r0[1];
//   pendulum.inertialSystem.frame_b.r0[2] = pendulum.sliderConstraint.frame_a.r0[2];
//   pendulum.inertialSystem.frame_b.r0[3] = pendulum.sliderConstraint.frame_a.r0[3];
//   pendulum.inertialSystem.frame_b.v[1] = pendulum.sliderConstraint.frame_a.v[1];
//   pendulum.inertialSystem.frame_b.v[2] = pendulum.sliderConstraint.frame_a.v[2];
//   pendulum.inertialSystem.frame_b.v[3] = pendulum.sliderConstraint.frame_a.v[3];
//   pendulum.inertialSystem.frame_b.w[1] = pendulum.sliderConstraint.frame_a.w[1];
//   pendulum.inertialSystem.frame_b.w[2] = pendulum.sliderConstraint.frame_a.w[2];
//   pendulum.inertialSystem.frame_b.w[3] = pendulum.sliderConstraint.frame_a.w[3];
//   pendulum.inertialSystem.frame_b.z[1] = pendulum.sliderConstraint.frame_a.z[1];
//   pendulum.inertialSystem.frame_b.z[2] = pendulum.sliderConstraint.frame_a.z[2];
//   pendulum.inertialSystem.frame_b.z[3] = pendulum.sliderConstraint.frame_a.z[3];
//   pendulum.angle = pendulum.angleSensor.phi;
//   pendulum.position = pendulum.positionSensor.s;
//   (-gear.flange_a.tau) + gear.idealGear.flange_a.tau = 0.0;
//   gear.idealGear.flange_b.tau + gear.gearR2T.flange_a.tau = 0.0;
//   gear.idealGear.bearing.tau = 0.0;
//   (-gear.flange_b.f) + gear.gearR2T.flange_b.f = 0.0;
//   gear.gearR2T.bearingR.tau = 0.0;
//   gear.gearR2T.bearingT.f = 0.0;
//   gear.gearR2T.flange_a.phi = gear.idealGear.flange_b.phi;
//   gear.flange_a.phi = gear.idealGear.flange_a.phi;
//   gear.flange_b.s = gear.gearR2T.flange_b.s;
//   controller.limiter.y = controller.mux.u1[1];
//   controller.limiter.y = controller.y;
//   controller.L_r.u = controller.switch1.y;
//   controller.ConstantQ.y = controller.switch1.u2;
//   controller.switch2.u3 = controller.timeTable.y;
//   controller.ConstantQ1.y = controller.switch2.u2;
//   controller.switch1.u3 = controller.switch2.y;
//   controller.pulse.y = controller.switch2.u1;
//   controller.mux.u2[1] = controller.xPos;
//   controller.angle = controller.mux.u3[1];
//   controller.feedback.y = controller.limiter.u;
//   controller.step.y = controller.switch1.u1;
//   controller.mux.y[1] = controller.observer.u[1];
//   controller.mux.y[2] = controller.observer.u[2];
//   controller.mux.y[3] = controller.observer.u[3];
//   controller.L_r.y = controller.feedback.u1;
//   controller.L.y[1] = controller.feedback.u2;
//   controller.L.u[1] = controller.observer.y[1];
//   controller.L.u[2] = controller.observer.y[2];
//   controller.L.u[3] = controller.observer.y[3];
//   controller.L.u[4] = controller.observer.y[4];
//   gear.flange_b.s = pendulum.flange_a.s;
//   gear.flange_a.phi = motor.flange.phi;
//   controller.y = motor.u;
//   controller.xPos = pendulum.position;
//   controller.angle = pendulum.angle;
// algorithm
//   when {time >= pre(controller.timeTable.nextEvent), initial()} then
//     (controller.timeTable.a, controller.timeTable.b, controller.timeTable.nextEvent, controller.timeTable.last) := Modelica.Blocks.Sources.TimeTable$controller$timeTable.getInterpolationCoefficients({{controller.timeTable.table[1,1], controller.timeTable.table[1,2]}, {controller.timeTable.table[2,1], controller.timeTable.table[2,2]}, {controller.timeTable.table[3,1], controller.timeTable.table[3,2]}, {controller.timeTable.table[4,1], controller.timeTable.table[4,2]}, {controller.timeTable.table[5,1], controller.timeTable.table[5,2]}, {controller.timeTable.table[6,1], controller.timeTable.table[6,2]}, {controller.timeTable.table[7,1], controller.timeTable.table[7,2]}}, controller.timeTable.offset, controller.timeTable.startTime, time, controller.timeTable.last, 1e-13);
//   end when;
// end IntroductoryExamples_Systems_InvertedPendulum;
// endResult
