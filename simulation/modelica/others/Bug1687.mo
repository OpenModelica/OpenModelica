package Modelica "Modelica Standard Library (Version 3.1)"
extends Modelica.Icons.Library;

  package Blocks
  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;

    package Interfaces
    "Library of connectors and partial models for input/output blocks"
      import Modelica.SIunits;
        extends Modelica.Icons.Library;

    connector RealInput = input Real "'input Real' as connector"
      annotation (defaultComponentName="u",
      Icon(graphics={Polygon(
              points={{-100,100},{100,0},{-100,-100},{-100,100}},
              lineColor={0,0,127},
              fillColor={0,0,127},
              fillPattern=FillPattern.Solid)},
           coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.2)),
      Diagram(coordinateSystem(
            preserveAspectRatio=true, initialScale=0.2,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={Polygon(
              points={{0,50},{100,0},{0,-50},{0,50}},
              lineColor={0,0,127},
              fillColor={0,0,127},
              fillPattern=FillPattern.Solid), Text(
              extent={{-10,85},{-10,60}},
              lineColor={0,0,127},
              textString="%name")}),
        Documentation(info="<html>
<p>
Connector with one input signal of type Real.
</p>
</html>"));

    connector RealOutput = output Real "'output Real' as connector"
      annotation (defaultComponentName="y",
      Icon(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={Polygon(
              points={{-100,100},{100,0},{-100,-100},{-100,100}},
              lineColor={0,0,127},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}),
      Diagram(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={Polygon(
              points={{-100,50},{0,0},{-100,-50},{-100,50}},
              lineColor={0,0,127},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid), Text(
              extent={{30,110},{30,60}},
              lineColor={0,0,127},
              textString="%name")}),
        Documentation(info="<html>
<p>
Connector with one output signal of type Real.
</p>
</html>"));
        annotation (
          Documentation(info="<HTML>
<p>
This package contains interface definitions for
<b>continuous</b> input/output blocks with Real,
Integer and Boolean signals. Furthermore, it contains
partial models for continuous and discrete blocks.
</p>

</HTML>
",     revisions="<html>
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
"));
    end Interfaces;
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
        graphics={
        Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
        Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
        Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
        Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),
        Polygon(
          points={{16,-71},{29,-67},{29,-74},{16,-71}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-32,-21},{-46,-17},{-46,-25},{-32,-21}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid)}),
                            Documentation(info="<html>
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
<p>
Copyright &copy; 1998-2009, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense2\">here</a>.</i>
</p>
</HTML>
",   revisions="<html>
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
</html>"));
  end Blocks;

  package Mechanics
  "Library of 1-dim. and 3-dim. mechanical components (multi-body, rotational, translational)"
  extends Modelica.Icons.Library2;

    package Translational
    "Library to model 1-dimensional, translational mechanical systems"
      extends Modelica.Icons.Library2;
      import SI = Modelica.SIunits;

      package Components
      "Components for 1D translational mechanical drive trains"
        extends Modelica.Icons.Library2;

        model Fixed "Fixed flange"
          parameter SI.Position s0=0 "fixed offset position of housing";

          Interfaces.Flange_b flange   annotation (Placement(transformation(
                origin={0,0},
                extent={{-10,10},{10,-10}},
                rotation=180)));
        equation
          flange.s = s0;
          annotation (
            Icon(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Line(points={{-80,-40},{80,-40}}, color={0,0,0}),
                Line(points={{80,-40},{40,-80}}, color={0,0,0}),
                Line(points={{40,-40},{0,-80}}, color={0,0,0}),
                Line(points={{0,-40},{-40,-80}}, color={0,0,0}),
                Line(points={{-40,-40},{-80,-80}}, color={0,0,0}),
                Line(points={{0,-40},{0,-10}}, color={0,0,0}),
                Text(
                  extent={{0,-90},{0,-150}},
                  textString="%name",
                  lineColor={0,0,255})}),
            Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics),
            Documentation(info="<html>
<p>
The <i>flange</i> of a 1D translational mechanical system <i>fixed</i>
at an position s0 in the <i>housing</i>. May be used:
</p>
<ul>
<li> to connect a compliant element, such as a spring or a damper,
     between a sliding mass and the housing.
<li> to fix a rigid element, such as a sliding mass, at a specific
     position.
</ul>

</HTML>
"));
        end Fixed;

        model Spring "Linear 1D translational spring"
          extends Translational.Interfaces.PartialCompliant;
          parameter SI.TranslationalSpringConstant c(final min=0, start = 1)
          "spring constant ";
          parameter SI.Distance s_rel0=0 "unstretched spring length";

        equation
          f = c*(s_rel - s_rel0);
          annotation (
            Documentation(info="<html>
<p>
A <i>linear 1D translational spring</i>. The component can be connected either
between two sliding masses, or between
a sliding mass and the housing (model Fixed), to describe
a coupling of the sliding mass with the housing via a spring.
</p>

</HTML>
"),         Icon(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Line(points={{-60,-90},{20,-90}}, color={0,0,0}),
                Polygon(
                  points={{50,-90},{20,-80},{20,-100},{50,-90}},
                  lineColor={128,128,128},
                  fillColor={128,128,128},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{0,110},{0,50}},
                  textString="%name",
                  lineColor={0,0,255}),
                Line(points={{-86,0},{-60,0},{-44,-30},{-16,30},{14,-30},{44,30},{
                      60,0},{84,0}}, color={0,0,0})}),
            Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Line(points={{-100,0},{-100,65}}, color={128,128,128}),
                Line(points={{100,0},{100,65}}, color={128,128,128}),
                Line(points={{-100,60},{100,60}}, color={128,128,128}),
                Polygon(
                  points={{90,63},{100,60},{90,57},{90,63}},
                  lineColor={128,128,128},
                  fillColor={128,128,128},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-22,62},{18,87}},
                  lineColor={0,0,255},
                  textString="s_rel"),
                Line(points={{-86,0},{-60,0},{-44,-30},{-16,30},{14,-30},{44,30},{
                      60,0},{84,0}}, color={0,0,0})}));
        end Spring;

        model MassWithStopAndFriction
        "Sliding mass with hard stop and Stribeck friction"
          extends PartialFrictionWithStop;
          SI.Velocity v(start=0, stateSelect = StateSelect.always)
          "Absolute velocity of flange_a and flange_b";
          SI.Acceleration a(start=0)
          "Absolute acceleration of flange_a and flange_b";
          parameter Modelica.SIunits.Mass m(start=1) "mass";
          parameter Real F_prop(final unit="N.s/m", final min=0, start = 1)
          "Velocity dependent friction";
          parameter Modelica.SIunits.Force F_Coulomb(start=5)
          "Constant friction: Coulomb force";
          parameter Modelica.SIunits.Force F_Stribeck(start=10)
          "Stribeck effect";
          parameter Real fexp(final unit="s/m", final min=0, start = 2)
          "Exponential decay";
          Integer stopped = if s <= smin + L/2 then -1 else if s >= smax - L/2 then +1 else 0;
        encapsulated partial model PartialFrictionWithStop
          "Base model of Coulomb friction elements with stop"

            import SI = Modelica.SIunits;
            import Modelica.Mechanics.Translational.Interfaces.PartialRigid;
          parameter SI.Position smax(start= 25)
            "Right stop for (right end of) sliding mass";
          parameter SI.Position smin(start=-25)
            "Left stop for (left end of) sliding mass";
          parameter SI.Velocity v_small=1e-3
            "Relative velocity near to zero (see model info text)"
             annotation(Dialog(tab="Advanced"));
        // Equations to define the following variables have to be defined in subclasses
          SI.Velocity v_relfric "Relative velocity between frictional surfaces";
          SI.Acceleration a_relfric
            "Relative acceleration between frictional surfaces";
          SI.Force f
            "Friction force (positive, if directed in opposite direction of v_rel)";
          SI.Force f0 "Friction force for v=0 and forward sliding";
          SI.Force f0_max "Maximum friction force for v=0 and locked";
          Boolean free "true, if frictional element is not active";
        // Equations to define the following variables are given in this class
          Real sa(unit="1")
            "Path parameter of friction characteristic f = f(a_relfric)";
          Boolean startForward(start=false, fixed=true)
            "= true, if v_rel=0 and start of forward sliding or v_rel > v_small";
          Boolean startBackward(start=false, fixed=true)
            "= true, if v_rel=0 and start of backward sliding or v_rel < -v_small";
          Boolean locked(start=false) "true, if v_rel=0 and not sliding";
          extends PartialRigid(s(start=0, stateSelect = StateSelect.always));
          constant Integer Unknown=3 "Value of mode is not known";
          constant Integer Free=2 "Element is not active";
          constant Integer Forward=1 "v_rel > 0 (forward sliding)";
          constant Integer Stuck=0
            "v_rel = 0 (forward sliding, locked or backward sliding)";
          constant Integer Backward=-1 "v_rel < 0 (backward sliding)";
          Integer mode(
            final min=Backward,
            final max=Unknown,
            start=Unknown, fixed=true);
        protected
          constant SI.Acceleration unitAcceleration = 1 annotation(HideResult=true);
          constant SI.Force unitForce = 1 annotation(HideResult=true);
        equation
        /* Friction characteristic
   (locked is introduced to help the Modelica translator determining
   the different structural configurations,
   if for each configuration special code shall be generated)
*/
          startForward = pre(mode) == Stuck and (sa > f0_max/unitForce and s < (smax - L/2) or
                pre(startForward) and sa > f0/unitForce and s < (smax - L/2)) or pre(mode)
             == Backward and v_relfric > v_small or initial() and (v_relfric > 0);
          startBackward = pre(mode) == Stuck and (sa < -f0_max/unitForce and s > (smin + L/2) or
                pre(startBackward) and sa < -f0/unitForce and s > (smin + L/2)) or pre(mode)
             == Forward and v_relfric < -v_small or initial() and (v_relfric < 0);
          locked = not free and
            not (pre(mode) == Forward or startForward or pre(mode) == Backward or startBackward);

          a_relfric/unitAcceleration = if locked then               0 else
                                       if free then                 sa else
                                       if startForward then         sa - f0_max/unitForce else
                                       if startBackward then        sa + f0_max/unitForce else
                                       if pre(mode) == Forward then sa - f0_max/unitForce else
                                                                    sa + f0_max/unitForce;

        /* Friction torque has to be defined in a subclass. Example for a clutch:
   f = if locked then sa else
       if free then   0 else
       cgeo*fn*(if startForward then          Math.tempInterpol1( v_relfric, mue_pos, 2) else
                if startBackward then        -Math.tempInterpol1(-v_relfric, mue_pos, 2) else
                if pre(mode) == Forward then  Math.tempInterpol1( v_relfric, mue_pos, 2) else
                                             -Math.tempInterpol1(-v_relfric, mue_pos, 2));
*/
        // finite state machine to determine configuration
          mode = if free then Free else
            (if (pre(mode) == Forward  or pre(mode) == Free or startForward)  and v_relfric > 0 and s < (smax - L/2) then
               Forward else
             if (pre(mode) == Backward or pre(mode) == Free or startBackward) and v_relfric < 0 and s > (smin + L/2) then
               Backward else
               Stuck);
          annotation (Documentation(info="<html>
<p>
Basic model for Coulomb friction that models the stuck phase in a reliable way.<br>
Additionally, a left and right stop are handled.
</p>
</html>
"));
        end PartialFrictionWithStop;
        equation
          // Constant auxiliary variables
          f0 = (F_Coulomb + F_Stribeck);
          f0_max = f0*1.001;
          free = f0 <= 0 and F_prop <= 0 and s > smin + L/2 and s < smax - L/2;
          // Velocity and acceleration of flanges
          v = der(s);
          a = der(v);
          v_relfric = v;
          a_relfric = a;
        // Equilibrium of forces
          0 = flange_a.f + flange_b.f - f - m*der(v);
        // Friction force
          f = if locked then sa*unitForce else
              if free then   0 else
                            (if startForward then         F_prop*v + F_Coulomb + F_Stribeck else
                             if startBackward then        F_prop*v - F_Coulomb - F_Stribeck else
                             if pre(mode) == Forward then F_prop*v + F_Coulomb + F_Stribeck*exp(-fexp*abs(v)) else
                                                          F_prop*v - F_Coulomb - F_Stribeck*exp(-fexp*abs(v)));
        // Define events for hard stops and reinitiliaze the state variables velocity v and position s
        algorithm
          when (initial()) then
            assert(s > smin + L/2 or s >= smin + L/2 and v >= 0,
              "Error in initialization of hard stop. (s - L/2) must be >= smin ");
            assert(s < smax - L/2 or s <= smax - L/2 and v <= 0,
              "Error in initialization of hard stop. (s + L/2) must be <= smax ");
          end when;
          when stopped <> 0 then
            reinit(s, if stopped < 0 then smin + L/2 else smax - L/2);
            if (not initial() or stopped*v>0) then
              reinit(v, 0);
            end if;
          end when;
        /*
  when not (s < smax - L/2) then
    reinit(s, smax - L/2);
    if (not initial() or v>0) then
      reinit(v, 0);
    end if;
  end when;

  when not (s > smin + L/2) then
    reinit(s, smin + L/2);
    if (not initial() or v<0) then
      reinit(v, 0);
    end if;
  end when;
*/
          annotation (
            Documentation(info="
<HTML>
<P>This element describes the <i>Stribeck friction characteristics</i> of a sliding mass,
i. e. the frictional force acting between the sliding mass and the support. Included is a
<i>hard stop</i> for the position. <BR>
The surface is fixed and there is friction between sliding mass and surface.
The frictional force f is given for positive velocity v by:</P>
<i><uL>
f = F_Coulomb + F_prop * v + F_Stribeck * exp (-fexp * v)</i> </ul><br>
<IMG SRC=../Images/Translational/Stribeck.png>
<br><br>
The distance between the left and the right connector is given by parameter L.
The position of the center of gravity, coordinate s, is in the middle between
the two flanges. </p>
<p>
There are hard stops at smax and smin, i. e. if <i><uL>
flange_a.s &gt;= smin
<ul>    and </ul>
flange_b.s &lt;= xmax </ul></i>
the sliding mass can move freely.</p>
<p>When the absolute velocity becomes zero, the sliding mass becomes stuck, i.e., the absolute position remains constant. In this phase the
friction force is calculated from a force balance due to the requirement that the
absolute acceleration shall be zero. The elements begin to slide when the friction
force exceeds a threshold value, called the maximum static friction force, computed via: </P>
<i><uL>
   maximum_static_friction =  F_Coulomb + F_Stribeck
</i> </ul>
<font color=\"#ff0000\"> <b>This requires the states Stop.s and Stop.v</b> </font>. If these states are eliminated during the index reduction
the model will not work. To avoid this any inertias should be connected via springs
to the Stop element, other sliding masses, dampers or hydraulic chambers must be avoided. </p>
<p>For more details of the used friction model see the following reference: <br> <br>
Beater P. (1999): <DD><a href=\"http://www.springer.de/cgi-bin/search_book.pl?isbn=3-540-65444-5\">
Entwurf hydraulischer Maschinen</a>. Springer Verlag Berlin Heidelberg New York.</DL></P>
<P>The friction model is implemented in a \"clean\" way by state events and leads to
continuous/discrete systems of equations which have to be solved by appropriate
numerical methods. The method is described in: </P>

<dl>
Otter M., Elmqvist H., and Mattsson S.E. (1999):
<i><DD>Hybrid Modeling in Modelica based on the Synchronous Data Flow Principle</i>. CACSD'99, Aug. 22.-26, Hawaii. </DD>
</DL>
<P>More precise friction models take into account the elasticity of the material when
the two elements are \"stuck\", as well as other effects, like hysteresis. This has
the advantage that the friction element can be completely described by a differential
equation without events. The drawback is that the system becomes stiff (about 10-20 times
slower simulation) and that more material constants have to be supplied which requires more
sophisticated identification. For more details, see the following references, especially
(Armstrong and Canudas de Witt 1996): </P>
<dl>
<dt>
Armstrong B. (1991):</dt>
<DD><i>Control of Machines with Friction</i>. Kluwer Academic Press, Boston MA.<BR>
</DD>
<DT>Armstrong B., and Canudas de Wit C. (1996): </DT>
<DD><i>Friction Modeling and Compensation.</i> The Control Handbook, edited by W.S.Levine, CRC Press, pp. 1369-1382.<BR>
</DD>
<DT>Canudas de Wit C., Olsson H., Astroem K.J., and Lischinsky P. (1995): </DT>
<DD>A<i> new model for control of systems with friction.</i> IEEE Transactions on Automatic Control, Vol. 40, No. 3, pp. 419-425.<BR>
</DD>
</DL>

</HTML>
",       revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>First Version from December 7, 1999 by P. Beater (based on Rotational.BearingFriction)</i> </li>
<li><i>July 14, 2001 by P. Beater, assert on initialization added, diagram modified </i> </li>
<li><i>October 11, 2001, by Hans Olsson, Dynasim, modified assert to handle start at stops,
modified event logic such if you have friction parameters equal to zero you do not get events
between the stops.</i> </li>
<li><i>June 10, 2002 by P. Beater, StateSelect.always for variables s and v (instead of fixed=true). </i> </li>
</ul>
</html>"),  Icon(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={1,1}), graphics={
                Polygon(
                  points={{80,-100},{50,-90},{50,-110},{80,-100}},
                  lineColor={128,128,128},
                  fillColor={128,128,128},
                  fillPattern=FillPattern.Solid),
                Line(points={{-30,-100},{50,-100}}, color={0,0,0}),
                Rectangle(
                  extent={{-30,30},{35,-35}},
                  lineColor={0,0,0},
                  fillPattern=FillPattern.Sphere,
                  fillColor={255,255,255}),
                Line(points={{-90,0},{-30,0}}, color={0,127,0}),
                Rectangle(
                  extent={{-70,-45},{74,-60}},
                  lineColor={0,0,0},
                  fillColor={192,192,192},
                  fillPattern=FillPattern.Solid),
                Rectangle(
                  extent={{-63,-15},{-55,-45}},
                  lineColor={0,0,0},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid),
                Rectangle(
                  extent={{60,-16},{69,-45}},
                  lineColor={0,0,0},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid),
                Line(points={{35,0},{90,0}}, color={0,127,0}),
                Text(
                  extent={{0,100},{0,40}},
                  textString="%name",
                  lineColor={0,0,255}),
                Line(points={{-50,-90},{-30,-70}}, color={0,0,0}),
                Line(points={{-30,-70},{30,-70}}, color={0,0,0}),
                Line(points={{-30,-90},{-10,-70}}, color={0,0,0}),
                Line(points={{-10,-90},{10,-70}}, color={0,0,0}),
                Line(points={{10,-90},{30,-70}}, color={0,0,0})}),
            Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={1,1}), graphics={
                Polygon(
                  points={{50,-75},{20,-65},{20,-85},{50,-75}},
                  lineColor={128,128,128},
                  fillColor={128,128,128},
                  fillPattern=FillPattern.Solid),
                Line(points={{-60,-75},{20,-75}}, color={0,0,0}),
                Rectangle(
                  extent={{-30,26},{35,-9}},
                  lineColor={0,0,0},
                  fillPattern=FillPattern.Sphere,
                  fillColor={255,255,255}),
                Line(points={{-90,0},{-30,0}}, color={0,127,0}),
                Line(points={{35,0},{90,0}}, color={0,127,0}),
                Rectangle(
                  extent={{-68,-14},{76,-29}},
                  lineColor={0,0,0},
                  fillColor={192,192,192},
                  fillPattern=FillPattern.Solid),
                Rectangle(
                  extent={{-119,43},{-111,17}},
                  lineColor={0,0,0},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid),
                Line(
                  points={{-111,43},{-111,50}},
                  color={0,0,0},
                  pattern=LinePattern.Solid,
                  thickness=0.25,
                  arrow={Arrow.None,Arrow.None}),
                Line(
                  points={{-151,49},{-113,49}},
                  color={0,0,0},
                  pattern=LinePattern.Solid,
                  thickness=0.25,
                  arrow={Arrow.None,Arrow.None}),
                Text(
                  extent={{-149,51},{-126,60}},
                  textString="s min",
                  lineColor={0,0,255}),
                Polygon(
                  points={{-121,52},{-111,49},{-121,46},{-121,52}},
                  lineColor={0,0,0},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid),
                Rectangle(
                  extent={{124,42},{132,17}},
                  lineColor={0,0,0},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid),
                Line(
                  points={{124,39},{124,87}},
                  color={0,0,0},
                  pattern=LinePattern.Solid,
                  thickness=0.25,
                  arrow={Arrow.None,Arrow.None}),
                Line(
                  points={{-19,78},{121,78}},
                  color={0,0,0},
                  pattern=LinePattern.Solid,
                  thickness=0.25,
                  arrow={Arrow.None,Arrow.None}),
                Text(
                  extent={{-17,83},{6,92}},
                  textString="s max",
                  lineColor={0,0,255}),
                Polygon(
                  points={{114,81},{124,78},{114,75},{114,81}},
                  lineColor={0,0,0},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid),
                Line(
                  points={{5,26},{5,63}},
                  color={0,0,0},
                  pattern=LinePattern.Solid,
                  thickness=0.25,
                  arrow={Arrow.None,Arrow.None}),
                Line(
                  points={{-77,58},{-1,58}},
                  color={0,0,0},
                  pattern=LinePattern.Solid,
                  thickness=0.25,
                  arrow={Arrow.None,Arrow.None}),
                Text(
                  extent={{-75,60},{-38,71}},
                  textString="Position s",
                  lineColor={0,0,255}),
                Polygon(
                  points={{-5,61},{5,58},{-5,55},{-5,61}},
                  lineColor={0,0,0},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid),
                Line(points={{-100,-10},{-100,-60}}, color={0,0,0}),
                Line(points={{100,-10},{100,-60}}, color={0,0,0}),
                Polygon(
                  points={{90,-47},{100,-50},{90,-53},{90,-47}},
                  lineColor={0,0,0},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid),
                Polygon(
                  points={{-90,-47},{-90,-53},{-100,-50},{-90,-47}},
                  lineColor={0,0,0},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid),
                Line(points={{-90,-50},{92,-50}}, color={0,0,0}),
                Text(
                  extent={{-11,-46},{26,-36}},
                  textString="Length L",
                  lineColor={0,0,255})}));
        end MassWithStopAndFriction;
        annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={Rectangle(
                extent={{-67,-66},{44,-6}},
                lineColor={0,0,0},
                fillPattern=FillPattern.Sphere,
                fillColor={255,255,255})}),                     Documentation(info="<html>
<p>
This package contains basic components 1D mechanical translational drive trains.
</p>
</html>"));
      end Components;

      package Sources "Sources to drive 1D translational mechanical components"
        extends Modelica.Icons.Library2;

        model Force
        "External force acting on a drive train element as input signal"
          extends
          Modelica.Mechanics.Translational.Interfaces.PartialElementaryOneFlangeAndSupport2;
          Modelica.Blocks.Interfaces.RealInput f
          "driving force as input signal"   annotation (Placement(transformation(
                  extent={{-140,-20},{-100,20}}, rotation=0)));

        equation
          flange.f = -f;
          annotation (
            Documentation(info="<html>
<p>
The input signal \"f\" in [N] characterizes an <i>external
force</i> which acts (with positive sign) at a flange,
i.e., the component connected to the flange is driven by force f.
</p>
<p>
Input signal f can be provided from one of the signal generator
blocks of Modelica.Blocks.Source.
</p>

</HTML>
"),         Icon(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Polygon(
                  points={{-100,10},{20,10},{20,41},{90,0},{20,-41},{20,-10},{-100,
                      -10},{-100,10}},
                  lineColor={0,127,0},
                  fillColor={215,215,215},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-100,-40},{-47,-88}},
                  lineColor={0,0,0},
                  textString="f"),
                Text(
                  extent={{0,109},{0,49}},
                  textString="%name",
                  lineColor={0,0,255}),
                Line(points={{-30,-60},{30,-60}}, color={0,0,0}),
                Line(points={{0,-60},{0,-101}}, color={0,0,0}),
                Line(points={{-30,-80},{-10,-60}}, color={0,0,0}),
                Line(points={{-10,-80},{10,-60}}, color={0,0,0}),
                Line(points={{10,-80},{30,-60}}, color={0,0,0}),
                Polygon(
                  points={{-61,-50},{-30,-40},{-30,-60},{-61,-50}},
                  lineColor={0,0,0},
                  fillColor={128,128,128},
                  fillPattern=FillPattern.Solid),
                Line(points={{-31,-50},{50,-50}}, color={0,0,0}),
                Line(points={{-50,-80},{-30,-60}}, color={0,0,0})}),
            Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics));
        end Force;
        annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={Polygon(
                points={{-100,-32},{10,-32},{10,-1},{80,-42},{10,-83},{10,-52},{-100,
                    -52},{-100,-32}},
                lineColor={0,127,0},
                fillColor={0,127,0},
                fillPattern=FillPattern.Solid)}),               Documentation(info="<html>
<p>
This package contains ideal sources to drive 1D mechanical translational drive trains.
</p>
</html>"));
      end Sources;

      package Sensors "Sensors for 1-dim. translational mechanical quantities"
        extends Modelica.Icons.Library2;

        model PositionSensor "Ideal sensor to measure the absolute position"
          extends Translational.Interfaces.PartialAbsoluteSensor;
          Modelica.Blocks.Interfaces.RealOutput s "Absolute position of flange"
                                        annotation (Placement(transformation(extent={{100,-11},
                    {120,9}},            rotation=0), iconTransformation(extent={{100,
                    -10},{120,10}})));

        equation
          s = flange.s;
          annotation (
            Documentation(info="<html>
<p>
Measures the <i>absolute position s</i> of a flange in an ideal way and provides the result as
output signals (to be further processed with blocks of the
Modelica.Blocks library).
</p>

</HTML>
"),         Icon(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={1,1}), graphics={Line(points={{-70,0},{-90,0}}, color={0,0,0}),
                  Text(
                  extent={{80,-28},{114,-62}},
                  lineColor={0,0,0},
                  textString="s")}),
            Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={1,1}), graphics));
        end PositionSensor;
        annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                  100}}), graphics={
              Rectangle(
                extent={{-76,-81},{64,-1}},
                lineColor={0,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-6,-61},{-16,-37},{4,-37},{-6,-61}},
                lineColor={0,0,0},
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid),
              Line(points={{-6,-21},{-6,-37}}, color={0,0,0}),
              Line(points={{-76,-21},{-6,-21}}, color={0,0,0}),
              Line(points={{-56,-61},{-56,-81}}, color={0,0,0}),
              Line(points={{-36,-61},{-36,-81}}, color={0,0,0}),
              Line(points={{-16,-61},{-16,-81}}, color={0,0,0}),
              Line(points={{4,-61},{4,-81}}, color={0,0,0}),
              Line(points={{24,-61},{24,-81}}, color={0,0,0}),
              Line(points={{44,-61},{44,-81}}, color={0,0,0})}),
          Documentation(info="<html>
<p>
This package contains ideal sensor components that provide
the connector variables as signals for further processing with the
Modelica.Blocks library.
</p>
</html>"));
      end Sensors;

      package Interfaces
      "Interfaces for 1-dim. translational mechanical components"
          extends Modelica.Icons.Library;

        connector Flange_a
        "(left) 1D translational flange (flange axis directed INTO cut plane, e. g. from left to right)"

          SI.Position s "absolute position of flange";
          flow SI.Force f "cut force directed into flange";
          annotation(defaultComponentName = "flange_a",
            Documentation(info="<html>
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
"),         Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                    100,100}}), graphics={Rectangle(
                  extent={{-100,-100},{100,100}},
                  lineColor={0,127,0},
                  fillColor={0,127,0},
                  fillPattern=FillPattern.Solid)}),
            Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},
                    {100,100}}), graphics={Rectangle(
                  extent={{-40,-40},{40,40}},
                  lineColor={0,127,0},
                  fillColor={0,127,0},
                  fillPattern=FillPattern.Solid), Text(
                  extent={{-160,110},{40,50}},
                  lineColor={0,127,0},
                  textString="%name")}));
        end Flange_a;

        connector Flange_b
        "right 1D translational flange (flange axis directed OUT OF cut plane)"

          SI.Position s "absolute position of flange";
          flow SI.Force f "cut force directed into flange";
          annotation(defaultComponentName = "flange_b",
            Documentation(info="<html>
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
"),         Icon(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={Rectangle(
                  extent={{-100,-100},{100,100}},
                  lineColor={0,127,0},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid)}),
            Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={Rectangle(
                  extent={{-40,-40},{40,40}},
                  lineColor={0,127,0},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid), Text(
                  extent={{-40,110},{160,50}},
                  lineColor={0,127,0},
                  textString="%name")}));
        end Flange_b;

        connector Support "Support/housing 1D translational flange"

          SI.Position s "absolute position of flange";
          flow SI.Force f "cut force directed into flange";
          annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                    -100},{100,100}}), graphics={
                Rectangle(
                  extent={{-60,60},{60,-60}},
                  fillColor={175,175,175},
                  fillPattern=FillPattern.Solid,
                  pattern=LinePattern.None),
                Text(
                  extent={{-160,110},{40,50}},
                  lineColor={0,127,0},
                  textString="%name"),
                Rectangle(
                  extent={{-40,-40},{40,40}},
                  lineColor={0,127,0},
                  fillColor={0,127,0},
                  fillPattern=FillPattern.Solid)}), Icon(coordinateSystem(
                  preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
                graphics={Rectangle(
                  extent={{-150,150},{150,-150}},
                  fillColor={175,175,175},
                  fillPattern=FillPattern.Solid,
                  pattern=LinePattern.None), Rectangle(
                  extent={{-90,-90},{90,90}},
                  lineColor={0,127,0},
                  fillColor={0,127,0},
                  fillPattern=FillPattern.Solid)}));
        end Support;

        partial model PartialRigid
        "Rigid connection of two translational 1D flanges "
          SI.Position s
          "Absolute position of center of component (s = flange_a.s + L/2 = flange_b.s - L/2)";
          parameter SI.Length L(start=0)
          "Length of component, from left flange to right flange (= flange_b.s - flange_a.s)";
          Flange_a flange_a "Left flange of translational component"
             annotation (Placement(transformation(extent={{-110,-10},{-90,10}},
                  rotation=0)));
          Flange_b flange_b "Right flange of translational component"
             annotation (Placement(transformation(extent={{90,-10},{110,10}},
                  rotation=0)));
        equation
          flange_a.s = s - L/2;
          flange_b.s = s + L/2;
          annotation (
            Documentation(info="<html>
<p>
This is a 1-dim. translational component with two <i>rigidly</i> connected flanges.
The fixed distance between the left and the right flange is defined by parameter \"L\".
The forces at the right and left flange can be different.
It is used e.g. to built up sliding masses.
</p>
</html>
"),         Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics));
        end PartialRigid;

        partial model PartialCompliant
        "Compliant connection of two translational 1D flanges"

          Flange_a flange_a
          "Left flange of compliant 1-dim. translational component"
             annotation (Placement(transformation(extent={{-110,-10},{-90,10}},
                  rotation=0)));
          Flange_b flange_b
          "Right flange of compliant 1-dim. translational component"
            annotation (Placement(transformation(extent={{90,-10},{110,10}},
                  rotation=0)));
          SI.Distance s_rel(start=0)
          "relative distance (= flange_b.s - flange_a.s)";
          SI.Force f
          "force between flanges (positive in direction of flange axis R)";

        equation
          s_rel = flange_b.s - flange_a.s;
          flange_b.f = f;
          flange_a.f = -f;
          annotation (
            Documentation(info="<html>
<p>
This is a 1D translational component with a <i>compliant </i>connection of two
translational 1D flanges where inertial effects between the two
flanges are not included. The absolute value of the force at the left and the right
flange is the same. It is used to built up springs, dampers etc.
</p>

</HTML>
"),         Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={Polygon(
                  points={{50,-90},{20,-80},{20,-100},{50,-90}},
                  lineColor={128,128,128},
                  fillColor={128,128,128},
                  fillPattern=FillPattern.Solid), Line(points={{-60,-90},{20,-90}},
                    color={0,0,0})}));
        end PartialCompliant;

        partial model PartialElementaryOneFlangeAndSupport2
        "Partial model for a component with one translational 1-dim. shaft flange and a support used for textual modeling, i.e., for elementary models"
          parameter Boolean useSupport=false
          "= true, if support flange enabled, otherwise implicitly grounded"
              annotation(Evaluate=true, HideResult=true, choices(__Dymola_checkBox=true));
          Modelica.SIunits.Length s = flange.s - s_support
          "distance between flange and support (= flange.s - support.s)";
          Flange_b flange "Flange of component"
            annotation (Placement(transformation(extent={{90,-10},{110,10}},
                  rotation=0)));
          Support support(s=s_support, f=-flange.f) if useSupport
          "Support/housing of component"
            annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));
      protected
          Modelica.SIunits.Length s_support
          "Absolute position of support flange";
        equation
          if not useSupport then
             s_support = 0;
          end if;

          annotation (
            Documentation(info="<html>
<p>
This is a 1-dim. translational component with one flange and a support/housing.
It is used to build up elementary components of a drive train with
equations in the text layer.
</p>

<p>
If <i>useSupport=true</i>, the support connector is conditionally enabled
and needs to be connected.<br>
If <i>useSupport=false</i>, the support connector is conditionally disabled
and instead the component is internally fixed to ground.
</p>

</HTML>
"),         Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics),
            Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{
                    100,100}}), graphics={
                Line(
                  visible=not useSupport,
                  points={{-50,-120},{-30,-100}},
                  color={0,0,0}),
                Line(
                  visible=not useSupport,
                  points={{-30,-120},{-10,-100}},
                  color={0,0,0}),
                Line(
                  visible=not useSupport,
                  points={{-10,-120},{10,-100}},
                  color={0,0,0}),
                Line(
                  visible=not useSupport,
                  points={{10,-120},{30,-100}},
                  color={0,0,0}),
                Line(
                  visible=not useSupport,
                  points={{-30,-100},{30,-100}},
                  color={0,0,0})}));
        end PartialElementaryOneFlangeAndSupport2;

        partial model PartialAbsoluteSensor
        "Device to measure a single absolute flange variable"

          extends Modelica.Icons.TranslationalSensor;

          Interfaces.Flange_a flange
          "flange to be measured (flange axis directed in to cut plane, e. g. from left to right)"
             annotation (Placement(transformation(extent={{-110,-10},{-90,10}},
                  rotation=0)));

        equation
          0 = flange.f;
          annotation (
            Documentation(info="<html>
<p>
This is the superclass of a 1D translational component with one flange and one
output signal in order to measure an absolute kinematic quantity in the flange
and to provide the measured signal as output signal for further processing
with the Modelica.Blocks blocks.
</p>
</HTML>
"),         Icon(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={1,1}), graphics={
                Line(points={{-100,-90},{-20,-90}}, color={0,0,0}),
                Polygon(
                  points={{10,-90},{-20,-80},{-20,-100},{10,-90}},
                  lineColor={128,128,128},
                  fillColor={128,128,128},
                  fillPattern=FillPattern.Solid),
                Line(points={{-70,0},{-90,0}}, color={0,0,0}),
                Line(points={{70,0},{100,0}}, color={0,0,127}),
                Text(
                  extent={{-118,99},{118,40}},
                  textString="%name",
                  lineColor={0,0,255})}),
            Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={1,1}), graphics));
        end PartialAbsoluteSensor;
        annotation (Documentation(info="<html>
<p>
This package contains connectors and partial models for 1-dim.
translational mechanical components. The components of this package can
only be used as basic building elements for models.
</p>

</html>
"));
      end Interfaces;
      annotation (
        Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                100}}), graphics={
            Line(points={{-84,-73},{66,-73}}, color={0,0,0}),
            Rectangle(
              extent={{-81,-22},{-8,-65}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={192,192,192}),
            Line(points={{-8,-43},{-1,-43},{6,-64},{17,-23},{29,-65},{40,-23},{50,-44},
                  {61,-44}}, color={0,0,0}),
            Line(points={{-59,-73},{-84,-93}}, color={0,0,0}),
            Line(points={{-11,-73},{-36,-93}}, color={0,0,0}),
            Line(points={{-34,-73},{-59,-93}}, color={0,0,0}),
            Line(points={{14,-73},{-11,-93}}, color={0,0,0}),
            Line(points={{39,-73},{14,-93}}, color={0,0,0}),
            Line(points={{63,-73},{38,-93}}, color={0,0,0})}),
                                                            Documentation(info="<html>
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
elements (e.g. MassWithStopAndFriction) should be only connected
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
<p> Another restriction arises if the hard stops in model MassWithStopAndFriction are used, i. e.
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
   Modelica.SIunits.Position s    \"Absolute position of flange\";
   <b>flow</b> Modelica.SIunits.Force f  \"Cut-force in the flange\";
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
<dt><b>Library Officer</b>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> <br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
    Institut f&uuml;r Robotik und Mechatronik (DLR-RM)<br>
    Abteilung Systemdynamik und Regelungstechnik<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    Germany<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br><br>
</dl>

<p>
<b>Contributors to this library:</b>
</p>

<ul>
<li> Main author until 2006:<br>
     Peter Beater <br>
     Universit&auml;t Paderborn, Abteilung Soest<br>
     Fachbereich Maschinenbau/Automatisierungstechnik<br>
     L&uuml;becker Ring 2 <br>
     D 59494 Soest <br>
     Germany <br>
     email: <A HREF=\"mailto:info@beater.de\">info@beater.de</A><br><br>
     </li>

<li> <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
     Technical Consulting &amp; Electrical Engineering<br>
     A-3423 St.Andrae-Woerdern, Austria<br>
     email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a><br><br></li>

<li> <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> (DLR-RM)</li>
</ul>

<p>
Copyright &copy; 1998-2009, Modelica Association, Anton Haumer and Universit&auml;t Paderborn, FB 12.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense2\">here</a>.</i>
</p><br>

</HTML>
",     revisions="<html>
<ul>
<li><i>Version 1.0 (January 5, 2000)</i>
       by Peter Beater <br>
       Realized a first version based on Modelica library Mechanics.Rotational
       by Martin Otter and an existing Dymola library onedof.lib by Peter Beater.
       <br>
<li><i>Version 1.01 (July 18, 2001)</i>
       by Peter Beater <br>
       Assert statement added to \"Stop\", small bug fixes in examples.
       <br>
</li>
<li><i>Version 1.1.0 2007-11-16</i>
       by Anton Haumer<br>
       Redesign for Modelica 3.0-compliance<br>
       Added new components acording to Mechanics.Rotational library
       <br>
</li>
</ul>
</html>"));
    end Translational;
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
        graphics={
        Rectangle(
          extent={{-5,-40},{45,-70}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={192,192,192}),
        Ellipse(extent={{-90,-50},{-80,-60}}, lineColor={0,0,0}),
        Line(
          points={{-85,-55},{-60,-21}},
          color={0,0,0},
          thickness=0.5),
        Ellipse(extent={{-65,-16},{-55,-26}}, lineColor={0,0,0}),
        Line(
          points={{-60,-21},{9,-55}},
          color={0,0,0},
          thickness=0.5),
        Ellipse(
          extent={{4,-50},{14,-60}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Line(points={{-10,-34},{72,-34},{72,-76},{-10,-76}}, color={0,0,0})}),
    Documentation(info="<HTML>
<p>
This package contains components to model the movement
of 1-dim. rotational, 1-dim. translational, and
3-dim. <b>mechanical systems</b>.
</p>
</HTML>
"));
  end Mechanics;

  package Icons "Library of icons"

    partial package Library "Icon for library"

      annotation (             Icon(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={
            Rectangle(
              extent={{-100,-100},{80,50}},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Polygon(
              points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Polygon(
              points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Text(
              extent={{-85,35},{65,-85}},
              lineColor={0,0,255},
              textString="Library"),
            Text(
              extent={{-120,122},{120,73}},
              lineColor={255,0,0},
              textString="%name")}),
        Documentation(info="<html>
<p>
This icon is designed for a <b>library</b>.
</p>
</html>"));
    end Library;

    partial package Library2
    "Icon for library where additional icon elements shall be added"

      annotation (             Icon(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={
            Rectangle(
              extent={{-100,-100},{80,50}},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Polygon(
              points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Polygon(
              points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Text(
              extent={{-120,125},{120,70}},
              lineColor={255,0,0},
              textString="%name"),
            Text(
              extent={{-90,40},{70,10}},
              lineColor={160,160,164},
              textString="Library")}),
        Documentation(info="<html>
<p>
This icon is designed for a <b>package</b> where a package
specific graphic is additionally included in the icon.
</p>
</html>"));
    end Library2;

    partial model TranslationalSensor
    "Icon representing translational measurement device"

      annotation (
        Icon(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={
            Rectangle(
              extent={{-70,-60},{70,20}},
              lineColor={0,0,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{0,-40},{-10,-16},{10,-16},{0,-40}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Line(points={{0,0},{0,-16}}, color={0,0,0}),
            Line(points={{-70,0},{0,0}}, color={0,0,0}),
            Line(points={{-50,-40},{-50,-60}}, color={0,0,0}),
            Line(points={{-30,-40},{-30,-60}}, color={0,0,0}),
            Line(points={{-10,-40},{-10,-60}}, color={0,0,0}),
            Line(points={{10,-40},{10,-60}}, color={0,0,0}),
            Line(points={{30,-40},{30,-60}}, color={0,0,0}),
            Line(points={{50,-40},{50,-60}}, color={0,0,0})}),
        Diagram(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics),
        Documentation(info="<html>
<p>
This icon is designed for a <b>translational sensor</b> model.
</p>
</html>"));

    end TranslationalSensor;
    annotation (
      Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={
          Rectangle(
            extent={{-100,-100},{80,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{-120,135},{120,70}},
            lineColor={255,0,0},
            textString="%name"),
          Text(
            extent={{-90,40},{70,10}},
            lineColor={160,160,164},
            textString="Library"),
          Rectangle(
            extent={{-100,-100},{80,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{-90,40},{70,10}},
            lineColor={160,160,164},
            textString="Library"),
          Polygon(
            points={{-64,-20},{-50,-4},{50,-4},{36,-20},{-64,-20},{-64,-20}},
            lineColor={0,0,0},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-64,-20},{36,-84}},
            lineColor={0,0,0},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-60,-24},{32,-38}},
            lineColor={128,128,128},
            textString="Library"),
          Polygon(
            points={{50,-4},{50,-70},{36,-84},{36,-20},{50,-4}},
            lineColor={0,0,0},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid)}),
                              Documentation(info="<html>
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
",   revisions="<html>
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

  package SIunits
  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Library2;

    type Length = Real (final quantity="Length", final unit="m");

    type Position = Length;

    type Distance = Length (min=0);

    type Velocity = Real (final quantity="Velocity", final unit="m/s");

    type Acceleration = Real (final quantity="Acceleration", final unit="m/s2");

    type Mass = Real (
        quantity="Mass",
        final unit="kg",
        min=0);

    type Force = Real (final quantity="Force", final unit="N");

    type TranslationalSpringConstant=Real(final quantity="TranslationalSpringConstant", final unit
        =                                                                                          "N/m");
    annotation (
      Invisible=true,
      Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={Text(
            extent={{-63,-13},{45,-67}},
            lineColor={0,0,0},
            textString="[kg.m2]")}),
      Documentation(info="<html>
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

</html>",   revisions="<html>
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
</html>"),
      Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={
          Rectangle(
            extent={{169,86},{349,236}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{169,236},{189,256},{369,256},{349,236},{169,236}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{369,256},{369,106},{349,86},{349,236},{369,256}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{179,226},{339,196}},
            lineColor={160,160,164},
            textString="Library"),
          Text(
            extent={{206,173},{314,119}},
            lineColor={0,0,0},
            textString="[kg.m2]"),
          Text(
            extent={{163,320},{406,264}},
            lineColor={255,0,0},
            textString="Modelica.SIunits")}));
  end SIunits;
annotation (
preferredView="info",
version="3.1",
versionBuild=6,
versionDate="2009-08-14",
dateModified = "2010-01-17 20:15:49Z",
revisionId="$Id: package.mo,v 1.1.1.3 2010/03/01 10:59:58 Dag Exp $",
conversion(
 noneFromVersion="3.0.1",
 noneFromVersion="3.0",
 from(version="2.1", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos"),
 from(version="2.2", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos"),
 from(version="2.2.1", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos"),
 from(version="2.2.2", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos")),
__Dymola_classOrder={"UsersGuide","Blocks","StateGraph","Electrical","Magnetic","Mechanics","Fluid","Media","Thermal",
      "Math","Utilities","Constants", "Icons", "SIunits"},
Settings(NewStateSelection=true),
Documentation(info="<HTML>
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
end Modelica;

model ActuatorMechanics

  Modelica.Mechanics.Translational.Sources.Force force
    annotation (Placement(transformation(extent={{-74,18},{-54,38}})));
  Modelica.Mechanics.Translational.Components.MassWithStopAndFriction
    mass(
    smax=0.1,
    smin=0,
    L=0.01,
    s(start=0.005),
    m=1,
    F_prop=0,
    F_Coulomb=10)
    annotation (Placement(transformation(extent={{-40,18},{-20,38}})));
  Modelica.Mechanics.Translational.Components.Spring spring(c=1000)
    annotation (Placement(transformation(extent={{2,16},{22,36}})));
  Modelica.Mechanics.Translational.Components.Fixed fixed
    annotation (Placement(transformation(extent={{42,18},{62,38}})));
  Modelica.Mechanics.Translational.Sensors.PositionSensor positionSensor
    annotation (Placement(transformation(extent={{-12,-30},{8,-10}})));
  annotation (uses(Modelica(version="3.1")), Diagram(graphics));
equation
  connect(force.flange, mass.flange_a) annotation (Line(
      points={{-54,28},{-40,28}},
      color={0,127,0},
      smooth=Smooth.None));
  connect(mass.flange_b, spring.flange_a) annotation (Line(
      points={{-20,28},{-10,28},{-10,26},{2,26}},
      color={0,127,0},
      smooth=Smooth.None));
  connect(spring.flange_b, fixed.flange) annotation (Line(
      points={{22,26},{40,26},{40,28},{52,28}},
      color={0,127,0},
      smooth=Smooth.None));
  connect(mass.flange_b, positionSensor.flange) annotation (
      Line(
      points={{-20,28},{-16,28},{-16,-20},{-12,-20}},
      color={0,127,0},
      smooth=Smooth.None));
  force.f = 100;
end ActuatorMechanics;

