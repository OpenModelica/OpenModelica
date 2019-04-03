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

        partial model Rigid "Base class for the rigid connection of two rotational 1D flanges"
          SI.Angle phi "Absolute rotation angle of component (= flange_a.phi = flange_b.phi)";
          annotation(Documentation(info="<html>
<p>
This is a 1D rotational component with two rigidly connected flanges,
i.e., flange_a.phi = flange_b.phi. It is used e.g. to built up components
with inertia.
</p>

</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Flange_a flange_a "(left) driving flange (flange axis directed INTO cut plane)" annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Flange_b flange_b "(right) driven flange (flange axis directed OUT OF cut plane)" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          flange_a.phi=phi;
          flange_b.phi=phi;
        end Rigid;

        partial model PartialSpeedDependentTorque "Partial model of a torque acting at the flange (accelerates the flange)"
          Modelica.SIunits.AngularVelocity w=der(flange.phi) "Angular velocity at flange";
          Modelica.SIunits.Torque tau=flange.tau "accelerating torque acting at flange";
          annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<HTML>
<p>
Partial model of torque dependent on speed that accelerates the flange.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={255,255,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-96,-96},{96,96}}),Line(visible=true, points={{-30,-70},{30,-70}}),Line(visible=true, points={{-30,-90},{-10,-70}}),Line(visible=true, points={{-10,-90},{10,-70}}),Rectangle(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-20,-140},{20,-100}}),Line(visible=true, points={{10,-90},{30,-70}}),Line(visible=true, points={{0,-70},{0,-110}}),Line(visible=true, points={{-92,0},{-76,36},{-54,62},{-30,80},{-14,88},{10,92},{26,90},{46,80},{64,62}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={0,0,255}, extent={{-150,100},{150,140}}, textString="%name", fontName="Arial"),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{94,16},{80,74},{50,52},{94,16}})}));
          Modelica.Mechanics.Rotational.Interfaces.Flange_b flange "Flange on which torque is acting" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{10,-10},{-10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{10,-10},{-10,10}}, rotation=0)));
          Modelica.Mechanics.Rotational.Interfaces.Flange_a bearing "Bearing at which the reaction torque (i.e., -flange.tau) is acting" annotation(Placement(visible=true, transformation(origin={0,-120}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={0,-120}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          if cardinality(bearing) == 0 then
            bearing.phi=0;
          else
            bearing.tau=-flange.tau;
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
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-25},{-60,-25}}),Line(visible=true, points={{60,-25},{80,-25}}),Line(visible=true, points={{-70,-25},{-70,-70}}),Line(visible=true, points={{70,-25},{70,-70}}),Line(visible=true, points={{-80,25},{-60,25}}),Line(visible=true, points={{60,25},{80,25}}),Line(visible=true, points={{-70,45},{-70,25}}),Line(visible=true, points={{70,45},{70,25}}),Line(visible=true, points={{-70,-70},{70,-70}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-50,-50},{50,50}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-96,-10},{-50,10}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{50,-10},{96,10}}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{0,-90},{-20,-85},{-20,-95},{0,-90}}),Line(visible=true, points={{-90,-90},{-19,-90}}, color={128,128,128}),Text(visible=true, fillColor={128,128,128}, extent={{4,-96},{72,-83}}, textString="rotation axis", fontName="Arial"),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{9,73},{19,70},{9,67},{9,73}}),Line(visible=true, points={{9,70},{-21,70}}),Text(visible=true, extent={{25,65},{77,77}}, textString="w = der(phi) ", fontName="Arial")}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-100,-10},{-50,10}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{50,-10},{100,10}}),Line(visible=true, points={{-80,-25},{-60,-25}}),Line(visible=true, points={{60,-25},{80,-25}}),Line(visible=true, points={{-70,-25},{-70,-70}}),Line(visible=true, points={{70,-25},{70,-70}}),Line(visible=true, points={{-80,25},{-60,25}}),Line(visible=true, points={{60,25},{80,25}}),Line(visible=true, points={{-70,45},{-70,25}}),Line(visible=true, points={{70,45},{70,25}}),Line(visible=true, points={{-70,-70},{70,-70}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{-50,-50},{50,50}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,60},{150,100}}, textString="%name", fontName="Arial"),Text(visible=true, extent={{-150,-120},{150,-80}}, textString="J=%J", fontName="Arial")}));
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
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-40},{80,-40}}),Line(visible=true, points={{80,-40},{40,-80}}),Line(visible=true, points={{40,-40},{0,-80}}),Line(visible=true, points={{0,-40},{-40,-80}}),Line(visible=true, points={{-40,-40},{-80,-80}}),Line(visible=true, points={{0,-40},{0,-4}}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{8,46},{-12,51},{-12,41},{8,46}}),Line(visible=true, points={{-82,46},{-11,46}}, color={128,128,128}),Text(visible=true, fillColor={128,128,128}, extent={{12,40},{80,53}}, textString="rotation axis", fontName="Arial")}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,-130},{150,-90}}, textString="%name=%phi0", fontName="Arial"),Line(visible=true, points={{-80,-40},{80,-40}}),Line(visible=true, points={{80,-40},{40,-80}}),Line(visible=true, points={{40,-40},{0,-80}}),Line(visible=true, points={{0,-40},{-40,-80}}),Line(visible=true, points={{-40,-40},{-80,-80}}),Line(visible=true, points={{0,-40},{0,-10}})}));
        Interfaces.Flange_b flange_b "(right) flange fixed in housing" annotation(Placement(visible=true, transformation(origin={0,0}, extent={{10,-10},{-10,10}}, rotation=0), iconTransformation(origin={0,0}, extent={{10,-10},{-10,10}}, rotation=0)));
      equation
        flange_b.phi=phi0;
      end Fixed;

      model QuadraticSpeedDependentTorque "Quadratic dependency of torque versus speed"
        extends Modelica.Mechanics.Rotational.Interfaces.PartialSpeedDependentTorque;
        parameter Modelica.SIunits.Torque tau_nominal "nominal torque (if negative, torque is acting as load)";
        parameter Boolean TorqueDirection=true "same direction of torque in both directions of rotation";
        parameter Modelica.SIunits.AngularVelocity w_nominal(min=Modelica.Constants.eps) "nominal speed";
        annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,-100},{-80,-98},{-60,-92},{-40,-82},{-20,-68},{0,-50},{20,-28},{40,-2},{60,28},{80,62},{100,100}}, color={0,0,255}, smooth=Smooth.Bezier)}), Documentation(info="<HTML>
<p>
Model of torque, quadratic dependent on angular velocity of flange.<br>
Parameter TorqueDirection chooses whether direction of torque is the same in both directions of rotation or not.
</p>
</HTML>"));
      equation
        if TorqueDirection then
          tau=-tau_nominal*(w/w_nominal)^2;
        else
          tau=-tau_nominal*smooth(1, if w >= 0 then (w/w_nominal)^2 else -(w/w_nominal)^2);
        end if;
      end QuadraticSpeedDependentTorque;

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
            annotation(Evaluate=true, choices(choice=Modelica.Mechanics.Rotational.Types.Init.NoInit "no initialization (phi_start, w_start are guess values)", choice=Modelica.Mechanics.Rotational.Types.Init.SteadyState "steady state initialization (der(phi)=der(w)=0)", choice=Modelica.Mechanics.Rotational.Types.Init.InitialState "initialization with phi_start, w_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialAngle "initialization with phi_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialSpeed "initialization with w_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialAcceleration "initialization with a_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialAngleAcceleration "initialization with phi_start, a_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialSpeedAcceleration "initialization with w_start, a_start", choice=Modelica.Mechanics.Rotational.Types.Init.InitialAngleSpeedAcceleration "initialization with phi_start, w_start, a_start"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          end Temp;

          annotation(Documentation(info="<html>
<p>
Type <b>Init</b> defines initialization of absolute rotational
quantities.
</p>

</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        end Init;

      end Types;

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

    function atan2 "four quadrant inverse tangent"
      extends baseIcon2;
      input Real u1;
      input Real u2;
      output SI.Angle y;
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{0,-80},{8.93,-67.2},{17.1,-59.3},{27.3,-53.6},{42.1,-49.4},{69.9,-45.8},{80,-45.1}}, smooth=Smooth.Bezier),Line(visible=true, points={{-80,-34.9},{-46.1,-31.4},{-29.4,-27.1},{-18.3,-21.5},{-10.3,-14.5},{-2.03,-3.17},{7.97,11.6},{15.5,19.4},{24.3,25},{39,30},{62.1,33.5},{80,34.9}}, smooth=Smooth.Bezier),Line(visible=true, points={{-80,45.1},{-45.9,48.7},{-29.1,52.9},{-18.1,58.6},{-10.2,65.8},{-1.82,77.2},{0,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-90,-94},{-18,-46}}, textString="atan2", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{0,-80},{8.93,-67.2},{17.1,-59.3},{27.3,-53.6},{42.1,-49.4},{69.9,-45.8},{80,-45.1}}, smooth=Smooth.Bezier),Line(visible=true, points={{-80,-34.9},{-46.1,-31.4},{-29.4,-27.1},{-18.3,-21.5},{-10.3,-14.5},{-2.03,-3.17},{7.97,11.6},{15.5,19.4},{24.3,25},{39,30},{62.1,33.5},{80,34.9}}, smooth=Smooth.Bezier),Line(visible=true, points={{-80,45.1},{-45.9,48.7},{-29.1,52.9},{-18.1,58.6},{-10.2,65.8},{-1.82,77.2},{0,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-30,70},{-10,89}}, textString="pi", fontName="Arial"),Text(visible=true, extent={{-30,-88},{-10,-69}}, textString="-pi", fontName="Arial"),Text(visible=true, extent={{-30,30},{-10,49}}, textString="pi/2", fontName="Arial"),Line(visible=true, points={{0,40},{-8,40}}, color={192,192,192}),Line(visible=true, points={{0,-40},{-8,-40}}, color={192,192,192}),Text(visible=true, extent={{-30,-50},{-10,-31}}, textString="-pi/2", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<HTML>
y = atan2(u1,u2) computes y such that tan(y) = u1/u2 and
y is in the range -pi &lt; y &le; pi. u2 may be zero, provided
u1 is not zero.
</HTML>
"));

      external "C" y=atan2(u1,u2) ;

    end atan2;

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

      package Sensors "Potential, voltage, current, and power sensors"
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Documentation(info="<html>
<p>
This package contains potential, voltage, and current sensors.
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
        model CurrentSensor "Sensor to measure the current in a branch"
          extends Modelica.Icons.RotationalSensor;
          annotation(Documentation(revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-70,0},{-96,0}}),Line(visible=true, points={{70,0},{96,0}}),Line(visible=true, points={{0,-90},{0,-70}}, color={0,0,255})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, lineColor={0,0,255}, extent={{-29,-70},{30,-11}}, textString="A", fontName="Arial"),Line(visible=true, points={{-70,0},{-90,0}}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,80},{150,120}}, textString="%name", fontName="Arial"),Line(visible=true, points={{70,0},{90,0}}),Line(visible=true, points={{0,-90},{0,-70}}, color={0,0,255})}));
          Interfaces.PositivePin p "positive pin" annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Interfaces.NegativePin n "negative pin" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Modelica.Blocks.Interfaces.RealOutput i(redeclare type SignalType= SI.Current ) "current in the branch from p to n as output signal" annotation(Placement(visible=true, transformation(origin={0,-100}, extent={{-10,10},{10,-10}}, rotation=-90), iconTransformation(origin={0,-100}, extent={{-10,10},{10,-10}}, rotation=-90)));
        equation
          p.v=n.v;
          p.i=i;
          n.i=-i;
        end CurrentSensor;

      end Sensors;

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
        model IdealClosingSwitch "Ideal electrical closer"
          extends Modelica.Electrical.Analog.Interfaces.OnePort;
          parameter SI.Resistance Ron(final min=0)=1e-05 "Closed switch resistance" annotation(extent=[-56.6667,10;-10,56.6667]);
          parameter SI.Conductance Goff(final min=0)=1e-05 "Opened switch conductance" annotation(extent=[10,10;56.6667,56.6667]);
          annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-44,-4},{-36,4}}),Line(visible=true, points={{-90,0},{-44,0}}, color={0,0,255}),Line(visible=true, points={{-37,2},{40,50}}, color={0,0,255}),Line(visible=true, points={{40,0},{90,0}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,-70}}, textString="%name", fontName="Arial"),Line(visible=true, points={{0,51},{0,26}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-44,-4},{-36,4}}),Line(visible=true, points={{-96,0},{-44,0}}, color={0,0,255}),Line(visible=true, points={{-37,2},{40,50}}, color={0,0,255}),Line(visible=true, points={{40,0},{96,0}}, color={0,0,255}),Line(visible=true, points={{0,51},{0,26}}, color={0,0,255})}));
          Modelica.Blocks.Interfaces.BooleanInput control "true => p--n connected, false => switch open" annotation(Placement(visible=true, transformation(origin={0,70}, extent={{-20,-20},{20,20}}, rotation=-450), iconTransformation(origin={0,70}, extent={{-20,-20},{20,20}}, rotation=-90)));
        protected
          Real s "Auxiliary variable";
          parameter Modelica.SIunits.Voltage unitVoltage=1 annotation(HideResult=true);
          parameter Modelica.SIunits.Current unitCurrent=1 annotation(HideResult=true);
          annotation(Documentation(info="<HTML>
<P>
The ideal closing switch has a positive pin p and a negative pin n.
The switching behaviour is controlled by input signal control.
If control is true, pin p is connected
with negative pin n. Otherwise, pin p is not connected
with negative pin n.
</P>
<P>
In order to prevent singularities during switching, the opened
switch has a (very low) conductance Goff
and the closed switch has a (very low) resistance Ron.
The limiting case is also allowed, i.e., the resistance Ron of the
closed switch could be exactly zero and the conductance Goff of the
open switch could be also exactly zero. Note, there are circuits,
where a description with zero Ron or zero Goff is not possible.
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
</html>"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-44,4},{-36,-4}}),Line(color={0,0,255}, points={{-90,0},{-44,0}}),Line(color={0,0,255}, points={{-37,2},{40,50}}),Line(color={0,0,255}, points={{40,0},{90,0}}),Text(lineColor={0,0,255}, extent={{-100,-70},{100,-100}}, textString="%name"),Line(color={0,0,255}, points={{0,51},{0,26}})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-44,4},{-36,-4}}),Line(color={0,0,255}, points={{-96,0},{-44,0}}),Line(color={0,0,255}, points={{-37,2},{40,50}}),Line(color={0,0,255}, points={{40,0},{96,0}}),Text(lineColor={0,0,255}, extent={{-100,-40},{100,-79}}, textString="%name"),Line(color={0,0,255}, points={{0,51},{0,26}})}));
        equation
          v=s*unitCurrent*(if control then Ron else 1);
          i=s*unitVoltage*(if control then 1 else Goff);
        end IdealClosingSwitch;

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

        model Delta "Delta (polygon) connection"
          parameter Integer m(final min=2)=3 "number of phases";
          annotation(Documentation(info="<HTML>
<p>
Connects in a cyclic way plug_n.pin[j] to plug_p.pin[j+1],
thus establishing a so-called delta (or polygon) connection
when used in parallel to another component.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, extent={{-150,60},{150,120}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-40,68},{-40,-70},{79,0},{-40,68},{-40,67}}, color={0,0,255}, thickness=0.5),Text(visible=true, lineColor={0,0,255}, extent={{-100,-110},{100,-70}}, textString="m=%m", fontName="Arial"),Line(visible=true, points={{-90,0},{-40,0}}, color={0,0,255}),Line(visible=true, points={{80,0},{90,0}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Interfaces.PositivePlug plug_p(final m=m) annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Interfaces.NegativePlug plug_n(final m=m) annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
        equation
          for j in 1:m loop
            if j < m then
              connect(plug_n.pin[j],plug_p.pin[j + 1]);
            else
              connect(plug_n.pin[j],plug_p.pin[1]);
            end if;
          end for;
        end Delta;

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
        model IdealClosingSwitch "Multiphase ideal closer"
          extends Interfaces.TwoPlug;
          parameter Modelica.SIunits.Resistance Ron[m](final min=zeros(m))=fill(1e-05, m) "Closed switch resistance";
          parameter Modelica.SIunits.Conductance Goff[m](final min=zeros(m))=fill(1e-05, m) "Opened switch conductance";
          annotation(Documentation(info="<HTML>
<p>
Contains m ideal closing switches (Modelica.Electrical.Analog.Ideal.IdealClosingSwitch).
</p><
/HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,-100},{150,-40}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-90,0},{-44,0}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-44,-4},{-36,4}}),Line(visible=true, points={{-37,2},{40,50}}, color={0,0,255}),Line(visible=true, points={{0,88},{0,26}}, color={0,0,255}),Line(visible=true, points={{40,0},{90,0}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, extent={{-100,60},{-20,100}}, textString="m=", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, extent={{20,60},{100,100}}, textString="%m", fontName="Arial")}));
          Modelica.Electrical.Analog.Ideal.IdealClosingSwitch idealClosingSwitch[m](final Ron=Ron, final Goff=Goff) annotation(Placement(visible=true, transformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Modelica.Blocks.Interfaces.BooleanInput control[m] "true => p--n connected, false => switch open" annotation(Placement(visible=true, transformation(origin={0,70}, extent={{-20,-20},{20,20}}, rotation=-90), iconTransformation(origin={0,70}, extent={{-20,-20},{20,20}}, rotation=-90)));
        equation
          connect(idealClosingSwitch.n,plug_n.pin) annotation(Line(visible=true, origin={55,0}, points={{-45,0},{45,0}}, color={0,0,255}));
          connect(plug_p.pin,idealClosingSwitch.p) annotation(Line(visible=true, origin={-55,0}, points={{-45,0},{45,0}}, color={0,0,255}));
          connect(control,idealClosingSwitch.control) annotation(Line(visible=true, points={{0,70},{0,7}}, color={255,0,255}));
        end IdealClosingSwitch;

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

      end Interfaces;

      package Sensors "Multiphase potential, voltage and current Sensors"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains multiphase potential, voltage, and current sensors.
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
  <li>v1.0 2004/10/01 Anton Haumer</li>
  <li>v1.1 2006/01/12 Anton Haumer<br>
      added PowerSensor</li>
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
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-60,-90},{40,10}}),Line(visible=true, points={{-50,-16},{-36,-25}}),Line(visible=true, points={{-35,0},{-25,-14}}),Line(visible=true, points={{-10,7},{-10,-10}}),Line(visible=true, points={{15,0},{5,-14}}),Line(visible=true, points={{30,-15},{16,-25}}),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{-15,-45},{-5,-35}}),Line(visible=true, points={{-10,-40},{-6,-26}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-12,-24},{-0.5,-27},{2,1.5},{-12,-24}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model CurrentSensor "Multiphase current sensor"
          extends Modelica.Icons.RotationalSensor;
          parameter Integer m(final min=1)=3 "number of phases";
          annotation(Documentation(info="<HTML>
<p>
Contains m current sensors (Modelica.Electrical.Analog.Sensors.CurrentSensor),
thus measuring the m currents <i>i[m]</i> flowing from the m pins of plug_p to the m pins of plug_n.
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, lineColor={0,0,255}, extent={{-29,-70},{30,-11}}, textString="A", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,60},{150,120}}, textString="%name", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, extent={{-100,-100},{-20,-60}}, textString="m=", fontName="Arial"),Line(visible=true, points={{-70,0},{-90,0}}),Line(visible=true, points={{70,0},{90,0}}),Line(visible=true, points={{0,-100},{0,-70}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, extent={{20,-100},{100,-60}}, textString="%m", fontName="Arial")}));
          Interfaces.PositivePlug plug_p(final m=m) annotation(Placement(visible=true, transformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Interfaces.NegativePlug plug_n(final m=m) annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor[m] annotation(Placement(visible=true, transformation(origin={0,0}, extent={{-10,-10},{10,10}}, rotation=0)));
          Modelica.Blocks.Interfaces.RealOutput i[m](redeclare type SignalType= Modelica.SIunits.Current ) "current in the branch from p to n as output signal" annotation(Placement(visible=true, transformation(origin={0,-110}, extent={{-10,10},{10,-10}}, rotation=-90), iconTransformation(origin={0,-110}, extent={{-10,10},{10,-10}}, rotation=-90)));
        equation
          connect(currentSensor.n,plug_n.pin) annotation(Line(visible=true, points={{10,0},{100,0}}, color={0,0,255}));
          connect(plug_p.pin,currentSensor.p) annotation(Line(visible=true, points={{-100,0},{-10,0}}, color={0,0,255}));
          connect(currentSensor.i,i) annotation(Line(visible=true, points={{0,-10},{0,-110}}, color={0,0,255}));
        end CurrentSensor;

      end Sensors;

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
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={0,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{-60.0,60.0},{60.0,-60.0}}),Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.HorizontalCylinder, extent={{-60.0,60.0},{-80.0,-60.0}}),Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.HorizontalCylinder, extent={{60.0,10.0},{80.0,-10.0}}),Rectangle(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{-60.0,70.0},{20.0,50.0}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-70.0,-90.0},{-60.0,-90.0},{-30.0,-20.0},{20.0,-20.0},{50.0,-90.0},{60.0,-90.0},{60.0,-100.0},{-70.0,-100.0},{-70.0,-90.0}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={128,128,128}, extent={{-80.0,44.0},{60.0,-96.0}}),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{-40.0,36.0},{-40.0,-88.0},{60.0,-26.0},{-40.0,36.0}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model AIMC_DOL "Test example 1: AsynchronousInductionMachineSquirrelCage direct-on-line"
          extends Modelica.Icons.Example;
          constant Integer m=3 "number of phases";
          parameter Modelica.SIunits.Voltage VNominal=100 "nominal RMS voltage per phase";
          parameter Modelica.SIunits.Frequency fNominal=50 "nominal frequency";
          parameter Modelica.SIunits.Time tStart1=0.1 "start time";
          parameter Modelica.SIunits.Torque T_Load=161.4 "nominal load torque";
          parameter Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm rpmLoad=1440.45 "nominal load speed";
          parameter Modelica.SIunits.Inertia J_Load=0.29 "load's moment of inertia";
          annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), experiment(StopTime=1.5, Interval=0.001), experimentSetupOutput(doublePrecision=true), Documentation(info="<HTML>
<p>
<b>1st Test example: Asynchronous induction Machine with squirrel cage - direct on line starting</b><br>
At start time tStart three phase voltage is supplied to the asynchronous induction machine with squirrel cage;
the machine starts from standstill, accelerating inertias against load torque quadratic dependent on speed, finally reaching nominal speed.<br>
Simulate for 1.5 seconds and plot (versus time):
<ul>
<li>CurrentRMSsensor1.I: stator current RMS</li>
<li>AIMC1.rpm_mechanical: motor's speed</li>
<li>AIMC1.tau_electrical: motor's torque</li>
</ul>
Default machine parameters of model <i>AIM_SquirrelCage</i> are used.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          Modelica.Electrical.Machines.BasicMachines.AsynchronousInductionMachines.AIM_SquirrelCage AIMC1 annotation(Placement(visible=true, transformation(origin={-10.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          Modelica.Electrical.Machines.Sensors.CurrentRMSsensor CurrentRMSsensor1 annotation(Placement(visible=true, transformation(origin={0.0,0.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=90)));
          Modelica.Electrical.MultiPhase.Sources.SineVoltage SineVoltage1(final m=m, freqHz=fill(fNominal, m), V=fill(sqrt(2/3)*VNominal, m)) annotation(Placement(visible=true, transformation(origin={0.0,60.0}, extent={{10.0,10.0},{-10.0,-10.0}}, rotation=90)));
          Modelica.Electrical.MultiPhase.Basic.Star Star1(final m=m) annotation(Placement(visible=true, transformation(origin={-60.0,90.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=0)));
          Modelica.Blocks.Sources.BooleanStep BooleanStep1[m](each startTime=tStart1) annotation(Placement(visible=true, transformation(origin={-70.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          Modelica.Electrical.MultiPhase.Ideal.IdealClosingSwitch IdealCloser1(final m=m) annotation(Placement(visible=true, transformation(origin={0.0,30.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=-270)));
          Modelica.Mechanics.Rotational.Inertia LoadInertia(J=J_Load) annotation(Placement(visible=true, transformation(origin={50.0,-40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          Modelica.Mechanics.Rotational.QuadraticSpeedDependentTorque QuadraticLoadTorque1(w_nominal=Modelica.SIunits.Conversions.from_rpm(rpmLoad), tau_nominal=-T_Load) annotation(Placement(visible=true, transformation(origin={80.0,-40.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=0)));
          Modelica.Electrical.Machines.Examples.Utilities.TerminalBox TerminalBox1(StarDelta="D") annotation(Placement(visible=true, transformation(origin={-10.0,-20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          Modelica.Electrical.Analog.Basic.Ground Ground1 annotation(Placement(visible=true, transformation(origin={-90.0,90.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        equation
          connect(TerminalBox1.plugToGrid,CurrentRMSsensor1.plug_n) annotation(Line(visible=true, points={{-10.0,-28.0},{-10.0,-20.0},{0.0,-20.0},{0.0,-10.0}}, color={0,0,255}));
          connect(IdealCloser1.plug_n,CurrentRMSsensor1.plug_p) annotation(Line(visible=true, points={{0.0,20.0},{0.0,17.0},{0.0,17.0},{0.0,10.0}}, color={0,0,255}));
          connect(SineVoltage1.plug_p,IdealCloser1.plug_p) annotation(Line(visible=true, points={{0.0,70.0},{0.0,48.0},{0.0,46.0},{0.0,46.0},{0.0,40.0}}, color={0,0,255}));
          connect(BooleanStep1.y,IdealCloser1.control) annotation(Line(visible=true, points={{-59.0,40.0},{-20.0,40.0},{-20.0,30.0},{-7.0,30.0}}, color={255,0,255}));
          connect(AIMC1.flange_a,LoadInertia.flange_a) annotation(Line(visible=true, origin={20.0,-40.0}, points={{-20.0,0.0},{20.0,0.0}}));
          connect(TerminalBox1.negativeMachinePlug,AIMC1.plug_sn) annotation(Line(visible=true, points={{-16.0,-30.0},{-16.0,-30.0}}, color={0,0,255}));
          connect(TerminalBox1.positiveMachinePlug,AIMC1.plug_sp) annotation(Line(visible=true, points={{-4.0,-30.0},{-4.0,-30.0}}, color={0,0,255}));
          connect(LoadInertia.flange_b,QuadraticLoadTorque1.flange) annotation(Line(visible=true, points={{60.0,-40.0},{70.0,-40.0}}));
          connect(SineVoltage1.plug_n,Star1.plug_p) annotation(Line(visible=true, points={{0.0,50.0},{-0.0,90.0},{-50.0,90.0}}, color={0,0,255}));
          connect(Star1.pin_n,Ground1.p) annotation(Line(visible=true, points={{-70.0,90.0},{-80.0,90.0}}, color={0,0,255}));
        end AIMC_DOL;

        package Utilities "Library with auxiliary models for testing"
          extends Modelica.Icons.Library;
          annotation(Documentation(info="<HTML>
<p>
This package contains components utility components for testing examples.
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
  <li> v1.1  2004/10/01 Anton Haumer<br>
       changed naming and structure<br>
       issued to Modelica Standard Library 2.1</li>
  <li> v1.3.1 2004/11/06 Anton Haumer<br>
       small changes in VfController</li>
  <li> v1.6.1 2004/11/22 Anton Haumer<br>
       introduced TerminalBox</li>
  </ul>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          model TerminalBox
            constant Integer m=3 "number of phases";
            parameter String StarDelta="Y" annotation(choices(choice="Y" "Star connection", choice="D" "Delta connection"));
            Modelica.Electrical.MultiPhase.Interfaces.PositivePlug positiveMachinePlug(final m=m) annotation(Placement(visible=true, transformation(origin={60.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={60.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            Modelica.Electrical.MultiPhase.Interfaces.NegativePlug negativeMachinePlug(final m=m) annotation(Placement(visible=true, transformation(origin={-60.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-60.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            Modelica.Electrical.MultiPhase.Basic.Star star(final m=m) if StarDelta <> "D" annotation(Placement(visible=true, transformation(origin={-70.0,-80.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=180)));
            Modelica.Electrical.MultiPhase.Basic.Delta delta(final m=m) if StarDelta == "D" annotation(Placement(visible=true, transformation(origin={-30.0,-60.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=0)));
            Modelica.Electrical.MultiPhase.Interfaces.PositivePlug plugToGrid(final m=m) annotation(Placement(visible=true, transformation(origin={0.0,-80.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0), iconTransformation(origin={0.0,-80.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0)));
            annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{-80.0,-80.0},{-80.0,-84.0},{-80.0,-120.0},{-40.0,-140.0},{40.0,-140.0},{80.0,-110.0},{80.0,-84.0},{76.0,-80.0},{-80.0,-80.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-40.0,-130.0},{40.0,-90.0}}, textString="%StarDelta", fontName="Arial")}), Documentation(info="<html>
<p>
TerminalBox: at the bottom connected to both machine plugs, connect at the top to the grid as usual,<br>
choosing Y-connection (StarDelta=Y) or D-connection (StarDelta=D).
</p>
</html>"));
            Modelica.Electrical.Analog.Interfaces.NegativePin starpoint if StarDelta <> "D" annotation(Placement(visible=true, transformation(origin={-90.0,-80.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-90.0,-80.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          equation
            connect(star.pin_n,starpoint) annotation(Line(visible=true, points={{-80.0,-80.0},{-90.0,-80.0}}, color={0,0,255}));
            connect(positiveMachinePlug,plugToGrid) annotation(Line(visible=true, points={{60.0,-100.0},{0.0,-100.0},{0.0,-80.0}}, color={0,0,255}));
            connect(delta.plug_p,positiveMachinePlug) annotation(Line(visible=true, points={{-20.0,-60.0},{60.0,-60.0},{60.0,-100.0}}, color={0,0,255}));
            connect(negativeMachinePlug,delta.plug_n) annotation(Line(visible=true, points={{-60.0,-100.0},{-40.0,-100.0},{-40.0,-60.0}}, color={0,0,255}));
            connect(negativeMachinePlug,star.plug_p) annotation(Line(visible=true, points={{-60.0,-100.0},{-60.0,-80.0}}, color={0,0,255}));
          end TerminalBox;

        end Utilities;

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
<HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={0,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{-60.0,-60.0},{60.0,60.0}}),Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.HorizontalCylinder, extent={{-80.0,-60.0},{-60.0,60.0}}),Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.HorizontalCylinder, extent={{60.0,-10.0},{80.0,10.0}}),Rectangle(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{-59.66,50.0},{20.34,70.0}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-70.0,-90.0},{-60.0,-90.0},{-30.0,-20.0},{20.0,-20.0},{50.0,-90.0},{60.0,-90.0},{60.0,-100.0},{-70.0,-100.0},{-70.0,-90.0}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        package AsynchronousInductionMachines "Models of asynchronous induction machines"
          extends Modelica.Icons.Library;
          annotation(Documentation(info="<HTML>
<p>
This package contains models of asynchronous induction machines, based on space phasor theory:
<ul>
<li>AIM_SquirrelCage: asynchronous induction machine with squirrel cage</li>
<li>AIM_SlipRing: asynchronous induction machine with wound rotor</li>
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
  <li> v1.02 2004/09/19 Anton Haumer</li>
  <li> v1.03 2004/09/24 Anton Haumer<br>
       consistent naming of inductors and resistors in machine models</li>
  <li> v1.1  2004/10/01 Anton Haumer<br>
       changed naming and structure<br>
       issued to Modelica Standard Library 2.1</li>
  <li> v1.2  2004/10/27 Anton Haumer<br>
       fixed a bug with support (formerly bearing)</li>
  <li> v1.3.2 2004/11/10 Anton Haumer<br>
       ReluctanceRotor moved to SynchronousMachines</li>
  <li> v1.4   2004/11/11 Anton Haumer<br>
       removed mechanical flange support<br>
       to ease the implementation of a 3D-frame in a future release</li>
  <li> v1.6.3 2005/11/25 Anton Haumer<br>
       easier parametrisation of SlipRing model</li>
  </ul>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          model AIM_SquirrelCage "Asynchronous induction machine with squirrel cage rotor"
            extends Machines.Interfaces.PartialBasicInductionMachine;
            constant Modelica.SIunits.Frequency fNominal=50 "nominal frequency";
            parameter Modelica.SIunits.Resistance Rs=0.03 "|Nominal resistances and inductances|warm stator resistance per phase";
            parameter Modelica.SIunits.Inductance Lssigma=3*(1 - sqrt(1 - 0.0667))/(2*pi*fNominal) "|Nominal resistances and inductances|stator stray inductance per phase";
            parameter Modelica.SIunits.Inductance Lm=3*sqrt(1 - 0.0667)/(2*pi*fNominal) "|Nominal resistances and inductances|main field inductance";
            parameter Modelica.SIunits.Inductance Lrsigma=3*(1 - sqrt(1 - 0.0667))/(2*pi*fNominal) "|Nominal resistances and inductances|rotor stray inductance";
            parameter Modelica.SIunits.Resistance Rr=0.04 "|Nominal resistances and inductances|warm rotor resistance";
            output Modelica.SIunits.Current i_0_s(stateSelect=StateSelect.default)=spacePhasorS.zero.i "stator zero-sequence current";
            output Modelica.SIunits.Current idq_ss[2]=airGapS.i_ss "stator space phasor current / stator fixed frame";
            output Modelica.SIunits.Current idq_sr[2](each stateSelect=StateSelect.prefer)=airGapS.i_sr "stator space phasor current / rotor fixed frame";
            output Modelica.SIunits.Current idq_rs[2]=airGapS.i_rs "rotor space phasor current / stator fixed frame";
            output Modelica.SIunits.Current idq_rr[2](each stateSelect=StateSelect.prefer)=airGapS.i_rr "rotor space phasor current / rotor fixed frame";
            Modelica.Electrical.MultiPhase.Basic.Resistor rs(final m=m, final R=fill(Rs, m)) annotation(Placement(visible=true, transformation(origin={50.0,60.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=0)));
            Modelica.Electrical.MultiPhase.Basic.Inductor lssigma(final m=m, final L=fill(Lssigma, m)) annotation(Placement(visible=true, transformation(origin={20.0,60.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=0)));
            annotation(defaultComponentName="AIMC", Documentation(info="<HTML>
<p>
<b>Model of a three phase asynchronous induction machine with squirrel cage.</b><br>
Resistance and stray inductance of stator is modeled directly in stator phases, then using space phasor transformation. Resistance and stray inductance of rotor's squirrel cage is modeled in two axis of the rotor-fixed ccordinate system. Both together connected via a stator-fixed <i>AirGap</i> model. Only losses in stator and rotor resistance are taken into account.
</p>
<p>
<b>Default values for machine's parameters (a realistic example) are:</b><br>
<table>
<tr>
<td>number of pole pairs p</td>
<td>2</td><td> </td>
</tr>
<tr>
<td>stator's moment of inertia</td>
<td>0.29</td><td>kg.m2</td>
</tr>
<tr>
<td>rotor's moment of inertia</td>
<td>0.29</td><td>kg.m2</td>
</tr>
<tr>
<td>nominal frequency fNominal</td>
<td>50</td><td>Hz</td>
</tr>
<tr>
<td>nominal voltage per phase</td>
<td>100</td><td>V RMS</td>
</tr>
<tr>
<td>nominal current per phase</td>
<td>100</td><td>A RMS</td>
</tr>
<tr>
<td>nominal torque</td>
<td>161.4</td><td>Nm</td>
</tr>
<tr>
<td>nominal speed</td>
<td>1440.45</td><td>rpm</td>
</tr>
<tr>
<td>nominal mechanical output</td>
<td>24.346</td><td>kW</td>
</tr>
<tr>
<td>efficiency</td>
<td>92.7</td><td>%</td>
</tr>
<tr>
<td>power factor</td>
<td>0.875</td><td> </td>
</tr>
<tr>
<td>stator resistance</td>
<td>0.03</td><td>Ohm per phase in warm condition</td>
</tr>
<tr>
<td>rotor resistance</td>
<td>0.04</td><td>Ohm in warm condition</td>
</tr>
<tr>
<td>stator reactance Xs</td>
<td>3</td><td>Ohm per phase</td>
</tr>
<tr>
<td>rotor reactance Xr</td>
<td>3</td><td>Ohm</td>
</tr>
<tr>
<td>total stray coefficient sigma</td>
<td>0.0667</td><td> </td>
</tr>
<tr>
<td>These values give the following inductances, <br>assuming equal stator and rotor stray inductances:</td>
<td> </td><td> </td>
</tr>
<tr>
<td>stator stray inductance per phase</td>
<td>Xs * (1 - sqrt(1-sigma))/(2*pi*fNominal)</td><td> </td>
</tr>
<tr>
<td>rotor stray inductance</td>
<td>Xr * (1 - sqrt(1-sigma))/(2*pi*fNominal)</td><td> </td>
</tr>
<tr>
<td>main field inductance per phase</td>
<td>sqrt(Xs*Xr * (1-sigma))/(2*pi*fNominal)</td><td> </td>
</tr>
</table>
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
            Modelica.Electrical.Machines.SpacePhasors.Components.SpacePhasor spacePhasorS annotation(Placement(visible=true, transformation(origin={0.0,30.0}, extent={{10.0,10.0},{-10.0,-10.0}}, rotation=-270)));
            Modelica.Electrical.Machines.BasicMachines.Components.AirGapS airGapS(final p=p, final Lm=Lm) annotation(Placement(visible=true, transformation(origin={0.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
            Modelica.Electrical.Machines.BasicMachines.Components.SquirrelCage squirrelCageR(final Lrsigma=Lrsigma, final Rr=Rr) annotation(Placement(visible=true, transformation(origin={0.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
          equation
            connect(airGapS.support,internalSupport) annotation(Line(visible=true, points={{-10.0,0.0},{-90.0,-0.0},{-90.0,-100.0},{20.0,-100.0}}));
            connect(airGapS.flange_a,inertiaRotor.flange_a) annotation(Line(visible=true, points={{10.0,0.0},{28.0,0.0},{28.0,-0.0},{60.0,0.0}}));
            connect(spacePhasorS.plug_n,plug_sn) annotation(Line(visible=true, points={{-10.0,40.0},{-10.0,60.0},{-60.0,60.0},{-60.0,100.0}}, color={0,0,255}));
            connect(rs.plug_p,plug_sp) annotation(Line(visible=true, points={{60.0,60.0},{60.0,100.0}}, color={0,0,255}));
            connect(rs.plug_n,lssigma.plug_p) annotation(Line(visible=true, points={{40.0,60.0},{30.0,60.0}}, color={0,0,255}));
            connect(lssigma.plug_n,spacePhasorS.plug_p) annotation(Line(visible=true, points={{10.0,60.0},{10.0,40.0}}, color={0,0,255}));
            connect(spacePhasorS.ground,spacePhasorS.zero) annotation(Line(visible=true, points={{-10.0,20.0},{-10.0,14.0},{-0.0,14.0},{0.0,20.0}}, color={0,0,255}));
            connect(spacePhasorS.spacePhasor,airGapS.spacePhasor_s) annotation(Line(visible=true, points={{10.0,20.0},{10.0,10.0}}, color={0,0,255}));
            connect(airGapS.spacePhasor_r,squirrelCageR.spacePhasor_r) annotation(Line(visible=true, points={{10.0,-10.0},{10.0,-20.0}}, color={0,0,255}));
          end AIM_SquirrelCage;

        end AsynchronousInductionMachines;

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
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          model AirGapS "Airgap in stator-fixed coordinate system"
            constant Integer m=3 "number of phases";
            parameter Integer p(min=1) "number of pole pairs";
            parameter Modelica.SIunits.Inductance Lm "main field inductance";
            output Modelica.SIunits.Torque tau_electrical;
            Modelica.SIunits.Angle gamma "Rotor displacement angle";
            Modelica.SIunits.Current i_ss[2] "Stator current space phasor with respect to the stator fixed frame";
            Modelica.SIunits.Current i_sr[2] "Stator current space phasor with respect to the rotor fixed frame";
            Modelica.SIunits.Current i_rs[2] "Rotor current space phasor with respect to the stator fixed frame";
            Modelica.SIunits.Current i_rr[2] "Rotor current space phasor with respect to the rotor fixed frame";
            Modelica.SIunits.Current i_ms[2] "Magnetizing current space phasor with respect to the stator fixed frame";
            Modelica.SIunits.MagneticFlux psi_ms[2] "Magnetizing flux phasor with respect to the stator fixed frame";
            Modelica.SIunits.MagneticFlux psi_mr[2] "Magnetizing flux phasor with respect to the rotor fixed frame";
            Real RotationMatrix[2,2] "matrix of rotation from rotor to stator";
            Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation(Placement(visible=true, transformation(origin={0.0,100.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0), iconTransformation(origin={0.0,100.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0)));
            Modelica.Mechanics.Rotational.Interfaces.Flange_a support "support at which the reaction torque is acting" annotation(Placement(visible=true, transformation(origin={0.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={0.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            Modelica.Electrical.Machines.Interfaces.SpacePhasor spacePhasor_s annotation(Placement(visible=true, transformation(origin={-100.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-100.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            Modelica.Electrical.Machines.Interfaces.SpacePhasor spacePhasor_r annotation(Placement(visible=true, transformation(origin={100.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={100.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-90.0,90.0},{90.0,-92.0}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-80.0,80.0},{80.0,-80.0}}),Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.VerticalCylinder, extent={{-10.0,90.0},{10.0,-80.0}}),Text(visible=true, lineColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-80.0,-40.0},{0.0,40.0}}, textString="S", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150.0,-150.0},{150.0,-90.0}}, textString="%name", fontName="Arial")}), Documentation(info="<HTML>
<p>
Model of the airgap in stator-fixed coordinate system, using only equations.
</p>
</HTML>"));
          protected
            parameter Modelica.SIunits.Inductance L[2,2]={{Lm,0},{0,Lm}} "inductance matrix";
          equation
            gamma=p*(flange_a.phi - support.phi);
            RotationMatrix={{+cos(gamma),-sin(gamma)},{+sin(gamma),+cos(gamma)}};
            i_ss=spacePhasor_s.i_;
            i_ss=RotationMatrix*i_sr;
            i_rr=spacePhasor_r.i_;
            i_rs=RotationMatrix*i_rr;
            i_ms=i_ss + i_rs;
            psi_ms=L*i_ms;
            psi_mr=transpose(RotationMatrix)*psi_ms;
            spacePhasor_s.v_=der(psi_ms);
            spacePhasor_r.v_=der(psi_mr);
            tau_electrical=m/2*p*(spacePhasor_s.i_[2]*psi_ms[1] - spacePhasor_s.i_[1]*psi_ms[2]);
            flange_a.tau=-tau_electrical;
            support.tau=tau_electrical;
          end AirGapS;

          model SquirrelCage "Squirrel Cage"
            parameter Modelica.SIunits.Inductance Lrsigma "rotor stray inductance per phase translated to stator";
            parameter Modelica.SIunits.Resistance Rr "warm rotor resistance per phase translated to stator";
            Modelica.Electrical.Machines.Interfaces.SpacePhasor spacePhasor_r annotation(Placement(visible=true, transformation(origin={-100.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-100.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-60.0,45.0},{-30.0,75.0}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-30.0,45.0},{0.0,75.0}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{0.0,45.0},{30.0,75.0}}),Ellipse(visible=true, lineColor={0,0,255}, extent={{30.0,45.0},{60.0,75.0}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-60.0,30.0},{60.0,60.0}}),Line(visible=true, points={{-100.0,60.0},{-60.0,60.0}}, color={0,0,255}),Line(visible=true, points={{60.0,60.0},{80.0,60.0},{80.0,40.0}}, color={0,0,255}),Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{60.0,40.0},{100.0,-40.0}}),Line(visible=true, points={{80.0,-40.0},{80.0,-60.0}}, color={0,0,255}),Line(visible=true, points={{60.0,-60.0},{100.0,-60.0}}, color={0,0,255}),Line(visible=true, points={{70.0,-80.0},{90.0,-80.0}}, color={0,0,255}),Line(visible=true, points={{66.0,-70.0},{94.0,-70.0}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150.0,-150.0},{150.0,-90.0}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-100.0,90.0},{-100.0,60.0}}, color={0,0,255})}), Documentation(info="<HTML>
<p>
Model of a squirrel cage / damper cage in two axis.
</p>
</HTML>"));
          equation
            spacePhasor_r.v_=Rr*spacePhasor_r.i_ + Lrsigma*der(spacePhasor_r.i_);
          end SquirrelCage;

        end Components;

      end BasicMachines;

      package Sensors "Sensors for machine modelling"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains sensors that are usefull when modelling machines.
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
  <li> v1.03 2004/09/24 Anton Haumer</li>
  <li> v1.1  2004/10/01 Anton Haumer<br>
       changed RotorAngle</li>
  <li> v1.4   2004/11/11 Anton Haumer<br>
       removed mechanical flange support, also in sensor RotorAngle<br>
       to ease the implementation of a 3D-frame in a future release</li>
  </ul>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-74.0,46.0},{66.0,-94.0}}),Line(visible=true, points={{-4.0,46.0},{-4.0,16.0}}),Line(visible=true, points={{18.9,8.8},{36.2,33.3}}),Line(visible=true, points={{-26.9,8.8},{-44.2,33.3}}),Line(visible=true, points={{33.6,-10.3},{61.8,-0.1}}),Line(visible=true, points={{-41.6,-10.3},{-69.8,-0.1}}),Line(visible=true, points={{-4.0,-24.0},{5.02,4.6}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-4.48,7.6},{14.0,2.0},{14.0,33.2},{-4.48,7.6}}),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{-9.0,-19.0},{1.0,-29.0}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        model CurrentRMSsensor
          constant Integer m(final min=1)=3 "number of phases";
          Modelica.Electrical.MultiPhase.Interfaces.PositivePlug plug_p(final m=m) annotation(Placement(visible=true, transformation(origin={-100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          Modelica.Electrical.MultiPhase.Interfaces.NegativePlug plug_n(final m=m) annotation(Placement(visible=true, transformation(origin={100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          Modelica.Electrical.MultiPhase.Sensors.CurrentSensor CurrentSensor1(final m=m) annotation(Placement(visible=true, transformation(origin={0.0,50.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70.0,70.0},{70.0,-70.0}}),Line(visible=true, points={{0.0,70.0},{0.0,40.0}}),Line(visible=true, points={{22.9,32.8},{40.2,57.3}}),Line(visible=true, points={{-22.9,32.8},{-40.2,57.3}}),Line(visible=true, points={{37.6,13.7},{65.8,23.9}}),Line(visible=true, points={{-37.6,13.7},{-65.8,23.9}}),Line(visible=true, points={{0.0,0.0},{9.02,28.6}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-0.48,31.6},{18.0,26.0},{18.0,57.2},{-0.48,31.6}}),Ellipse(visible=true, fillPattern=FillPattern.Solid, extent={{-5.0,5.0},{5.0,-5.0}}),Line(visible=true, points={{-90.0,0.0},{-70.0,0.0}}, color={0,0,255}),Line(visible=true, points={{70.0,0.0},{90.0,0.0}}, color={0,0,255}),Line(visible=true, points={{0.0,-70.0},{0.0,-100.0}}, color={0,0,255}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-40.0,-60.0},{40.0,-20.0}}, textString="A RMS", fontName="Arial")}), Documentation(info="<HTML>
<p>
Measured 3-phase instantaneous currents are transformed to the corresponding space phasor; <br>
output is length of the space phasor divided by sqrt(2), thus giving in sinusoidal stationary state RMS current.
</p>
</HTML>"));
          Modelica.Electrical.Machines.SpacePhasors.Blocks.ToSpacePhasor ToSpacePhasor1 annotation(Placement(visible=true, transformation(origin={0.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
          Modelica.Electrical.Machines.SpacePhasors.Blocks.ToPolar ToPolar1 annotation(Placement(visible=true, transformation(origin={0.0,-30.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
          Modelica.Blocks.Math.Gain Gain1(final k=1/sqrt(2)) annotation(Placement(visible=true, transformation(origin={-0.0,-70.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
          Modelica.Blocks.Interfaces.RealOutput I(redeclare type SignalType= Modelica.SIunits.Current ) annotation(Placement(visible=true, transformation(origin={0.0,-110.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90), iconTransformation(origin={0.0,-110.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=-90)));
        equation
          connect(ToSpacePhasor1.y,ToPolar1.u) annotation(Line(visible=true, origin={0.0,-9.5}, points={{0.0,8.5},{0.0,-8.5}}, color={0,0,255}));
          connect(CurrentSensor1.i,ToSpacePhasor1.u) annotation(Line(visible=true, points={{0.0,39.0},{0.0,22.0},{0.0,22.0}}, color={0,0,255}));
          connect(ToPolar1.y[1],Gain1.u) annotation(Line(visible=true, origin={0.0,-49.5}, points={{0.0,8.5},{0.0,-8.5}}, color={0,0,255}));
          connect(CurrentSensor1.plug_n,plug_n) annotation(Line(visible=true, points={{10.0,50.0},{100.0,50.0},{100.0,0.0}}, color={0,0,255}));
          connect(plug_p,CurrentSensor1.plug_p) annotation(Line(visible=true, points={{-100.0,0.0},{-100.0,50.0},{-10.0,50.0}}, color={0,0,255}));
          connect(Gain1.y,I) annotation(Line(visible=true, points={{-0.0,-81.0},{0.0,-91.5},{0.0,-91.5},{0.0,-110.0}}, color={0,0,255}));
        end CurrentRMSsensor;

      end Sensors;

      package SpacePhasors "Library with space phasor-models"
        extends Modelica.Icons.Library2;
        annotation(Documentation(info="<HTML>
<p>
This package contains components, blocks and functions to utilize space phasor theory.
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
  <li> v1.30 2004/11/05 Anton Haumer<br>
       several improvements in SpacePhasors.Blocks</li>
  <li> v1.60 2005/11/03 Anton Haumer<br>
       added Components.Rotator</li>
  <li> v1.6.1 2005/11/10 Anton Haumer<br>
       improved Transformation and Rotation</li>
  </ul>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-8.0,-26.0},{64.0,46.0},{44.0,38.0},{56.0,26.0},{64.0,46.0}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-8.0,-26.0},{64.0,-98.0},{56.0,-78.0},{44.0,-90.0},{64.0,-98.0}}, color={0,0,255}, thickness=0.5)}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        package Components "Basic space phasor models"
          extends Modelica.Icons.Library;
          annotation(Documentation(info="<HTML>
<p>
This package contains basic space phasor models:
<ul>
<li>SpacePhasor: physical transformation of voltages and currents three phase <-> space phasors</li>
</ul>
Real and imaginary part of voltage space phasor are the potentials v_[2] of the space phasor connector; (implicit grounded).<br>
Real and imaginary part of current space phasor are the currents i_[2] at the space phasor connector;
a ground has to be used where necessary for currents flowing back.<br>
Zero-sequence voltage and current are present at pin zero. An additional zero-sequence impedance could be connected between pin zero and pin ground.
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
  <li> v1.60 2005/11/03 Anton Haumer<br>
       added Rotator</li>
  <li> v1.6.1 2005/11/10 Anton Haumer<br>
       improved Transformation and Rotation</li>
  </ul>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          model SpacePhasor "Physical transformation: three phase <-> space phasors"
            constant Integer m=3 "number of phases";
            constant Real pi=Modelica.Constants.pi;
            Modelica.SIunits.Voltage v[m] "instantaneous phase voltages";
            Modelica.SIunits.Current i[m] "instantaneous phase currents";
            Modelica.Electrical.MultiPhase.Interfaces.PositivePlug plug_p(final m=m) annotation(Placement(visible=true, transformation(origin={-100.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-100.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            Modelica.Electrical.MultiPhase.Interfaces.NegativePlug plug_n(final m=m) annotation(Placement(visible=true, transformation(origin={-100.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-100.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            Modelica.Electrical.Analog.Interfaces.PositivePin zero annotation(Placement(visible=true, transformation(origin={100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            Modelica.Electrical.Analog.Interfaces.NegativePin ground annotation(Placement(visible=true, transformation(origin={100.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={100.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            Modelica.Electrical.Analog.Basic.Ground gnd annotation(Placement(visible=true, transformation(origin={70.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
            annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<HTML>
<p>
Physical transformation of voltages and currents: three phases <-> space phasors:<br>
x[k] = X0 + {cos(-(k - 1)/m*2*pi),-sin(-(k - 1)/m*2*pi) * X[Re,Im]<br>
and vice versa:<br>
X0 = sum(x[k])/m<br>
X[Re,Im] = sum(2/m*{cos((k - 1)/m*2*pi),sin((k - 1)/m*2*pi)}*x[k])<br>
were x designates three phase values, X[Re,Im] designates the space phasor and X0 designates the zero sequence system.<br>
<i>Physcial transformation</i> means that both voltages and currents are transformed in both directions.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={35.0,35.0}, points={{-35.0,-35.0},{35.0,35.0}}, color={0,0,255}, arrowSize=20),Line(visible=true, origin={35.0,-35.0}, points={{-35.0,35.0},{35.0,-35.0}}, color={0,0,255}, arrowSize=20),Line(visible=true, origin={-30.0,0.0}, points={{-40.0,0.0},{-20.0,30.0},{0.0,0.0},{20.0,-30.0},{40.0,0.0}}, color={0,0,255}, smooth=Smooth.Bezier),Line(visible=true, origin={-40.0,0.0}, points={{-40.0,0.0},{-20.0,30.0},{0.0,0.0},{20.0,-30.0},{40.0,0.0}}, color={0,0,255}, smooth=Smooth.Bezier),Line(visible=true, origin={-50.0,0.0}, points={{-40.0,0.0},{-20.0,30.0},{0.0,0.0},{20.0,-30.0},{40.0,0.0}}, color={0,0,255}, smooth=Smooth.Bezier),Polygon(visible=true, origin={70.0,-70.0}, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-10.0,0.0},{0.0,10.0},{10.0,-10.0}}),Polygon(visible=true, origin={70.0,70.0}, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-10.0,0.0},{0.0,-10.0},{10.0,10.0}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150.0,110.0},{150.0,150.0}}, textString="%name", fontName="Arial")}));
            Modelica.Electrical.Machines.Interfaces.SpacePhasor spacePhasor annotation(Placement(visible=true, transformation(origin={0.0,0.0}, extent={{90.0,90.0},{110.0,110.0}}, rotation=0), iconTransformation(origin={0.0,0.0}, extent={{90.0,90.0},{110.0,110.0}}, rotation=0)));
          protected
            parameter Real TransformationMatrix[2,m]=2/m*{array(cos(+(k - 1)/m*2*pi) for k in 1:m),array(+sin(+(k - 1)/m*2*pi) for k in 1:m)};
            parameter Real InverseTransformation[m,2]=array({cos(-(k - 1)/m*2*pi),-sin(-(k - 1)/m*2*pi)} for k in 1:m);
          equation
            connect(gnd.p,ground) annotation(Line(visible=true, points={{70.0,-90.0},{100.0,-90.0},{100.0,-100.0}}, color={0,0,255}));
            v=plug_p.pin.v - plug_n.pin.v;
            i=+plug_p.pin.i;
            i=-plug_n.pin.i;
            zero.v=1/m*sum(v);
            spacePhasor.v_=TransformationMatrix*v;
            -zero.i=1/m*sum(i);
            -spacePhasor.i_=TransformationMatrix*i;
          end SpacePhasor;

        end Components;

        package Blocks "Blocks for space phasor transformation"
          extends Modelica.Icons.Library;
          annotation(Documentation(info="<HTML>
<p>
This package contains space phasor transformation blocks for use in controllers:
<ul>
<li>ToSpacePhasor: transforms a set of threephase values to space phasor and zero sequence system</li>
<li>FromSpacePhasor: transforms a space phasor and zero sequence system to a set of threephase values</li>
<li>Rotator: rotates a space phasor (from one coordinate system into another)</li>
<li>ToPolar: Converts a space phasor from rectangular coordinates to polar coordinates</li>
<li>FromPolar: Converts a space phasor from polar coordinates to rectangular coordinates</li>
</ul>
</p>

</HTML>", revisions="<HTML>
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
  <li> v1.30 2004/11/05 Anton Haumer<br>
       several improvements in SpacePhasors.Blocks</li>
  <li> v1.6.1 2005/11/10 Anton Haumer<br>
       improved Transformation and Rotation</li>
  </ul>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
          block ToSpacePhasor "Conversion: three phase -> space phasor"
            extends Modelica.Blocks.Interfaces.MIMO(final nin=m, final nout=2);
            constant Integer m=3 "number of phases";
            constant Real pi=Modelica.Constants.pi;
            Modelica.Blocks.Interfaces.RealOutput zero annotation(Placement(visible=true, transformation(origin={110.0,-80.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0), iconTransformation(origin={110.0,-80.0}, extent={{-10.0,10.0},{10.0,-10.0}}, rotation=0)));
            annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<HTML>
<p>
Transformation of threephase values (voltages or currents) to space phasor and zero sequence value.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={35.0,35.0}, points={{-35.0,-35.0},{35.0,35.0}}, color={0,0,255}, arrowSize=20),Line(visible=true, origin={35.0,-35.0}, points={{-35.0,35.0},{35.0,-35.0}}, color={0,0,255}, arrowSize=20),Line(visible=true, origin={-30.0,0.0}, points={{-40.0,0.0},{-20.0,30.0},{0.0,0.0},{20.0,-30.0},{40.0,0.0}}, color={0,0,255}, smooth=Smooth.Bezier),Line(visible=true, origin={-40.0,0.0}, points={{-40.0,0.0},{-20.0,30.0},{0.0,0.0},{20.0,-30.0},{40.0,0.0}}, color={0,0,255}, smooth=Smooth.Bezier),Line(visible=true, origin={-50.0,0.0}, points={{-40.0,0.0},{-20.0,30.0},{0.0,0.0},{20.0,-30.0},{40.0,0.0}}, color={0,0,255}, smooth=Smooth.Bezier),Polygon(visible=true, origin={70.0,-70.0}, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-10.0,0.0},{0.0,10.0},{10.0,-10.0}}),Polygon(visible=true, origin={70.0,70.0}, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{-10.0,0.0},{0.0,-10.0},{10.0,10.0}})}));
          protected
            parameter Real TransformationMatrix[2,m]=2/m*{array(cos(+(k - 1)/m*2*pi) for k in 1:m),array(+sin(+(k - 1)/m*2*pi) for k in 1:m)};
            parameter Real InverseTransformation[m,2]=array({cos(-(k - 1)/m*2*pi),-sin(-(k - 1)/m*2*pi)} for k in 1:m);
          equation
            zero=1/m*sum(u);
            y=TransformationMatrix*u;
          end ToSpacePhasor;

          block ToPolar "Converts a space phasor to polar coordinates"
            extends Modelica.Blocks.Interfaces.MIMOs(final n=2);
            constant Real small=Modelica.Constants.small;
            annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<HTML>
<p>
Converts a space phasor from rectangular coordinates to polar coordinates.
</p>
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-60.0,60.0},{-60.0,-60.0},{60.0,-60.0}}, color={0,0,255}),Line(visible=true, points={{-100.0,-100.0},{100.0,100.0}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, points={{26.0,26.0},{14.0,20.0},{20.0,14.0},{26.0,26.0}}),Line(visible=true, points={{-18.0,-18.0},{-14.0,-22.0},{-10.0,-28.0},{-6.0,-34.0},{-2.0,-44.0},{0.0,-52.0},{0.0,-60.0}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, points={{-18.0,-18.0},{-14.0,-26.0},{-10.0,-22.0},{-18.0,-18.0}}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-100.0,-6.0},{-6.0,100.0}}, textString="R", fontName="Arial"),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{6.0,-100.0},{100.0,6.0}}, textString="P", fontName="Arial")}));
          equation
            y[1]=sqrt(u[1]^2 + u[2]^2);
            y[2]=if noEvent(y[1] <= small) then 0 else Modelica.Math.atan2(u[2], u[1]);
          end ToPolar;

        end Blocks;

      end SpacePhasors;

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
</HTML>"), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{-70.0,-30.0},{-10.0,30.0},{50.0,-30.0},{-10.0,-90.0},{-70.0,-30.0}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        connector SpacePhasor "Connector for Space Phasors"
          Modelica.SIunits.Voltage v_[2];
          flow Modelica.SIunits.Current i_[2];
          annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{0.0,100.0},{-100.0,0.0},{0.0,-100.0},{100.0,0.0},{0.0,100.0}}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150.0,-150.0},{150.0,-90.0}}, textString="%name", fontName="Arial")}), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{0.0,100.0},{-100.0,0.0},{0.0,-100.0},{100.0,0.0},{0.0,100.0}})}), Documentation(info="<HTML>
<p>
Connector for Space Phasors:
<ul>
<li>Voltage v_[2] ... Real and Imaginary part of voltage space phasor</li>
<li>Current i_[2] ... Real and Imaginary part of current space phasor</li>
</ul>
</p>
</HTML>"));
        end SpacePhasor;

        partial model PartialBasicMachine "Partial machine model"
          parameter Modelica.SIunits.Inertia J_Rotor "rotor's moment of inertia";
          output Modelica.SIunits.Angle phi_mechanical=flange_a.phi "mechanical angle of rotor against stator";
          output Modelica.SIunits.AngularVelocity w_mechanical=der(phi_mechanical) "mechanical angular velocity of rotor against stator";
          output Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm rpm_mechanical=Modelica.SIunits.Conversions.to_rpm(w_mechanical) "mechanical speed of rotor against stator [rpm]";
          output Modelica.SIunits.Torque tau_electrical=inertiaRotor.flange_a.tau "electromagnetic torque";
          output Modelica.SIunits.Torque tau_shaft=-flange_a.tau "shaft torque";
          Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation(Placement(visible=true, transformation(origin={100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          Modelica.Mechanics.Rotational.Inertia inertiaRotor(final J=J_Rotor) annotation(Placement(visible=true, transformation(origin={70.0,0.0}, extent={{10.0,10.0},{-10.0,-10.0}}, rotation=180)));
          Modelica.Mechanics.Rotational.Fixed fixedHousing(final phi0=0) annotation(Placement(visible=true, transformation(origin={40.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={0,127,255}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40.0,60.0},{80.0,-60.0}}),Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.HorizontalCylinder, extent={{-40.0,60.0},{-60.0,-60.0}}),Rectangle(visible=true, fillColor={128,128,128}, fillPattern=FillPattern.HorizontalCylinder, extent={{80.0,10.0},{100.0,-10.0}}),Rectangle(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, extent={{-40.0,70.0},{40.0,50.0}}),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{-50.0,-90.0},{-40.0,-90.0},{-10.0,-20.0},{40.0,-20.0},{70.0,-90.0},{80.0,-90.0},{80.0,-100.0},{-50.0,-100.0},{-50.0,-90.0}}),Text(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150.0,-180.0},{150.0,-120.0}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        protected
          Modelica.Mechanics.Rotational.Interfaces.Flange_b internalSupport annotation(Placement(visible=true, transformation(origin={20.0,-100.0}, extent={{-1.0,-1.0},{1.0,1.0}}, rotation=0)));
          annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-40,60},{80,-60}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={0,127,255}),Rectangle(extent={{-40,60},{-60,-60}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={128,128,128}),Rectangle(extent={{80,10},{100,-10}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={128,128,128}),Rectangle(extent={{-40,70},{40,50}}, fillPattern=FillPattern.Solid, lineColor={128,128,128}, fillColor={128,128,128}),Polygon(points={{-50,-90},{-40,-90},{-10,-20},{40,-20},{70,-90},{80,-90},{80,-100},{-50,-100},{-50,-90}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-150,-120},{150,-180}}, fillColor={0,0,255}, textString="%name")}), Documentation(info="<HTML>
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
          connect(internalSupport,fixedHousing.flange_b) annotation(Line(visible=true, points={{20.0,-100.0},{40.0,-100.0}}));
          connect(inertiaRotor.flange_b,flange_a) annotation(Line(visible=true, points={{80.0,0.0},{92.0,0.0},{92.0,0.0},{100.0,0.0}}));
        end PartialBasicMachine;

        partial model PartialBasicInductionMachine "Partial model for induction machine"
          extends PartialBasicMachine(J_Rotor=0.29);
          constant Real pi=Modelica.Constants.pi;
          constant Integer m=3 "number of phases";
          parameter Integer p(min=1)=2 "number of pole pairs (Integer)";
          output Modelica.SIunits.Voltage vs[m]=plug_sp.pin.v - plug_sn.pin.v "stator instantaneous voltages";
          output Modelica.SIunits.Current is[m]=plug_sp.pin.i "stator instantaneous currents";
          Modelica.Electrical.MultiPhase.Interfaces.PositivePlug plug_sp(final m=m) annotation(Placement(visible=true, transformation(origin={60.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={60.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          Modelica.Electrical.MultiPhase.Interfaces.NegativePlug plug_sn(final m=m) annotation(Placement(visible=true, transformation(origin={-60.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-60.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
          annotation(Documentation(info="<HTML>
<p>
Partial model for induction machine models, containing:
<ul>
<li>main parts of the icon</li>
<li>stator plugs</li>
<li>mechanical connectors</li>
</ul>
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-50.0,100.0},{-20.0,100.0},{-20.0,70.0}}, color={0,0,255}),Line(visible=true, points={{50.0,100.0},{20.0,100.0},{20.0,70.0}}, color={0,0,255})}));
        end PartialBasicInductionMachine;

      end Interfaces;

    end Machines;

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
      package StateSelection "Type, constants and menu choices to define state selection of variables"
        annotation(Documentation(info="<html>

</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        extends Modelica.Icons.Enumeration;
        constant Integer Never=1 "Never (never use as state)";
        constant Integer Avoid=2 "Avoid (avoid to use as state)";
        constant Integer Default=3 "Default (default behaviour)";
        constant Integer Prefer=4 "Prefer (use as state if possible)";
        constant Integer Always=5 "Always (always use as state)";
        type Temp "Temporary type of state selection with choices for menus (until enumerations are available)"
          extends Modelica.Icons.TypeInteger(min=1, max=5);
          annotation(Evaluate=true, choices(choice=Modelica.Blocks.Types.StateSelection.Never "Never (never use as state)", choice=Modelica.Blocks.Types.StateSelection.Avoid "Avoid (avoid to use as state)", choice=Modelica.Blocks.Types.StateSelection.Default "Default (default behaviour)", choice=Modelica.Blocks.Types.StateSelection.Prefer "Prefer (use as state if possible)", choice=Modelica.Blocks.Types.StateSelection.Always "Always (always use as state)"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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

      block BooleanStep "Generate step signal of type Boolean"
        parameter Modelica.SIunits.Time startTime=0 "Time instant of step start";
        parameter Boolean startValue=false "Output before startTime";
        extends Interfaces.partialBooleanSource;
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-70},{0,-70},{0,50},{80,50}}),Text(visible=true, extent={{-150,-140},{150,-110}}, textString="%startTime", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-70},{0,-70},{0,50},{80,50}}, thickness=0.5),Text(visible=true, extent={{-25,-94},{21,-76}}, textString="startTime", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, pattern=LinePattern.Dash, points={{2,50},{-80,50},{2,50}}),Text(visible=true, extent={{-130,42},{-86,56}}, textString="not startValue", fontName="Arial"),Text(visible=true, extent={{-126,-78},{-94,-64}}, textString="startValue", fontName="Arial")}), Documentation(info="<html>

</html>"));
      equation
        y=if time >= startTime then not startValue else startValue;
      end BooleanStep;

    end Sources;

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

    end Math;

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

      partial block MIMOs "Multiple Input Multiple Output continuous control block with same number of inputs and outputs"
        extends BlockIcon;
        parameter Integer n=1 "Number of inputs (= number of outputs)";
        annotation(Documentation(info="<HTML>
<p>
Block has a continuous Real input and a continuous Real output signal vector
where the signal sizes of the input and output vector are identical.
</p>
</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
        RealInput u[n] "Connector of Real input signals" annotation(Placement(visible=true, transformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0), iconTransformation(origin={-120,0}, extent={{-20,-20},{20,20}}, rotation=0)));
        RealOutput y[n] "Connector of Real output signals" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
      end MIMOs;

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
        type AngularVelocity_rpm= Real(final quantity="AngularVelocity", final unit="rev/min") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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

      function to_rpm "Convert from radian per second to revolutions per minute"
        extends ConversionIcon;
        input AngularVelocity rs "radian per second value";
        output NonSIunits.AngularVelocity_rpm rpm "revolutions per minute value";
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-100,20},{-20,100}}, textString="rad/s", fontName="Arial"),Text(visible=true, extent={{20,-100},{100,-20}}, textString="rev/min", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      algorithm
        rpm:=30/Modelica.Constants.pi*rs;
      end to_rpm;

      function from_rpm "Convert from revolutions per minute to radian per second"
        extends ConversionIcon;
        input NonSIunits.AngularVelocity_rpm rpm "revolutions per minute value";
        output AngularVelocity rs "radian per second value";
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-100,20},{-20,100}}, textString="rev/min", fontName="Arial"),Text(visible=true, extent={{20,-100},{100,-20}}, textString="rad/s", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      algorithm
        rs:=Modelica.Constants.pi/30*rpm;
      end from_rpm;

      partial function ConversionIcon "Base icon for conversion functions"
        annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={191,0,0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Line(visible=true, points={{-90,0},{30,0}}, color={191,0,0}),Polygon(visible=true, lineColor={191,0,0}, fillColor={191,0,0}, fillPattern=FillPattern.Solid, points={{90,0},{30,20},{30,-20},{90,0}}),Text(visible=true, extent={{-115,105},{115,155}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
      end ConversionIcon;

    end Conversions;

    type Angle= Real(final quantity="Angle", final unit="rad", displayUnit="deg") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Time= Real(final quantity="Time", final unit="s") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type AngularVelocity= Real(final quantity="AngularVelocity", final unit="rad/s", displayUnit="rev/min") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type AngularAcceleration= Real(final quantity="AngularAcceleration", final unit="rad/s2") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Velocity= Real(final quantity="Velocity", final unit="m/s") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Acceleration= Real(final quantity="Acceleration", final unit="m/s2") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Frequency= Real(final quantity="Frequency", final unit="Hz") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type MomentOfInertia= Real(final quantity="MomentOfInertia", final unit="kg.m2") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Inertia= MomentOfInertia annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Torque= Real(final quantity="Torque", final unit="N.m") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type ElectricCurrent= Real(final quantity="ElectricCurrent", final unit="A") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Current= ElectricCurrent annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type ElectricPotential= Real(final quantity="ElectricPotential", final unit="V") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Voltage= ElectricPotential annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type MagneticFlux= Real(final quantity="MagneticFlux", final unit="Wb") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Inductance= Real(final quantity="Inductance", final unit="H") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Resistance= Real(final quantity="Resistance", final unit="Ohm") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    type Conductance= Real(final quantity="Conductance", final unit="S") annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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

    partial class Enumeration "Icon for an enumeration (emulated by a package)"
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-138,104},{138,164}}, textString="%name", fontName="Arial"),Ellipse(visible=true, lineColor={255,0,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Text(visible=true, fillColor={255,0,127}, extent={{-100,-100},{100,100}}, textString="e", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end Enumeration;

    type TypeInteger "Icon for an Integer type"
      extends Integer;
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Text(visible=true, extent={{-94,-94},{94,94}}, textString="I", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    end TypeInteger;

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
model Modelica_Electrical_Machines_Examples_AIMC_DOL
  extends Modelica.Electrical.Machines.Examples.AIMC_DOL;
end Modelica_Electrical_Machines_Examples_AIMC_DOL;
