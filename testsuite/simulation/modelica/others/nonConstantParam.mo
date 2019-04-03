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
", revisions=""), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  package Mechanics "Library to model 1-dim. and 3-dim. mechanical systems (multi-body, rotational, translational)"
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-(5),-(70)},{45,-(40)}}),Ellipse(visible=true, extent={{-(90),-(60)},{-(80),-(50)}}),Line(visible=true, points={{-(85),-(55)},{-(60),-(21)}}, thickness=0.5),Ellipse(visible=true, extent={{-(65),-(26)},{-(55),-(16)}}),Line(visible=true, points={{-(60),-(21)},{9,-(55)}}, thickness=0.5),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{4,-(60)},{14,-(50)}}),Line(visible=true, points={{-(10),-(34)},{72,-(34)},{72,-(76)},{-(10),-(76)}})}), Documentation(info="<HTML>
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
</html>"), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    package Rotational "Library to model 1-dimensional, rotational mechanical systems"
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
", revisions=""), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(83),-(66)},{-(63),-(66)}}),Line(visible=true, points={{36,-(68)},{56,-(68)}}),Line(visible=true, points={{-(73),-(66)},{-(73),-(91)}}),Line(visible=true, points={{46,-(68)},{46,-(91)}}),Line(visible=true, points={{-(83),-(29)},{-(63),-(29)}}),Line(visible=true, points={{36,-(32)},{56,-(32)}}),Line(visible=true, points={{-(73),-(9)},{-(73),-(29)}}),Line(visible=true, points={{46,-(12)},{46,-(32)}}),Line(visible=true, points={{-(73),-(91)},{46,-(91)}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-(47),-(80)},{27,-(17)}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-(87),-(54)},{-(47),-(41)}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{27,-(56)},{66,-(42)}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      package Interfaces "Connectors and partial models for 1D rotational mechanical components"
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Documentation(info="<html>
<p>
This package contains connectors and partial models for 1-dim.
rotational mechanical components. The components of this package can
only be used as basic building elements for models.
</p>

</HTML>
"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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
"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{100,100}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-(160),50},{40,90}}, textString="%name", fontName="Arial"),Ellipse(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{-(40),-(40)},{40,40}})}));
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
"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(98),-(100)},{102,100}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(40),-(40)},{40,40}}),Text(visible=true, extent={{-(40),50},{160,90}}, textString="%name", fontName="Arial")}));
        end Flange_b;

        partial model Rigid "Base class for the rigid connection of two rotational 1D flanges"
          SI.Angle phi "Absolute rotation angle of component (= flange_a.phi = flange_b.phi)";
          annotation(Documentation(info="<html>
<p>
This is a 1D rotational component with two rigidly connected flanges,
i.e., flange_a.phi = flange_b.phi. It is used e.g. to built up components
with inertia.
</p>

</HTML>
"), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),-(100)},{100,100}})), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Flange_a flange_a "(left) driving flange (flange axis directed INTO cut plane)" annotation(Placement(visible=true, transformation(origin={-(100),0}, extent={{-(10),-(10)},{10,10}}, rotation=0), iconTransformation(origin={-(100),0}, extent={{-(10),-(10)},{10,10}}, rotation=0)));
          Flange_b flange_b "(right) driven flange (flange axis directed OUT OF cut plane)" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-(10),-(10)},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-(10),-(10)},{10,10}}, rotation=0)));
        equation
          flange_a.phi=phi;
          flange_b.phi=phi;
        end Rigid;

        partial model PartialSpeedDependentTorque "Partial model of a torque acting at the flange (accelerates the flange)"
          Modelica.SIunits.AngularVelocity w=der(flange.phi) "Angular velocity at flange";
          Modelica.SIunits.Torque tau=flange.tau "accelerating torque acting at flange";
          annotation(Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<HTML>
<p>
Partial model of torque dependent on speed that accelerates the flange.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={255,255,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(96),-(96)},{96,96}}),Line(visible=true, points={{-(30),-(70)},{30,-(70)}}),Line(visible=true, points={{-(30),-(90)},{-(10),-(70)}}),Line(visible=true, points={{-(10),-(90)},{10,-(70)}}),Rectangle(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-(20),-(140)},{20,-(100)}}),Line(visible=true, points={{10,-(90)},{30,-(70)}}),Line(visible=true, points={{0,-(70)},{0,-(110)}}),Line(visible=true, points={{-(92),0},{-(76),36},{-(54),62},{-(30),80},{-(14),88},{10,92},{26,90},{46,80},{64,62}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={0,0,255}, extent={{-(150),100},{150,140}}, textString="%name", fontName="Arial"),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{94,16},{80,74},{50,52},{94,16}})}));
          Modelica.Mechanics.Rotational.Interfaces.Flange_b flange "Flange on which torque is acting" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{10,-(10)},{-(10),10}}, rotation=0), iconTransformation(origin={100,0}, extent={{10,-(10)},{-(10),10}}, rotation=0)));
          Modelica.Mechanics.Rotational.Interfaces.Flange_a bearing "Bearing at which the reaction torque (i.e., -flange.tau) is acting" annotation(Placement(visible=true, transformation(origin={0,-(120)}, extent={{-(10),-(10)},{10,10}}, rotation=0), iconTransformation(origin={0,-(120)}, extent={{-(10),-(10)},{10,10}}, rotation=0)));
        equation
          if cardinality(bearing) == 0 then
            bearing.phi=0;
          else
            bearing.tau=-(flange.tau);
          end if;
        end PartialSpeedDependentTorque;

      end Interfaces;

      model Inertia "1D-rotational component with inertia"
        import SI = Modelica.SIunits;
        import Modelica.Mechanics.Rotational.Types.Init;
        import Modelica.Blocks.Types.StateSelection;
        parameter SI.Inertia J(min=0)=1 "Moment of inertia";
        parameter Init.Temp initType=Modelica.Mechanics.Rotational.Types.Init.NoInit "Type of initialization (defines usage of start values below)" annotation(Dialog(group="Initialization"));
        parameter SI.Angle phi_start=0 "Initial or guess value of rotor rotation angle phi" annotation(Dialog(group="Initialization"), Evaluate=false);
        parameter SI.AngularVelocity w_start=0 "Initial or guess value of angular velocity w = der(phi)" annotation(Dialog(group="Initialization"), Evaluate=false);
        parameter SI.AngularAcceleration a_start=0 "Initial value of angular acceleration a = der(w)" annotation(Dialog(group="Initialization", enable=initType >= Init.InitialAcceleration), Evaluate=false);
        parameter StateSelection.Temp stateSelection=Modelica.Blocks.Types.StateSelection.Default "Priority to use phi and w as states" annotation(Dialog(tab="Advanced"));
        extends Interfaces.Rigid(phi(start=phi_start, stateSelect=if stateSelection == StateSelection.Never then StateSelect.never else if stateSelection == StateSelection.Avoid then StateSelect.avoid else if stateSelection == StateSelection.Default then StateSelect.default else if stateSelection == StateSelection.Prefer then StateSelect.prefer else StateSelect.always));
        SI.AngularVelocity w(start=w_start, stateSelect=if stateSelection == StateSelection.Never then StateSelect.never else if stateSelection == StateSelection.Avoid then StateSelect.avoid else if stateSelection == StateSelection.Default then StateSelect.default else if stateSelection == StateSelection.Prefer then StateSelect.prefer else StateSelect.always) "Absolute angular velocity of component";
        SI.AngularAcceleration a "Absolute angular acceleration of component";
        annotation(Documentation(info="<html>
<p>
Rotational component with <b>inertia</b> and two rigidly connected flanges.
</p>

</HTML>
"), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(80),-(25)},{-(60),-(25)}}),Line(visible=true, points={{60,-(25)},{80,-(25)}}),Line(visible=true, points={{-(70),-(25)},{-(70),-(70)}}),Line(visible=true, points={{70,-(25)},{70,-(70)}}),Line(visible=true, points={{-(80),25},{-(60),25}}),Line(visible=true, points={{60,25},{80,25}}),Line(visible=true, points={{-(70),45},{-(70),25}}),Line(visible=true, points={{70,45},{70,25}}),Line(visible=true, points={{-(70),-(70)},{70,-(70)}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-(50),-(50)},{50,50}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-(96),-(10)},{-(50),10}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{50,-(10)},{96,10}}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{0,-(90)},{-(20),-(85)},{-(20),-(95)},{0,-(90)}}),Line(visible=true, points={{-(90),-(90)},{-(19),-(90)}}, color={128,128,128}),Text(visible=true, fillColor={128,128,128}, extent={{4,-(96)},{72,-(83)}}, textString="rotation axis", fontName="Arial"),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{9,73},{19,70},{9,67},{9,73}}),Line(visible=true, points={{9,70},{-(21),70}}),Text(visible=true, extent={{25,65},{77,77}}, textString="w = der(phi) ", fontName="Arial")}), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-(100),-(10)},{-(50),10}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{50,-(10)},{100,10}}),Line(visible=true, points={{-(80),-(25)},{-(60),-(25)}}),Line(visible=true, points={{60,-(25)},{80,-(25)}}),Line(visible=true, points={{-(70),-(25)},{-(70),-(70)}}),Line(visible=true, points={{70,-(25)},{70,-(70)}}),Line(visible=true, points={{-(80),25},{-(60),25}}),Line(visible=true, points={{60,25},{80,25}}),Line(visible=true, points={{-(70),45},{-(70),25}}),Line(visible=true, points={{70,45},{70,25}}),Line(visible=true, points={{-(70),-(70)},{70,-(70)}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-(50),-(50)},{50,50}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(150),60},{150,100}}, textString="%name", fontName="Arial"),Text(visible=true, extent={{-(150),-(120)},{150,-(80)}}, textString="J=%J", fontName="Arial")}));
      initial equation
        if initType == Init.SteadyState then
          der(phi)=0;
          der(w)=0;
        elseif initType == Init.InitialState then
          phi=phi_start;
          w=w_start;
        elseif initType == Init.InitialAngle then
          phi=phi_start;
        elseif initType == Init.InitialSpeed then
          w=w_start;
        elseif initType == Init.InitialAcceleration then
          a=a_start;
        elseif initType == Init.InitialAngleAcceleration then
          phi=phi_start;
          a=a_start;
        elseif initType == Init.InitialSpeedAcceleration then
          w=w_start;
          a=a_start;
        elseif initType == Init.InitialAngleSpeedAcceleration then
          phi=phi_start;
          w=w_start;
          a=a_start;
        else
        end if;
      equation
        w=der(phi);
        a=der(w);
        J*a=flange_a.tau + flange_b.tau;
      end Inertia;

      model Fixed "Flange fixed in housing at a given angle"
        parameter SI.Angle phi0=0 "Fixed offset angle of housing";
        annotation(Documentation(info="<html>
<p>
The <b>flange</b> of a 1D rotational mechanical system is <b>fixed</b>
at an angle phi0 in the <b>housing</b>. May be used:
</p>
<ul>
<li> to connect a compliant element, such as a spring or a damper,
     between an inertia or gearbox component and the housing.
<li> to fix a rigid element, such as an inertia, with a specific
     angle to the housing.
</ul>

</HTML>
"), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(80),-(40)},{80,-(40)}}),Line(visible=true, points={{80,-(40)},{40,-(80)}}),Line(visible=true, points={{40,-(40)},{0,-(80)}}),Line(visible=true, points={{0,-(40)},{-(40),-(80)}}),Line(visible=true, points={{-(40),-(40)},{-(80),-(80)}}),Line(visible=true, points={{0,-(40)},{0,-(4)}}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{8,46},{-(12),51},{-(12),41},{8,46}}),Line(visible=true, points={{-(82),46},{-(11),46}}, color={128,128,128}),Text(visible=true, fillColor={128,128,128}, extent={{12,40},{80,53}}, textString="rotation axis", fontName="Arial")}), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(150),-(130)},{150,-(90)}}, textString="%name=%phi0", fontName="Arial"),Line(visible=true, points={{-(80),-(40)},{80,-(40)}}),Line(visible=true, points={{80,-(40)},{40,-(80)}}),Line(visible=true, points={{40,-(40)},{0,-(80)}}),Line(visible=true, points={{0,-(40)},{-(40),-(80)}}),Line(visible=true, points={{-(40),-(40)},{-(80),-(80)}}),Line(visible=true, points={{0,-(40)},{0,-(10)}})}));
        Interfaces.Flange_b flange_b "(right) flange fixed in housing" annotation(Placement(visible=true, transformation(origin={0,0}, extent={{10,-(10)},{-(10),10}}, rotation=0), iconTransformation(origin={0,0}, extent={{10,-(10)},{-(10),10}}, rotation=0)));
      equation
        flange_b.phi=phi0;
      end Fixed;

      model TorqueStep "Constant torque, not dependent on speed"
        extends Modelica.Mechanics.Rotational.Interfaces.PartialSpeedDependentTorque;
        parameter Modelica.SIunits.Torque stepTorque=1 "height of torque step (if negative, torque is acting as load)";
        parameter Modelica.SIunits.Torque offsetTorque=0 "offset of torque";
        parameter Modelica.SIunits.Time startTime=0 "output = offset for time < startTime";
        annotation(Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(80),-(60)},{0,-(60)},{0,60},{80,60}}, color={0,0,255}),Text(visible=true, fillColor={0,0,255}, extent={{0,-(60)},{100,-(40)}}, textString="time", fontName="Arial")}), Documentation(info="<HTML>
<p>
Model of a torque step at time .<br>
Positive torque acts accelerating.
</p>
</HTML>"));
      equation
        tau=(-(offsetTorque)) - (if time < startTime then 0 else stepTorque);
      end TorqueStep;

      package Types "Constants and types with choices, especially to build menus"
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Documentation(info="<HTML>
<p>
In this package <b>types</b> and <b>constants</b> are defined that are used
in library Modelica.Blocks. The types have additional annotation choices
definitions that define the menus to be built up in the graphical
user interface when the type is used as parameter in a declaration.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        package Init "Type, constants and menu choices to define initialization of absolute rotational quantities"
          extends Modelica.Icons.Enumeration;
          constant Integer NoInit=1 "no initialization (phi_start, w_start are guess values)";
          constant Integer SteadyState=2 "steady state initialization (der(phi)=der(w)=0)";
          constant Integer InitialState=3 "initialization with phi_start, w_start";
          constant Integer InitialAngle=4 "initialization with phi_start";
          constant Integer InitialSpeed=5 "initialization with w_start";
          constant Integer InitialAcceleration=6 "initialization with a_start";
          constant Integer InitialAngleAcceleration=7 "initialization with phi_start, a_start";
          constant Integer InitialSpeedAcceleration=8 "initialization with w_start, a_start";
          constant Integer InitialAngleSpeedAcceleration=9 "initialization with phi_start, w_start, a_start";
          type Temp "Temporary type of absolute initialization with choices for menus (until enumerations are available)"
            extends Modelica.Icons.TypeInteger(min=1, max=9);
            annotation(Evaluate=true, choices(choice=Modelica.Mechanics.Rotational.Types.Init.NoInit "no initialization (phi_start, w_start are guess values)", choice=Modelica.Mechanics.Rotational.Types.Init.SteadyState "steady state initialization (der(phi)=der(w)=0)", choice=Modelica.Mechanics.Rotational.Types.Init.InitialState "initialization with phi_start, w_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialAngle "initialization with phi_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialSpeed "initialization with w_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialAcceleration "initialization with a_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialAngleAcceleration "initialization with phi_start, a_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialSpeedAcceleration "initialization with w_start, a_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialAngleSpeedAcceleration "initialization with phi_start, w_start, a_start"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          end Temp;

          annotation(Documentation(info="<html>
<p>
Type <b>Init</b> defines initialization of absolute rotational
quantities.
</p>

</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        end Init;

      end Types;

    end Rotational;

  end Mechanics;

  package Math "Mathematical functions (e.g., sin, cos) and operations on matrices (e.g., norm, solve, eig, exp)"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Invisible=true, Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-(59),-(56)},{42,-(9)}}, textString="f(x)", fontName="Arial")}), Documentation(info="<HTML>
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

</html>"), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    function asin "inverse sine (-1 <= u <= 1)"
      extends baseIcon2;
      input Real u;
      output SI.Angle y;
      annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(90),0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-(8)},{90,0}}),Line(visible=true, points={{-(80),-(80)},{-(79.2),-(72.8)},{-(77.6),-(67.5)},{-(73.6),-(59.4)},{-(66.3),-(49.8)},{-(53.5),-(37.3)},{-(30.2),-(19.7)},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-(88),30},{-(16),78}}, textString="asin", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-(40),-(88)},{-(15),-(72)}}, textString="-pi/2", fontName="Arial"),Text(visible=true, extent={{-(38),72},{-(13),88}}, textString=" pi/2", fontName="Arial"),Text(visible=true, extent={{70,5},{90,25}}, textString="+1", fontName="Arial"),Text(visible=true, extent={{-(90),1},{-(70),21}}, textString="-1", fontName="Arial"),Line(visible=true, points={{-(100),0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-(6)},{100,0}}),Line(visible=true, points={{-(80),-(80)},{-(79.2),-(72.8)},{-(77.6),-(67.5)},{-(73.6),-(59.4)},{-(66.3),-(49.8)},{-(53.5),-(37.3)},{-(30.2),-(19.7)},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={160,160,160}, extent={{92,-(22)},{112,-(2)}}, textString="u", fontName="Arial")}), Documentation(info="<html>

</html>"));

      external "C" y=asin(u) ;

    end asin;

    function exp "exponential, base e"
      extends baseIcon2;
      input Real u;
      output Real y;
      annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(90),-(80.3976)},{68,-(80.3976)}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-(80.3976)},{68,-(72.3976)},{68,-(88.3976)},{90,-(80.3976)}}),Line(visible=true, points={{-(80),-(80)},{-(31),-(77.9)},{-(6.03),-(74)},{10.9,-(68.4)},{23.7,-(61)},{34.2,-(51.6)},{43,-(40.3)},{50.3,-(27.8)},{56.7,-(13.5)},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-(86),2},{-(14),50}}, textString="exp", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(100),-(80.3976)},{84,-(80.3976)}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,-(80.3976)},{84,-(74.3976)},{84,-(86.3976)},{100,-(80.3976)}}),Line(visible=true, points={{-(80),-(80)},{-(31),-(77.9)},{-(6.03),-(74)},{10.9,-(68.4)},{23.7,-(61)},{34.2,-(51.6)},{43,-(40.3)},{50.3,-(27.8)},{56.7,-(13.5)},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-(31),72},{-(11),88}}, textString="20", fontName="Arial"),Text(visible=true, extent={{-(92),-(103)},{-(72),-(83)}}, textString="-3", fontName="Arial"),Text(visible=true, extent={{70,-(103)},{90,-(83)}}, textString="3", fontName="Arial"),Text(visible=true, extent={{-(18),-(73)},{2,-(53)}}, textString="1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{96,-(102)},{116,-(82)}}, textString="u", fontName="Arial")}));

      external "C" y=exp(u) ;

    end exp;

    partial function baseIcon2 "Basic icon for mathematical function with y-axis in middle"
      annotation(Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,80},{-(8),80}}, color={192,192,192}),Line(visible=true, points={{0,-(80)},{-(8),-(80)}}, color={192,192,192}),Line(visible=true, points={{0,-(90)},{0,84}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{5,90},{25,110}}, textString="y", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{0,100},{-(6),84},{6,84},{0,100}})}), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{100,100}}),Line(visible=true, points={{0,-(80)},{0,68}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{0,90},{-(8),68},{8,68},{0,90}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(150),110},{150,150}}, textString="%name", fontName="Arial")}));
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
"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, extent={{-(29),-(27)},{3,-(13)}}),Line(visible=true, points={{37,-(58)},{62,-(58)}}),Line(visible=true, points={{36,-(49)},{61,-(49)}}),Line(visible=true, points={{-(78),-(50)},{-(43),-(50)}}),Line(visible=true, points={{-(67),-(55)},{-(55),-(55)}}),Line(visible=true, points={{-(61),-(50)},{-(61),-(20)},{-(29),-(20)}}),Line(visible=true, points={{3,-(20)},{48,-(20)},{48,-(49)}}),Line(visible=true, points={{48,-(58)},{48,-(78)},{-(61),-(78)},{-(61),-(55)}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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
"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model SignalVoltage "Generic voltage source using the input signal as source voltage"
          SI.Current i "Current flowing from pin p to pin n";
          annotation(Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(50),-(50)},{50,50}}),Line(visible=true, points={{-(96),0},{-(50),0}}),Line(visible=true, points={{50,0},{96,0}}),Line(visible=true, points={{-(50),0},{50,0}}),Line(visible=true, points={{-(109),20},{-(84),20}}, color={160,160,160}),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-(94),23},{-(84),20},{-(94),17},{-(94),23}}),Line(visible=true, points={{91,20},{116,20}}, color={160,160,160}),Text(visible=true, lineColor={0,0,255}, fillColor={160,160,160}, extent={{-(109),25},{-(89),45}}, textString="i", fontName="Arial"),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{106,23},{116,20},{106,17},{106,23}}),Text(visible=true, lineColor={0,0,255}, fillColor={160,160,160}, extent={{91,25},{111,45}}, textString="i", fontName="Arial"),Line(visible=true, points={{-(119),-(5)},{-(119),5}}, color={160,160,160}),Line(visible=true, points={{-(124),0},{-(114),0}}, color={160,160,160}),Line(visible=true, points={{116,0},{126,0}}, color={160,160,160})}), Documentation(revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Martin Otter<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(50),-(50)},{50,50}}),Line(visible=true, points={{-(90),0},{-(50),0}}),Line(visible=true, points={{50,0},{90,0}}),Line(visible=true, points={{-(50),0},{50,0}}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(120)},{100,-(80)}}, textString="%name", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{-(120),0},{-(20),50}}, textString="+", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{20,0},{120,50}}, textString="-", fontName="Arial")}));
          Interfaces.PositivePin p annotation(Placement(visible=true, transformation(origin={-(100),0}, extent={{-(10),-(10)},{10,10}}, rotation=0), iconTransformation(origin={-(100),0}, extent={{-(10),-(10)},{10,10}}, rotation=0)));
          Interfaces.NegativePin n annotation(Placement(visible=true, transformation(origin={100,0}, extent={{10,-(10)},{-(10),10}}, rotation=0), iconTransformation(origin={100,0}, extent={{10,-(10)},{-(10),10}}, rotation=0)));
          Modelica.Blocks.Interfaces.RealInput v(redeclare type SignalType= SI.Voltage ) "Voltage between pin p and n (= p.v - n.v) as input signal" annotation(Placement(visible=true, transformation(origin={0,70}, extent={{-(20),-(20)},{20,20}}, rotation=-(90)), iconTransformation(origin={0,70}, extent={{-(20),-(20)},{20,20}}, rotation=-(90))));
        equation
          v=p.v - n.v;
          0=p.i + n.i;
          i=p.i;
        end SignalVoltage;

        model ConstantVoltage "Source for constant voltage"
          parameter SI.Voltage V=1 "Value of constant voltage";
          extends Interfaces.OnePort;
          annotation(Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(90),0},{-(10),0}}),Line(visible=true, points={{-(10),60},{-(10),-(60)}}),Line(visible=true, points={{0,30},{0,-(30)}}),Line(visible=true, points={{0,0},{90,0}})}), Documentation(revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(90),0},{-(10),0}}),Line(visible=true, points={{-(10),60},{-(10),-(60)}}),Line(visible=true, points={{0,30},{0,-(30)}}),Line(visible=true, points={{0,0},{90,0}}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(120)},{100,-(80)}}, textString="%name=%V", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{-(120),0},{-(20),50}}, textString="+", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{20,0},{120,50}}, textString="-", fontName="Arial")}));
        equation
          v=V;
        end ConstantVoltage;

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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        connector Pin "Pin of an electrical component"
          SI.Voltage v "Potential at the pin";
          flow SI.Current i "Current flowing into the pin";
          annotation(defaultComponentName="pin", Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{100,100}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(40),-(40)},{40,40}})}), Documentation(revisions="<html>
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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{100,100}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(40),-(40)},{40,40}}),Text(visible=true, fillColor={0,0,255}, extent={{-(160),50},{40,110}}, textString="%name", fontName="Arial")}));
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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{100,100}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(40),-(40)},{40,40}}),Text(visible=true, fillColor={0,0,255}, extent={{-(40),50},{160,110}}, textString="%name", fontName="Arial")}));
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
</html>"), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(110),20},{-(85),20}}, color={160,160,160}),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-(95),23},{-(85),20},{-(95),17},{-(95),23}}),Line(visible=true, points={{90,20},{115,20}}, color={160,160,160}),Line(visible=true, points={{-(125),0},{-(115),0}}, color={160,160,160}),Line(visible=true, points={{-(120),-(5)},{-(120),5}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{-(110),25},{-(90),45}}, textString="i", fontName="Arial"),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{105,23},{115,20},{105,17},{105,23}}),Line(visible=true, points={{115,0},{125,0}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{90,25},{110,45}}, textString="i", fontName="Arial")}), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          PositivePin p "Positive pin (potential p.v > n.v for positive voltage drop v)" annotation(Placement(visible=true, transformation(origin={-(100),0}, extent={{-(10),-(10)},{10,10}}, rotation=0), iconTransformation(origin={-(100),0}, extent={{-(10),-(10)},{10,10}}, rotation=0)));
          NegativePin n "Negative pin" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{10,-(10)},{-(10),10}}, rotation=0), iconTransformation(origin={100,0}, extent={{10,-(10)},{-(10),10}}, rotation=0)));
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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(60),50},{60,50}}, color={0,0,255}),Line(visible=true, points={{-(40),30},{40,30}}, color={0,0,255}),Line(visible=true, points={{-(20),10},{20,10}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,50}}, color={0,0,255}),Text(visible=true, fillColor={0,0,255}, extent={{-(144),-(60)},{138,0}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(60),50},{60,50}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-(40),30},{40,30}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-(20),10},{20,10}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{0,96},{0,50}}, color={0,0,255}, thickness=0.5),Text(visible=true, extent={{-(24),-(38)},{22,-(6)}}, textString="p.v=0", fontName="Arial")}));
          Interfaces.Pin p annotation(Placement(visible=true, transformation(origin={0,100}, extent={{-(10),10},{10,-(10)}}, rotation=90), iconTransformation(origin={0,100}, extent={{-(10),10},{10,-(10)}}, rotation=90)));
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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(70),-(30)},{70,30}}),Line(visible=true, points={{-(90),0},{-(70),0}}, color={0,0,255}),Line(visible=true, points={{70,0},{90,0}}, color={0,0,255}),Text(visible=true, extent={{-(144),-(100)},{144,-(60)}}, textString="R=%R", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{-(144),40},{144,100}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, extent={{-(70),-(30)},{70,30}}),Line(visible=true, points={{-(96),0},{-(70),0}}, color={0,0,255}),Line(visible=true, points={{70,0},{96,0}}, color={0,0,255})}));
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
</html>"), Diagram(coordinateSystem(extent={{-(100),-(100)},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-(60),-(15)},{-(30),15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{-(30),-(15)},{0,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{0,-(15)},{30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{30,-(15)},{60,15}}, endAngle=180),Line(visible=true, points={{60,0},{96,0}}, color={0,0,255}),Line(visible=true, points={{-(96),0},{-(60),0}}, color={0,0,255})}), Icon(coordinateSystem(extent={{-(100),-(100)},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-(60),-(15)},{-(30),15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{-(30),-(15)},{0,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{0,-(15)},{30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{30,-(15)},{60,15}}, endAngle=180),Line(visible=true, points={{60,0},{90,0}}, color={0,0,255}),Line(visible=true, points={{-(90),0},{-(60),0}}, color={0,0,255}),Text(visible=true, extent={{-(138),-(102)},{144,-(60)}}, textString="L=%L", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{-(146),38},{148,100}}, textString="%name", fontName="Arial")}));
        equation
          L*der(i)=v;
        end Inductor;

      end Basic;

    end Analog;

    package Machines "Library for electric machines"
      extends Modelica.Icons.Library2;
      annotation(version="1.7.2", versionDate="2006-02-10", Settings(NewStateSelection=true, Evaluate=true), preferedView="info", Documentation(info="<HTML>
<p>
This package contains components to model electrical machines:
<ul>
<li>Examples: test examples</li>
<li>BasicMachines: basic machine models</li>
<li>Sensors: sensors, usefull when modelling machines</li>
<li>SpacePhasors: an independent library for using space phasors</li>
<li>Interfaces: Space phasor connector and partial machine models</li>
</ul>
</p>
<p>
<b>Limitations and assumptions:</b>
<ul>
<li>number of phases (of induction machines) is limited to 3, therefore definition as a constant m=3</li>
<li>phase symmetric windings as well as symmetry of the whole machine structure</li>
<li>all values are used in physical units, no scaling to p.u. is done</li>
<li>only basic harmonics (in space) are taken into account</li>
<li>waveform (with respect to time) of voltages and currents is not restricted</li>
<li>constant parameters, i.e. no saturation, no skin effect</li>
<li>no iron losses, eddy currents, friction losses;<br>
    only ohmic losses in stator and rotor winding</li>
</ul>
You may have a look at a short summary of space phasor theory at <a href=\"http://www.haumer.at/refimg/SpacePhasors.pdf\">http://www.haumer.at/refimg/SpacePhasors.pdf</a>
</p>
<p>
<b>Further development:</b>
<ul>
<li>generalizing space phasor theory to m phases with arbitrary spatial angle of the coils</li>
<li>generalizing space phasor theory to arbitrary number of windings and winding factor of the coils</li>
<li>MachineModels: other machine types</li>
<li>effects: saturation, skin-effect, other losses than ohmic, ...</li>
</ul>
</p>
<p>
<dl>
  <dt><b>Main Authors:</b></dt>
  <dd>
  <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
  Technical Consulting & Electrical Engineering<br>
  A-3423 St.Andrae-Woerdern<br>Austria<br>
  email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a>
  </dd>
</dl>
</p>
<p>
Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p>
</HTML>", revisions="<HTML>
  <ul>
  <li> v1.00  2004/09/16 Anton Haumer<br>
       first stable release</li>
  <li> v1.01  2004/09/18 Anton Haumer<br>
       moved common equations from machine models to PartialMachine<br>
       improved MoveToRotational</li>
  <li> v1.02  2004/09/19 Anton Haumer<br>
       new package structure for machine types<br>
       added DC machine models</li>
  <li> v1.03  2004/09/24 Anton Haumer<br>
       added package Sensors<br>
       added DC machine with series excitation<br>
       debugged and improved MoveToRotational</li>
  <li> v1.1   2004/10/01 Anton Haumer<br>
       changed naming and structure<br>
       issued to Modelica Standard Library 2.1</li>
  <li> v1.2   2004/10/27 Anton Haumer<br>
       fixed a bug with support (formerly bearing)</li>
  <li> v1.3   2004/11/05 Anton Haumer<br>
       several improvements in SpacePhasors.Blocks</li>
  <li> v1.3.1 2004/11/06 Anton Haumer<br>
       small changes in Examples.Utilities.VfController</li>
  <li> v1.3.2 2004/11/10 Anton Haumer<br>
       ReluctanceRotor moved to SynchronousMachines</li>
  <li> v1.4   2004/11/11 Anton Haumer<br>
       removed mechanical flange support<br>
       to ease the implementation of a 3D-frame in a future release</li>
  <li> v1.51  2005/02/01 Anton Haumer<br>
       changed parameter polePairs to Integer</li>
  <li> v1.52  2005/10/12 Anton Haumer<br>
       added BasicMachines.SynchronousInductionMachines.SM_ElectricalExcitedDamperCage<br>
       using new basicMachines.Components.ElectricalExcitation<br>
       as well as a new exmaple.</li>
  <li> v1.53  2005/10/14 Anton Haumer<br>
       introduced unsymmetrical DamperCage for Synchronous Machines</li>
  <li> v1.60  2005/11/04 Anton Haumer<br>
       added SpacePhasors.Components.Rotator<br>
       corrected consistent naming of parameters and variables</li>
  <li> v1.6.1 2005/11/22 Anton Haumer<br>
       improved Transformation and Rotation in SpacePhasor.<br>
       introduced Examples.Utilities.TerminalBox</li>
  <li> v1.6.2 2005/10/23 Anton Haumer<br>
       selectable DamperCage for Synchronous Machines</li>
  <li> v1.6.3 2005/11/25 Anton Haumer<br>
       easier parametrisation of AsynchronousInductionMachines.AIM_SlipRing model</li>
  <li> v1.7.0 2005/12/15 Anton Haumer<br>
       back-changed the naming to ensure backward compatibility</li>
  <li> v1.7.1 2006/02/06 Anton Haumer<br>
       changed some naming of synchronous machines, not affecting existing models</li>
  </ul>
</HTML>"), Icon(coordinateSystem(extent={{-(100),-(100)},{100,100}}), graphics={Rectangle(extent={{-(60),60},{60,-(60)}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={0,127,255}),Rectangle(extent={{-(60),60},{-(80),-(60)}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={128,128,128}),Rectangle(extent={{60,10},{80,-(10)}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={128,128,128}),Rectangle(extent={{-(60),70},{20,50}}, fillPattern=FillPattern.Solid, lineColor={128,128,128}, fillColor={128,128,128}),Polygon(points={{-(70),-(90)},{-(60),-(90)},{-(30),-(20)},{20,-(20)},{50,-(90)},{60,-(90)},{60,-(100)},{-(70),-(100)},{-(70),-(90)}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Solid)}));
      package Examples "Test examples"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains test examples of electric machines,<br>
and a package utilities with components used for the examples.
</p>

</HTML>", revisions="<HTML>
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
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>

  <ul>
  <li> v1.00 2004/09/16 Anton Haumer</li>
  <li> v1.01 2004/09/18 Anton Haumer<br>
       adapted to improved MoveToRotational</li>
  <li> v1.02 2004/09/19 Anton Haumer<br>
       added examples for DC machines</li>
  <li> v1.03 2004/09/24 Anton Haumer<br>
       usage of Sensors.CurrentRMSsensor<br>
       added example for DC machine with series excitation</li>
  <li> v1.1  2004/10/01 Anton Haumer<br>
       changed naming and structure<br>
       issued to Modelica Standard Library 2.1</li>
  <li> v1.3.1 2004/11/06 Anton Haumer<br>
       small changes in Utilities.VfController</li>
  <li> v1.52 2005/10/12 Anton Haumer<br>
       new example for electrical excited synchronous induction machine</li>
  <li> v1.6.1 2004/11/22 Anton Haumer<br>
       introduced Utilities.TerminalBox</li>
  </ul>
</HTML>"), Icon(coordinateSystem(extent={{-(100),-(100)},{100,100}}), graphics={Ellipse(extent={{-(80),44},{60,-(96)}}, lineColor={128,128,128}),Polygon(points={{-(40),36},{-(40),-(88)},{60,-(26)},{-(40),36}}, fillPattern=FillPattern.Solid, lineColor={128,128,128}, fillColor={128,128,128})}));
        model DCEE_start "Test example 9: DC with electrical ecxitation starting with voltage ramp"
          extends Modelica.Icons.Example;
          parameter Modelica.SIunits.Voltage Va=100 "actual armature voltage";
          parameter Modelica.SIunits.Time tStart=0.2 "armature voltage ramp";
          parameter Modelica.SIunits.Time tRamp=0.8 "armature voltage ramp";
          parameter Modelica.SIunits.Voltage Ve=100 "actual excitation voltage";
          parameter Modelica.SIunits.Torque T_Load=63.66 "nominal load torque";
          parameter Modelica.SIunits.Time tStep=1.5 "time of load torque step";
          parameter Modelica.SIunits.Inertia J_Load=0.15 "load's moment of inertia";
          annotation(Diagram(coordinateSystem(extent={{-(100.0),-(100.0)},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), experiment(StopTime=2, Interval=0.001), experimentSetupOutput(doublePrecision=true), Documentation(info="<HTML>
<p>
<b>9th Test example: Electrically separate excited DC Machine started with an armature voltage ramp</b><br>
A voltage ramp is applied to the armature, causing the DC machine to start,
and accelerating inertias.<br>At time tStep a load step is applied.<br>
Simulate for 2 seconds and plot (versus time):
<ul>
<li>DCEE1.ia: armature current</li>
<li>DCEE1.rpm_mechanical: motor's speed</li>
<li>DCEE1.tau_electrical: motor's torque</li>
<li>DCEE1.ie: excitation current</li>
</ul>
Default machine parameters of model <i>DC_ElectricalExcited</i> are used.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-(100.0),-(100.0)},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Modelica.Blocks.Sources.Ramp Ramp1(duration=tRamp, height=Va, startTime=tStart) annotation(Placement(visible=true, transformation(origin={-(70.0),70.0}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=0)));
          Modelica.Mechanics.Rotational.Inertia LoadInertia(J=J_Load) annotation(Placement(visible=true, transformation(origin={50.0,-(40.0)}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=0)));
          Modelica.Mechanics.Rotational.TorqueStep TorqueStep1(startTime=tStep, stepTorque=-(T_Load)) annotation(Placement(visible=true, transformation(origin={80.0,-(40.0)}, extent={{10.0,-(10.0)},{-(10.0),10.0}}, rotation=0)));
          Modelica.Electrical.Analog.Sources.ConstantVoltage ConstantVoltage1(V=Ve) annotation(Placement(visible=true, transformation(origin={-(40.0),-(40.0)}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=-(450))));
          Modelica.Electrical.Machines.BasicMachines.DCMachines.DC_ElectricalExcited DCEE1 annotation(Placement(visible=true, transformation(origin={-(10.0),-(40.0)}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=0)));
          Modelica.Electrical.Analog.Sources.SignalVoltage SignalVoltage1 annotation(Placement(visible=true, transformation(origin={-(10.0),40.0}, extent={{10.0,-(10.0)},{-(10.0),10.0}}, rotation=-(720))));
          Modelica.Electrical.Analog.Basic.Ground Grounda annotation(Placement(visible=true, transformation(origin={-(70.0),40.0}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=-(90))));
          Modelica.Electrical.Analog.Basic.Ground Grounde annotation(Placement(visible=true, transformation(origin={-(70.0),-(50.0)}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=-(90))));
        equation
          connect(LoadInertia.flange_b,TorqueStep1.flange) annotation(Line(visible=true, points={{60.0,-(40.0)},{70.0,-(40.0)}}));
          connect(DCEE1.flange_a,LoadInertia.flange_a) annotation(Line(visible=true, points={{0.0,-(40.0)},{40.0,-(40.0)}}));
          connect(DCEE1.pin_ep,ConstantVoltage1.p) annotation(Line(visible=true, points={{-(20.0),-(34.0)},{-(30.0),-(34.0)},{-(30.0),-(30.0)},{-(40.0),-(30.0)}}, color={0,0,255}));
          connect(DCEE1.pin_en,ConstantVoltage1.n) annotation(Line(visible=true, points={{-(20.0),-(46.0)},{-(30.0),-(46.0)},{-(30.0),-(50.0)},{-(40.0),-(50.0)}}, color={0,0,255}));
          connect(Ramp1.y,SignalVoltage1.v) annotation(Line(visible=true, points={{-(59.0),70.0},{-(10.0),70.0},{-(10.0),47.0}}, color={0,0,255}));
          connect(SignalVoltage1.p,DCEE1.pin_ap) annotation(Line(visible=true, points={{0.0,40.0},{0.0,-(20.0)},{-(4.0),-(20.0)},{-(4.0),-(30.0)}}, color={0,0,255}));
          connect(SignalVoltage1.n,Grounda.p) annotation(Line(visible=true, points={{-(20.0),40.0},{-(60.0),40.0}}, color={0,0,255}));
          connect(DCEE1.pin_an,Grounda.p) annotation(Line(visible=true, points={{-(16.0),-(30.0)},{-(16.0),-(20.0)},{-(20.0),-(20.0)},{-(20.0),40.0},{-(60.0),40.0}}, color={0,0,255}));
          connect(ConstantVoltage1.n,Grounde.p) annotation(Line(visible=true, points={{-(40.0),-(50.0)},{-(60.0),-(50.0)}}, color={0,0,255}));
        end DCEE_start;

      end Examples;

      package BasicMachines "Basic machine models"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains components for modeling electrical machines, specially threephase induction machines, based on space phasor theory:
<ul>
<li>package AsynchronousInductionMachines: models of three phase asynchronous induction machines</li>
<li>package SynchronousInductionMachines: models of three phase synchronous induction machines</li>
<li>package DCMachines: models of DC machines with different excitation</li>
<li>package Components: components for modeling machines</li>
</ul>
The induction machine models use package SpacePhasors.
</p>

</HTML>", revisions="<HTML>
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
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>

  <ul>
  <li> v1.00  2004/09/16 Anton Haumer</li>
  <li> v1.01  2004/09/18 Anton Haumer<br>
       moved common equations from machine models to PartialMachine</li>
  <li> v1.02  2004/09/19 Anton Haumer<br>
       new package structure for machine types<br>
       added DCMachine models</li>
  <li> v1.03  2004/09/24 Anton Haumer<br>
       added DC machine with series excitation</li>
  <li> v1.1   2004/10/01 Anton Haumer<br>
       changed naming and structure<br>
       issued to Modelica Standard Library 2.1</li>
  <li> v1.2   2004/10/27 Anton Haumer<br>
       fixed a bug with support (formerly bearing)</li>
  <li> v1.3.2 2004/11/10 Anton Haumer<br>
       ReluctanceRotor moved to SynchronousMachines</li>
  <li> v1.4   2004/11/11 Anton Haumer<br>
       removed mechanical flange support<br>
       to ease the implementation of a 3D-frame in a future release</li>
  <li> v1.53  2005/10/14 Anton Haumer<br>
       introduced unsymmetrical DamperCage for Synchronous Machines</li>
  <li> v1.6.2 2005/10/23 Anton Haumer<br>
       selectable DamperCage for Synchronous Machines</li>
  <li> v1.6.3 2005/11/25 Anton Haumer<br>
       easier parametrisation of AsynchronousInductionMachines.AIM_SlipRing model</li>
  <li> v1.7.1 2006/02/06 Anton Haumer<br>
       changed some naming of synchronous machines, not affecting existing models</li>
  </ul>
<HTML>"), Icon(coordinateSystem(extent={{-(100),-(100)},{100,100}}), graphics={Rectangle(visible=true, fillColor={0,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{-(60),-(60)},{60,60}}),Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.HorizontalCylinder, extent={{-(80),-(60)},{-(60),60}}),Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.HorizontalCylinder, extent={{60,-(10)},{80,10}}),Rectangle(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{-(59.66),50},{20.34,70}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-(70),-(90)},{-(60),-(90)},{-(30),-(20)},{20,-(20)},{50,-(90)},{60,-(90)},{60,-(100)},{-(70),-(100)},{-(70),-(90)}})}));
        package DCMachines "Models of DC machines"
          extends Modelica.Icons.Library;
          annotation(Documentation(info="<HTML>
<p>
This package contains models of DC machines:
<ul>
<li>DC_PermanentMagnet: DC machine with permanent magnet excitation</li>
<li>DC_ElectricalExcited: DC machine with electrical shunt or separate excitation</li>
<li>DC_SeriesExcited: DC machine with series excitation</li>
</ul>
</p>

</HTML>
", revisions="<HTML>
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
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>

  <ul>
  <li> v1.02 2004/09/19 Anton Haumer</li>
  <li> v1.03 2004/09/24 Anton Haumer<br>
       added DC machine with series excitation</li>
  <li> v1.1  2004/10/01 Anton Haumer<br>
       changed naming and structure<br>
       issued to Modelica Standard Library 2.1</li>
  <li> v1.2  2004/10/27 Anton Haumer<br>
       fixed a bug with support (formerly bearing)</li>
  <li> v1.4   2004/11/11 Anton Haumer<br>
       removed mechanical flange support<br>
       to ease the implementation of a 3D-frame in a future release</li>
  </ul>
</HTML>"));
          model DC_ElectricalExcited "Electrical shunt/separate excited linear DC machine"
            extends Machines.Interfaces.PartialBasicDCMachine;
            parameter Modelica.SIunits.Voltage VaNominal=100 "|Nominal parameters|nominal armature voltage";
            parameter Modelica.SIunits.Current IaNominal=100 "|Nominal parameters|nominal armature current";
            parameter Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm rpmNominal=1425 "|Nominal parameters|nominal speed";
            parameter Modelica.SIunits.Resistance Ra=0.05 "|Nominal resistances and inductances|warm armature resistance";
            parameter Modelica.SIunits.Inductance La=0.0015 "|Nominal resistances and inductances|armature inductance";
            parameter Modelica.SIunits.Current IeNominal=1 "|Excitation|nominal excitation current";
            parameter Modelica.SIunits.Resistance Re=100 "|Excitation|warm field excitation resistance";
            parameter Modelica.SIunits.Inductance Le=1 "|Excitation|total field excitation inductance";
            output Modelica.SIunits.Voltage ve=pin_ep.v - pin_en.v "Field excitation voltage";
            output Modelica.SIunits.Current ie=pin_ep.i "Field excitation current";
            Modelica.Electrical.Analog.Basic.Resistor ra(final R=Ra) annotation(Placement(visible=true, transformation(origin={50.0,60.0}, extent={{10.0,-(10.0)},{-(10.0),10.0}}, rotation=0)));
            Modelica.Electrical.Analog.Basic.Inductor la(final L=La) annotation(Placement(visible=true, transformation(origin={20.0,60.0}, extent={{10.0,-(10.0)},{-(10.0),10.0}}, rotation=0)));
            Modelica.Electrical.Analog.Basic.Resistor re(final R=Re) annotation(Placement(visible=true, transformation(origin={-(50.0),-(40.0)}, extent={{10.0,10.0},{-(10.0),-(10.0)}}, rotation=-(180))));
            Modelica.Electrical.Analog.Interfaces.PositivePin pin_ep annotation(Placement(visible=true, transformation(origin={-(100.0),60.0}, extent={{-(10.0),10.0},{10.0,-(10.0)}}, rotation=0), iconTransformation(origin={-(100.0),60.0}, extent={{-(10.0),10.0},{10.0,-(10.0)}}, rotation=0)));
            Modelica.Electrical.Analog.Interfaces.NegativePin pin_en annotation(Placement(visible=true, transformation(origin={-(100.0),-(60.0)}, extent={{10.0,10.0},{-(10.0),-(10.0)}}, rotation=0), iconTransformation(origin={-(100.0),-(60.0)}, extent={{10.0,10.0},{-(10.0),-(10.0)}}, rotation=0)));
            annotation(defaultComponentName="DCEE", Diagram(coordinateSystem(extent={{-(100.0),-(100.0)},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-(100.0),-(100.0)},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(130.0),-(4.0)},{-(129.0),1.0},{-(125.0),5.0},{-(120.0),6.0},{-(115.0),5.0},{-(111.0),1.0},{-(110.0),-(4.0)}}, color={0,0,255}),Line(visible=true, points={{-(110.0),-(4.0)},{-(109.0),1.0},{-(105.0),5.0},{-(100.0),6.0},{-(95.0),5.0},{-(91.0),1.0},{-(90.0),-(4.0)}}, color={0,0,255}),Line(visible=true, points={{-(90.0),-(4.0)},{-(89.0),1.0},{-(85.0),5.0},{-(80.0),6.0},{-(75.0),5.0},{-(71.0),1.0},{-(70.0),-(4.0)}}, color={0,0,255}),Line(visible=true, points={{-(100.0),-(50.0)},{-(100.0),-(20.0)},{-(70.0),-(20.0)},{-(70.0),-(2.0)}}, color={0,0,255}),Line(visible=true, points={{-(100.0),50.0},{-(100.0),20.0},{-(130.0),20.0},{-(130.0),-(4.0)}}, color={0,0,255})}), Documentation(info="<HTML>
<p>
<b>Model of a DC Machine with Electrical shunt or separate excitation.</b><br>
Armature resistance and inductance are modeled directly after the armature pins, then using a <i>AirGapDC</i> model.<br>
Only losses in armature and excitation resistance are taken into account. No saturation is modelled.<br>
Shunt or separate excitation is defined by the user's external circuit.
</p>
<p>
<b>Default values for machine's parameters (a realistic example) are:</b><br>
<table>
<tr>
<td>stator's moment of inertia</td>
<td>0.29</td><td>kg.m2</td>
</tr>
<tr>
<td>rotor's moment of inertia</td>
<td>0.15</td><td>kg.m2</td>
</tr>
<tr>
<td>nominal armature voltage</td>
<td>100</td><td>V</td>
</tr>
<tr>
<td>nominal armature current</td>
<td>100</td><td>A</td>
</tr>
<tr>
<td>nominal torque</td>
<td>63.66</td><td>Nm</td>
</tr>
<tr>
<td>nominal speed</td>
<td>1425</td><td>rpm</td>
</tr>
<tr>
<td>nominal mechanical output</td>
<td>9.5</td><td>kW</td>
</tr>
<tr>
<td>efficiency</td>
<td>95.0</td><td>% only armature</td>
</tr>
<tr>
<td>efficiency</td>
<td>94.06</td><td>% including excitation</td>
</tr>
<tr>
<td>armature resistance</td>
<td>0.05</td><td>Ohm in warm condition</td>
</tr>
<tr>
<td>aramture inductance</td>
<td>0.0015</td><td>H</td>
</tr>
<tr>
<td>nominal excitation voltage</td>
<td>100</td><td>V</td>
</tr>
<tr>
<td>nominal excitation current</td>
<td>1</td><td>A</td>
</tr>
<tr>
<td>excitation resistance</td>
<td>100</td><td>Ohm in warm condition</td>
</tr>
<tr>
<td>excitation inductance</td>
<td>1</td><td>H</td>
</tr>
</table>
Armature resistance resp. inductance include resistance resp. inductance of commutating pole winding and
compensation windig, if present.<br>
Armature current does not cover excitation current of a shunt excitation; in this case total current drawn from the grid = armature current + excitation current.
</p>
</HTML>"));
            Modelica.Electrical.Machines.BasicMachines.Components.AirGapDC airGapDC(final Le=Le, final TurnsRatio=TurnsRatio) annotation(Placement(visible=true, transformation(origin={0.0,0.0}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=-(90))));
          protected
            parameter Real TurnsRatio=(VaNominal - Ra*IaNominal)/(Modelica.SIunits.Conversions.from_rpm(rpmNominal)*Le*IeNominal) "Ratio of armature turns over number of turns of the excitation winding";
          equation
            connect(re.p,pin_ep) annotation(Line(visible=true, points={{-(60.0),-(40.0)},{-(80.0),-(40.0)},{-(80.0),60.0},{-(100.0),60.0}}, color={0,0,255}));
            connect(pin_ap,ra.p) annotation(Line(visible=true, points={{60.0,100.0},{60.0,60.0}}, color={0,0,255}));
            connect(la.p,ra.n) annotation(Line(visible=true, points={{30.0,60.0},{40.0,60.0}}, color={0,0,255}));
            connect(la.n,airGapDC.pin_ap) annotation(Line(visible=true, points={{10.0,60.0},{10.0,10.0}}, color={0,0,255}));
            connect(airGapDC.pin_an,pin_an) annotation(Line(visible=true, points={{-(10.0),10.0},{-(10.0),60.0},{-(60.0),60.0},{-(60.0),100.0}}, color={0,0,255}));
            connect(re.n,airGapDC.pin_ep) annotation(Line(visible=true, points={{-(40.0),-(40.0)},{10.0,-(40.0)},{10.0,-(10.0)}}, color={0,0,255}));
            connect(airGapDC.pin_en,pin_en) annotation(Line(visible=true, points={{-(10.0),-(10.0)},{-(10.0),-(60.0)},{-(100.0),-(60.0)}}, color={0,0,255}));
            connect(airGapDC.flange_a,inertiaRotor.flange_a) annotation(Line(visible=true, points={{10.0,0.0},{26.0,0.0},{26.0,-(0.0)},{60.0,0.0}}));
            connect(airGapDC.support,internalSupport) annotation(Line(visible=true, points={{-(10.0),0.0},{-(90.0),-(0.0)},{-(90.0),-(100.0)},{20.0,-(100.0)}}));
            assert(VaNominal > Ra*IaNominal, "VaNominal has to be > (Ra+Re)*IaNominal");
          end DC_ElectricalExcited;

        end DCMachines;

        package Components "Machine components like AirGaps"
          extends Modelica.Icons.Library;
          annotation(Documentation(info="<HTML>
<p>
This package contains components for modeling electrical machines, specially threephase induction machines, based on space phasor theory:
<ul>
<li>AirGapS: model of an airgap whose coordinate system is fixed to the stator</li>
<li>AirGapR: model of an airgap whose coordinate system is fixed to the rotor</li>
<li>SquirrelCage: model of a squirrel cage rotor</li>
<li>PermanentMagnet: model of a permanent magnet excitation</li>
<li>ElectricalExcitation: model of an electrical excitation (converting excitation to space phasor)</li>
<li>AirGapDC: model of an airgap of DC machines</li>
</ul>
These models use package SpacePhasors.
</p>

</HTML>", revisions="<HTML>
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
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>

  <ul>
  <li> v1.00 2004/09/16 Anton Haumer</li>
  <li> v1.02 2004/09/19 Anton Haumer<br>
       added AirGapDC models</li>
  <li> v1.2  2004/10/27 Anton Haumer<br>
       fixed a bug with support (formerly bearing)</li>
  <li> v1.52 2005/10/12 Anton Haumer<br>
       added electrical excitation</li>
  <li> v1.53 Beta 2005/10/14 Anton Haumer<br>
       introduced unsymmetrical DamperCage for Synchronous Machines</li>
  </ul>
</HTML>"));
          model AirGapDC "Linear airgap model of a DC machine"
            parameter Modelica.SIunits.Inductance Le "Excitation inductance";
            parameter Real TurnsRatio "Ratio of armature turns over number of turns of the excitation winding";
            Modelica.SIunits.AngularVelocity w "Angluar velocity";
            Modelica.SIunits.Voltage vei "Voltage drop across field excitation inductance";
            Modelica.SIunits.Current ie "Excitation current";
            Modelica.SIunits.MagneticFlux psi_e "Excitation flux";
            Modelica.SIunits.Voltage vai "Induced armature voltage";
            Modelica.SIunits.Current ia "Armature current";
            output Modelica.SIunits.Torque tau_electrical;
            Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation(Placement(transformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true), iconTransformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true)));
            Modelica.Mechanics.Rotational.Interfaces.Flange_a support "support at which the reaction torque is acting" annotation(Placement(transformation(x=0.0, y=-(100.0), scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-(100.0), scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
            Modelica.Electrical.Analog.Interfaces.PositivePin pin_ap annotation(Placement(transformation(x=-(100.0), y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true), iconTransformation(x=-(100.0), y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true)));
            Modelica.Electrical.Analog.Interfaces.PositivePin pin_ep annotation(Placement(transformation(x=100.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true), iconTransformation(x=100.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true)));
            Modelica.Electrical.Analog.Interfaces.NegativePin pin_an annotation(Placement(transformation(x=-(100.0), y=-(100.0), scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-(100.0), y=-(100.0), scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
            Modelica.Electrical.Analog.Interfaces.NegativePin pin_en annotation(Placement(transformation(x=100.0, y=-(100.0), scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-(100.0), scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
            annotation(Diagram, Icon(coordinateSystem(extent={{-(100),-(100)},{100,100}}), graphics={Ellipse(extent={{-(90),90},{90,-(92)}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Ellipse(extent={{-(80),80},{80,-(80)}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Rectangle(extent={{-(10),90},{10,-(80)}}, lineColor={0,0,0}, fillPattern=FillPattern.VerticalCylinder, fillColor={128,128,128}),Text(lineColor={0,0,255}, extent={{0,40},{80,-(40)}}, fillColor={0,0,0}, textString="E"),Text(lineColor={0,0,255}, extent={{-(150),-(100)},{150,-(160)}}, fillColor={0,0,255}, textString="%name"),Text(lineColor={0,0,255}, extent={{-(80),40},{0,-(40)}}, fillColor={0,0,0}, textString="A")}), Documentation(info="<HTML>
<p>
Linear model of the airgap (without saturation effects) of a DC machine, using only equations.<br>
Induced excitation voltage is calculated from der(flux), where flux is defined by excitation inductance times excitation current.<br>
Induced armature voltage is calculated from flux times angular velocity.
</p>
</HTML>"));
          equation
            vai=pin_ap.v - pin_an.v;
            ia=+(pin_ap.i);
            ia=-(pin_an.i);
            vei=pin_ep.v - pin_en.v;
            ie=+(pin_ep.i);
            ie=-(pin_en.i);
            psi_e=Le*ie;
            vei=der(psi_e);
            w=der(flange_a.phi) - der(support.phi);
            vai=TurnsRatio*psi_e*w;
            tau_electrical=TurnsRatio*psi_e*ia;
            flange_a.tau=-(tau_electrical);
            support.tau=tau_electrical;
          end AirGapDC;

        end Components;

      end BasicMachines;

      package Interfaces "SpacePhasor connector and PartialMachines"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains the space phasor connector and partial models for machine models.
</p>

</HTML>", revisions="<HTML>
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
  <dt><b>Copyright:</b></dt>
  <dd>Copyright &copy; 1998-2006, Modelica Association and Anton Haumer.<br>
  <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
  under the terms of the <b>Modelica license</b>, see the license conditions
  and the accompanying <b>disclaimer</b> in the documentation of package
  Modelica in file \"Modelica/package.mo\".</i></dd>
</p>
</dl>

  <ul>
  <li> v1.00 2004/09/16 Anton Haumer</li>
  <li> v1.01 2004/09/18 Anton Haumer<br>
       moved common equations from machine models to PartialMachine</li>
  <li> v1.02 2004/09/19 Anton Haumer<br>
       added PartialDCMachine</li>
  <li> v1.2  2004/10/27 Anton Haumer<br>
       fixed a bug with support (formerly bearing)</li>
  <li> v1.4   2004/11/11 Anton Haumer<br>
       removed mechanical flange support<br>
       to ease the implementation of a 3D-frame in a future release</li>
  <li> v1.51 Beta 2005/02/01 Anton Haumer<br>
       changed parameter polePairs to Integer</li>
  </ul>
</HTML>"), Icon(coordinateSystem(extent={{-(100),-(100)},{100,100}}), graphics={Polygon(points={{-(70),-(30)},{-(10),30},{50,-(30)},{-(10),-(90)},{-(70),-(30)}}, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid)}));
        partial model PartialBasicMachine "Partial machine model"
          parameter Modelica.SIunits.Inertia J_Rotor "rotor's moment of inertia";
          output Modelica.SIunits.Angle phi_mechanical=flange_a.phi "mechanical angle of rotor against stator";
          output Modelica.SIunits.AngularVelocity w_mechanical=der(phi_mechanical) "mechanical angular velocity of rotor against stator";
          output Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm rpm_mechanical=Modelica.SIunits.Conversions.to_rpm(w_mechanical) "mechanical speed of rotor against stator [rpm]";
          output Modelica.SIunits.Torque tau_electrical=inertiaRotor.flange_a.tau "electromagnetic torque";
          output Modelica.SIunits.Torque tau_shaft=-(flange_a.tau) "shaft torque";
          Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation(Placement(visible=true, transformation(origin={100.0,0.0}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=0), iconTransformation(origin={100.0,0.0}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=0)));
          Modelica.Mechanics.Rotational.Inertia inertiaRotor(final J=J_Rotor) annotation(Placement(visible=true, transformation(origin={70.0,0.0}, extent={{10.0,10.0},{-(10.0),-(10.0)}}, rotation=180)));
          Modelica.Mechanics.Rotational.Fixed fixedHousing(final phi0=0) annotation(Placement(visible=true, transformation(origin={40.0,-(100.0)}, extent={{-(10.0),-(10.0)},{10.0,10.0}}, rotation=0)));
        protected
          Modelica.Mechanics.Rotational.Interfaces.Flange_b internalSupport annotation(Placement(visible=true, transformation(origin={20.0,-(100.0)}, extent={{-(1.0),-(1.0)},{1.0,1.0}}, rotation=0)));
          annotation(Icon(coordinateSystem(extent={{-(100),-(100)},{100,100}}), graphics={Rectangle(extent={{-(40),60},{80,-(60)}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={0,127,255}),Rectangle(extent={{-(40),60},{-(60),-(60)}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={128,128,128}),Rectangle(extent={{80,10},{100,-(10)}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={128,128,128}),Rectangle(extent={{-(40),70},{40,50}}, fillPattern=FillPattern.Solid, lineColor={128,128,128}, fillColor={128,128,128}),Polygon(points={{-(50),-(90)},{-(40),-(90)},{-(10),-(20)},{40,-(20)},{70,-(90)},{80,-(90)},{80,-(100)},{-(50),-(100)},{-(50),-(90)}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-(150),-(120)},{150,-(180)}}, fillColor={0,0,255}, textString="%name")}), Documentation(info="<HTML>
<p>
Base partial model DC machines:
<ul>
<li>main parts of the icon</li>
<li>mechanical flange</li>
<li>mechanical support</li>
</ul>
</p>
<p>
The machine's stator is implicitely fixed.
</p>
</HTML>"), Diagram);
        equation
          connect(internalSupport,fixedHousing.flange_b) annotation(Line(visible=true, points={{20.0,-(100.0)},{40.0,-(100.0)}}));
          connect(inertiaRotor.flange_b,flange_a) annotation(Line(visible=true, points={{80.0,0.0},{92.0,0.0},{92.0,0.0},{100.0,0.0}}));
        end PartialBasicMachine;

        partial model PartialBasicDCMachine "Partial model for DC machine"
          extends PartialBasicMachine(J_Rotor=0.15);
          output Modelica.SIunits.Voltage va=pin_ap.v - pin_an.v "armature voltage";
          output Modelica.SIunits.Current ia=pin_ap.i "armature current";
          annotation(Documentation(info="<HTML>
<p>
Partial model for DC machine models, containing:
<ul>
<li>main parts of the icon</li>
<li>armature pins</li>
<li>mechanical connectors</li>
</ul>
</p>
</HTML>"), Diagram, Icon(coordinateSystem(extent={{-(100),-(100)},{100,100}}), graphics={Line(points={{-(50),100},{-(20),100},{-(20),70}}, color={0,0,255}),Line(points={{50,100},{20,100},{20,70}}, color={0,0,255})}));
          Modelica.Electrical.Analog.Interfaces.PositivePin pin_ap annotation(Placement(visible=true, transformation(origin={60.0,100.0}, extent={{-(10.0),10.0},{10.0,-(10.0)}}, rotation=0), iconTransformation(origin={60.0,100.0}, extent={{-(10.0),10.0},{10.0,-(10.0)}}, rotation=0)));
          Modelica.Electrical.Analog.Interfaces.NegativePin pin_an annotation(Placement(visible=true, transformation(origin={-(60.0),100.0}, extent={{-(10.0),10.0},{10.0,-(10.0)}}, rotation=0), iconTransformation(origin={-(60.0),100.0}, extent={{-(10.0),10.0},{10.0,-(10.0)}}, rotation=0)));
        end PartialBasicDCMachine;

      end Interfaces;

    end Machines;

  end Electrical;

  package Blocks "Library for basic input/output control blocks (continuous, discrete, logical, table blocks)"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, extent={{-(32),-(35)},{16,-(6)}}),Rectangle(visible=true, extent={{-(32),-(85)},{16,-(56)}}),Line(visible=true, points={{16,-(20)},{49,-(20)},{49,-(71)},{16,-(71)}}),Line(visible=true, points={{-(32),-(72)},{-(64),-(72)},{-(64),-(21)},{-(32),-(21)}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{16,-(71)},{29,-(67)},{29,-(74)},{16,-(71)}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-(32),-(21)},{-(46),-(17)},{-(46),-(25)},{-(32),-(21)}})}), Documentation(info="<html>
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
</html>"), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    package Types "Constants and types with choices, especially to build menus"
      extends Modelica.Icons.Library;
      annotation(preferedView="info", Documentation(info="<HTML>
<p>
In this package <b>types</b> and <b>constants</b> are defined that are used
in library Modelica.Blocks. The types have additional annotation choices
definitions that define the menus to be built up in the graphical
user interface when the type is used as parameter in a declaration.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      package StateSelection "Type, constants and menu choices to define state selection of variables"
        annotation(Documentation(info="<html>

</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        extends Modelica.Icons.Enumeration;
        constant Integer Never=1 "Never (never use as state)";
        constant Integer Avoid=2 "Avoid (avoid to use as state)";
        constant Integer Default=3 "Default (default behaviour)";
        constant Integer Prefer=4 "Prefer (use as state if possible)";
        constant Integer Always=5 "Always (always use as state)";
        type Temp "Temporary type of state selection with choices for menus (until enumerations are available)"
          extends Modelica.Icons.TypeInteger(min=1, max=5);
          annotation(Evaluate=true, choices(choice=Modelica.Blocks.Types.StateSelection.Never "Never (never use as state)", choice=Modelica.Blocks.Types.StateSelection.Avoid "Avoid (avoid to use as state)", choice=Modelica.Blocks.Types.StateSelection.Default "Default (default behaviour)", choice=Modelica.Blocks.Types.StateSelection.Prefer "Prefer (use as state if possible)", choice=Modelica.Blocks.Types.StateSelection.Always "Always (always use as state)"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        end Temp;

      end StateSelection;

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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{0,0},{430,-(442)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      block Ramp "Generate ramp signal"
        parameter Real height=1 "Height of ramps";
        parameter Real duration(min=Modelica.Constants.small)=2 "Durations of ramp";
        parameter Real offset=0 "Offset of output signal";
        parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
        extends Interfaces.SO;
        annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(80),68},{-(80),-(80)}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-(80),90},{-(88),68},{-(72),68},{-(80),90}}),Line(visible=true, points={{-(90),-(70)},{82,-(70)}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-(70)},{68,-(62)},{68,-(78)},{90,-(70)}}),Line(visible=true, points={{-(80),-(70)},{-(40),-(70)},{31,38}}),Text(visible=true, extent={{-(150),-(150)},{150,-(110)}}, textString="duration=%duration", fontName="Arial"),Line(visible=true, points={{31,38},{86,38}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-(80),90},{-(88),68},{-(72),68},{-(80),90}}),Line(visible=true, points={{-(80),68},{-(80),-(80)}}, color={192,192,192}),Line(visible=true, points={{-(80),-(20)},{-(20),-(20)},{50,50}}, thickness=0.5),Line(visible=true, points={{-(90),-(70)},{82,-(70)}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-(70)},{68,-(62)},{68,-(78)},{90,-(70)}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-(40),-(20)},{-(42),-(30)},{-(37),-(30)},{-(40),-(20)}}),Line(visible=true, points={{-(40),-(20)},{-(40),-(70)}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-(40),-(70)},{-(43),-(60)},{-(38),-(60)},{-(40),-(70)},{-(40),-(70)}}),Text(visible=true, fillColor={160,160,160}, extent={{-(80),-(49)},{-(41),-(33)}}, textString="offset", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-(40),-(88)},{6,-(70)}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-(66),72},{-(25),92}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-(100)},{94,-(80)}}, textString="time", fontName="Arial"),Line(visible=true, points={{-(20),-(20)},{-(20),-(70)}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-(19),-(20)},{50,-(20)}}, color={192,192,192}),Line(visible=true, points={{50,50},{101,50}}, thickness=0.5),Line(visible=true, points={{50,50},{50,-(20)}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,-(20)},{42,-(18)},{42,-(22)},{50,-(20)}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-(20),-(20)},{-(11),-(18)},{-(11),-(22)},{-(20),-(20)}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,50},{48,40},{53,40},{50,50}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,-(20)},{47,-(10)},{52,-(10)},{50,-(20)},{50,-(20)}}),Text(visible=true, fillColor={160,160,160}, extent={{53,7},{82,25}}, textString="height", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{0,-(37)},{35,-(17)}}, textString="duration", fontName="Arial")}), Documentation(info="<html>

</html>"));
      equation
        y=offset + (if time < startTime then 0 else if time < startTime + duration then (time - startTime)*height/duration else height);
      end Ramp;

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
"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{0,0},{733,-(491)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      connector RealSignal "Real port (both input/output possible)"
        replaceable type SignalType= Real annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        extends SignalType;
        annotation(Documentation(info="<html>
<p>
Connector with one signal of type Real (no icon, no input/output prefix).
</p>
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end RealSignal;

      connector RealInput= input RealSignal "'input Real' as connector" annotation(defaultComponentName="u", Documentation(info="<html>
<p>
Connector with one input signal of type Real.
</p>
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={0,0,127}, fillPattern=FillPattern.Solid, points={{-(100),100},{100,0},{-(100),-(100)},{-(100),100}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={0,0,127}, fillPattern=FillPattern.Solid, points={{0,50},{100,0},{0,-(50)},{0,50}}),Text(visible=true, fillColor={0,0,127}, extent={{-(120),60},{100,105}}, textString="%name", fontName="Arial")}));
      connector RealOutput= output RealSignal "'output Real' as connector" annotation(defaultComponentName="y", Documentation(info="<html>
<p>
Connector with one output signal of type Real.
</p>
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-(100),100},{100,0},{-(100),-(100)},{-(100),100}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-(100),50},{0,0},{-(100),-(50)},{-(100),50}}),Text(visible=true, fillColor={0,0,127}, extent={{-(100),60},{130,140}}, textString="%name", fontName="Arial")}));
      partial block BlockIcon "Basic graphical layout of input/output block"
        annotation(Documentation(info="<html>
<p>
Block that has only the basic icon for an input/output
block (no declarations, no equations). Most blocks
of package Modelica.Blocks inherit directly or indirectly
from this block.
</p>
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{100,100}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(150),110},{150,150}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end BlockIcon;

      partial block SO "Single Output continuous control block"
        extends BlockIcon;
        annotation(Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>
<p>
Block has one continuous Real output signal.
</p>
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        RealOutput y "Connector of Real output signal" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-(10),-(10)},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-(10),-(10)},{10,10}}, rotation=0)));
      end SO;

    end Interfaces;

  end Blocks;

  package SIunits "Type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Invisible=true, Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-(63),-(67)},{45,-(13)}}, textString="[kg.m2]", fontName="Arial")}), Documentation(info="<html>
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
</html>"), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{169,86},{349,236}}),Polygon(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{169,236},{189,256},{369,256},{349,236},{169,236}}),Polygon(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{369,256},{369,106},{349,86},{349,236},{369,256}}),Text(visible=true, fillColor={160,160,160}, extent={{179,196},{339,226}}, textString="Library", fontName="Arial"),Text(visible=true, extent={{206,119},{314,173}}, textString="[kg.m2]", fontName="Arial"),Text(visible=true, fillColor={255,0,0}, extent={{163,264},{406,320}}, textString="Modelica.SIunits", fontName="Arial")}));
    package Conversions "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Library2;
      annotation(preferedView="info", Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, lineThickness=1, extent={{-(92),-(67)},{-(33),-(7)}}, textString="°C", fontName="Arial"),Text(visible=true, extent={{22,-(67)},{82,-(7)}}, textString="K", fontName="Arial"),Line(visible=true, points={{-(26),-(36)},{6,-(36)}}),Polygon(visible=true, pattern=LinePattern.None, fillPattern=FillPattern.Solid, points={{6,-(28)},{6,-(45)},{26,-(37)},{6,-(28)}})}), Documentation(info="<HTML>
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
"), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Library2;
        type Temperature_degC= Real(final quantity="ThermodynamicTemperature", final unit="degC") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        type AngularVelocity_rpm= Real(final quantity="AngularVelocity", final unit="rev/min") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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
"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-(66),-(67)},{52,-(13)}}, textString="[rev/min]", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end NonSIunits;

      function to_rpm "Convert from radian per second to revolutions per minute"
        extends ConversionIcon;
        input AngularVelocity rs "radian per second value";
        output NonSIunits.AngularVelocity_rpm rpm "revolutions per minute value";
        annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-(100),20},{-(20),100}}, textString="rad/s", fontName="Arial"),Text(visible=true, extent={{20,-(100)},{100,-(20)}}, textString="rev/min", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      algorithm
        rpm:=30/Modelica.Constants.pi*rs;
      end to_rpm;

      function from_rpm "Convert from revolutions per minute to radian per second"
        extends ConversionIcon;
        input NonSIunits.AngularVelocity_rpm rpm "revolutions per minute value";
        output AngularVelocity rs "radian per second value";
        annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-(100),20},{-(20),100}}, textString="rev/min", fontName="Arial"),Text(visible=true, extent={{20,-(100)},{100,-(20)}}, textString="rad/s", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      algorithm
        rs:=Modelica.Constants.pi/30*rpm;
      end from_rpm;

      partial function ConversionIcon "Base icon for conversion functions"
        annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={191,0,0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{100,100}}),Line(visible=true, points={{-(90),0},{30,0}}, color={191,0,0}),Polygon(visible=true, lineColor={191,0,0}, fillColor={191,0,0}, fillPattern=FillPattern.Solid, points={{90,0},{30,20},{30,-(20)},{90,0}}),Text(visible=true, extent={{-(115),105},{115,155}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end ConversionIcon;

    end Conversions;

    type Angle= Real(final quantity="Angle", final unit="rad", displayUnit="deg") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Time= Real(final quantity="Time", final unit="s") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type AngularVelocity= Real(final quantity="AngularVelocity", final unit="rad/s", displayUnit="rev/min") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type AngularAcceleration= Real(final quantity="AngularAcceleration", final unit="rad/s2") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Velocity= Real(final quantity="Velocity", final unit="m/s") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Acceleration= Real(final quantity="Acceleration", final unit="m/s2") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type MomentOfInertia= Real(final quantity="MomentOfInertia", final unit="kg.m2") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Inertia= MomentOfInertia annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Torque= Real(final quantity="Torque", final unit="N.m") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type ElectricCurrent= Real(final quantity="ElectricCurrent", final unit="A") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Current= ElectricCurrent annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type ElectricPotential= Real(final quantity="ElectricPotential", final unit="V") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Voltage= ElectricPotential annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type MagneticFlux= Real(final quantity="MagneticFlux", final unit="Wb") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Inductance= Real(final quantity="Inductance", final unit="H") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Resistance= Real(final quantity="Resistance", final unit="Ohm") annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{80,50}}),Polygon(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{-(100),50},{-(80),70},{100,70},{80,50},{-(100),50}}),Polygon(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{100,70},{100,-(80)},{80,-(100)},{80,50},{100,70}}),Text(visible=true, fillColor={255,0,0}, extent={{-(120),70},{120,135}}, textString="%name", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-(90),10},{70,40}}, textString="Library", fontName="Arial"),Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{80,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{-(100),50},{-(80),70},{100,70},{80,50},{-(100),50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{100,70},{100,-(80)},{80,-(100)},{80,50},{100,70}}),Text(visible=true, fillColor={160,160,160}, extent={{-(90),10},{70,40}}, textString="Library", fontName="Arial"),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-(64),-(20)},{-(50),-(4)},{50,-(4)},{36,-(20)},{-(64),-(20)},{-(64),-(20)}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-(64),-(84)},{36,-(20)}}),Text(visible=true, fillColor={128,128,128}, extent={{-(60),-(38)},{32,-(24)}}, textString="Library", fontName="Arial"),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,-(4)},{50,-(70)},{36,-(84)},{36,-(20)},{50,-(4)}})}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    partial package Library "Icon for library"
      annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{80,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{-(100),50},{-(80),70},{100,70},{80,50},{-(100),50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{100,70},{100,-(80)},{80,-(100)},{80,50},{100,70}}),Text(visible=true, fillColor={0,0,255}, extent={{-(85),-(85)},{65,35}}, textString="Library", fontName="Arial"),Text(visible=true, fillColor={255,0,0}, extent={{-(120),73},{120,122}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Library;

    partial package Library2 "Icon for library where additional icon elements shall be added"
      annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{80,50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{-(100),50},{-(80),70},{100,70},{80,50},{-(100),50}}),Polygon(visible=true, fillColor={210,210,210}, fillPattern=FillPattern.Solid, points={{100,70},{100,-(80)},{80,-(100)},{80,50},{100,70}}),Text(visible=true, fillColor={255,0,0}, extent={{-(120),70},{120,125}}, textString="%name", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, fillPattern=FillPattern.Solid, extent={{-(90),10},{70,40}}, textString="Library", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Library2;

    partial model Example "Icon for an example model"
      annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{80,50}}),Polygon(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-(100),50},{-(80),70},{100,70},{80,50},{-(100),50}}),Polygon(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{100,70},{100,-(80)},{80,-(100)},{80,50},{100,70}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-(85),-(85)},{65,35}}, textString="Example", fontName="Arial"),Text(visible=true, fillColor={255,0,0}, extent={{-(120),73},{120,132}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Example;

    partial class Enumeration "Icon for an enumeration (emulated by a package)"
      annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-(138),104},{138,164}}, textString="%name", fontName="Arial"),Ellipse(visible=true, lineColor={255,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{100,100}}),Text(visible=true, fillColor={255,0,127}, extent={{-(100),-(100)},{100,100}}, textString="e", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Enumeration;

    type TypeInteger "Icon for an Integer type"
      extends Integer;
      annotation(Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-(100),-(100)},{100,100}}),Text(visible=true, extent={{-(94),-(94)},{94,94}}, textString="I", fontName="Arial")}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end TypeInteger;

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
    constant NonSI.Temperature_degC T_zero=-(273.15) "Absolute zero temperature";
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
</html>"), Icon(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-(34),-(38)},{12,-(38)}}, thickness=0.5),Line(visible=true, points={{-(20),-(38)},{-(24),-(48)},{-(28),-(56)},{-(34),-(64)}}, thickness=0.5),Line(visible=true, points={{-(2),-(38)},{2,-(46)},{8,-(56)},{14,-(64)}}, thickness=0.5)}), Diagram(coordinateSystem(extent={{-(100),100},{100,-(100)}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  end Constants;

end Modelica;
model Modelica_Electrical_Machines_Examples_DCEE_start
  extends Modelica.Electrical.Machines.Examples.DCEE_start;
end Modelica_Electrical_Machines_Examples_DCEE_start;
