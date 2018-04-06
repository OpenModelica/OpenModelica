// name: StreamConcept_NoMedium_Total.mo
// keywords: stream instream connector
// status: correct
//
// Test model from SiemensPower that tests stream connectors.
//

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

        partial block BlockIcon "Basic graphical layout of input/output block"

          annotation (
            Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={Rectangle(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid), Text(
                extent={{-150,150},{150,110}},
                textString="%name",
                lineColor={0,0,255})}),
          Documentation(info="<html>
<p>
Block that has only the basic icon for an input/output
block (no declarations, no equations). Most blocks
of package Modelica.Blocks inherit directly or indirectly
from this block.
</p>
</html>"));

        end BlockIcon;

        partial block SO "Single Output continuous control block"
          extends BlockIcon;

          RealOutput y "Connector of Real output signal"
            annotation (Placement(transformation(extent={{100,-10},{120,10}},
                rotation=0)));
          annotation (
            Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics),
          Documentation(info="<html>
<p>
Block has one continuous Real output signal.
</p>
</html>"));

        end SO;
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

    package Sources
    "Library of signal source blocks generating Real and Boolean signals"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
          extends Modelica.Icons.Library;

          block Ramp "Generate ramp signal"
            parameter Real height=1 "Height of ramps";
            parameter Modelica.SIunits.Time duration(min=Modelica.Constants.small, start = 2)
        "Durations of ramp";
            parameter Real offset=0 "Offset of output signal";
            parameter Modelica.SIunits.Time startTime=0
        "Output = offset for time < startTime";
            extends Interfaces.SO;

          equation
            y = offset + (if time < startTime then 0 else if time < (startTime +
              duration) then (time - startTime)*height/duration else height);
            annotation (
              Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={1,1}), graphics={
              Line(points={{-80,68},{-80,-80}}, color={192,192,192}),
              Polygon(
                points={{-80,90},{-88,68},{-72,68},{-80,90}},
                lineColor={192,192,192},
                fillColor={192,192,192},
                fillPattern=FillPattern.Solid),
              Line(points={{-90,-70},{82,-70}}, color={192,192,192}),
              Polygon(
                points={{90,-70},{68,-62},{68,-78},{90,-70}},
                lineColor={192,192,192},
                fillColor={192,192,192},
                fillPattern=FillPattern.Solid),
              Line(points={{-80,-70},{-40,-70},{31,38}}, color={0,0,0}),
              Text(
                extent={{-150,-150},{150,-110}},
                lineColor={0,0,0},
                textString="duration=%duration"),
              Line(points={{31,38},{86,38}}, color={0,0,0})}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={1,1}), graphics={
              Polygon(
                points={{-80,90},{-86,68},{-74,68},{-80,90}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Line(points={{-80,68},{-80,-80}}, color={95,95,95}),
              Line(
                points={{-80,-20},{-20,-20},{50,50}},
                color={0,0,255},
                thickness=0.5),
              Line(points={{-90,-70},{82,-70}}, color={95,95,95}),
              Polygon(
                points={{90,-70},{68,-64},{68,-76},{90,-70}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-40,-20},{-42,-30},{-37,-30},{-40,-20}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Line(
                points={{-40,-20},{-40,-70}},
                color={95,95,95},
                thickness=0.25,
                arrow={Arrow.None,Arrow.None}),
              Polygon(
                points={{-40,-70},{-43,-60},{-38,-60},{-40,-70},{-40,-70}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-72,-39},{-34,-50}},
                lineColor={0,0,0},
                textString="offset"),
              Text(
                extent={{-38,-72},{6,-83}},
                lineColor={0,0,0},
                textString="startTime"),
              Text(
                extent={{-78,92},{-37,72}},
                lineColor={0,0,0},
                textString="y"),
              Text(
                extent={{70,-80},{94,-91}},
                lineColor={0,0,0},
                textString="time"),
              Line(points={{-20,-20},{-20,-70}}, color={95,95,95}),
              Line(
                points={{-19,-20},{50,-20}},
                color={95,95,95},
                thickness=0.25,
                arrow={Arrow.None,Arrow.None}),
              Line(
                points={{50,50},{101,50}},
                color={0,0,255},
                thickness=0.5),
              Line(
                points={{50,50},{50,-20}},
                color={95,95,95},
                thickness=0.25,
                arrow={Arrow.None,Arrow.None}),
              Polygon(
                points={{50,-20},{42,-18},{42,-22},{50,-20}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-20,-20},{-11,-18},{-11,-22},{-20,-20}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{50,50},{48,40},{53,40},{50,50}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{50,-20},{47,-10},{52,-10},{50,-20},{50,-20}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{53,23},{82,10}},
                lineColor={0,0,0},
                textString="height"),
              Text(
                extent={{-2,-21},{37,-33}},
                lineColor={0,0,0},
                textString="duration")}),
          Documentation(info="<html>
<p>
The Real output y is a ramp signal:
</p>

<p>
<img src=\"../Images/Blocks/Sources/Ramp.png\">
</p>
</html>"));
          end Ramp;

          block Sine "Generate sine signal"
            parameter Real amplitude=1 "Amplitude of sine wave";
            parameter SIunits.Frequency freqHz(start=1)
        "Frequency of sine wave";
            parameter SIunits.Angle phase=0 "Phase of sine wave";
            parameter Real offset=0 "Offset of output signal";
            parameter SIunits.Time startTime=0
        "Output = offset for time < startTime";
            extends Interfaces.SO;
    protected
            constant Real pi=Modelica.Constants.pi;

          equation
            y = offset + (if time < startTime then 0 else amplitude*
              Modelica.Math.sin(2*pi*freqHz*(time - startTime) + phase));
            annotation (
              Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={1,1}), graphics={
              Line(points={{-80,68},{-80,-80}}, color={192,192,192}),
              Polygon(
                points={{-80,90},{-88,68},{-72,68},{-80,90}},
                lineColor={192,192,192},
                fillColor={192,192,192},
                fillPattern=FillPattern.Solid),
              Line(points={{-90,0},{68,0}}, color={192,192,192}),
              Polygon(
                points={{90,0},{68,8},{68,-8},{90,0}},
                lineColor={192,192,192},
                fillColor={192,192,192},
                fillPattern=FillPattern.Solid),
              Line(points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,
                    74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,
                    59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,
                    -64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},
                    {57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, color={0,0,0}),
              Text(
                extent={{-147,-152},{153,-112}},
                lineColor={0,0,0},
                textString="freqHz=%freqHz")}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={1,1}), graphics={
              Line(points={{-80,-90},{-80,84}}, color={95,95,95}),
              Polygon(
                points={{-80,97},{-84,81},{-76,81},{-80,97}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Line(points={{-99,-40},{85,-40}}, color={95,95,95}),
              Polygon(
                points={{97,-40},{81,-36},{81,-45},{97,-40}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Line(
                points={{-41,-2},{-31.6,34.2},{-26.1,53.1},{-21.3,66.4},{-17.1,74.6},
                    {-12.9,79.1},{-8.64,79.8},{-4.42,76.6},{-0.201,69.7},{4.02,59.4},
                    {8.84,44.1},{14.9,21.2},{27.5,-30.8},{33,-50.2},{37.8,-64.2},{
                    42,-73.1},{46.2,-78.4},{50.5,-80},{54.7,-77.6},{58.9,-71.5},{
                    63.1,-61.9},{67.9,-47.2},{74,-24.8},{80,0}},
                color={0,0,255},
                thickness=0.5),
              Line(
                points={{-41,-2},{-80,-2}},
                color={0,0,255},
                thickness=0.5),
              Text(
                extent={{-87,12},{-40,0}},
                lineColor={0,0,0},
                textString="offset"),
              Line(points={{-41,-2},{-41,-40}}, color={95,95,95}),
              Text(
                extent={{-60,-43},{-14,-54}},
                lineColor={0,0,0},
                textString="startTime"),
              Text(
                extent={{75,-47},{100,-60}},
                lineColor={0,0,0},
                textString="time"),
              Text(
                extent={{-80,99},{-40,82}},
                lineColor={0,0,0},
                textString="y"),
              Line(points={{-9,79},{43,79}}, color={95,95,95}),
              Line(points={{-41,-2},{50,-2}}, color={95,95,95}),
              Polygon(
                points={{33,79},{30,66},{37,66},{33,79}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{37,57},{83,39}},
                lineColor={0,0,0},
                textString="amplitude"),
              Polygon(
                points={{33,-2},{30,11},{36,11},{33,-2},{33,-2}},
                lineColor={95,95,95},
                fillColor={95,95,95},
                fillPattern=FillPattern.Solid),
              Line(points={{33,77},{33,-2}}, color={95,95,95})}),
          Documentation(info="<html>
<p>
The Real output y is a sine signal:
</p>

<p>
<img src=\"../Images/Blocks/Sources/Sine.png\">
</p>
</html>"));
          end Sine;
          annotation (
            Documentation(info="<HTML>
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
  <tr><td valign=\"top\"><b>offset</b></td>
      <td valign=\"top\">Value which is added to the signal</td>
  </tr>
  <tr><td valign=\"top\"><b>startTime</b></td>
      <td valign=\"top\">Start time of signal. For time &lt; startTime,
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
",     revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Integer sources added. Step, TimeTable and BooleanStep slightly changed.</li>
<li><i>Nov. 8, 1999</i>
       by <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
       <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
       <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
       (nperiod=-1 is an infinite number of periods).</li>
<li><i>Oct. 31, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
       <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
       All sources vectorized. New sources: ExpSine, Trapezoid,
       BooleanConstant, BooleanStep, BooleanPulse, SampleTrigger.
       Improved documentation, especially detailed description of
       signals in diagram layer.</li>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>"));
    end Sources;
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

  package Math
  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;

  function sin "Sine"
    extends baseIcon1;
    input SI.Angle u;
    output Real y;

  external "C" y=  sin(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},
                {-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},
                {-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},
                {29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{
                57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, color={0,0,0}),
          Text(
            extent={{12,84},{84,36}},
            lineColor={192,192,192},
            textString="sin")}),
      Diagram(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-100,0},{84,0}}, color={95,95,95}),
          Polygon(
            points={{100,0},{84,6},{84,-6},{100,0}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{
                -43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{
                -14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{
                29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,
                -61.9},{63.9,-47.2},{72,-24.8},{80,0}},
            color={0,0,255},
            thickness=0.5),
          Text(
            extent={{-105,72},{-85,88}},
            textString="1",
            lineColor={0,0,255}),
          Text(
            extent={{70,25},{90,5}},
            textString="2*pi",
            lineColor={0,0,255}),
          Text(
            extent={{-103,-72},{-83,-88}},
            textString="-1",
            lineColor={0,0,255}),
          Text(
            extent={{82,-6},{102,-26}},
            lineColor={95,95,95},
            textString="u"),
          Line(
            points={{-80,80},{-28,80}},
            color={175,175,175},
            smooth=Smooth.None),
          Line(
            points={{-80,-80},{50,-80}},
            color={175,175,175},
            smooth=Smooth.None)}),
      Documentation(info="<html>
<p>
This function returns y = sin(u), with -&infin; &lt; u &lt; &infin;:
</p>

<p>
<img src=\"../Images/Math/sin.png\">
</p>
</html>"),   Library="ModelicaExternalC");
  end sin;

  function asin "Inverse sine (-1 <= u <= 1)"
    extends baseIcon2;
    input Real u;
    output SI.Angle y;

  external "C" y=  asin(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,
                -49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,
                52.7},{75.2,62.2},{77.6,67.5},{80,80}}, color={0,0,0}),
          Text(
            extent={{-88,78},{-16,30}},
            lineColor={192,192,192},
            textString="asin")}),
      Diagram(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Text(
            extent={{-40,-72},{-15,-88}},
            textString="-pi/2",
            lineColor={0,0,255}),
          Text(
            extent={{-38,88},{-13,72}},
            textString=" pi/2",
            lineColor={0,0,255}),
          Text(
            extent={{68,-9},{88,-29}},
            textString="+1",
            lineColor={0,0,255}),
          Text(
            extent={{-90,21},{-70,1}},
            textString="-1",
            lineColor={0,0,255}),
          Line(points={{-100,0},{84,0}}, color={95,95,95}),
          Polygon(
            points={{98,0},{82,6},{82,-6},{98,0}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},
                {-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{
                75.2,62.2},{77.6,67.5},{80,80}},
            color={0,0,255},
            thickness=0.5),
          Text(
            extent={{82,24},{102,4}},
            lineColor={95,95,95},
            textString="u"),
          Line(
            points={{0,80},{86,80}},
            color={175,175,175},
            smooth=Smooth.None),
          Line(
            points={{80,86},{80,-10}},
            color={175,175,175},
            smooth=Smooth.None)}),
      Documentation(info="<html>
<p>
This function returns y = asin(u), with -1 &le; u &le; +1:
</p>

<p>
<img src=\"../Images/Math/asin.png\">
</p>
</html>"),   Library="ModelicaExternalC");
  end asin;

  partial function baseIcon1
    "Basic icon for mathematical function with y-axis on left side"

    annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
              -100},{100,100}}), graphics={
          Rectangle(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,0},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-80,68}}, color={192,192,192}),
          Polygon(
            points={{-80,90},{-88,68},{-72,68},{-80,90}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-150,150},{150,110}},
            textString="%name",
            lineColor={0,0,255})}),                          Diagram(
          coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
          graphics={
          Line(points={{-80,80},{-88,80}}, color={95,95,95}),
          Line(points={{-80,-80},{-88,-80}}, color={95,95,95}),
          Line(points={{-80,-90},{-80,84}}, color={95,95,95}),
          Text(
            extent={{-75,104},{-55,84}},
            lineColor={95,95,95},
            textString="y"),
          Polygon(
            points={{-80,98},{-86,82},{-74,82},{-80,98}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid)}),
      Documentation(info="<html>
<p>
Icon for a mathematical function, consisting of an y-axis on the left side.
It is expected, that an x-axis is added and a plot of the function.
</p>
</html>"));
  end baseIcon1;

  partial function baseIcon2
    "Basic icon for mathematical function with y-axis in middle"

    annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
              -100},{100,100}}), graphics={
          Rectangle(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,0},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Line(points={{0,-80},{0,68}}, color={192,192,192}),
          Polygon(
            points={{0,90},{-8,68},{8,68},{0,90}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-150,150},{150,110}},
            textString="%name",
            lineColor={0,0,255})}),                          Diagram(
          coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
              100}}), graphics={
          Line(points={{0,80},{-8,80}}, color={95,95,95}),
          Line(points={{0,-80},{-8,-80}}, color={95,95,95}),
          Line(points={{0,-90},{0,84}}, color={95,95,95}),
          Text(
            extent={{5,104},{25,84}},
            lineColor={95,95,95},
            textString="y"),
          Polygon(
            points={{0,98},{-6,82},{6,82},{0,98}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid)}),
      Documentation(revisions="<html>
<p>
Icon for a mathematical function, consisting of an y-axis in the middle.
It is expected, that an x-axis is added and a plot of the function.
</p>
</html>"));
  end baseIcon2;
  annotation (
    Invisible=true,
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
        graphics={Text(
          extent={{-59,-9},{42,-56}},
          lineColor={0,0,0},
          textString="f(x)")}),
    Documentation(info="<HTML>
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
",   revisions="<html>
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

  package Constants
  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Library2;

    final constant Real pi=2*Modelica.Math.asin(1.0);

    final constant Real small=1.e-60
    "Smallest number such that small and -small are representable on the machine";
    annotation (
      Documentation(info="<html>
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
Copyright &copy; 1998-2009, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense2\">here</a>.</i>
</p><br>
</html>
",   revisions="<html>
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
</html>"),
      Invisible=true,
      Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={
          Line(
            points={{-34,-38},{12,-38}},
            color={0,0,0},
            thickness=0.5),
          Line(
            points={{-20,-38},{-24,-48},{-28,-56},{-34,-64}},
            color={0,0,0},
            thickness=0.5),
          Line(
            points={{-2,-38},{2,-46},{8,-56},{14,-64}},
            color={0,0,0},
            thickness=0.5)}),
      Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
              100,100}}), graphics={
          Rectangle(
            extent={{200,162},{380,312}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{200,312},{220,332},{400,332},{380,312},{200,312}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{400,332},{400,182},{380,162},{380,312},{400,332}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{210,302},{370,272}},
            lineColor={160,160,164},
            textString="Library"),
          Line(
            points={{266,224},{312,224}},
            color={0,0,0},
            thickness=1),
          Line(
            points={{280,224},{276,214},{272,206},{266,198}},
            color={0,0,0},
            thickness=1),
          Line(
            points={{298,224},{302,216},{308,206},{314,198}},
            color={0,0,0},
            thickness=1),
          Text(
            extent={{152,412},{458,334}},
            lineColor={255,0,0},
            textString="Modelica.Constants")}));
  end Constants;

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

    partial function Function "Icon for a function"

      annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                -100},{100,100}}), graphics={
            Text(
              extent={{-140,162},{136,102}},
              textString="%name",
              lineColor={0,0,255}),
            Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={255,127,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-100,100},{100,-100}},
              lineColor={255,127,0},
              textString="f")}),
                          Documentation(info="<html>
<p>
This icon is designed for a <b>function</b>
</p>
</html>"));
    end Function;
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

    package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Library2;

      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Library2;
        annotation (Documentation(info="<HTML>
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
"),   Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                  100}}), graphics={Text(
                extent={{-66,-13},{52,-67}},
                lineColor={0,0,0},
                textString="[km/h]")}));
      end NonSIunits;
      annotation (Icon(coordinateSystem(preserveAspectRatio=true,
                       extent={{-100,-100},{100,100}}), graphics={
            Text(
              extent={{-33,-7},{-92,-67}},
              lineColor={0,0,0},
              lineThickness=1,
              textString="°C"),
            Text(
              extent={{82,-7},{22,-67}},
              lineColor={0,0,0},
              textString="K"),
            Line(points={{-26,-36},{6,-36}}, color={0,0,0}),
            Polygon(
              points={{6,-28},{6,-45},{26,-37},{6,-28}},
              pattern=LinePattern.None,
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255})}),
                                Documentation(info="<HTML>
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

    type Angle = Real (
        final quantity="Angle",
        final unit="rad",
        displayUnit="deg");

    type Length = Real (final quantity="Length", final unit="m");

    type Area = Real (final quantity="Area", final unit="m2");

    type Time = Real (final quantity="Time", final unit="s");

    type Frequency = Real (final quantity="Frequency", final unit="Hz");

    type Density = Real (
        final quantity="Density",
        final unit="kg/m3",
        displayUnit="g/cm3",
        min=0);

    type Pressure = Real (
        final quantity="Pressure",
        final unit="Pa",
        displayUnit="bar");

    type AbsolutePressure = Pressure (min=0);

    type MassFlowRate = Real (quantity="MassFlowRate", final unit="kg/s");

    type SpecificEnergy = Real (final quantity="SpecificEnergy", final unit=
            "J/kg");

    type SpecificEnthalpy = SpecificEnergy;
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
revisionId="$Id: package.mo,v 1.3 2010/01/18 11:28:31 Dag Exp $",
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

package SiemensPower "SiemensPower"

  package Boundaries "Sources and sinks"

    model watersink_ph_StreamConcept
    "Pressure-enthalpy sink for simple water flows"
      import SI = Modelica.SIunits;

      parameter SI.AbsolutePressure p0=1.01325e5 "Pressure";
      parameter SI.SpecificEnthalpy h0=1e5 "Specific enthalpy for reverse flow";
      Interfaces.FluidPort_a_StreamConcept port
        annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
               0)));
      Modelica.Blocks.Interfaces.RealInput p_in
        annotation (Placement(transformation(
            origin={-40,80},
            extent={{-20,-20},{20,20}},
            rotation=270)));
     /* Modelica.Blocks.Interfaces.RealInput h_in    annotation (Placement(transformation(
        origin={40,80},
        extent={{-20,-20},{20,20}},
        rotation=270)));*/
    equation

      port.p = p_in;
      port.h_outflow = h0;

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Ellipse(
              extent={{-80,80},{80,-80}},
              lineColor={0,0,255},
              pattern=LinePattern.None,
              fillColor={0,128,255},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-20,34},{28,-26}},
              lineColor={255,255,255},
              textString="P"),
            Text(extent={{-100,-78},{100,-106}}, textString="%name"),
            Text(
              extent={{-96,94},{-46,64}},
              textString="p",
              lineColor={0,128,255}),
            Text(
              extent={{50,92},{100,62}},
              textString="h",
              lineColor={0,128,255})}),              Documentation(
     info="<HTML>
                    <p>This is a model for a fluid boundary condition with fixed
                   <ul>
                        <li> pressure
                        <li> specific enthalpy
                   </ul>
                    </p>
                    Note that the specific enthalpy value takes only effect in case of reverse flow.
                   </HTML>",
        revisions="<html>
                      <ul>
                              <li> Feb 2009, modified for stream connectors by Haiko Steuer
                              <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>"),
        Diagram(graphics));
    end watersink_ph_StreamConcept;
  annotation (Documentation(info="<html>
This package contains sources and sinks fluids and heat.
</html>"));
  end Boundaries;

  package Components "Aggregates"

    package Valves

      package Tests

        model valve_fixeddensity_test
        valve_fixeddensity valve_fixeddensity1
          annotation (Placement(transformation(extent={{-6,-30},{14,-10}})));
        Boundaries.watersink_ph_StreamConcept watersink_ph_StreamConcept(p0=
              100000, h0=1e5)
          annotation (Placement(transformation(extent={{58,-30},{78,-10}})));
          Modelica.Blocks.Sources.Sine sine(
            freqHz=0.01,
          amplitude=0.5e5,
          offset=1e5,
          startTime=5)
            annotation (Placement(transformation(extent={{-82,32},{-62,52}})));
          Modelica.Blocks.Sources.Ramp ramp2(
          startTime=500,
            duration=30,
          height=0,
          offset=1e5)
            annotation (Placement(transformation(extent={{34,32},{54,52}})));
          Modelica.Blocks.Sources.Ramp ramp3(
            offset=1,
            startTime=30,
            duration=300,
          height=0)
            annotation (Placement(transformation(extent={{-22,32},{-2,52}})));
        Boundaries.watersink_ph_StreamConcept watersink_ph_StreamConcept1(h0=
              2e5, p0=100000)
          annotation (Placement(transformation(extent={{-50,-30},{-70,-10}})));
        SiemensPower.Components.Valves.Tests.EnthalpySensor InStreamEnthalpy
          annotation (Placement(transformation(extent={{-48,58},{-28,78}})));
        equation
        connect(valve_fixeddensity1.port_b, watersink_ph_StreamConcept.port)
          annotation (Line(
            points={{14,-20},{58,-20}},
            color={0,127,255},
            smooth=Smooth.None));
        connect(ramp2.y, watersink_ph_StreamConcept.p_in) annotation (Line(
            points={{55,42},{64,42},{64,-12}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(ramp3.y, valve_fixeddensity1.Y) annotation (Line(
            points={{-1,42},{4,42},{4,-14}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(watersink_ph_StreamConcept1.port, valve_fixeddensity1.port_a)
          annotation (Line(
            points={{-50,-20},{-6,-20}},
            color={0,127,255},
            smooth=Smooth.None));
        connect(sine.y, watersink_ph_StreamConcept1.p_in) annotation (Line(
            points={{-61,42},{-56,42},{-56,-12}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(InStreamEnthalpy.port, valve_fixeddensity1.port_a) annotation (
            Line(
            points={{-38,58},{-38,-4},{-6,-4},{-6,-20}},
            color={0,127,255},
            smooth=Smooth.None));
        annotation (Diagram(graphics));
        end valve_fixeddensity_test;

        model EnthalpySensor "Ideal one port specific enthalpy sensor"

          Modelica.Blocks.Interfaces.RealOutput h_out(final quantity="SpecificEnergy",
                                                      final unit="J/kg")
          "Specific enthalpy in port medium"
            annotation (Placement(transformation(extent={{100,-10},{120,10}},
                  rotation=0)));

        Interfaces.FluidPort_a_StreamConcept port
            annotation (Placement(transformation(
                origin={0,-100},
                extent={{-10,-10},{10,10}},
                rotation=90)));

        equation
          port.m_flow = 0;
          port.h_outflow = 0;

          h_out = inStream(port.h_outflow);

        annotation (Documentation(info="<html>
<p>
Partial component to model an <b>absolute sensor</b>. Can be used for pressure sensor models.
Use for other properties such as temperature or density is discouraged, because the enthalpy at the connector can have different meanings, depending on the connection topology. Use <tt>PartialFlowSensor</tt> instead.
as signal.
</p>
</html>"),  Diagram(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}},
                grid={1,1}), graphics),
            Icon(coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={1,1}), graphics));
        end EnthalpySensor;
      end Tests;

      model valve_fixeddensity "Valve model with flexible behavior"
        import SI = Modelica.SIunits;
        import Fct = SiemensPower.Utilities.Functions;
      extends
        SiemensPower.Utilities.BaseClasses.PartialTwoPortIsenthalpicTransport(      final
          h_start_out =                                                                               h_start_in, final
          allowFlowReversal =    true);

        constant Real pi = Modelica.Constants.pi;
        constant Real a=0.536851 "Flow coefficient for steam valve";
        constant Real b=0.478107 "Flow coefficient for steam valve";

        parameter SI.Length d=0.2 "Diameter" annotation (Dialog(group="Geometry for water or steam valve",enable=kind_of_valve<>"linear valve" and explicit_geometry));
        parameter Real Kv=0.001
        "Hydraulic conductance at full opening for simple linear valve: mflow = Kv Y dp"
                annotation (Dialog(group="Geometry for linear valve",enable=kind_of_valve=="linear valve" and explicit_geometry));

        parameter Real Y0=1 "Opening Y (if not set from outide)";
        parameter Boolean OMC=false "Reverse flow stopped";

        // nominal values
        parameter SI.SpecificEnthalpy h_a_nom=h_start_in "Enthalpy at port_a"     annotation(Dialog(group="Nominal values (in case of no explicit geometry)", enable= not explicit_geometry));
        parameter SI.AbsolutePressure p_a_nom=p_start_in "Pressure at port_a" annotation(Dialog(group="Nominal values (in case of no explicit geometry)", enable= not explicit_geometry));
        parameter SI.AbsolutePressure p_b_nom=p_start_out "Pressure at port_b" annotation(Dialog(group="Nominal values (in case of no explicit geometry)", enable= not explicit_geometry));
        parameter SI.MassFlowRate m_flow_nom=m_start "Mass flow rate" annotation(Dialog(group="Nominal values (in case of no explicit geometry)", enable= not explicit_geometry));
        parameter Real Y_nom=Y0 "Valve opening" annotation(Dialog(group="Nominal values (in case of no explicit geometry)", enable= not explicit_geometry));

        parameter Real chi=8
        "Spray coefficient for water valve, m ~ sqrt(1/chi)"
            annotation (Dialog(tab="Advanced",enable=kind_of_valve=="water valve"));
        parameter Real delta=0.001
        "Regularisation factor for sqrtReg(x,deltareg)"                             annotation (Dialog(tab="Advanced",enable=kind_of_valve<>"linear valve"));

      //  final parameter Real Kv_nom=m_flow_nom/(Y_nom*(p_a_nom-p_b_nom))
       //   "hydraulic conductance due to nominal values";
      //  final parameter Real Klinear = (if explicit_geometry then Kv else Kv_nom)
       //   "actual hydraulic conductance";
       // final parameter SI.Length d_nom = d*sqrt(m_flow_nom/m_nom)
       //   "diameter due to nominal values";
        final parameter SI.Length diameter = d "actual diameter";
        final parameter SI.Area A = pi*0.25*diameter^2
        "inner cross sectional area";

         Modelica.Blocks.Interfaces.RealInput Y(start=Y0)
        "Opening (if desired)"
          annotation (Placement(transformation(
              origin={0,60},
              extent={{-20,-20},{20,20}},
              rotation=270)));

       //   Real x(start=p_start_out/p_start_in) "Pressure ratio";
      //    Real flowdirection;
          SI.Density rho;
          Real x;
          Real flowdirection;

      /*  final parameter SI.Density rho_nom =  SI.density(SI.setState_phX(p_a_nom,h_a_nom,X_start_in));
  final parameter Real x_nom = max(a,p_b_nom/p_a_nom);
  final parameter Real SteamPsi = b*Fct.sqrtReg(1-(x_nom-a)^2/(1-a)^2,delta);
  final parameter SI.MassFlowRate m_nom = pi*0.25*d^2*Y_nom*(if (kind_of_valve=="steam valve") then SteamPsi*Fct.sqrtReg(2*p_a_nom*rho_nom,delta*p_a_nom) else Fct.sqrtReg(2/chi*(p_a_nom-p_b_nom)*rho_nom,delta*p_a_nom));
*/
      equation
       // opening

       if (dp>=0) then
            x = port_b.p/port_a.p;
            flowdirection=1;

        else    //reverse flow
            x=port_a.p/port_b.p;
            flowdirection=-1;
       end if;

         rho=900;

         m_flow = flowdirection*A*Y*Fct.sqrtReg(2/chi*abs(dp)*rho,delta*p_a_nom);

        annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                  -100},{100,100}}), graphics={
              Polygon(
                points={{-100,40},{-100,-40},{0,0},{-100,40}},
                lineColor={0,0,0},
                pattern=LinePattern.None,
                lineThickness=0.5,
                fillPattern=FillPattern.Sphere,
                fillColor={0,128,255}),
              Polygon(
                points={{100,40},{0,0},{100,-40},{100,40}},
                lineColor={0,0,255},
                pattern=LinePattern.None,
                fillColor={0,128,255},
                fillPattern=FillPattern.Solid),
              Line(
                points={{-38,16},{-30,28},{-22,34},{-14,38},{-6,40},{4,40},{12,38},{
                    20,36},{28,32},{34,24},{38,16}},
                color={0,0,0},
                thickness=1),
              Text(
                extent={{-92,-22},{96,-82}},
                lineColor={0,0,0},
                lineThickness=1,
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid,
                textString="%kind_of_valve")}),
                                  Documentation(info="<HTML>
<p>Three modesl are availabe:
<ul>
<li> Steam valve according to Dynaplant model
<li> Water valve according to Dynaplant model
<li> Valve with simple linear behavior
</ul>
<p>
In all three models, CHECKVALVE can be chosen to avoid reverse flow.</HTML>",
            revisions="<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>"));
      end valve_fixeddensity;
    end Valves;
  annotation (Documentation(info="<html>
This package contains components of power plants.
</html>"));
  end Components;

  package Interfaces "Connectors"

    connector FluidPort_StreamConcept
    "Interface for quasi one-dimensional fluid flow in a piping network (incompressible or compressible, one or more phases, one or more substances)"
     import SI = Modelica.SIunits;
    //  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
    //    "Medium model" annotation (choicesAllMatching=true);

      flow SI.MassFlowRate m_flow
      "Mass flow rate from the connection point into the component";
      SI.AbsolutePressure p "Thermodynamic pressure in the connection point";
      stream SI.SpecificEnthalpy h_outflow
      "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
    //  stream Medium.MassFraction Xi_outflow[Medium.nXi]
    //    "Independent mixture mass fractions m_i/m close to the connection point if m_flow < 0";
    //  stream Medium.ExtraProperty C_outflow[Medium.nC]
    //    "Properties c_i/m close to the connection point if m_flow < 0";
    end FluidPort_StreamConcept;

    connector FluidPort_a_StreamConcept
    "Generic fluid connector at design inlet"
      extends SiemensPower.Interfaces.FluidPort_StreamConcept;
      annotation (defaultComponentName="port_a",
                  Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Ellipse(
              extent={{-40,40},{40,-40}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid), Text(extent={{-150,110},{150,50}},
                textString="%name")}),
           Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
                100,100}}), graphics={Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,127,255},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid), Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid)}));
    end FluidPort_a_StreamConcept;

    connector FluidPort_b_StreamConcept
    "Generic fluid connector at design outlet"
      extends SiemensPower.Interfaces.FluidPort_StreamConcept;
      annotation (defaultComponentName="port_b",
                  Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Ellipse(
              extent={{-40,40},{40,-40}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-30,30},{30,-30}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{-150,110},{150,50}}, textString="%name")}),
           Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
                100,100}}), graphics={
            Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,127,255},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              fillColor={0,127,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-80,80},{80,-80}},
              lineColor={0,127,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}));
    end FluidPort_b_StreamConcept;
  annotation (Documentation(info="<html>
This package contains interfaces if not present in the boundary package.
</html>"));
  end Interfaces;

  package Utilities "Parts and basics of components"

    package BaseClasses "Partial models"

      partial model PartialTwoPortIsenthalpicTransport
      "Partial element transporting fluid between two ports without storing mass or enthalpy"
        import SI = Modelica.SIunits;
        import CO = Modelica.Constants;
        extends
        SiemensPower.Utilities.BaseClasses.PartialTwoPortTransport_StreamConcept(
         h_start_out=h_start_in);

         // Advanced
         parameter Boolean allowFlowReversal = true "Allow flow reversal" annotation(Dialog(tab = "Advanced"));
         parameter SI.MassFlowRate m_flow_small = m_start/100
        "Small mass flow rate for regularization of zero flow"
          annotation(Dialog(tab = "Advanced", group="Upstream", enable=smoothUpstreamMedium and allowFlowReversal));

      //  Medium.ThermodynamicState stateUpstream "state for upstream medium";
        SI.MassFlowRate m_flow(start=m_start)
        "Mass flow rate from port_a to port_b (m_flow > 0 is design flow direction)";

    protected
        SI.AbsolutePressure p;
        SI.SpecificEnthalpy h;
        Real fromleft; //0 ...1

      equation
        // no mass storage
        m_flow = port_a.m_flow;
        port_a.m_flow + port_b.m_flow = 0;

        // Isenthalpic flow
        port_a.h_outflow = inStream(port_b.h_outflow);
        port_b.h_outflow = inStream(port_a.h_outflow);

        // upstream medium

           if noEvent(m_flow>m_flow_small) then
             fromleft = 1;
           elseif noEvent(m_flow<-m_flow_small) then
             fromleft = 0;
           else
               fromleft = 0.5*(1 - 0.5*m_flow/m_flow_small*((m_flow/m_flow_small)^2-3)); // Modelica.Fluid.Utilities.regStep
           end if;

        p = fromleft*port_a.p+(1-fromleft)*port_b.p;
        h  = fromleft*inStream(port_a.h_outflow) +(1-fromleft)*inStream(port_b.h_outflow);

       annotation (
          Diagram(coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={1,1}), graphics),
          Documentation(info="<html>
<p>
This component transports fluid between its two ports, without
storing mass or energy.
When using this partial component, an equation for the momentum
balance has to be added by specifying a relationship
between the pressure drop \"port_a.p - port_b.p\" and the
mass flow rate \"m_flow = port_a.m_flow\".
</p>
</html>",
      revisions="<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</html>"));
      end PartialTwoPortIsenthalpicTransport;

      partial model PartialTwoPortTransport_StreamConcept
      "Base class for components with two fluid ports"
        import SI = Modelica.SIunits;

       /* Medium.ThermodynamicState medium_a(p(start=p_start_in), T(start=T_start_in))
    "actual state at port_a";
  Medium.ThermodynamicState medium_b(p(start=p_start_out), T(start=T_start_out))
    "actual state at port_b";

// Medium
  replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
    constrainedby Modelica.Media.Interfaces.PartialMedium
           annotation (choicesAllMatching = true);
*/
        parameter Boolean preferredStates=true
        "Try to select preferred medium states"                                        annotation(Dialog(tab="Advanced"));

      // Initializatin parameters
       parameter Modelica.SIunits.MassFlowRate m_start=1
        "Guess value for mass flow rate"                                                   annotation(Dialog(tab="Initialization"));

        parameter SI.AbsolutePressure p_start_in = 1.1e5
        "Start value of inlet pressure"
          annotation(Dialog(tab = "Initialization"));
        parameter SI.AbsolutePressure p_start_out = 1.0e5
        "Start value of outlet pressure"
          annotation(Dialog(tab = "Initialization"));

       parameter Boolean use_T_start = false
        "Use T_start if true, otherwise h_start"
          annotation(Dialog(tab = "Initialization"), Evaluate=true);

        parameter SI.SpecificEnthalpy h_start_in= 300e3
        "Start value of specific enthalpy"
          annotation(Dialog(tab = "Initialization", enable = not use_T_start));
        parameter SI.SpecificEnthalpy h_start_out= 300e3
        "Start value of specific enthalpy"
          annotation(Dialog(tab = "Initialization", enable = not use_T_start));

      //  parameter SI.MassFraction X_start_in[Medium.nX] = Medium.reference_X
       //   "Start value of mass fractions m_i/m"
       // parameter SI.MassFraction X_start_out[Medium.nX] = Medium.reference_X
        //  "Start value of mass fractions m_i/m"

        Interfaces.FluidPort_a_StreamConcept port_a "Inlet port"
                                                                annotation (Placement(transformation(extent={{-120,-20},{-80,
                  20}}, rotation=0), iconTransformation(extent={{-120,-20},{-80,20}})));

        Interfaces.FluidPort_b_StreamConcept port_b "Outlet port"
                                                                 annotation (Placement(transformation(extent={{120,-20},{80,20}},
                rotation=0), iconTransformation(extent={{120,-20},{80,20}})));

        SI.Pressure dp(start=p_start_in-p_start_out);

      /*  Medium.ThermodynamicState state_from_a(p(start=p_start_in), T(start=T_start_in))
    "state for medium inflowing through port_a";
  Medium.ThermodynamicState state_from_b(p(start=p_start_out), T(start=T_start_out))
    "state for medium inflowing through port_b";
*/
      equation
      // medium states

        dp = port_a.p - port_b.p;

        // no substance storage

          annotation (Dialog(tab="Initialization", enable=Medium.nXi > 0), uses(
              Modelica(version="3.1")),
                      Dialog(tab="Initialization", enable=Medium.nXi > 0),
                    Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
                  -100},{100,100}}), graphics),
          Documentation(info="<HTML>
<p>This base class describes the geometry and most important variables for the fluid flow without storing substance.<br>
In the derived class, the following quantities/equations have to be set:<br>
<ul>
<li> pressure loss dp (e.g. momentum balance)
<li> mass flow rate (e.g. mass balance)
<li> outflow enthalpies (e.g. energy balance)
<li>
</ul>
<p>
</HTML>",   revisions="<html>
<ul>
<li> Feb 2009, added by Haiko Steuer
</ul>
</HTML>"),Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                  100}}), graphics));
      end PartialTwoPortTransport_StreamConcept;
    annotation (Documentation(info="<html>
This package contains partial base classes.
</html>"));
    end BaseClasses;

    package Functions "Algorithms and external functions"

      function der_sqrtReg "Time derivative of sqrtReg"
        extends Modelica.Icons.Function;
        input Real x;
        input Real delta=0.01 "Range of significant deviation from sqrt(x)";
        input Real dx "Derivative of x";
        output Real dy;
      algorithm
        dy := dx*0.5*(x*x+2*delta*delta)/((x*x+delta*delta)^1.25);
      annotation (Documentation(info="<html>
Computing the time derivative of the sqrt approximation sqrtReg
</html>",   revisions="<html>
<ul>
<li> December 2006, added to SiemensPower by Haiko Steuer
<li><i>15 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Created. </li>
</ul>
</html>"));
      end der_sqrtReg;

      function sqrtReg
      "Symmetric square root approximation with finite derivative in zero"
        extends Modelica.Icons.Function;
        input Real x;
        input Real delta=0.01 "Range of significant deviation from sqrt(x)";
        output Real y;

      algorithm
        y := x/sqrt(sqrt(x*x+delta*delta));

       annotation(derivative(zeroDerivative=delta)=SiemensPower.Utilities.Functions.der_sqrtReg,
          Documentation(info="<html>
This function approximates sqrt(x)*sign(x), such that the derivative is finite and smooth in x=0.
</p>
<p>
<table border=1 cellspacing=0 cellpadding=2>
<tr><th>Function</th><th>Approximation</th><th>Range</th></tr>
<tr><td>y = sqrtReg(x)</td><td>y ~= sqrt(abs(x))*sign(x)</td><td>abs(x) &gt;&gt delta</td></tr>
<tr><td>y = sqrtReg(x)</td><td>y ~= x/sqrt(delta)</td><td>abs(x) &lt;&lt  delta</td></tr>
</table>
<p>
With the default value of delta=0.01, the difference between sqrt(x) and sqrtReg(x) is 16% around x=0.1, 0.25% around x=0.1 and 0.0025% around x=1.
</p>
</html>",   revisions="<html>
<ul>
<li>December 2006, added to SiemensPower by Haiko Steuer
<li><i>15 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Created. </li>
</ul>
</html>"));
      end sqrtReg;
    annotation (Documentation(info="<html>
This package contains functions.
</html>"));
    end Functions;
  annotation (Documentation(info="<html>
This package contains basic utilities.
</html>"));
  end Utilities;
    annotation (
  version="1.6",
 preferedView="info",
 uses(Modelica(version="3.1")),
     Documentation(info="<html>
<blockquote>This branch is intended to build the basis for real life test models for modelica environments not supporting Modelica.Media and Streams.</blockquote>
<blockquote>Any use in project should be avoided.</blockquote>
<blockquote>At the Moment only a few models have been adapted and the remaining models might be damaged. </blockquote>
<blockquote>Models that haven been changed:</blockquote>
<p><ol>
<li>Medium, Stream and Composition have been removed from the Fluid connector and the connector moved to SiemensPower.Interfaces.</li>
<li>Only the water/steam sources have been adapted so far.</li>
<li></li>
</ol></p>
<p><br/>N&ouml;tige &Auml;nderungen:</p>
<p><ol>
<li>kein if then else zur Definition von Parametern. Spezialfall linspace N = 1 in linspace.</li>
<li>&Uuml;bergabe von Argumentern an Funktionen in Funktionen in SiemensPower.Media.TTSE. Check der exportierten Funktionen in ttse_dym.a.</li>
</ol></p>
<p><b><font style=\"font-size: 10pt; \">Articles</font></b></p>
<p><ul>
<li>For the user: Frequently asked questions regarding Dymola, Modelica and SiemensPower: <a href=\"http://diagnostics-cvs/trac/Modelica/wiki/Dymola/DymolaFAQ\">FAQ</a> </li>
<li>For the model developer: <a href=\"http://diagnostics-cvs/trac/Modelica/wiki/SiemensPower/ModellingGuidelines\">Guidelines</a> </li>
</ul></p>
<p><b><font style=\"font-size: 10pt; \">Contact</font></b> </p>
<blockquote><a href=\"mailto:Kilian.Link@siemens.com\">Kilian Link</a></blockquote>
<blockquote>Siemens AG</blockquote>
<blockquote>Energy Sector </blockquote>
<blockquote>E F ES EN 12 </blockquote>
<blockquote>P.O. Box 3220 </blockquote>
<blockquote>91050 Erlangen </blockquote>
<blockquote>Germany </blockquote>
<p><b><font style=\"font-size: 10pt; \">Copyright and Disclaimer</font></b> </p>
<blockquote><br/>Copyright &AMP;copy 2007-2009 Siemens AG, E F ES EN 12. All rights reserved.</blockquote>
<blockquote><br/>The library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a>. </blockquote>
</html>",
revisions="<html>
See <a href=\"http://diagnostics-cvs/trac/Modelica/roadmap\">roadmap</a> for future developments.
<ul>
<li> Dec 2009, SiemensPower 1.6 based on Modelica 3.1 (including Modelica.Fluid)
<li> April 2009, SiemensPower 1.4 based on Modelica.Fluid 1.0 (stream connector)
<li> Feb 2009, SiemensPower 1.1 based on MSL 3.0
<li> Oct 2008, SiemensPower 1.0 based on Modelica.Fluid 1.0 Beta 2
</ul>
</HTML>"));
end SiemensPower;
model SiemensPower_Components_Valves_Tests_valve_fixeddensity_test
 extends SiemensPower.Components.Valves.Tests.valve_fixeddensity_test;
  annotation(experiment(
    StopTime=1000,
    NumberOfIntervals=500,
    Tolerance=0.0001,
    Algorithm="dassl"),uses(SiemensPower(version="1.6")));
end SiemensPower_Components_Valves_Tests_valve_fixeddensity_test;

// Result:
// function Modelica.Math.asin "Inverse sine (-1 <= u <= 1)"
//   input Real u;
//   output Real y(quantity = "Angle", unit = "rad", displayUnit = "deg");
//
//   external "C" y = asin(u);
// end Modelica.Math.asin;
//
// function Modelica.Math.sin "Sine"
//   input Real u(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   output Real y;
//
//   external "C" y = sin(u);
// end Modelica.Math.sin;
//
// function SiemensPower.Utilities.Functions.der_sqrtReg "Time derivative of sqrtReg"
//   input Real x;
//   input Real delta = 0.01 "Range of significant deviation from sqrt(x)";
//   input Real dx "Derivative of x";
//   output Real dy;
// algorithm
//   dy := 0.5 * dx * (x ^ 2.0 + 2.0 * delta ^ 2.0) / (x ^ 2.0 + delta ^ 2.0) ^ 1.25;
// end SiemensPower.Utilities.Functions.der_sqrtReg;
//
// function SiemensPower.Utilities.Functions.sqrtReg "Symmetric square root approximation with finite derivative in zero"
//   input Real x;
//   input Real delta = 0.01 "Range of significant deviation from sqrt(x)";
//   output Real y;
// algorithm
//   y := x / (x ^ 2.0 + delta ^ 2.0) ^ 0.25;
// end SiemensPower.Utilities.Functions.sqrtReg;
//
// class SiemensPower_Components_Valves_Tests_valve_fixeddensity_test
//   parameter Boolean valve_fixeddensity1.preferredStates = true "Try to select preferred medium states";
//   parameter Real valve_fixeddensity1.m_start(quantity = "MassFlowRate", unit = "kg/s") = 1.0 "Guess value for mass flow rate";
//   parameter Real valve_fixeddensity1.p_start_in(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) = 110000.0 "Start value of inlet pressure";
//   parameter Real valve_fixeddensity1.p_start_out(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) = 100000.0 "Start value of outlet pressure";
//   parameter Boolean valve_fixeddensity1.use_T_start = false "Use T_start if true, otherwise h_start";
//   parameter Real valve_fixeddensity1.h_start_in(quantity = "SpecificEnergy", unit = "J/kg") = 300000.0 "Start value of specific enthalpy";
//   parameter Real valve_fixeddensity1.h_start_out(quantity = "SpecificEnergy", unit = "J/kg") = valve_fixeddensity1.h_start_in "Start value of specific enthalpy";
//   Real valve_fixeddensity1.port_a.m_flow(quantity = "MassFlowRate", unit = "kg/s") "Mass flow rate from the connection point into the component";
//   Real valve_fixeddensity1.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) "Thermodynamic pressure in the connection point";
//   Real valve_fixeddensity1.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg") "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
//   Real valve_fixeddensity1.port_b.m_flow(quantity = "MassFlowRate", unit = "kg/s") "Mass flow rate from the connection point into the component";
//   Real valve_fixeddensity1.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) "Thermodynamic pressure in the connection point";
//   Real valve_fixeddensity1.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg") "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
//   Real valve_fixeddensity1.dp(quantity = "Pressure", unit = "Pa", displayUnit = "bar", start = valve_fixeddensity1.p_start_in - valve_fixeddensity1.p_start_out);
//   parameter Boolean valve_fixeddensity1.allowFlowReversal = true "Allow flow reversal";
//   parameter Real valve_fixeddensity1.m_flow_small(quantity = "MassFlowRate", unit = "kg/s") = 0.01 * valve_fixeddensity1.m_start "Small mass flow rate for regularization of zero flow";
//   Real valve_fixeddensity1.m_flow(quantity = "MassFlowRate", unit = "kg/s", start = valve_fixeddensity1.m_start) "Mass flow rate from port_a to port_b (m_flow > 0 is design flow direction)";
//   protected Real valve_fixeddensity1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0);
//   protected Real valve_fixeddensity1.h(quantity = "SpecificEnergy", unit = "J/kg");
//   protected Real valve_fixeddensity1.fromleft;
//   constant Real valve_fixeddensity1.pi = 3.141592653589793;
//   parameter Real valve_fixeddensity1.d(quantity = "Length", unit = "m") = 0.2 "Diameter";
//   parameter Real valve_fixeddensity1.Kv = 0.001 "Hydraulic conductance at full opening for simple linear valve: mflow = Kv Y dp";
//   parameter Real valve_fixeddensity1.Y0 = 1.0 "Opening Y (if not set from outide)";
//   parameter Boolean valve_fixeddensity1.OMC = false "Reverse flow stopped";
//   parameter Real valve_fixeddensity1.h_a_nom(quantity = "SpecificEnergy", unit = "J/kg") = valve_fixeddensity1.h_start_in "Enthalpy at port_a";
//   parameter Real valve_fixeddensity1.p_a_nom(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) = valve_fixeddensity1.p_start_in "Pressure at port_a";
//   parameter Real valve_fixeddensity1.p_b_nom(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) = valve_fixeddensity1.p_start_out "Pressure at port_b";
//   parameter Real valve_fixeddensity1.m_flow_nom(quantity = "MassFlowRate", unit = "kg/s") = valve_fixeddensity1.m_start "Mass flow rate";
//   parameter Real valve_fixeddensity1.Y_nom = valve_fixeddensity1.Y0 "Valve opening";
//   parameter Real valve_fixeddensity1.chi = 8.0 "Spray coefficient for water valve, m ~ sqrt(1/chi)";
//   parameter Real valve_fixeddensity1.delta = 0.001 "Regularisation factor for sqrtReg(x,deltareg)";
//   final parameter Real valve_fixeddensity1.diameter(quantity = "Length", unit = "m") = valve_fixeddensity1.d "actual diameter";
//   final parameter Real valve_fixeddensity1.A(quantity = "Area", unit = "m2") = 0.7853981633974483 * valve_fixeddensity1.diameter ^ 2.0 "inner cross sectional area";
//   Real valve_fixeddensity1.Y(start = valve_fixeddensity1.Y0) "Opening (if desired)";
//   Real valve_fixeddensity1.rho(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
//   Real valve_fixeddensity1.x;
//   Real valve_fixeddensity1.flowdirection;
//   parameter Real watersink_ph_StreamConcept.p0(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) = 100000.0 "Pressure";
//   parameter Real watersink_ph_StreamConcept.h0(quantity = "SpecificEnergy", unit = "J/kg") = 100000.0 "Specific enthalpy for reverse flow";
//   Real watersink_ph_StreamConcept.port.m_flow(quantity = "MassFlowRate", unit = "kg/s") "Mass flow rate from the connection point into the component";
//   Real watersink_ph_StreamConcept.port.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) "Thermodynamic pressure in the connection point";
//   Real watersink_ph_StreamConcept.port.h_outflow(quantity = "SpecificEnergy", unit = "J/kg") "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
//   Real watersink_ph_StreamConcept.p_in;
//   Real sine.y "Connector of Real output signal";
//   parameter Real sine.amplitude = 50000.0 "Amplitude of sine wave";
//   parameter Real sine.freqHz(quantity = "Frequency", unit = "Hz", start = 1.0) = 0.01 "Frequency of sine wave";
//   parameter Real sine.phase(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Phase of sine wave";
//   parameter Real sine.offset = 100000.0 "Offset of output signal";
//   parameter Real sine.startTime(quantity = "Time", unit = "s") = 5.0 "Output = offset for time < startTime";
//   protected constant Real sine.pi = 3.141592653589793;
//   Real ramp2.y "Connector of Real output signal";
//   parameter Real ramp2.height = 0.0 "Height of ramps";
//   parameter Real ramp2.duration(quantity = "Time", unit = "s", min = 1e-60, start = 2.0) = 30.0 "Durations of ramp";
//   parameter Real ramp2.offset = 100000.0 "Offset of output signal";
//   parameter Real ramp2.startTime(quantity = "Time", unit = "s") = 500.0 "Output = offset for time < startTime";
//   Real ramp3.y "Connector of Real output signal";
//   parameter Real ramp3.height = 0.0 "Height of ramps";
//   parameter Real ramp3.duration(quantity = "Time", unit = "s", min = 1e-60, start = 2.0) = 300.0 "Durations of ramp";
//   parameter Real ramp3.offset = 1.0 "Offset of output signal";
//   parameter Real ramp3.startTime(quantity = "Time", unit = "s") = 30.0 "Output = offset for time < startTime";
//   parameter Real watersink_ph_StreamConcept1.p0(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) = 100000.0 "Pressure";
//   parameter Real watersink_ph_StreamConcept1.h0(quantity = "SpecificEnergy", unit = "J/kg") = 200000.0 "Specific enthalpy for reverse flow";
//   Real watersink_ph_StreamConcept1.port.m_flow(quantity = "MassFlowRate", unit = "kg/s") "Mass flow rate from the connection point into the component";
//   Real watersink_ph_StreamConcept1.port.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) "Thermodynamic pressure in the connection point";
//   Real watersink_ph_StreamConcept1.port.h_outflow(quantity = "SpecificEnergy", unit = "J/kg") "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
//   Real watersink_ph_StreamConcept1.p_in;
//   Real InStreamEnthalpy.h_out(quantity = "SpecificEnergy", unit = "J/kg") "Specific enthalpy in port medium";
//   Real InStreamEnthalpy.port.m_flow(quantity = "MassFlowRate", unit = "kg/s") "Mass flow rate from the connection point into the component";
//   Real InStreamEnthalpy.port.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) "Thermodynamic pressure in the connection point";
//   Real InStreamEnthalpy.port.h_outflow(quantity = "SpecificEnergy", unit = "J/kg") "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
// equation
//   if valve_fixeddensity1.dp >= 0.0 then
//     valve_fixeddensity1.x = valve_fixeddensity1.port_b.p / valve_fixeddensity1.port_a.p;
//     valve_fixeddensity1.flowdirection = 1.0;
//   else
//     valve_fixeddensity1.x = valve_fixeddensity1.port_a.p / valve_fixeddensity1.port_b.p;
//     valve_fixeddensity1.flowdirection = -1.0;
//   end if;
//   valve_fixeddensity1.rho = 900.0;
//   valve_fixeddensity1.m_flow = valve_fixeddensity1.flowdirection * valve_fixeddensity1.A * valve_fixeddensity1.Y * SiemensPower.Utilities.Functions.sqrtReg(2.0 * abs(valve_fixeddensity1.dp) * valve_fixeddensity1.rho / valve_fixeddensity1.chi, valve_fixeddensity1.delta * valve_fixeddensity1.p_a_nom);
//   valve_fixeddensity1.m_flow = valve_fixeddensity1.port_a.m_flow;
//   valve_fixeddensity1.port_a.m_flow + valve_fixeddensity1.port_b.m_flow = 0.0;
//   valve_fixeddensity1.port_a.h_outflow = watersink_ph_StreamConcept.port.h_outflow;
//   valve_fixeddensity1.port_b.h_outflow = $OMC$inStreamDiv(($OMC$PositiveMax(-watersink_ph_StreamConcept1.port.m_flow, 1e-07) * watersink_ph_StreamConcept1.port.h_outflow + $OMC$PositiveMax(-InStreamEnthalpy.port.m_flow, 1e-07) * InStreamEnthalpy.port.h_outflow) / ($OMC$PositiveMax(-watersink_ph_StreamConcept1.port.m_flow, 1e-07) + $OMC$PositiveMax(-InStreamEnthalpy.port.m_flow, 1e-07)), watersink_ph_StreamConcept1.port.h_outflow);
//   if noEvent(valve_fixeddensity1.m_flow > valve_fixeddensity1.m_flow_small) then
//     valve_fixeddensity1.fromleft = 1.0;
//   elseif noEvent(valve_fixeddensity1.m_flow < (-valve_fixeddensity1.m_flow_small)) then
//     valve_fixeddensity1.fromleft = 0.0;
//   else
//     valve_fixeddensity1.fromleft = 0.5 * (1.0 + (-0.5) * valve_fixeddensity1.m_flow * (-3.0 + (valve_fixeddensity1.m_flow / valve_fixeddensity1.m_flow_small) ^ 2.0) / valve_fixeddensity1.m_flow_small);
//   end if;
//   valve_fixeddensity1.p = valve_fixeddensity1.fromleft * valve_fixeddensity1.port_a.p + (1.0 - valve_fixeddensity1.fromleft) * valve_fixeddensity1.port_b.p;
//   valve_fixeddensity1.h = valve_fixeddensity1.fromleft * $OMC$inStreamDiv(($OMC$PositiveMax(-watersink_ph_StreamConcept1.port.m_flow, 1e-07) * watersink_ph_StreamConcept1.port.h_outflow + $OMC$PositiveMax(-InStreamEnthalpy.port.m_flow, 1e-07) * InStreamEnthalpy.port.h_outflow) / ($OMC$PositiveMax(-watersink_ph_StreamConcept1.port.m_flow, 1e-07) + $OMC$PositiveMax(-InStreamEnthalpy.port.m_flow, 1e-07)), watersink_ph_StreamConcept1.port.h_outflow) + (1.0 - valve_fixeddensity1.fromleft) * watersink_ph_StreamConcept.port.h_outflow;
//   valve_fixeddensity1.dp = valve_fixeddensity1.port_a.p - valve_fixeddensity1.port_b.p;
//   watersink_ph_StreamConcept.port.p = watersink_ph_StreamConcept.p_in;
//   watersink_ph_StreamConcept.port.h_outflow = watersink_ph_StreamConcept.h0;
//   sine.y = sine.offset + (if time < sine.startTime then 0.0 else sine.amplitude * sin(6.283185307179586 * sine.freqHz * (time - sine.startTime) + sine.phase));
//   ramp2.y = ramp2.offset + (if time < ramp2.startTime then 0.0 else if time < ramp2.startTime + ramp2.duration then (time - ramp2.startTime) * ramp2.height / ramp2.duration else ramp2.height);
//   ramp3.y = ramp3.offset + (if time < ramp3.startTime then 0.0 else if time < ramp3.startTime + ramp3.duration then (time - ramp3.startTime) * ramp3.height / ramp3.duration else ramp3.height);
//   watersink_ph_StreamConcept1.port.p = watersink_ph_StreamConcept1.p_in;
//   watersink_ph_StreamConcept1.port.h_outflow = watersink_ph_StreamConcept1.h0;
//   InStreamEnthalpy.port.m_flow = 0.0;
//   InStreamEnthalpy.port.h_outflow = 0.0;
//   InStreamEnthalpy.h_out = $OMC$inStreamDiv(($OMC$PositiveMax(-valve_fixeddensity1.port_a.m_flow, 1e-07) * valve_fixeddensity1.port_a.h_outflow + $OMC$PositiveMax(-watersink_ph_StreamConcept1.port.m_flow, 1e-07) * watersink_ph_StreamConcept1.port.h_outflow) / ($OMC$PositiveMax(-valve_fixeddensity1.port_a.m_flow, 1e-07) + $OMC$PositiveMax(-watersink_ph_StreamConcept1.port.m_flow, 1e-07)), valve_fixeddensity1.port_a.h_outflow);
//   valve_fixeddensity1.port_a.m_flow + watersink_ph_StreamConcept1.port.m_flow + InStreamEnthalpy.port.m_flow = 0.0;
//   valve_fixeddensity1.port_b.m_flow + watersink_ph_StreamConcept.port.m_flow = 0.0;
//   valve_fixeddensity1.port_b.p = watersink_ph_StreamConcept.port.p;
//   ramp2.y = watersink_ph_StreamConcept.p_in;
//   ramp3.y = valve_fixeddensity1.Y;
//   InStreamEnthalpy.port.p = valve_fixeddensity1.port_a.p;
//   InStreamEnthalpy.port.p = watersink_ph_StreamConcept1.port.p;
//   sine.y = watersink_ph_StreamConcept1.p_in;
// end SiemensPower_Components_Valves_Tests_valve_fixeddensity_test;
// endResult
