// name:     Gear - Complete example with Gear
// keywords: Gear, Mechanics, Modelica2.2
// status:   correct
// cflags:   +std=2.x
//
// Testing instantiation of the Gear model
//


package Modelica "Modelica Standard Library"
extends Icons.Library;
annotation(preferedView="info",
  Window(
    x=0.02,
    y=0.01,
    width=0.2,
    height=0.57,
    library=1,
    autolayout=1),
  version="2.2",
  versionDate="2005-04-15",
  conversion(
    from(version="1.6",
         ModelicaAdditions(version="1.5"),
         MultiBody(version="1.0.1"),
         MultiBody(version="1.0"),
         Matrices(version="0.8"),
         script="Scripts/ConvertModelica_from_1.6_to_2.1.mos"),
    from(version="2.1 Beta1", script="Scripts/ConvertModelica_from_2.1Beta1_to_2.1.mos"),
    noneFromVersion= "2.1"),
  Settings(NewStateSelection=true),
  Documentation(info="<HTML>
<p>
Package <b>Modelica</b> is a <b>standardized</b> and <b>pre-defined</b> package
that is developed together with the Modelica language from the
Modelica Association, see
<a href=\"http://www.Modelica.org\">http://www.Modelica.org</a>.
It is also called <b>Modelica Standard Library</b>.
It provides constants, types, connectors, partial models and model
components
in various disciplines.
</p>
<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"Modelica://Modelica.UsersGuide\">Users Guide</a>
     discusses the most important aspects of this library.</li>
<li><a href=\"Modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
    summarizes the changes of new versions of this package.</li>
<li> Packages <b>Examples</b> in the various subpackages, provide
     demos of the corresponding subpackage.</li>
</ul>
<p>
The Modelica package consists currently of the following subpackages
</p>

<table border=1 cellspacing=0 cellpadding=2>
  <tr><td><a href=\"Modelica://Modelica.Blocks\">Blocks</a></td>
      <td>Continuous, discrete and logical input/output blocks</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.Constants\">Constants</a></td>
      <td>Mathematical and physical constants (pi, eps, h, ...)</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.Electrical\">Electrical</a></td>
      <td> Electric and electronic components<br>
           (<a href=\"Modelica://Modelica.Electrical.Analog\">Analog</a>,
            <a href=\"Modelica://Modelica.Electrical.Digital\">Digital</a>,
            <a href=\"Modelica://Modelica.Electrical.Machines\">Machines</a>,
            <a href=\"Modelica://Modelica.Electrical.MultiPhase\">MultiPhase</a>)</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.Icons\">Icons</a></td>
      <td>Icon definitions</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.Math\">Math</a></td>
      <td>Mathematical functions for scalars and
          <a href=\"Modelica://Modelica.Math.Matrices\">Matrices</a><br>
         (such as sin, cos, solve, eigenValues, singular values)</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.Mechanics\">Mechanics</a></td>
      <td>Mechanical components<br>
          (<a href=\"Modelica://Modelica.Mechanics.Rotational\">1D-rotational</a>,
           <a href=\"Modelica://Modelica.Mechanics.Translational\">1D-translational</a>,
           <a href=\"Modelica://Modelica.Mechanics.MultiBody\">3D multi-body</a>)</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.Media\">Media</a></td>
      <td>Media models for liquids and gases<br>
          (about 1250 media, including high precision water model)</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.SIunits\">SIunits</a></td>
      <td>SI-unit type definitions (such as Voltage, Torque)</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.StateGraph\">StateGraph</a></td>
      <td>Hierarchical state machines (similiar power as Statecharts)</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.Thermal\">Thermal</a></td>
      <td>Thermal components<br>
          (<a href=\"Modelica://Modelica.Thermal.HeatTransfer\">1-D lumped heat transfer</a>,
          <a href=\"Modelica://Modelica.Thermal.FluidHeatFlow\">1-D incompressible thermo-fluid flow</a>)</td>
  </tr>

  <tr><td><a href=\"Modelica://Modelica.Utilities\">Utilities</a></td>
      <td>Utility functions especially for scripting<br>
          (<a href=\"Modelica://Modelica.Utilities.Files\">Files</a>,
          <a href=\"Modelica://Modelica.Utilities.Streams\">Streams</a>,
          <a href=\"Modelica://Modelica.Utilities.Strings\">Strings</a>,
          <a href=\"Modelica://Modelica.Utilities.System\">System</a>)</td>
  </tr>
</table>

<p>
Copyright &copy; 1998-2005, Modelica Association.
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</HTML>
"));

  package Blocks "Library for basic input/output control blocks"
    import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;
  annotation(preferedView="info",
    Window(
      x=0.03,
      y=0.05,
      width=0.21,
      height=0.48,
      library=1,
      autolayout=1),
    Icon(
      Rectangle(extent=[-32, -6; 16, -35], style(color=0)),
      Rectangle(extent=[-32, -56; 16, -85], style(color=0)),
      Line(points=[16, -20; 49, -20; 49, -71; 16, -71], style(color=0)),
      Line(points=[-32, -72; -64, -72; -64, -21; -32, -21], style(color=0)),
      Polygon(points=[16, -71; 29, -67; 29, -74; 16, -71], style(
          color=0,
          fillColor=0,
          fillPattern=1)),
      Polygon(points=[-32, -21; -46, -17; -46, -25; -32, -21], style(
          color=0,
          fillColor=0,
          fillPattern=1))), Documentation(info="<html>
<p>
This library contains input/output blocks to build up block diagrams.
The library is structured in the following sublibraries:
</p>
<pre>
  Interfaces    Connectors and partial models for block diagram components
  Examples      Demonstration examples
  Continuous    Basic continuous input/output blocks
  Discrete      Discrete control blocks
  Logical       Logical and relational operations on Boolean signals
  Nonlinear     Discontinuous or non-differentiable algebraic
                control blocks
  Math          Mathematical functions as input/output blocks
  Sources       Sources such as signal generators
  Routing       Combine and extract signals
  Tables        One and two-dimensional interpolation in tables
  Types         Constants and types with choices, especially to build menus
</pre>
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
Copyright &copy; 1998-2005, Modelica Association and DLR.
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
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

    package Interfaces "Connectors and partial models for input/output blocks"
      import Modelica.SIunits;
        extends Modelica.Icons.Library;
        annotation(preferedView="info",
          Coordsys(
            extent=[0, 0; 733, 491],
            grid=[2, 2],
            component=[20, 20]),
          Window(
            x=0.05,
            y=0.09,
            width=0.72,
            height=0.71,
            library=1,
            autolayout=1),
          Documentation(info="
<HTML>
<p>
This package contains interface definitions for
<b>continuous</b> input/output blocks. In particular it
contains the following <b>connector</b> classes:
</p>
<pre>
  <b>RealInput</b>       Connector with input  signals of type Real.
  <b>RealOutput</b>      Connector with output signals of type Real.
  <b>BooleanInput</b>    Connector with input  signals of type Boolean.
  <b>BooleanOutput</b>   Connector with output signals of type Boolean.
  <b>IntegerInput</b>    Connector with input  signals of type Integer.
  <b>IntegerOutput</b>   Connector with output signals of type Integer.
  <b>RealSignal</b>      Connector with input/output signals of type Real.
  <b>BooleanSignal</b>   Connector with input/output signals of type Boolean.
  <b>IntegerSignal</b>   Connector with input/output signals of type Integer.
</pre>
<p>
The following <b>partial</b> block classes are provided
to model <b>continuous</b> control blocks:
</p>
<pre>
  <b>BlockIcon</b>     Basic graphical layout of continuous block
  <b>SO</b>            Single Output continuous control block
  <b>MO</b>            Multiple Output continuous control block
  <b>SISO</b>          Single Input Single Output continuous control block
  <b>SI2SO</b>         2 Single Input / 1 Single Output continuous control block
  <b>SIMO</b>          Single Input Multiple Output continuous control block
  <b>MISO</b>          Multiple Input Single Output continuous control block
  <b>MIMO</b>          Multiple Input Multiple Output continuous control block
  <b>MIMOs</b>         Multiple Input Multiple Output continuous control block
                with same number of inputs and outputs
  <b>MI2MO</b>         2 Multiple Input / Multiple Output continuous
                control block
  <b>SignalSource</b>  Base class for continuous signal sources
  <b>SVcontrol</b>     Single-Variable continuous controller
  <b>MVcontrol</b>     Multi-Variable continuous controller
</pre>
<p>
The following <b>partial</b> block classes are provided
to model <b>discrete</b> control blocks:
</p>
<pre>
  <b>DiscreteBlockIcon</b> Basic graphical layout of discrete block
  <b>DiscreteBlock</b>     Base class of discrete control blocks
  <b>DiscreteSISO</b>      Single Input Single Output discrete control block
  <b>DiscreteMIMO</b>      Multiple Input Multiple Output discrete control block
  <b>DiscreteMIMOs</b>     Multiple Input Multiple Output discrete control block
  <b>SVdiscrete</b>        Discrete Single-Variable controller
  <b>MVdiscrete</b>        Discrete Multi-Variable controllerk
</pre>
<p>
The following <b>partial</b> block classes are provided
to model <b>Boolean</b> control blocks:
</p>
<pre>
  <b>BooleanBlockIcon</b>     Basic graphical layout of Boolean block
  <b>BooleanSISO</b>          Single Input Single Output control block
                       with signals of type Boolean
  <b>BooleanMIMOs</b>         Multiple Input Multiple Output control block
                       with same number of inputs and outputs
  <b>MI2BooleanMOs</b>        2 Multiple Input / Boolean Multiple Output
                       block with same signal lengths
  <b>BooleanSignalSource</b>  Base class for Boolean signal sources
  <b>IntegerMIBooleanMOs</b>  Multiple Integer Input Multiple Boolean Output control block
                       with same number of inputs and outputs
</pre>
<p>
The following <b>partial</b> block classes are provided
to model <b>Integer</b> control blocks:
</p>
<pre>
  <b>IntegerBlockIcon</b>     Basic graphical layout of Integer block
  <b>IntegerMO</b>            Multiple Output control block
  <b>IntegerSignalSource</b>  Base class for Integer signal sources
</pre>
<p>In addition, a subpackage <b>BusAdaptors</b> is temporarily provided
in order to make a signal bus concept available. It will be removed,
when the package Block is revised exploiting new Modelica features.</p>
</HTML>
",     revisions="<html>
<ul>
<li><i>Oct. 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Added several new interfaces. <a href=\"../Documentation/ChangeNotes1.5.html\">Detailed description</a> available.
<li><i>Oct. 24, 1999</i>
       by <a href=\"http://www.op.dlr.de/~otter/\">Martin Otter</a>:<br>
       RealInputSignal renamed to RealInput. RealOutputSignal renamed to
       output RealOutput. GraphBlock renamed to BlockIcon. SISOreal renamed to
       SISO. SOreal renamed to SO. I2SOreal renamed to M2SO.
       SignalGenerator renamed to SignalSource. Introduced the following
       new models: MIMO, MIMOs, SVcontrol, MVcontrol, DiscreteBlockIcon,
       DiscreteBlock, DiscreteSISO, DiscreteMIMO, DiscreteMIMOs,
       BooleanBlockIcon, BooleanSISO, BooleanSignalSource, MI2BooleanMOs.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.op.dlr.de/~otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>
"));

    connector RealSignal "Real port (both input/output possible)"
      replaceable type SignalType = Real;

      extends SignalType;

    end RealSignal;

    connector RealInput = input RealSignal "'input Real' as connector"
      annotation (defaultComponentName="u",
      Coordsys(extent=[-100, -100; 100, 100],
        grid=[1,1],
        component=[20,20]),
      Icon(Polygon(points=[-100,100; 100,0; -100,-100; -100,100], style(
              color=74,
              rgbcolor={0,0,127},
              fillColor=74,
              rgbfillColor={0,0,127}))),
      Diagram(Polygon(points=[0,50; 100,0; 0,-50; 0,50], style(
              color=74,
              rgbcolor={0,0,127},
              fillColor=74,
              rgbfillColor={0,0,127})),
                                      Text(
          extent=[-140,120; 100,60],
          string="%name",
            style(color=74, rgbcolor={0,0,127}))));

    connector RealOutput = output RealSignal "'output Real' as connector"
      annotation (defaultComponentName="y",
      Coordsys(extent=[-100, -100; 100, 100],
        grid=[1,1],
        component=[20,20]),
      Icon(Polygon(points=[-100, 100; 100, 0; -100, -100; -100, 100], style(
              color=74,
              rgbcolor={0,0,127},
              fillColor=7,
              rgbfillColor={255,255,255}))),
      Diagram(Polygon(points=[-100,50; 0,0; -100,-50; -100,50], style(
              color=74,
              rgbcolor={0,0,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
                                      Text(
          extent=[-100,120; 140,60],
          string="%name",
            style(color=74, rgbcolor={0,0,127}))));

        partial block BlockIcon "Basic graphical layout of continuous block"
          annotation (
            Coordsys(extent=[-100, -100; 100, 100]),
            Window(
              x=0,
              y=0,
              width=0.6,
              height=0.6),
            Icon(Rectangle(extent=[-100, -100; 100, 100], style(
                color=74,
                rgbcolor={0,0,127},
                fillColor=7,
                rgbfillColor={255,255,255})),
                                   Text(extent=[-150, 150; 150, 110], string=
                    "%name")));
        equation

        end BlockIcon;

        partial block SO "Single Output continuous control block"
          extends BlockIcon;

          RealOutput y "Connector of Real output signal"
            annotation (extent=[100, -10; 120, 10]);
          annotation (
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Window(
              x=0.25,
              y=0.02,
              width=0.6,
              height=0.6),
            Diagram);
        end SO;
    end Interfaces;

    package Sources "Signal source blocks generating Real and Boolean signals"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
          extends Modelica.Icons.Library;
          annotation(preferedView="info",
            Coordsys(
              extent=[0, 0; 430, 442],
              grid=[1, 1],
              component=[20, 20]),
            Window(
              x=0.06,
              y=0.1,
              width=0.43,
              height=0.65,
              library=1,
              autolayout=1),
            Documentation(info="<HTML>
<p>
This package contains <b>source</b> components, i.e., blocks which
have only output signals. These blocks are used as signal generators.
</p>
<p>The following <b>sources</b> are provided to generate <b>Real</b> signals:</p>
<pre>
  <b>Clock</b>             Generate actual time.
  <b>Constant</b>          Generate constant signals.
  <b>Step</b>              Generate step signals.
  <b>Ramp</b>              Generate ramp signals.
  <b>Sine</b>              Generate sine signals.
  <b>ExpSine</b>           Generate exponentially damped sine signals.
  <b>Exponentials</b>      Generate a rising and falling exponential signal.
  <b>Pulse</b>             Generate pulse signals.
  <b>SawTooth</b>          Generate sawtooth signals.
  <b>Trapezoid</b>         Generate trapezoidal signals.
  <b>KinematicPTP</b>      Generate an acceleration signal to move as fast as
                    possible along a distance within given kinematic constraints.
  <b>TimeTable</b>         Generate a (possibly discontinuous) signal by
                    linear interpolation in a table.
</pre
<p>
The following <b>sources</b> are provided to generate <b>Boolean</b> signals:
</p>
<pre>
  <b>BooleanExpression</b> Generate signal by a Boolean expression
  <b>BooleanConstant</b>   Generate constant signals.
  <b>BooleanStep</b>       Generate step signals.
  <b>BooleanPulse</b>      Generate pulse signals.
  <b>SampleTrigger</b>     Generate sample triggers.
</pre>
<p>The following <b>sources</b> are provided to generate <b>Integer</b> signals:</p>
<pre>
  <b>IntegerConstant</b>   Generate constant signals.
  <b>IntegerStep</b>       Generate step signals.
</pre>
<p>
All Real source signals (with the exception of the Constant source)
have at least the following two parameters:
</p>
<pre>
   <b>offset</b>       Value which is added to the signal.
   <b>startTime</b>    Start time of signal. For time &lt; startTime,
                the output y is set to offset.
</pre>
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
       <A HREF=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</A>,
       <a href=\"http://www.op.dlr.de/~otter/\">Martin Otter</a>:<br>
       New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
       (nperiod=-1 is an infinite number of periods).</li>
<li><i>Oct. 31, 1999</i>
       by <a href=\"http://www.op.dlr.de/~otter/\">Martin Otter</a>:<br>
       <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
       <A HREF=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</A>,
       All sources vectorized. New sources: ExpSine, Trapezoid,
       BooleanConstant, BooleanStep, BooleanPulse, SampleTrigger.
       Improved documentation, especially detailed description of
       signals in diagram layer.</li>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.op.dlr.de/~otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>"));

          block Sine "Generate sine signal"
            parameter Real amplitude=1 "Amplitude of sine wave";
            parameter SIunits.Frequency freqHz=1 "Frequency of sine wave";
            parameter SIunits.Angle phase=0 "Phase of sine wave";
            parameter Real offset=0 "Offset of output signal";
            parameter SIunits.Time startTime=0
        "Output = offset for time < startTime";
            extends Interfaces.SO;
    protected
            constant Real pi=Modelica.Constants.pi;
            annotation (
              Coordsys(
                extent=[-100, -100; 100, 100],
                grid=[1, 1],
                component=[20, 20]),
              Window(
                x=0.23,
                y=0.08,
                width=0.66,
                height=0.68),
              Icon(
                Line(points=[-80, 68; -80, -80], style(color=8)),
                Polygon(points=[-80, 90; -88, 68; -72, 68; -80, 90], style(color=8,
                       fillColor=8)),
                Line(points=[-90, 0; 68, 0], style(color=8)),
                Polygon(points=[90, 0; 68, 8; 68, -8; 90, 0], style(color=8,
                      fillColor=8)),
                Line(points=[-80, 0; -68.7, 34.2; -61.5, 53.1; -55.1, 66.4; -49.4,
                      74.6; -43.8, 79.1; -38.2, 79.8; -32.6, 76.6; -26.9, 69.7; -21.3,
                       59.4; -14.9, 44.1; -6.83, 21.2; 10.1, -30.8; 17.3, -50.2;
                      23.7, -64.2; 29.3, -73.1; 35, -78.4; 40.6, -80; 46.2, -77.6;
                      51.9, -71.5; 57.5, -61.9; 63.9, -47.2; 72, -24.8; 80, 0],
                    style(color=0)),
                Text(
                  extent=[-147, -152; 153, -112],
                  string="freqHz=%freqHz",
                  style(color=0))),
              Diagram(
                Line(points=[-80, -90; -80, 84], style(color=8)),
                Polygon(points=[-80, 100; -86, 84; -74, 84; -80, 100], style(color=
                        8, fillColor=8)),
                Line(points=[-99, -40; 85, -40], style(color=8)),
                Polygon(points=[101, -40; 85, -34; 85, -46; 101, -40], style(color=
                        8, fillColor=8)),
                Line(points=[-40, 0; -31.6, 34.2; -26.1, 53.1; -21.3, 66.4; -17.1,
                      74.6; -12.9, 79.1; -8.64, 79.8; -4.42, 76.6; -0.201, 69.7;
                      4.02, 59.4; 8.84, 44.1; 14.9, 21.2; 27.5, -30.8; 33, -50.2;
                      37.8, -64.2; 42, -73.1; 46.2, -78.4; 50.5, -80; 54.7, -77.6;
                      58.9, -71.5; 63.1, -61.9; 67.9, -47.2; 74, -24.8; 80, 0],
                    style(color=0, thickness=2)),
                Line(points=[-41, -2; -80, -2], style(color=0, thickness=2)),
                Text(
                  extent=[-128, 7; -82, -11],
                  string="offset",
                  style(color=9)),
                Line(points=[-41, -2; -41, -40], style(color=8, pattern=2)),
                Text(
                  extent=[-60, -43; -14, -61],
                  string="startTime",
                  style(color=9)),
                Text(
                  extent=[84, -52; 108, -72],
                  string="time",
                  style(color=9)),
                Text(
                  extent=[-74, 106; -33, 86],
                  string="y",
                  style(color=9)),
                Line(points=[-9, 79; 43, 79], style(color=8, pattern=2)),
                Line(points=[-42, -1; 50, 0], style(color=8, pattern=2)),
                Polygon(points=[33, 80; 30, 67; 37, 67; 33, 80], style(
                    color=8,
                    fillColor=8,
                    fillPattern=1)),
                Text(
                  extent=[37, 57; 83, 39],
                  string="amplitude",
                  style(color=9)),
                Polygon(points=[33, 1; 30, 14; 36, 14; 33, 1; 33, 1], style(
                    color=8,
                    fillColor=8,
                    fillPattern=1)),
                Line(points=[33, 79; 33, 0], style(
                    color=8,
                    pattern=1,
                    thickness=1,
                    arrow=0))));
          equation
            y = offset + (if time < startTime then 0 else amplitude*
              Modelica.Math.sin(2*pi*freqHz*(time - startTime) + phase));
          end Sine;
    end Sources;
  end Blocks;

  package Constants "Mathematical constants and constants of nature"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Library2;

    constant Real pi=2*Modelica.Math.asin(1.0);

    constant Real small=1.e-60
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
Copyright &copy; 1998-2005, Modelica Association and DLR.
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
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
      Window(
        x=0.16,
        y=0.01,
        width=0.65,
        height=0.81,
        library=1,
        autolayout=1),
      Invisible=true,
      Icon(
        Line(points=[-34, -38; 12, -38], style(color=0, thickness=2)),
        Line(points=[-20, -38; -24, -48; -28, -56; -34, -64], style(color=0,
              thickness=2)),
        Line(points=[-2, -38; 2, -46; 8, -56; 14, -64], style(color=0, thickness=
                2))),
      Diagram(
        Rectangle(extent=[200, 162; 380, 312], style(fillColor=30, fillPattern=1)),
        Polygon(points=[200, 312; 220, 332; 400, 332; 380, 312; 200, 312], style(
              fillColor=30, fillPattern=1)),
        Polygon(points=[400, 332; 400, 182; 380, 162; 380, 312; 400, 332], style(
              fillColor=30, fillPattern=1)),
        Text(
          extent=[210, 302; 370, 272],
          string="Library",
          style(
            color=9,
            fillColor=0,
            fillPattern=1)),
        Line(points=[266, 224; 312, 224], style(color=0, thickness=4)),
        Line(points=[280, 224; 276, 214; 272, 206; 266, 198], style(color=0,
              thickness=4)),
        Line(points=[298, 224; 302, 216; 308, 206; 314, 198], style(color=0,
              thickness=4)),
        Text(
          extent=[152, 412; 458, 334],
          string="Modelica.Constants",
          style(color=1))));
  end Constants;

  package Icons "Icon definitions"
    annotation(preferedView="info",
      Window(
        x=0.08,
        y=0.08,
        width=0.28,
        height=0.51,
        library=1,
        autolayout=1),
      Icon(
        Rectangle(extent=[-100, -100; 80, 50], style(fillColor=30, fillPattern=1)),
        Polygon(points=[-100, 50; -80, 70; 100, 70; 80, 50; -100, 50], style(
              fillColor=30, fillPattern=1)),
        Polygon(points=[100, 70; 100, -80; 80, -100; 80, 50; 100, 70], style(
              fillColor=30, fillPattern=1)),
        Text(
          extent=[-120, 135; 120, 70],
          string="%name",
          style(color=1)),
        Text(
          extent=[-90, 40; 70, 10],
          string="Library",
          style(
            color=9,
            fillColor=0,
            fillPattern=1)),
        Rectangle(extent=[-100, -100; 80, 50], style(fillColor=30, fillPattern=1)),
        Polygon(points=[-100, 50; -80, 70; 100, 70; 80, 50; -100, 50], style(
              fillColor=30, fillPattern=1)),
        Polygon(points=[100, 70; 100, -80; 80, -100; 80, 50; 100, 70], style(
              fillColor=30, fillPattern=1)),
        Text(
          extent=[-90, 40; 70, 10],
          string="Library",
          style(
            color=9,
            fillColor=0,
            fillPattern=1)),
        Polygon(points=[-64, -20; -50, -4; 50, -4; 36, -20; -64, -20; -64, -20],
            style(
            color=0,
            fillColor=8,
            fillPattern=1)),
        Rectangle(extent=[-64, -20; 36, -84], style(
            color=0,
            fillColor=8,
            fillPattern=1)),
        Text(
          extent=[-60, -24; 32, -38],
          string="Library",
          style(
            color=10,
            fillColor=10,
            fillPattern=1)),
        Polygon(points=[50, -4; 50, -70; 36, -84; 36, -20; 50, -4], style(
            color=0,
            fillColor=8,
            fillPattern=1))), Documentation(info="<html>
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
Copyright &copy; 1998-2005, Modelica Association and DLR.
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
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

    partial package Library "Icon for library"
      annotation (Coordsys(
          extent=[-100, -100; 100, 100],
          grid=[1, 1],
          component=[20, 20]), Icon(
          Rectangle(extent=[-100, -100; 80, 50], style(fillColor=30,
                fillPattern=
                  1)),
          Polygon(points=[-100, 50; -80, 70; 100, 70; 80, 50; -100, 50], style(
                fillColor=30, fillPattern=1)),
          Polygon(points=[100, 70; 100, -80; 80, -100; 80, 50; 100, 70], style(
                fillColor=30, fillPattern=1)),
          Text(
            extent=[-85, 35; 65, -85],
            string="Library",
            style(color=3)),
          Text(
            extent=[-120, 122; 120, 73],
            string="%name",
            style(color=1))));
    end Library;

    partial package Library2
    "Icon for library where additional icon elements shall be added"
      annotation (Coordsys(
          extent=[-100, -100; 100, 100],
          grid=[1, 1],
          component=[20, 20]), Icon(
          Rectangle(extent=[-100, -100; 80, 50], style(fillColor=30,
                fillPattern=
                  1)),
          Polygon(points=[-100, 50; -80, 70; 100, 70; 80, 50; -100, 50], style(
                fillColor=30, fillPattern=1)),
          Polygon(points=[100, 70; 100, -80; 80, -100; 80, 50; 100, 70], style(
                fillColor=30, fillPattern=1)),
          Text(
            extent=[-120, 125; 120, 70],
            string="%name",
            style(color=1)),
          Text(
            extent=[-90, 40; 70, 10],
            string="Library",
            style(
              color=9,
              fillColor=0,
              fillPattern=1))));
    end Library2;
  end Icons;

  package Math "Mathematical functions"
    import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;
  annotation(preferedView="info",
      Window(
        x=0.04,
        y=0.05,
        width=0.44,
        height=0.68,
        library=1,
        autolayout=1),
    Invisible=true,
    Icon(Text(
        extent=[-59, -9; 42, -56],
        string="f(x)",
        style(color=0))),
    Documentation(info="<HTML>
<p>
This package contains the following basic mathematical functions:
</p>
<pre>
   <b>Matrices</b>      Library with functions operating on matrices
   <b>sin</b>(u)        sine
   <b>cos</b>(u)        cosine
   <b>tan</b>(u)        tangent     (u shall not be -pi/2, pi/2, 3*pi/2, ...)
   <b>asin</b>(u)       inverse sine    (-1 &le; u &le; 1)
   <b>acos</b>(u)       inverse cosine  (-1 &le; u &le; 1)
   <b>atan</b>(u)       inverse tangent
   <b>atan2</b>(u1,u2)  four quadrant inverse tangent
   <b>sinh</b>(u)       hyperbolic sine
   <b>cosh</b>(u)       hyperbolic cosine
   <b>tanh</b>(u)       hyperbolic tangent
   <b>exp</b>(u)        exponential, base e
   <b>log</b>(u)        natural (base e) logarithm (u &gt; 0)
   <b>log10</b>(u)      base 10 logarithm (u &gt; 0)
</pre>
<p>
These functions are used by calling them directly
with a full name (e.g. y = Modelica.Math.asin(0.5)).
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
Copyright &copy; 1998-2005, Modelica Association and DLR.
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
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

  function sin "sine"
    extends baseIcon1;
    input SI.Angle u;
    output Real y;
    annotation (
      Coordsys(
        extent=[-100, -100; 100, 100],
        grid=[2, 2],
        component=[20, 20]),
      Window(
        x=0.02,
        y=0.21,
        width=0.6,
        height=0.6),
      Icon(
        Line(points=[-90, 0; 68, 0], style(color=8)),
        Polygon(points=[90, 0; 68, 8; 68, -8; 90, 0], style(color=8, fillColor=8)),
        Line(points=[-80, 0; -68.7, 34.2; -61.5, 53.1; -55.1, 66.4; -49.4, 74.6;
              -43.8, 79.1; -38.2, 79.8; -32.6, 76.6; -26.9, 69.7; -21.3, 59.4; -
              14.9, 44.1; -6.83, 21.2; 10.1, -30.8; 17.3, -50.2; 23.7, -64.2;
              29.3, -73.1; 35, -78.4; 40.6, -80; 46.2, -77.6; 51.9, -71.5; 57.5,
              -61.9; 63.9, -47.2; 72, -24.8; 80, 0], style(color=0)),
        Text(
          extent=[12, 84; 84, 36],
          string="sin",
          style(color=8))),
      Diagram(
        Line(points=[-100, 0; 84, 0], style(color=8)),
        Polygon(points=[100, 0; 84, 6; 84, -6; 100, 0], style(color=8, fillColor=
                8)),
        Line(points=[-80, 0; -68.7, 34.2; -61.5, 53.1; -55.1, 66.4; -49.4, 74.6;
              -43.8, 79.1; -38.2, 79.8; -32.6, 76.6; -26.9, 69.7; -21.3, 59.4; -
              14.9, 44.1; -6.83, 21.2; 10.1, -30.8; 17.3, -50.2; 23.7, -64.2;
              29.3, -73.1; 35, -78.4; 40.6, -80; 46.2, -77.6; 51.9, -71.5; 57.5,
              -61.9; 63.9, -47.2; 72, -24.8; 80, 0], style(color=0)),
        Text(extent=[-105, 72; -85, 88], string="1"),
        Text(extent=[70, 25; 90, 5], string="2*pi"),
        Text(extent=[-105, -72; -85, -88], string="-1"),
        Text(
          extent=[92, -2; 112, -22],
          string="u",
          style(color=9))));
  external "C" y=  sin(u);
  end sin;

  function asin "inverse sine (-1 <= u <= 1)"
    extends baseIcon2;
    input Real u;
    output SI.Angle y;
    annotation (
      Coordsys(
        extent=[-100, -100; 100, 100],
        grid=[2, 2],
        component=[20, 20]),
      Window(
        x=0.29,
        y=0.02,
        width=0.6,
        height=0.6),
      Icon(
        Line(points=[-90, 0; 68, 0], style(color=8)),
        Polygon(points=[90, 0; 68, 8; 68, -8; 90, 0], style(color=8, fillColor=8)),
        Line(points=[-80, -80; -79.2, -72.8; -77.6, -67.5; -73.6, -59.4; -66.3, -
              49.8; -53.5, -37.3; -30.2, -19.7; 37.4, 24.8; 57.5, 40.8; 68.7,
              52.7; 75.2, 62.2; 77.6, 67.5; 80, 80], style(color=0)),
        Text(
          extent=[-88, 78; -16, 30],
          string="asin",
          style(color=8))),
      Diagram(
        Text(extent=[-40, -72; -15, -88], string="-pi/2"),
        Text(extent=[-38, 88; -13, 72], string=" pi/2"),
        Text(extent=[70, 25; 90, 5], string="+1"),
        Text(extent=[-90, 21; -70, 1], string="-1"),
        Line(points=[-100, 0; 84, 0], style(color=8)),
        Polygon(points=[100, 0; 84, 6; 84, -6; 100, 0], style(color=8, fillColor=
                8)),
        Line(points=[-80, -80; -79.2, -72.8; -77.6, -67.5; -73.6, -59.4; -66.3, -
              49.8; -53.5, -37.3; -30.2, -19.7; 37.4, 24.8; 57.5, 40.8; 68.7,
              52.7; 75.2, 62.2; 77.6, 67.5; 80, 80], style(color=0)),
        Text(
          extent=[92, -2; 112, -22],
          string="u",
          style(color=9))));
  external "C" y=  asin(u);
  end asin;

  partial function baseIcon1
    "Basic icon for mathematical function with y-axis on left side"
    annotation (Icon(
        Rectangle(extent=[-100, 100; 100, -100], style(color=0, fillColor=7)),
        Line(points=[-80, -80; -80, 68], style(color=8)),
        Polygon(points=[-80, 90; -88, 68; -72, 68; -80, 90], style(color=8,
              fillColor=8)),
        Text(extent=[-150, 150; 150, 110], string="%name")), Diagram(
        Line(points=[-80, 80; -88, 80], style(color=8)),
        Line(points=[-80, -80; -88, -80], style(color=8)),
        Line(points=[-80, -90; -80, 84], style(color=8)),
        Text(
          extent=[-75, 110; -55, 90],
          string="y",
          style(color=9)),
        Polygon(points=[-80, 100; -86, 84; -74, 84; -80, 100], style(color=8,
              fillColor=8))));
  end baseIcon1;

  partial function baseIcon2
    "Basic icon for mathematical function with y-axis in middle"
    annotation (Icon(
        Rectangle(extent=[-100, 100; 100, -100], style(color=0, fillColor=7)),
        Line(points=[0, -80; 0, 68], style(color=8)),
        Polygon(points=[0, 90; -8, 68; 8, 68; 0, 90], style(color=8, fillColor=8)),
        Text(extent=[-150, 150; 150, 110], string="%name")), Diagram(
        Line(points=[0, 80; -8, 80], style(color=8)),
        Line(points=[0, -80; -8, -80], style(color=8)),
        Line(points=[0, -90; 0, 84], style(color=8)),
        Text(
          extent=[5, 110; 25, 90],
          string="y",
          style(color=9)),
        Polygon(points=[0, 100; -6, 84; 6, 84; 0, 100], style(color=8, fillColor=
                8))));
  end baseIcon2;

  function tempInterpol1
    "temporary routine for linear interpolation (will be removed)"
    input Real u "input value (first column of table)";
    input Real table[:, :] "table to be interpolated";
    input Integer icol "column of table to be interpolated";
    output Real y "interpolated input value (icol column of table)";
  protected
    Integer i;
    Integer n "number of rows of table";
    Real u1;
    Real u2;
    Real y1;
    Real y2;
  algorithm
    n := size(table, 1);

    if n <= 1 then
      y := table[1, icol];

    else
      // Search interval

      if u <= table[1, 1] then
        i := 1;

      else
        i := 2;
        // Supports duplicate table[i, 1] values
        // in the interior to allow discontinuities.
        // Interior means that
        // if table[i, 1] = table[i+1, 1] we require i>1 and i+1<n

        while i < n and u >= table[i, 1] loop
          i := i + 1;

        end while;
        i := i - 1;

      end if;

      // Get interpolation data
      u1 := table[i, 1];
      u2 := table[i + 1, 1];
      y1 := table[i, icol];
      y2 := table[i + 1, icol];

      assert(u2 > u1, "Table index must be increasing");
      // Interpolate
      y := y1 + (y2 - y1)*(u - u1)/(u2 - u1);

    end if;
  end tempInterpol1;
  end Math;

  package Mechanics "Library for mechanical systems"
  extends Modelica.Icons.Library2;
  annotation(preferedView="info",
    Window(
      x=0.03,
      y=0.05,
      width=0.36,
      height=0.26,
      library=1,
      autolayout=1),
    Icon(
      Rectangle(extent=[-5, -40; 45, -70], style(
          gradient=2,
          fillColor=8,
          fillPattern=1)),
      Ellipse(extent=[-90, -50; -80, -60], style(color=0)),
      Line(points=[-85, -55; -60, -21], style(color=0, thickness=2)),
      Ellipse(extent=[-65, -16; -55, -26], style(color=0)),
      Line(points=[-60, -21; 9, -55], style(color=0, thickness=2)),
      Ellipse(extent=[4, -50; 14, -60], style(
          color=0,
          fillColor=0,
          fillPattern=1)),
      Line(points=[-10, -34; 72, -34; 72, -76; -10, -76], style(color=0))),
    Documentation(info="<HTML>
<p>
This package contains components to model <b>mechanical systems</b>.
Currently, the following subpackages are available:</p>
<pre>
   <b>MultiBody</b>      3-dimensional mechanical components.
   <b>Rotational</b>     1-dimensional rotational mechanical components.
   <b>Translational</b>  1-dimensional translational mechanical components.
</pre>
</HTML>
",   revisions="<html>
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
</html>"));

    package Rotational "1-dimensional rotational mechanical components"
      import SI = Modelica.SIunits;
      extends Modelica.Icons.Library2;
      annotation(preferedView="info",
        Window(
          x=0.05,
          y=0.09,
          width=0.43,
          height=0.63,
          library=1,
          autolayout=1),
        Documentation(info="<html>
<h4>Content</h4>
<ol>
  <li>Overview of library Modelica.Mechanics.Rotational</li>
  <li>Components of the library</li>
  <li>Flange connectors</li>
  <li>Sign conventions</li>
  <li>User-defined components</li>
  <li>Requirements for simulation tools</li>
  <li>Support torque</li>
</ol>
<h4>1. Overview of library Modelica.Mechanics.Rotational</h4>
<p>
This package contains components to model <b>1-dimensional rotational
mechanical</b> systems, including different types of gearboxes,
shafts with inertia, external torques, spring/damper elements,
frictional elements, backlash, elements to measure angle, angular velocity,
angular acceleration and the cut-torque of a flange. In sublibrary
<b>Examples</b> several examples are present to demonstrate the usage of
the elements. Just open the corresponding example model and simulate
the model according to the provided description.
</p>
<p>
A unique feature of this library is the <b>component-oriented</b>
modeling of <b>Coulomb friction</b> elements, such as friction in bearings,
clutches, brakes, and gear efficiency. Even (dynamically) coupled
friction elements, e.g., as in automatic gearboxes, can be handeled
<b>without</b> introducing stiffness which leads to fast simulations.
The underlying theory is new and is based on the solution of mixed
continuous/discrete systems of equations, i.e., equations where the
<b>unknowns</b> are of type <b>Real</b>, <b>Integer</b> or <b>Boolean</b>.
Provided appropriate numerical algorithms for the solution of such types of
systems are available in the simulation tool, the simulation of
(dynamically) coupled friction elements of this library is
<b>efficient</b> and <b>reliable</b>.
</p>
<p><IMG SRC=\"../Images/drive1.png\" ALT=\"drive1\"></p>
<p>
A simple example of the usage of this library is given in the
figure above. This drive consists of a shaft with inertia J1=0.2 which
is connected via an ideal gearbox with gear ratio=5 to a second shaft
with inertia J2=5. The left shaft is driven via an external,
sinusoidal torque.
The <b>filled</b> and <b>non-filled grey squares</b> at the left and
right side of a component represent <b>mechanical flanges</b>.
Drawing a line between such squares means that the corresponding
flanges are <b>rigidly attached</b> to each other.
By convention in this library, the connector characterized as a
<b>filled</b> grey square is called <b>flange_a</b> and placed at the
left side of the component in the \"design view\" and the connector
characterized as a <b>non-filled</b> grey square is called <b>flange_b</b>
and placed at the right side of the component in the \"design view\".
The two connectors are completely <b>identical</b>, with the only
exception that the graphical layout is a little bit different in order
to distinguish them for easier access of the connector variables.
For example, <tt>J1.flange_a.tau</tt> is the cut-torque in the connector
<tt>flange_a</tt> of component <tt>J1</tt>.
</p>
<p>
The components of this
library can be <b>connected</b> together in an <b>arbitrary</b> way. E.g., it is
possible to connect two springs or two shafts with inertia directly
together, see figure below.
</p>
<p><IMG SRC=\"../Images/driveConnections.png\" ALT=\"driveConnections\"></p>
<h4>2. Components of the library</h4>
<p>
This package contains the following model components:
</p>
<table BORDER=1 CELLSPACING=0 CELLPADDING=2>
<tr><th>Name</th><th>Description</th></tr>
<tr><td><tt><b>Examples</b></tt></td><td>Sublibrary containing example models.</td></tr>
<tr><td><tt><b>Interfaces</b></tt></td><td>Sublibrary containing interface definitions.</td></tr>
<tr><td><tt><b>Inertia</b></tt></td><td>Rotational component with inertia.</td></tr>
<tr><td><tt><b>IdealGear</b></tt></td><td>Ideal gear transforming rotational in rotational motion.</td></tr>
<tr><td><tt><b>IdealPlanetary</b></tt></td><td>Ideal standard planetary gear.</td></tr>
<tr><td><tt><b>IdealGearR2T</b></tt></td><td>Ideal gear transforming rotational in translational motion.</td></tr>
<tr><td><tt><b>Spring</b></tt></td><td>Linear spring.</td></tr>
<tr><td><tt><b>Damper</b></tt></td><td>Linear damper.</td></tr>
<tr><td><tt><b>SpringDamper</b></tt></td><td>Linear spring and linear damper in parallel connection.</td></tr>
<tr><td><tt><b>ElastoBacklash</b></tt></td><td>Linear spring, linear damper and backlash in series connection (backlash is modeled with elasticity).</td></tr>
<tr><td><tt><b>BearingFriction</b></tt></td><td>Coulomb friction in the bearings.</td></tr>
<tr><td><tt><b>Clutch</b></tt></td><td>Frictional clutch where the clutch pressure force is an input signal (= Coulomb friction between two flanges).</td></tr>
<tr><td><tt><b>OneWayClutch</b></tt></td><td>Parallel connection of free wheel and clutch</td></tr>
<tr><td><tt><b>Brake</b></tt></td><td>Frictional brake where the brake pressure force is an input signal (= Coulomb friction between flange and housing).</td></tr>
<tr><td><tt><b>LossyGear</b></tt></td><td>Gear with mesh efficiency and bearing friction (stuck/rolling possible)</td></tr>
<tr><td><tt><b>GearEfficiency</b></tt></td><td>Efficiency of a gearbox.</td></tr>
<tr><td><tt><b>Gear</b></tt></td><td>Realistic model of a gearbox (taking into account efficiency, bearing friction, elasticity, damping, backlash)</td></tr>
<tr><td><tt><b>GearNew</b></tt></td><td>Realistic model of a gearbox (taking into account efficiency, bearing friction, elasticity, damping, backlash), based on new component LossyGear</td></tr>
<tr><td><tt><b>Position</b></tt></td><td>Forced movement of a flange with a reference angle given as input signal (positive angle for positive input signal).</td></tr>
<tr><td><tt><b>Accelerate</b></tt></td><td>Forced movement of a flange with an angular acceleration given as input signal (positive acceleration for positive input signal).</td></tr>
<tr><td><tt><b>Move</b></tt></td><td>Forced movement of a flange according to an angle, speed and angular acceleration given as input signals.</td></tr>
<tr><td><tt><b>Fixed</b></tt></td><td>Fixing flange in housing at a predefined angle.</td></tr>
<tr><td><tt><b>Torque</b></tt></td><td>External torque defined as input signal which accelerates the connected flange for positive input signal.</td></tr>
<tr><td><tt><b>RelativeStates</b></tt></td><td>Definition of relative state variables</td></tr>
<tr><td><tt><b>Sensors</b></tt></td><td>Sublibrary containing ideal sensors to measure flange variables.</td></tr>
</table>
<h4>3. Flange connectors</h4>
<p>
A flange is described by the connector class
Interfaces.<b>Flange_a</b>
or Interfaces.<b>Flange_b</b>. As already noted, the two connector
classes are completely identical. There is only a difference in the icons,
in order to easier identify a flange variable in a diagram.
Both connector classes contain the following variables:
</p>
<pre>
   SIunits.Angle       phi  \"absolute rotation angle of flange\";
   <b>flow</b> SIunits.Torque tau  \"cut-torque in the flange\";
</pre>
<p>
If needed, the angular velocity <tt>w</tt> and the
angular acceleration <tt>a</tt> of a flange connector can be
determined by differentiation of the flange angle <tt>phi</tt>:
</p>
<pre>
     w = <b>der</b>(phi);    a = <b>der</b>(w);
</pre>
<h4>4. Sign conventions</h4>
<p>
The variables of a component of this library can be accessed in the
usual way. However, since most of these variables are basically elements
of <b>vectors</b>, i.e., have a direction, the question arises how the
signs of variables shall be interpreted. The basic idea is explained
at hand of the following figure:
</p>
<p><IMG SRC=\"../Images/drive2.png\" ALT=\"drive2\"></p>
<p>
In the figure, three identical drive trains are shown. The only
difference is that the gear of the middle drive train and the
gear as well as the right inertia of the lower drive train
are horizontally flipped with regards to the upper drive train.
The signs of variables are now interpreted in the following way:
Due to the 1-dimensional nature of the model, all components are
basically connected together along one line (more complicated
cases are discussed below). First, one has to define
a <b>positive</b> direction of this line, called <b>axis of rotation</b>.
In the top part of the figure this is characterized by an arrow
defined as <tt>axis of rotation</tt>. The simple rule is now:
If a variable of a component is positive and can be interpreted as
the element of a vector (e.g. torque or angular velocity vector), the
corresponding vector is directed into the positive direction
of the axis of rotation. In the following figure, the right-most
inertias of the figure above are displayed with the positive
vector direction displayed according to this rule:
</p>
<p><IMG SRC=\"../Images/drive3.png\" ALT=\"drive3\"></p>
<p>
The cut-torques <tt>J2.flange_a.tau, J4.flange_a.tau, J6.flange_b.tau</tt>
of the right inertias are all identical and are directed into the
direction of rotation if the values are positive. Similiarily,
the angular velocities <tt>J2.w, J4.w, J6.w</tt> of the right inertias
are all identical and are also directed into the
direction of rotation if the values are positive. Some special
cases are shown in the next figure:
</p>
<p><IMG SRC=\"../Images/drive4.png\" ALT=\"drive4\"></p>
<p>
In the upper part of the figure, two variants of the connection of an
external torque and an inertia are shown. In both cases, a positive
signal input into the torque component accelerates the inertias
<tt>inertia1, inertia2</tt> into the positive axis of rotation,
i.e., the angular accelerations <tt>inertia1.a, inertia2.a</tt>
are positive and are directed along the \"axis of rotation\" arrow.
In the lower part of the figure the connection of inertias with
a planetary gear is shown. Note, that the three flanges of the
planetary gearbox are located along the axis of rotation and that
the axis direction determines the positive rotation along these
flanges. As a result, the positive rotation for <tt>inertia4, inertia6</tt>
is as indicated with the additional grey arrows.
</p>
<h4>5. User-defined components</h4>
<p>
In this section some hints are given to define your own
1-dimensional rotational components which are compatible with the
elements of this package.
It is convenient to define a new
component by inheritance from one of the following base classes,
which are defined in sublibrary Interfaces:
</p>
<table BORDER=1 CELLSPACING=0 CELLPADDING=2>
<tr><th>Name</th><th>Description</th></tr>
<tr><td><tt><b>Rigid</b></tt></td><td>Rigid connection of two rotational 1D flanges (used for elements with inertia).</td></tr>
<tr><td><tt><b>Compliant</b></tt></td><td>Compliant connection of two rotational 1D flanges (used for force laws such as a spring or a damper).</td></tr>
<tr><td><tt><b>TwoFlanges</b></tt></td><td>General connection of two rotational 1D flanges (used for gearboxes).</td></tr>
<tr><td><tt><b>AbsoluteSensor</b></tt></td><td>Measure absolute flange variables.</td></tr>
<tr><td><tt><b>RelativeSensor</b></tt></td><td>Measure relative flange variables.</td></tr>
</table>
<p>
The difference between these base classes are the auxiliary
variables defined in the model and the relations between
the flange variables already defined in the base class.
For example, in model <b>Rigid</b> the flanges flange_a and
flange_b are rigidly connected, i.e., flange_a.phi = flange_b.phi,
whereas in model <b>Compliant</b> the cut-torques are the
same, i.e., flange_a.tau + flange_b.tau = 0.
</p>
<p>
The equations of a mechanical component are vector equations, i.e.,
they need to be expressed in a common coordinate system.
Therefore, for a component a <b>local axis of rotation</b> has to be
defined. All vector quantities, such as cut-torques or angular
velocities have to be expressed according to this definition.
Examples for such a definition are given in the following figure
for an inertia component and a planetary gearbox:
</p>
<p><IMG SRC=\"../Images/driveAxis.png\" ALT=\"driveAxis\"></p>
<p>
As can be seen, all vectors are directed into the direction
of the rotation axis. The angles in the flanges are defined
correspondingly. For example, the angle <tt>sun.phi</tt> in the
flange of the sun wheel of the planetary gearbox is positive,
if rotated in mathematical positive direction (= counter clock
wise) along the axis of rotation.
</p>
<p>
On first view, one may assume that the selected local
coordinate system has an influence on the usage of the
component. But this is not the case, as shown in the next figure:
</p>
<p><IMG SRC=\"../Images/inertias.png\" ALT=\"inertias\"></p>
<p>
In the figure the <b>local</b> axes of rotation of the components
are shown. The connection of two inertias in the left and in the
right part of the figure are completely equivalent, i.e., the right
part is just a different drawing of the left part. This is due to the
fact, that by a connection, the two local coordinate systems are
made identical and the (automatically) generated connection equations
(= angles are identical, cut-torques sum-up to zero) are also
expressed in this common coordinate system. Therefore, even if in
the left figure it seems to be that the angular velocity vector of
<tt>J2</tt> goes from right to left, in reality it goes from
left to right as shown in the right part of the figure, where the
local coordinate systems are drawn such that they are aligned.
Note, that the simple rule stated in section 4 (Sign conventions)
also determines that
the angular velocity of <tt>J2</tt> in the left part of the
figure is directed from left to right.
</p>
<p>
To summarize, the local coordinate system selected for a component
is just necessary, in order that the equations of this component
are expressed correctly. The selection of the coordinate system
is arbitrary and has no influence on the usage of the component.
Especially, the actual direction of, e.g., a cut-torque is most
easily determined by the rule of section 4. A more strict determination
by aligning coordinate systems and then using the vector direction
of the local coordinate systems, often requires a re-drawing of the
diagram and is therefore less convenient to use.
</p>
<h4>6. Requirements for simulation tools</h4>
<p>
This library is designed in a fully object oriented way in order that
components can be connected together in every meaningful combination
(e.g. direct connection of two springs or two inertias).
As a consequence, most models lead to a system of
differential-algebraic equations of <b>index 3</b> (= constraint
equations have to be differentiated twice in order to arrive at
a state space representation) and the Modelica translator or
the simulator has to cope with this system representation.
According to our present knowledge, this requires that the
Modelica translator is able to symbolically differentiate equations
(otherwise it is e.g. not possible to provide consistent initial
conditions; even if consistent initial conditions are present, most
numerical DAE integrators can cope at most with index 2 DAEs).
</p>
</p>
The elements of this library can be connected together in an
arbitrary way. However, difficulties may occur, if the elements which can <b>lock</b> the
<b>relative motion</b> between two flanges are connected <b>rigidly</b>
together such that essentially the <b>same relative motion</b> can be locked.
The reason is
that the cut-torque in the locked phase is not uniquely defined if the
elements are locked at the same time instant (i.e., there does not exist a
unique solution) and some simulation systems may not be
able to handle this situation, since this leads to a singularity during
simulation. Currently, this type of problem can occur with the
Coulomb friction elements <b>BearingFriction, Clutch, Brake, LossyGear</b> when
the elements become stuck:
</p>
<p><IMG SRC=\"../Images/driveConnections2.png\" ALT=\"driveConnections2\"></p>
<p>
In the figure above two typical situations are shown: In the upper part of
the figure, the series connection of rigidly attached BearingFriction and
Clutch components are shown. This does not hurt, because the BearingFriction
element can lock the relative motion between the element and the housing,
whereas the clutch element can lock the relative motion between the two
connected flanges. Contrary, the drive train in the lower part of the figure
may rise to simulation problems, because the BearingFriction element
and the Brake element can lock the relative motion between a flange and
the housing and these flanges are rigidly connected together, i.e.,
essentially the same relative motion can be locked. These difficulties
may be solved by either introducing a compliance between these flanges
or by combining the BearingFriction and Brake element into
one component and resolving the ambiguity of the frictional torque in the
stuck mode. A tool may handle this situation also <b>automatically</b>,
by picking one solution of the infinitely many, e.g., the one where
the difference to the value of the previous time instant is as small
as possible.
</p>
<h4>7. Support torques</h4>
<p>The following figure shows examples of components equipped with
a bearing flange (framed flange in the lower center), which can be used
to fix components on the ground or on other rotating elements or to combine
them with force elements. If the bearing flange is not connected, the
components are assumed to be mounted on the ground. Otherwise, the bearing
connector offers the possibility to consider, e.g., gearboxes mounted on
the ground via spring-damper-systems (cf. example <tt>ElasticBearing</tt>). Independently, these components
provide a variable <tt>tau_support</tt> stating the support torque exerted
on the bearing.</p>
<p><IMG SRC=\"../Images/bearing.png\" ALT=\"bearing\"></p>
<p>In general, it is not necessary to connect the bearing flange
with a fixation, i.e., the two implementations in the following figure give
identical results.</p>
<p><IMG SRC=\"../Images/bearing2.png\" ALT=\"bearing2\"></p>
<dl>
<dt><b>Main Author:</b></dt>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
    Institut f&uuml;r Robotik und Mechatronik<br>
    Postfach 11 16<br>
    D-82230 Wessling<br>
    Germany<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br></dd>
</dl>


<p>
Copyright &copy; 1998-2005, Modelica Association and DLR.
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</HTML>
",     revisions="<html>
<ul>
<li><i>October 27, 2003</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Bearing flanges added for mounted components and support torque computation implemented.<br>
       New component <tt>Torque2</tt> and new example <tt>ElasticBearing</tt>.
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New components <b>LossyGear</b> (with corresponding examples) and <b>Gear2</b>.<br>
       Interface <b>FrictionBase</b> adapted to new initialization.</li>
<li><i>June 19, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New elements:<br><!-- silly construction follows as Dymola not able to handle nested lists -->
       <tt>IdealGearR2T&nbsp;&nbsp;&nbsp;</tt> Ideal gear transforming rotational in translational motion<br>
       <tt>Position&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</tt> Forced movement of a flange with a reference angle given as input signal<br>
       <tt>RelativeStates&nbsp;</tt> Definition of relative state variables<br>
       Icon of Rotational.Torque changed.
       Elements Acceleration, Torque, Fixed, Sensors ordered according
       to the Translational library.</li>
<li><i>Nov. 4, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Improved documentation and improved graphical layout of the diagram level.
       Changes according to the Twente meeting introduced. Especially:
       Alias names, instead of extends. Model Shaft renamed to Inertia.
       Torque1D renamed to Torque.
       AccMotion renamed to Accelerate. LockedL, LockedR replaced by Fixed.
       SpeedSensor splitted into AngleSensor and
       SpeedSensor. RelSpeedSensor splitted into RelAngleSensor and
       RelSpeedSensor. Initialization of friction elements improved.
       Flanges renamed to flange_a, flange_b. MoveAngle renamed to
       KinematicPTP, vectorized and moved to Blocks.Sources.<br>
       Advice given from P. Beater, H. Elmqvist, S.E. Mattsson, H. Olsson
       is appreciated.</li>
<li><i>July 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Documentation and icons improved. Appropriate initial conditions
       introduced as start values in the demo models. Bearing model
       replaced by FixedRight and FixedLeft models; sensor elements replaced by
       TorqueSensor, SpeedSensor, AccSensor; new sensor elements
       RelSpeedSensor, RelAccSensor to measure relative kinematic quantitites.
       New elements GearEfficiency and Gear.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version based on an existing Dymola library
       of Martin Otter and Hilding Elmqvist.</li>
</ul>
</html>"),
        Icon(
          Line(points=[-83, -66; -63, -66], style(color=0)),
          Line(points=[36, -68; 56, -68], style(color=0)),
          Line(points=[-73, -66; -73, -91], style(color=0)),
          Line(points=[46, -68; 46, -91], style(color=0)),
          Line(points=[-83, -29; -63, -29], style(color=0)),
          Line(points=[36, -32; 56, -32], style(color=0)),
          Line(points=[-73, -9; -73, -29], style(color=0)),
          Line(points=[46, -12; 46, -32], style(color=0)),
          Line(points=[-73, -91; 46, -91], style(color=0)),
          Rectangle(extent=[-47, -17; 27, -80], style(
              color=0,
              gradient=2,
              fillColor=8)),
          Rectangle(extent=[-87, -41; -47, -54], style(
              color=0,
              gradient=2,
              fillColor=8)),
          Rectangle(extent=[27, -42; 66, -56], style(
              color=0,
              gradient=2,
              fillColor=8))));

      package Interfaces
      "Connectors and partial models for 1D rotational mechanical components"
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Window(
            x=0.07,
            y=0.13,
            width=0.43,
            height=0.52,
            library=1,
            autolayout=1), Documentation(info="<html>
<p>
This package contains connectors and partial models for 1D rotational mechanical
components. In particular
</p>
<pre>
  <b>Flange_a</b>                 Left flange of a component.
  <b>Flange_b</b>                 Right flange of a component.
  <b>Rigid</b>                    Rigid connection of two rotational 1D flanges
                           (used for elements with inertia).
  <b>Compliant</b>                Compliant connection of two rotational 1D flanges
                           (used for force laws such as a spring or a damper).
  <b>TwoFlanges</b>               Component with two rotational 1D flanges
  <b>Bearing</b>                  Component with two rotational 1D flanges, one bearing flange
                           and cardinality dependent equations
  <b>TwoFlangesAndBearing</b>     Component inherited from Bearing for equation-based classes
  <b>TwoFlangesAndBearingH</b>    Component inherited from Bearing for hierarchical components
  <b>AbsoluteSensor</b>           Base class to measure absolute flange variables.
  <b>RelativeSensor</b>           Base class to measure relative flange variables.
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
<br>
<p><b>Release Notes:</b></p>
<ul>
<li><i>October 27, 2003</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
       <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New components: Bearing, TwoFlangesAndBearing and TwoFlangesAndBearingH.</li>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Component FrictionBase adapted to new initialization.</li>
<li><i>July 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New components: TwoFlanges, AbsoluteSensor, RelativeSensor.</li>
<li><i>June 28, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
<br>
<p><b>Copyright &copy; 1999-2003, Modelica Association and DLR.</b></p>
<p><i>
The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i></p>
</HTML>
"));

        connector Flange_a "1D rotational flange (filled square icon)"
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
          annotation(defaultComponentName = "flange_a",
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Window(
              x=0.23,
              y=0.02,
              width=0.56,
              height=0.68),
            Documentation(info="<HTML>
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
<p><b>Release Notes:</b></p>
<ul>
<li><i>Nov. 2, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Improved documentation.</li>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
</HTML>
"),         Icon(Ellipse(extent=[-100,100; 100,-100], style(
                  color=0,
                  rgbcolor={0,0,0},
                  fillColor=10,
                  rgbfillColor={95,95,95},
                  fillPattern=1))),
            Diagram(                Text(
                extent=[-160,110; 40,50],
                string="%name",
                style(color=0)), Ellipse(extent=[-40,40; 40,-40], style(
                  color=0,
                  rgbcolor={0,0,0},
                  fillColor=10,
                  rgbfillColor={135,135,135}))),
            Terminal(Rectangle(extent=[-100, -100; 100, 100], style(color=0,
                    fillColor=10))));
        end Flange_a;

        connector Flange_b "1D rotational flange (non-filled square icon)"
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
          annotation(defaultComponentName = "flange_b",
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Window(
              x=0.21,
              y=0.05,
              width=0.48,
              height=0.65),
            Documentation(info="<HTML>
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
<p><b>Release Notes:</b></p>
<ul>
<li><i>Nov. 2, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Improved documentation.</li>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),         Icon(Ellipse(extent=[-98,100; 102,-100], style(
                  color=0,
                  rgbcolor={0,0,0},
                  fillColor=7,
                  rgbfillColor={255,255,255},
                  fillPattern=1))),
            Diagram(             Ellipse(extent=[-40,40; 40,-40], style(
                  color=0,
                  rgbcolor={0,0,0},
                  fillColor=7,
                  rgbfillColor={255,255,255})),
                                    Text(
                extent=[-40,110; 160,50],
                string="%name",
                style(color=0))),
            Terminal(Rectangle(extent=[-100, -100; 100, 100], style(color=0,
                    fillColor=7))));
        end Flange_b;

        partial model Rigid
        "Base class for the rigid connection of two rotational 1D flanges"

          SI.Angle phi
          "Absolute rotation angle of component (= flange_a.phi = flange_b.phi)";

          Flange_a flange_a
          "(left) driving flange (flange axis directed INTO cut plane)"
            annotation (extent=[-110, -10; -90, 10]);
          Flange_b flange_b
          "(right) driven flange (flange axis directed OUT OF cut plane)"
            annotation (extent=[90, -10; 110, 10]);
          annotation (
            Documentation(info="<html>
<p>
This is a 1D rotational component with two rigidly connected flanges,
i.e., flange_a.phi = flange_b.phi. It is used e.g. to built up components
with inertia.
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),         Diagram,
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Window(
              x=0.18,
              y=0.3,
              width=0.61,
              height=0.66));
        equation
          flange_a.phi = phi;
          flange_b.phi = phi;
        end Rigid;

        partial model Compliant
        "Base class for the compliant connection of two rotational 1D flanges"

          SI.Angle phi_rel(start=0)
          "Relative rotation angle (= flange_b.phi - flange_a.phi)";
          SI.Torque tau "Torque between flanges (= flange_b.tau)";
          Flange_a flange_a
          "(left) driving flange (flange axis directed INTO cut plane)"
            annotation (extent=[-110, -10; -90, 10]);
          Flange_b flange_b
          "(right) driven flange (flange axis directed OUT OF cut plane)"
            annotation (extent=[90, -10; 110, 10]);
          annotation (
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Window(
              x=0.32,
              y=0.01,
              width=0.6,
              height=0.6),
            Documentation(info="<html>
<p>
This is a 1D rotational component with a compliant connection of two
rotational 1D flanges where inertial effects between the two
flanges are neglected. The basic assumption is that the cut-torques
of the two flanges sum-up to zero, i.e., they have the same absolute value
but opposite sign: flange_a.tau + flange_b.tau = 0. This base class
is used to built up force elements such as springs, dampers, friction.
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),         Diagram);
        equation
          phi_rel = flange_b.phi - flange_a.phi;
          flange_b.tau = tau;
          flange_a.tau = -tau;
        end Compliant;

        partial model TwoFlanges
        "Base class for a component with two rotational 1D flanges"
          Flange_a flange_a annotation (extent=[-110, -10; -90, 10]);
          Flange_b flange_b annotation (extent=[90, -10; 110, 10]);
          annotation (
            Documentation(info="<html>
<p>
This is a 1D rotational component with two flanges.
It is used e.g. to build up parts of a drive train consisting
of several base components. There are specialized versions of this
base class for rigidly connected flanges (Interfaces.Rigid) and
for a compliant connection of flanges (Interfaces.Compliant).
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>July 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),         Diagram,
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Window(
              x=0.37,
              y=0.05,
              width=0.6,
              height=0.6));
        end TwoFlanges;

        partial model Bearing
        "Base class for interface classes with bearing connector"
          extends TwoFlanges;

          SI.Torque tau_support;

          Flange_a bearing annotation (extent=[-10, -110; 10, -90]);
          annotation (
            Diagram(Rectangle(extent=[-20, -80; 20, -120], style(color=8, fillColor=
                     8))),
            Icon(Rectangle(extent=[-20, -80; 20, -120], style(color=8, fillColor=8))),
            Documentation(info="<html>
<p>
This is a 1D rotational component with two flanges and an additional bearing flange.
It is a superclass for the two components TwoFlangesAndBearing and TwoFlangesAndBearingH.</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>October 27, 2003</i>
       by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"));

        end Bearing;

        partial model TwoFlangesAndBearing
        "Base class for a equation-based component with two rotational 1D flanges and one rotational 1D bearing flange"

          extends Bearing;

          SI.Angle phi_a;
          SI.Angle phi_b;

          annotation (Documentation(info="<html>
<p>
This is a 1D rotational component with two flanges and an additional bearing flange.
It is used e.g. to build up equation-based parts of a drive train.</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>October 27, 2003</i>
       by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"));
        equation
          if cardinality(bearing) == 0 then
            bearing.phi = 0;
          else
            bearing.tau = tau_support;
          end if;

          0 = flange_a.tau + flange_b.tau + tau_support;

          phi_a = flange_a.phi - bearing.phi;
          phi_b = flange_b.phi - bearing.phi;
        end TwoFlangesAndBearing;

        partial model TwoFlangesAndBearingH
        "Base class for a hierarchically composed component with two rotational 1D flanges and one rotational bearing flange"

          extends Bearing;

          Adapter adapter(bearingConnected=cardinality(bearing) > 1)
            annotation (extent=[-10, -70; 10, -50], rotation=90);
      protected
          encapsulated model Adapter
            import Modelica.Mechanics.Rotational.Interfaces.TwoFlanges;
            extends TwoFlanges;
            parameter Boolean bearingConnected;

            annotation (Icon(Rectangle(extent=[-90, 10; 90, -10], style(color=8,
                      fillColor=8)), Text(extent=[0, 60; 0, 20], string="%name")));
          equation
            flange_a.phi = flange_b.phi;

            if bearingConnected then
              0 = flange_a.tau + flange_b.tau;
            else
              0 = flange_a.phi;
            end if;
          end Adapter;
        equation
          tau_support = -adapter.flange_b.tau;
          connect(adapter.flange_a, bearing) annotation (points=[-6.12303e-016,-70; 0,
                -70; 0,-100],      style(color=0));
          annotation (Documentation(info="<html>
<p>
This is a 1D rotational component with two flanges and an additional bearing flange.
It is used e.g. to build up parts of a drive train consisting
of several base components.</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>October 27, 2003</i>
       by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"));
        end TwoFlangesAndBearingH;

        partial model FrictionBase "Base class of Coulomb friction elements"
          // parameter SI.AngularVelocity w_small=1 "Relative angular velocity near to zero (see model info text)";
          parameter SI.AngularVelocity w_small=1e10
          "Relative angular velocity near to zero if jumps due to a reinit(..) of the velocity can occur (set to low value only if such impulses can occur)"
             annotation(Dialog(tab="Advanced"));

            // Equations to define the following variables have to be defined in subclasses
          SI.AngularVelocity w_relfric
          "Relative angular velocity between frictional surfaces";
          SI.AngularAcceleration a_relfric
          "Relative angular acceleration between frictional surfaces";
          SI.Torque tau
          "Friction torque (positive, if directed in opposite direction of w_rel)";
          SI.Torque tau0 "Friction torque for w=0 and forward sliding";
          SI.Torque tau0_max "Maximum friction torque for w=0 and locked";
          Boolean free "true, if frictional element is not active";

          // Equations to define the following variables are given in this class
          Real sa
          "Path parameter of friction characteristic tau = f(a_relfric)";

          Boolean startForward(start=false, fixed=true)
          "true, if w_rel=0 and start of forward sliding or w_rel > w_small";
          Boolean startBackward(start=false, fixed=true)
          "true, if w_rel=0 and start of backward sliding or w_rel < -w_small";
          Boolean locked "true, if w_rel=0 and not sliding";

          constant Integer Unknown=3 "Value of mode is not known";
          constant Integer Free=2 "Element is not active";
          constant Integer Forward=1 "w_rel > 0 (forward sliding)";
          constant Integer Stuck=0
          "w_rel = 0 (forward sliding, locked or backward sliding)";
          constant Integer Backward=-1 "w_rel < 0 (backward sliding)";
          Integer mode(
            final min=Backward,
            final max=Unknown,
            start=Unknown,
            fixed=true);
        equation
          /* Friction characteristic
      (locked is introduced to help the Modelica translator determining
      the different structural configurations, if for each configuration
      special code shall be generated) */

          startForward = pre(mode) == Stuck and (sa > tau0_max or pre(startForward)
             and sa > tau0) or pre(mode) == Backward and w_relfric > w_small or
            initial() and (w_relfric > 0);
          startBackward = pre(mode) == Stuck and (sa < -tau0_max or pre(
            startBackward) and sa < -tau0) or pre(mode) == Forward and w_relfric <
            -w_small or initial() and (w_relfric < 0);
          locked = not free and not (pre(mode) == Forward or startForward or pre(
            mode) == Backward or startBackward);

          a_relfric = if locked then 0 else if free then sa else if startForward then
                  sa - tau0 else if startBackward then sa + tau0 else if pre(mode)
             == Forward then sa - tau0 else sa + tau0;

          /* Friction torque has to be defined in a subclass. Example for a clutch:
       tau = if locked then sa else if free then 0 else cgeo*fn*
            (if startForward then   Math.tempInterpol1( w_relfric, mue_pos, 2) else
             if startBackward then -Math.tempInterpol1(-w_relfric, mue_pos, 2) else
             if pre(mode) == Forward then  Math.tempInterpol1( w_relfric, mue_pos, 2)
                                     else -Math.tempInterpol1(-w_relfric, mue_pos, 2)); */

          // finite state machine to determine configuration
          mode = if free then Free else (if (pre(mode) == Forward or pre(mode) ==
            Free or startForward) and w_relfric > 0 then Forward else if (pre(mode)
             == Backward or pre(mode) == Free or startBackward) and w_relfric < 0 then
                  Backward else Stuck);
        end FrictionBase;
      end Interfaces;

      model Inertia "1D-rotational component with inertia"
        parameter SI.Inertia J=1 "Moment of inertia";
        SI.AngularVelocity w "Absolute angular velocity of component";
        SI.AngularAcceleration a "Absolute angular acceleration of component";
        annotation (
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[1, 1],
            component=[20, 20]),
          Window(
            x=0.28,
            y=0.04,
            width=0.7,
            height=0.63),
          Documentation(info="<html>
<p>
Rotational component with <b>inertia</b> and two rigidly connected flanges.
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
</HTML>
"),       Icon(
            Rectangle(extent=[-100,10; -50,-10],  style(
                color=0,
                gradient=2,
                fillColor=8)),
            Rectangle(extent=[50,10; 100,-10],  style(
                color=0,
                gradient=2,
                fillColor=8)),
            Line(points=[-80, -25; -60, -25], style(color=0)),
            Line(points=[60, -25; 80, -25], style(color=0)),
            Line(points=[-70, -25; -70, -70], style(color=0)),
            Line(points=[70, -25; 70, -70], style(color=0)),
            Line(points=[-80, 25; -60, 25], style(color=0)),
            Line(points=[60, 25; 80, 25], style(color=0)),
            Line(points=[-70, 45; -70, 25], style(color=0)),
            Line(points=[70, 45; 70, 25], style(color=0)),
            Line(points=[-70, -70; 70, -70], style(color=0)),
            Rectangle(extent=[-50, 50; 50, -50], style(
                color=0,
                gradient=2,
                fillColor=8)),
            Text(extent=[0, 120; 0, 60], string="%name"),
            Text(
              extent=[0, -80; 0, -130],
              string="J=%J",
              style(color=0))),
          Diagram(
            Line(points=[-80, -25; -60, -25], style(color=0)),
            Line(points=[60, -25; 80, -25], style(color=0)),
            Line(points=[-70, -25; -70, -70], style(color=0)),
            Line(points=[70, -25; 70, -70], style(color=0)),
            Line(points=[-80, 25; -60, 25], style(color=0)),
            Line(points=[60, 25; 80, 25], style(color=0)),
            Line(points=[-70, 45; -70, 25], style(color=0)),
            Line(points=[70, 45; 70, 25], style(color=0)),
            Line(points=[-70, -70; 70, -70], style(color=0)),
            Rectangle(extent=[-50, 50; 50, -50], style(
                color=0,
                gradient=2,
                fillColor=8)),
            Rectangle(extent=[-96,10; -50,-10],   style(
                color=0,
                gradient=2,
                fillColor=8)),
            Rectangle(extent=[50,10; 96,-10],   style(
                color=0,
                gradient=2,
                fillColor=8)),
            Polygon(points=[0, -90; -20, -85; -20, -95; 0, -90], style(color=10,
                  fillColor=10)),
            Line(points=[-90, -90; -19, -90], style(color=10, fillColor=10)),
            Text(
              extent=[4, -83; 72, -96],
              string="rotation axis",
              style(color=10)),
            Polygon(points=[9, 73; 19, 70; 9, 67; 9, 73], style(color=0, fillColor=
                    0)),
            Line(points=[9, 70; -21, 70], style(color=0, fillColor=0)),
            Text(extent=[25, 77; 77, 65], string="w = der(phi) ")));
        extends Interfaces.Rigid;
      equation
        w = der(phi);
        a = der(w);
        J*a = flange_a.tau + flange_b.tau;
      end Inertia;

      model IdealGear "Ideal gear without inertia"
        extends Interfaces.TwoFlangesAndBearing;
        parameter Real ratio=1 "Transmission ratio (flange_a.phi/flange_b.phi)";

        annotation (
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[2, 2],
            component=[20, 20]),
          Window(
            x=0.23,
            y=0.01,
            width=0.6,
            height=0.57),
          Documentation(info="<html>
<p>
This element characterices any type of gear box which is fixed in the
ground and which has one driving shaft and one driven shaft.
The gear is <b>ideal</b>, i.e., it does not have inertia, elasticity, damping
or backlash. If these effects have to be considered, the gear has to be
connected to other elements in an appropriate way.
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),       Icon(
            Rectangle(extent=[-40, 20; -20, -20], style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-40, 140; -20, 20], style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[20, 100; 40, 60], style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[20, 60; 40, -60], style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[40,10; 100,-10],  style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-20, 90; 20, 70], style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-100,10; -40,-10],  style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Text(extent=[0, 190; 0, 130], string="%name=%ratio"),
            Line(points=[-80, 20; -60, 20], style(color=0)),
            Line(points=[-80, -20; -60, -20], style(color=0)),
            Line(points=[-70, -20; -70, -70], style(color=0)),
            Line(points=[0, 60; 0, -90], style(color=0)),
            Line(points=[-10, 60; 10, 60], style(color=0)),
            Line(points=[-10, 100; 10, 100], style(color=0)),
            Line(points=[60, -20; 80, -20], style(color=0)),
            Line(points=[60, 20; 80, 20], style(color=0)),
            Line(points=[70, -20; 70, -70], style(color=0)),
            Line(points=[70, -70; -70, -70], style(color=0))),
          Diagram(
            Rectangle(extent=[-40, 20; -20, -20], style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-40, 140; -20, 20], style(
                color=0,
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[20, 100; 40, 60], style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[20, 60; 40, -60], style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-96,10; -40,-10],   style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[40,10; 96,-10],   style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-20, 90; 20, 70], style(
                color=0,
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Line(points=[-90, -80; -20, -80], style(color=10, fillColor=10)),
            Polygon(points=[0, -80; -20, -75; -20, -85; 0, -80], style(color=10,
                  fillColor=10)),
            Text(
              extent=[34, -72; 34, -86],
              string="rotation axis",
              style(color=10)),
            Line(points=[-80, 20; -60, 20], style(color=0)),
            Line(points=[-80, -20; -60, -20], style(color=0)),
            Line(points=[-70, -20; -70, -70], style(color=0)),
            Line(points=[70, -70; -70, -70], style(color=0)),
            Line(points=[0, 60; 0, -90], style(color=0)),
            Line(points=[-10, 60; 10, 60], style(color=0)),
            Line(points=[-10, 100; 10, 100], style(color=0)),
            Line(points=[60, 20; 80, 20], style(color=0)),
            Line(points=[60, -20; 80, -20], style(color=0)),
            Line(points=[70, -20; 70, -70], style(color=0))));
      equation
        phi_a = ratio*phi_b;
        0 = ratio*flange_a.tau + flange_b.tau;
      end IdealGear;

      model SpringDamper "Linear 1D rotational spring and damper in parallel"
        extends Interfaces.Compliant;
        parameter Real c(final unit="N.m/rad", final min=0) "Spring constant";
        parameter SI.Angle phi_rel0=0 "Unstretched spring angle";
        parameter Real d(
          final unit="N.m.s/rad",
          final min=0) = 0 "Damping constant";
        SI.AngularVelocity w_rel
        "Relative angular velocity between flange_b and flange_a";

        annotation (
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[1, 1],
            component=[20, 20]),
          Window(
            x=0.45,
            y=0.04,
            width=0.44,
            height=0.65),
          Documentation(info="<html>
<p>
A <b>spring</b> and <b>damper</b> element <b>connected in parallel</b>.
The component can be
connected either between two inertias/gears to describe the shaft elasticity
and damping, or between an inertia/gear and the housing (component Fixed),
to describe a coupling of the element with the housing via a spring/damper.
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),       Icon(
            Line(points=[-80, 40; -60, 40; -45, 10; -15, 70; 15, 10; 45, 70; 60, 40;
                   80, 40], style(color=0)),
            Line(points=[-80, 40; -80, -70], style(color=0)),
            Line(points=[-80, -70; -52, -70], style(color=0)),
            Rectangle(extent=[-52, -40; 38, -100], style(color=0, fillColor=8)),
            Line(points=[-52, -40; 68, -40], style(color=0)),
            Line(points=[-52, -100; 68, -100], style(color=0)),
            Line(points=[38, -70; 80, -70], style(color=0)),
            Line(points=[80, 40; 80, -70], style(color=0)),
            Line(points=[-90, 0; -80, 0], style(color=0)),
            Line(points=[80, 0; 90, 0], style(color=0)),
            Text(
              extent=[-101, -147; 98, -107],
              string="d=%d",
              style(color=0)),
            Text(extent=[0, 130; 0, 70], string="%name=%c")),
          Diagram(
            Line(points=[-80, 32; -58, 32; -43, 2; -13, 62; 17, 2; 47, 62; 62, 32;
                  80, 32], style(color=0, thickness=2)),
            Line(points=[-68, 32; -68, 97], style(color=10)),
            Line(points=[72, 32; 72, 97], style(color=10)),
            Line(points=[-68, 92; 72, 92], style(color=10)),
            Polygon(points=[62, 95; 72, 92; 62, 89; 62, 95], style(color=10,
                  fillColor=10)),
            Text(
              extent=[-20, 72; 20, 97],
              string="phi_rel",
              style(color=3)),
            Rectangle(extent=[-52, -20; 38, -80], style(color=0, fillColor=8)),
            Line(points=[-52, -80; 68, -80], style(color=0)),
            Line(points=[-52, -20; 68, -20], style(color=0)),
            Line(points=[38, -50; 80, -50], style(color=0)),
            Line(points=[-80, -50; -52, -50], style(color=0)),
            Line(points=[-80, 32; -80, -50], style(color=0)),
            Line(points=[80, 32; 80, -50], style(color=0)),
            Line(points=[-96,0; -80,0],   style(color=0)),
            Line(points=[96,0; 80,0],   style(color=0)),
            Text(
              extent=[15, -87; 83, -100],
              string="rotation axis",
              style(color=10)),
            Polygon(points=[11, -94; -9, -89; -9, -99; 11, -94], style(color=10,
                  fillColor=10)),
            Line(points=[-79, -94; -8, -94], style(color=10, fillColor=10))));
      equation
        w_rel = der(phi_rel);
        tau = c*(phi_rel - phi_rel0) + d*w_rel;
      end SpringDamper;

      model ElastoBacklash
      "Backlash connected in series to linear spring and damper (backlash is modeled with elasticity)"

        extends Interfaces.Compliant;

        parameter SI.Angle b(final min=0) = 0 "Total backlash";
        parameter Real c(
          final unit="N.m/rad",
          final min=Modelica.Constants.small) = 1.e5
        "Spring constant (c > 0 required)";
        parameter SI.Angle phi_rel0=0 "Unstretched spring angle";
        parameter Real d(
          final unit="N.m.s/rad",
          final min=0) = 0 "Damping constant";
        SI.AngularVelocity w_rel
        "Relative angular velocity between flange_b and flange_a";
    protected
        SI.Angle b2=b/2;
        // A minimum backlash is defined in order to avoid an infinite
        // number of state events if backlash b is set to zero.
        constant SI.Angle b_min=1.e-10 "minimum backlash";
        annotation (
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[1, 1],
            component=[20, 20]),
          Window(
            x=0.45,
            y=0.01,
            width=0.44,
            height=0.65),
          Documentation(info="<html>
<p>
This element consists of a <b>backlash</b> element <b>connected in series</b>
to a <b>spring</b> and <b>damper</b> element which are <b>connected in parallel</b>.
The spring constant shall be non-zero, otherwise the component cannot be used.
</p>
<p>
In combination with components IdealGear, the ElastoBacklash model
can be used to model a gear box with backlash, elasticity and damping.
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),       Icon(
            Line(points=[-80, 32; -58, 32; -48, 0; -34, 61; -20, 0; -8, 60; 0, 30;
                  20, 30], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Rectangle(extent=[-60, -20; -10, -80], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0,
                fillColor=8)),
            Line(points=[-52, -80; 0, -80], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Line(points=[-52, -20; 0, -20], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Line(points=[-10, -50; 20, -50], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Line(points=[-80, -50; -60, -50], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Line(points=[-80, 32; -80, -50], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Line(points=[20, 30; 20, -50], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Line(points=[-90, 0; -80, 0], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Line(points=[90, 0; 80, 0], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Line(points=[20, 0; 60, 0; 60, -30], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Line(points=[40, -12; 40, -40; 80, -40; 80, 0], style(
                color=0,
                pattern=1,
                thickness=1,
                arrow=0)),
            Text(
              extent=[-99, -130; 100, -90],
              string="b=%b",
              style(color=0)),
            Text(extent=[0, 120; 0, 60], string="%name=%c")),
          Diagram(
            Line(points=[-80, 32; -58, 32; -48, 0; -34, 60; -20, 0; -8, 60; 0, 30;
                  20, 30], style(color=0, thickness=2)),
            Line(points=[-68, 32; -68, 97], style(color=10)),
            Line(points=[80, 0; 80, 96], style(color=10)),
            Line(points=[-68, 92; 72, 92], style(color=10)),
            Polygon(points=[70, 95; 80, 92; 70, 89; 70, 95], style(color=10,
                  fillColor=10)),
            Text(
              extent=[-10, 70; 30, 95],
              string="phi_rel",
              style(color=10)),
            Rectangle(extent=[-60, -20; -10, -80], style(
                color=0,
                thickness=2,
                fillColor=8)),
            Line(points=[-52, -80; 0, -80], style(color=0, thickness=2)),
            Line(points=[-52, -20; 0, -20], style(color=0, thickness=2)),
            Line(points=[-10, -50; 20, -50], style(color=0, thickness=2)),
            Line(points=[-80, -50; -60, -50], style(color=0, thickness=2)),
            Line(points=[-80, 32; -80, -50], style(color=0, thickness=2)),
            Line(points=[20, 30; 20, -50], style(color=0, thickness=2)),
            Line(points=[-96,0; -80,0],   style(color=0)),
            Line(points=[96,0; 80,0],   style(color=0, thickness=2)),
            Line(points=[20, 0; 60, 0; 60, -30], style(color=0, thickness=2)),
            Line(points=[40, -12; 40, -40; 80, -40; 80, 0], style(color=0,
                  thickness=2)),
            Line(points=[30, 0; 30, 64], style(color=10)),
            Line(points=[30, 60; 80, 60], style(color=10)),
            Polygon(points=[70, 63; 80, 60; 70, 57; 70, 63], style(color=10,
                  fillColor=10)),
            Text(
              extent=[39, 60; 68, 46],
              string="b",
              style(
                color=9,
                fillColor=8,
                fillPattern=1)),
            Text(
              extent=[15, -89; 83, -102],
              string="rotation axis",
              style(color=10)),
            Polygon(points=[11, -96; -9, -91; -9, -101; 11, -96], style(color=10,
                  fillColor=10)),
            Line(points=[-79, -96; -8, -96], style(color=10, fillColor=10))));
      equation
        w_rel = der(phi_rel);
        tau = if b2 > b_min then (if phi_rel > b2 then c*(phi_rel - phi_rel0 - b2)
           + d*w_rel else (if phi_rel < -b2 then c*(phi_rel - phi_rel0 + b2) + d*
          w_rel else 0)) else c*(phi_rel - phi_rel0) + d*w_rel;
      end ElastoBacklash;

      model BearingFriction "Coulomb friction in bearings "
        extends Interfaces.TwoFlangesAndBearing;

        parameter Real tau_pos[:, :]=[0, 1]
        "[w,tau] Positive sliding friction characteristic (w>=0)";
        parameter Real peak(final min=1) = 1
        "peak*tau_pos[1,2] = Maximum friction torque for w==0";

        extends Interfaces.FrictionBase;

        SI.Angle phi;
        SI.AngularVelocity w
        "Absolute angular velocity of flange_a and flange_b";
        SI.AngularAcceleration a
        "Absolute angular acceleration of flange_a and flange_b";

        annotation (
          Documentation(info="<html>
<p>
This element describes <b>Coulomb friction</b> in <b>bearings</b>,
i.e., a frictional torque acting between a flange and the housing.
The positive sliding friction torque \"tau\" has to be defined
by table \"tau_pos\" as function of the absolute angular velocity \"w\".
E.g.
<p>
<pre>
       w | tau
      ---+-----
       0 |   0
       1 |   2
       2 |   5
       3 |   8
</pre>
<p>
gives the following table:
</p>
<pre>
   tau_pos = [0, 0; 1, 2; 2, 5; 3, 8];
</pre>
<p>
Currently, only linear interpolation in the table is supported.
Outside of the table, extrapolation through the last
two table entries is used. It is assumed that the negative
sliding friction force has the same characteristic with negative
values. Friction is modelled in the following way:
</p>
<p>
When the absolute angular velocity \"w\" is not zero, the friction torque
is a function of w and of a constant normal force. This dependency
is defined via table tau_pos and can be determined by measurements,
e.g. by driving the gear with constant velocity and measuring the
needed motor torque (= friction torque).
</p>
<p>
When the absolute angular velocity becomes zero, the elements
connected by the friction element become stuck, i.e., the absolute
angle remains constant. In this phase the friction torque is
calculated from a torque balance due to the requirement, that
the absolute acceleration shall be zero.  The elements begin
to slide when the friction torque exceeds a threshold value,
called the maximum static friction torque, computed via:
</p>
<pre>
   maximum_static_friction = <b>peak</b> * sliding_friction(w=0)  (<b>peak</b> >= 1)
</pre>
<p>
This procedure is implemented in a \"clean\" way by state events and
leads to continuous/discrete systems of equations if friction elements
are dynamically coupled which have to be solved by appropriate
numerical methods. The method is described in:
</p>
<dl>
<dt>Otter M., Elmqvist H., and Mattsson S.E. (1999):
<dd><b>Hybrid Modeling in Modelica based on the Synchronous
    Data Flow Principle</b>. CACSD'99, Aug. 22.-26, Hawaii.
</dl>
<p>
More precise friction models take into account the elasticity of the
material when the two elements are \"stuck\", as well as other effects,
like hysteresis. This has the advantage that the friction element can
be completely described by a differential equation without events. The
drawback is that the system becomes stiff (about 10-20 times slower
simulation) and that more material constants have to be supplied which
requires more sophisticated identification. For more details, see the
following references, especially (Armstrong and Canudas de Witt 1996):
</p>
<dl>
<dt>Armstrong B. (1991):
<dd><b>Control of Machines with Friction</b>. Kluwer Academic
    Press, Boston MA.<br><br>
<dt>Armstrong B., and Canudas de Wit C. (1996):
<dd><b>Friction Modeling and Compensation.</b>
    The Control Handbook, edited by W.S.Levine, CRC Press,
    pp. 1369-1382.<br><br>
<dt>Canudas de Wit C., Olsson H., Astroem K.J., and Lischinsky P. (1995):
<dd><b>A new model for control of systems with friction.</b>
    IEEE Transactions on Automatic Control, Vol. 40, No. 3, pp. 419-425.<br><br>
</dl>
<br>
<p><b>Release Notes:</b></p>
<ul>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),       Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[1, 1],
            component=[20, 20]),
          Window(
            x=0.25,
            y=0.01,
            width=0.53,
            height=0.61),
          Icon(
            Rectangle(extent=[-100,10; 100,-10], style(
                color=0,
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-60, -10; 60, -60], style(color=0)),
            Rectangle(extent=[-60, -10; 60, -25], style(
                color=0,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-60, -45; 60, -61], style(
                color=0,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-50, -18; 50, -50], style(
                color=0,
                fillColor=7,
                fillPattern=1)),
            Polygon(points=[60, -60; 60, -70; 75, -70; 75, -80; -75, -80; -75, -70;
                   -60, -70; -60, -60; 60, -60], style(
                color=0,
                fillColor=9,
                fillPattern=1)),
            Line(points=[-75, -10; -75, -70], style(color=0)),
            Line(points=[75, -10; 75, -70], style(color=0)),
            Rectangle(extent=[-60, 60; 60, 10], style(color=0)),
            Rectangle(extent=[-60, 60; 60, 45], style(
                color=0,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-60, 25; 60, 10], style(
                color=0,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-50, 51; 50, 19], style(
                color=0,
                fillColor=7,
                fillPattern=1)),
            Line(points=[-75, 70; -75, 10], style(color=0)),
            Polygon(points=[60, 60; 60, 70; 75, 70; 75, 80; -75, 80; -75, 70; -60,
                  70; -60, 60; 60, 60], style(
                color=0,
                fillColor=9,
                fillPattern=1)),
            Line(points=[75, 70; 75, 10], style(color=0)),
            Text(extent=[0, 150; 0, 90], string="%name"),
            Line(points=[-10, -90; 0, -80], style(color=0)),
            Line(points=[-5, -90; 5, -80], style(color=0)),
            Line(points=[0, -90; 10, -80], style(color=0)),
            Line(points=[5, -90; 10, -85], style(color=0)),
            Line(points=[-10, -85; -5, -80], style(color=0))),
          Diagram(
            Rectangle(extent=[-96,10; 96,-10],   style(
                color=0,
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-60, -10; 60, -60], style(color=0)),
            Rectangle(extent=[-60, -10; 60, -25], style(
                color=0,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-60, -45; 60, -61], style(
                color=0,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-50, -18; 50, -50], style(
                color=0,
                fillColor=7,
                fillPattern=1)),
            Polygon(points=[60, -60; 60, -70; 75, -70; 75, -80; -75, -80; -75, -70;
                   -60, -70; -60, -60; 60, -60], style(
                color=0,
                fillColor=9,
                fillPattern=1)),
            Line(points=[-75, -10; -75, -70], style(color=0)),
            Line(points=[75, -10; 75, -70], style(color=0)),
            Rectangle(extent=[-60, 60; 60, 10], style(color=0)),
            Rectangle(extent=[-60, 60; 60, 45], style(
                color=0,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-60, 25; 60, 10], style(
                color=0,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[-50, 51; 50, 19], style(
                color=0,
                fillColor=7,
                fillPattern=1)),
            Line(points=[-75, 70; -75, 10], style(color=0)),
            Polygon(points=[60, 60; 60, 70; 75, 70; 75, 80; -75, 80; -75, 70; -60,
                  70; -60, 60; 60, 60], style(
                color=0,
                fillColor=9,
                fillPattern=1)),
            Line(points=[75, 70; 75, 10], style(color=0)),
            Line(points=[-20, -24; 38, -24], style(color=1, thickness=4)),
            Polygon(points=[-20, -19; -20, -29; -36, -24; -20, -19], style(
                color=1,
                fillColor=1,
                fillPattern=1)),
            Text(
              extent=[-45, -23; 49, -51],
              string="tau (friction torque)",
              style(color=1)),
            Text(
              extent=[14, 97; 82, 84],
              string="rotation axis",
              style(color=10)),
            Polygon(points=[10, 90; -10, 95; -10, 85; 10, 90], style(color=10,
                  fillColor=10)),
            Line(points=[-80, 90; -9, 90], style(color=10, fillColor=10)),
            Line(points=[-10, -90; 0, -80], style(color=0)),
            Line(points=[-5, -90; 5, -80], style(color=0)),
            Line(points=[0, -90; 10, -80], style(color=0)),
            Line(points=[5, -90; 10, -85], style(color=0)),
            Line(points=[-10, -85; -5, -80], style(color=0))));
      equation
        // Constant auxiliary variables
        tau0 = Modelica.Math.tempInterpol1(0, tau_pos, 2);
        tau0_max = peak*tau0;
        free = false;

        phi = phi_a;
        phi = phi_b;

        // Angular velocity and angular acceleration of flanges
        w = der(phi);
        a = der(w);
        w_relfric = w;
        a_relfric = a;

        // Equilibrium of torques
        0 = flange_a.tau + flange_b.tau - tau;

        // Friction torque
        tau = if locked then sa else (if startForward then
          Modelica.Math.tempInterpol1(w, tau_pos, 2) else if startBackward then -
          Modelica.Math.tempInterpol1(-w, tau_pos, 2) else if pre(mode) == Forward then
                Modelica.Math.tempInterpol1(w, tau_pos, 2) else -
          Modelica.Math.tempInterpol1(-w, tau_pos, 2));
      end BearingFriction;

      model GearEfficiency "Obsolete component (use model LossyGear instead)"
        extends Interfaces.TwoFlangesAndBearing;

        parameter Real eta(
          min=Modelica.Constants.small,
          max=1) = 1 "Efficiency";
        SI.Angle phi;
        SI.Power power_a "Energy flowing into flange_a (= power)";
        Boolean driving_a
        "True, if energy is flowing INTO and not out of flange flange_a";

        annotation (
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[1, 1],
            component=[20, 20]),
          Window(
            x=0.23,
            y=0.06,
            width=0.69,
            height=0.62),
          Icon(
            Text(extent=[0, 130; 0, 70], string="%name"),
            Rectangle(extent=[-100,20; 100,-20], style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Line(points=[-30, -40; 30, -40], style(color=0)),
            Line(points=[0, -40; 0, -90], style(color=0)),
            Polygon(points=[-30, -20; 60, -20; 60, -80; 70, -80; 50, -100; 30, -80;
                   40, -80; 40, -30; -30, -30; -30, -20; -30, -20], style(
                color=1,
                gradient=0,
                fillColor=1,
                fillPattern=1)),
            Text(
              extent=[0, 70; 0, 20],
              string="eta=%eta",
              style(color=0)),
            Line(points=[30, -50; 20, -60], style(color=0)),
            Line(points=[30, -40; 10, -60], style(color=0)),
            Line(points=[20, -40; 0, -60], style(color=0)),
            Line(points=[10, -40; -10, -60], style(color=0)),
            Line(points=[0, -40; -20, -60], style(color=0)),
            Line(points=[-10, -40; -30, -60], style(color=0)),
            Line(points=[-20, -40; -30, -50], style(color=0))),
          obsolete=
              "This model can get stuck due when the torque direction varies, use LossyGear instead.",
          Documentation(info="<html>
<p>
THIS COMPONENT IS <b>OBSOLETE</b> and should <b>no longer be used</b>. It is only
kept for <b>backward compatibility</b> purposes. Use model
Modelica.Mechanics.Rotational.LossyGear instead which implements
gear efficiency in a much more reliable way.
</p>
<p>
This component consists of two rigidly connected flanges flange_a and flange_b without
inertia where an <b>efficency</b> coefficient <b>eta</b> reduces the driven
torque as function of the driving torque depending on the direction
of the energy flow, i.e., energy is always lost. This can be seen as a
simple model of the Coulomb friction acting between the teeth of a
gearbox.
</p>
<p>
Note, that most gearbox manufacturers provide tables of the
efficiency of a gearbox as function of the angular velocity
(efficiency becomes zero, if the angular velocity is zero).
However, such a table is practically useless for simulation purposes,
because in gearboxes always two types of friction is present:
(1) Friction in the <b>bearings</b> and (2) friction between
the teeth of the gear. (1) leads to a velocity dependent, additive
loss-torque, whereas (2) leads to a torque-dependent reduction of the
driving torque. The gearbox manufacturers measure both effects
together and determine the gear efficiency from it, although for
simulation purposes the two effects need to be separated.
Assume for example that only constant bearing friction, i.e.,
bearingTorque=const., is present, i.e.,
</p>
<pre>
   (1)  loadTorque = motorTorque - sign(w)*bearingTorque
</pre>
<p>
Gearbox manufacturers use the loss-formula
</p>
<pre>
   (2)  loadTorque = eta*motorTorque
</pre>
<p>
Comparing (1) and (2) gives a formulat for the efficiency eta:
</p>
<pre>
   eta = (1 - sign(w)*bearingTorque/motorTorque)
</pre>
<p>
When the motorTorque becomes smaller as the bearingTorque,
(2) is useless, because the efficiency is zero. To summarize,
be careful to determine the gear <b>efficiency</b> of this element
from tables of the gear manufacturers.
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>July 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),       Diagram(
            Rectangle(extent=[-96,20; 96,-21],   style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Line(points=[-30, -40; 30, -40], style(color=0)),
            Line(points=[0, 60; 0, 40], style(color=0)),
            Line(points=[-30, 40; 29, 40], style(color=0)),
            Line(points=[0, -40; 0, -90], style(color=0)),
            Polygon(points=[-30, -20; 60, -20; 60, -80; 70, -80; 50, -100; 30, -80;
                   40, -80; 40, -30; -30, -30; -30, -20; -30, -20], style(
                color=1,
                gradient=0,
                fillColor=1,
                fillPattern=1)),
            Text(
              extent=[16, 83; 84, 70],
              string="rotation axis",
              style(color=10)),
            Polygon(points=[12, 76; -8, 81; -8, 71; 12, 76], style(color=10,
                  fillColor=10)),
            Line(points=[-78, 76; -7, 76], style(color=10, fillColor=10)),
            Line(points=[30, -50; 20, -60], style(color=0)),
            Line(points=[30, -40; 10, -60], style(color=0)),
            Line(points=[20, -40; 0, -60], style(color=0)),
            Line(points=[10, -40; -10, -60], style(color=0)),
            Line(points=[0, -40; -20, -60], style(color=0)),
            Line(points=[-10, -40; -30, -60], style(color=0)),
            Line(points=[-20, -40; -30, -50], style(color=0))));

      equation
        phi = phi_a;
        phi = phi_b;
        power_a = flange_a.tau*der(phi);
        driving_a = power_a >= 0;
        flange_b.tau = -(if driving_a then eta*flange_a.tau else flange_a.tau/eta);
      end GearEfficiency;

      model Gear "Realistic model of a gearbox"
        extends Interfaces.TwoFlangesAndBearingH;

        parameter Real ratio=1 "transmission ratio (flange_a.phi/flange_b.phi)";
        parameter Real eta(
          min=Modelica.Constants.small,
          max=1) = 1 "Gear efficiency";
        parameter Real friction_pos[:, :]=[0, 1]
        "[w,tau] positive sliding friction characteristic (w>=0)";
        parameter Real peak(final min=1) = 1
        "peak*friction_pos[1,2] = maximum friction torque at zero velocity";
        parameter Real c(
          final unit="N.m/rad",
          final min=Modelica.Constants.small) = 1.e5
        "Gear elasticity (spring constant)";
        parameter Real d(
          final unit="N.m.s/rad",
          final min=0) = 0 "(relative) gear damping";
        parameter SI.Angle b(final min=0) = 0 "Total backlash";

        annotation (
          Documentation(info="<html>
<p>
This component models the essential effects of a gearbox, in particular
gear <b>efficiency</b> due to friction between the teeth, <b>bearing friction</b>,
gear <b>elasticity</b> and <b>damping</b>, <b>backlash</b>.
The inertia of the gear wheels is not modeled. If necessary, inertia
has to be taken into account by connecting components of model Inertia
to the left and/or the right flange.
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>July 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),       Icon(
            Rectangle(extent=[-40, 60; 40, -60], style(
                color=3,
                pattern=1,
                thickness=1,
                gradient=2,
                arrow=0,
                fillColor=8,
                fillPattern=1)),
            Polygon(points=[-60, -80; -46, -80; -20, -20; 20, -20; 46, -80; 60, -80;
                   60, -90; -60, -90; -60, -80], style(
                color=0,
                fillColor=0,
                fillPattern=1)),
            Rectangle(extent=[-100,10; -60,-10],  style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Rectangle(extent=[60,10; 100,-10],  style(
                gradient=2,
                fillColor=8,
                fillPattern=1)),
            Polygon(points=[-60, 10; -60, 20; -40, 40; -40, -40; -60, -20; -60, 10],
                 style(
                color=10,
                gradient=2,
                fillColor=10,
                fillPattern=1)),
            Polygon(points=[60, 20; 40, 40; 40, -40; 60, -20; 60, 20], style(
                color=10,
                fillColor=10,
                fillPattern=1)),
            Text(extent=[0, 129; 0, 70], string="%name=%ratio"),
            Text(
              extent=[-100, -152; 99, -112],
              string="c=%c",
              style(color=0))),
          Diagram(
            Text(
              extent=[2, 29; 46, 22],
              string="rotation axis",
              style(color=10)),
            Polygon(points=[4, 25; -4, 27; -4, 23; 4, 25], style(color=10,
                  fillColor=10)),
            Line(points=[-36, 25; -3, 25], style(color=10, fillColor=10))));
        IdealGear gearRatio(final ratio=ratio)
          annotation (extent=[-70, -10; -50, 10]);
        GearEfficiency gearEfficiency(final eta=eta)
          annotation (extent=[-30, -10; -10, 10]);
        ElastoBacklash elastoBacklash(
          final b=b,
          final c=c,
          final phi_rel0=0,
          final d=d) annotation (extent=[50, -10; 70, 10]);
        BearingFriction bearingFriction(final tau_pos=friction_pos, final peak=peak)
          annotation (extent=[10, -10; 30, 10]);
      equation
        connect(flange_a, gearRatio.flange_a)
          annotation (points=[-100, 0; -70, 0], style(color=0));
        connect(gearRatio.flange_b, gearEfficiency.flange_a)
          annotation (points=[-50, 0; -30, 0], style(color=0));
        connect(gearEfficiency.flange_b, bearingFriction.flange_a)
          annotation (points=[-10, 0; 10, 0], style(color=0));
        connect(bearingFriction.flange_b, elastoBacklash.flange_a)
          annotation (points=[30, 0; 50, 0], style(color=0));
        connect(elastoBacklash.flange_b, flange_b)
          annotation (points=[70, 0; 100, 0], style(color=0));
        connect(gearRatio.bearing, adapter.flange_b) annotation (points=[-60,-10;
              -60,-40; 6.12303e-016,-40; 6.12303e-016,-50],    style(color=0));
        connect(gearEfficiency.bearing, adapter.flange_b) annotation (points=[-20,
              -10; -20,-40; 6.12303e-016,-40; 6.12303e-016,-50],    style(color=0));
        connect(bearingFriction.bearing, adapter.flange_b) annotation (points=[20,
              -10; 20,-40; 6.12303e-016,-40; 6.12303e-016,-50],    style(color=0));
      end Gear;

      model Fixed "Flange fixed in housing at a given angle"
        parameter SI.Angle phi0=0 "Fixed offset angle of housing";

        Interfaces.Flange_b flange_b "(right) flange fixed in housing"
          annotation (extent=[10,-10; -10,10]);
        annotation (
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[2, 2],
            component=[20, 20]),
          Window(
            x=0.27,
            y=0.02,
            width=0.63,
            height=0.73),
          Icon(
            Text(extent=[0, -92; 0, -152], string="%name=%phi0"),
            Line(points=[-80, -40; 80, -40], style(color=0)),
            Line(points=[80, -40; 40, -80], style(color=0)),
            Line(points=[40, -40; 0, -80], style(color=0)),
            Line(points=[0, -40; -40, -80], style(color=0)),
            Line(points=[-40, -40; -80, -80], style(color=0)),
            Line(points=[0, -40; 0, -10], style(color=0))),
          Documentation(info="<html>
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
<p><b>Release Notes:</b></p>
<ul>
<li><i>July 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),       Diagram(
            Line(points=[-80, -40; 80, -40], style(color=0)),
            Line(points=[80, -40; 40, -80], style(color=0)),
            Line(points=[40, -40; 0, -80], style(color=0)),
            Line(points=[0, -40; -40, -80], style(color=0)),
            Line(points=[-40, -40; -80, -80], style(color=0)),
            Line(points=[0,-40; 0,-4],    style(color=0)),
            Polygon(points=[8, 46; -12, 51; -12, 41; 8, 46], style(color=10,
                  fillColor=10)),
            Line(points=[-82, 46; -11, 46], style(color=10, fillColor=10)),
            Text(
              extent=[12, 53; 80, 40],
              string="rotation axis",
              style(color=10))));
      equation
        flange_b.phi = phi0;
      end Fixed;

      model Torque "Input signal acting as external torque on a flange"
        Modelica.Blocks.Interfaces.RealInput tau( redeclare type SignalType =
              SI.Torque)
        "Torque driving the flange (a positive value accelerates the flange)"
          annotation (extent=[-140, -20; -100, 20]);
        Interfaces.Flange_b flange_b "(Right) flange"
          annotation (extent=[90, -10; 110, 10]);
        annotation (
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[1, 1],
            component=[20, 20]),
          Window(
            x=0.32,
            y=0.03,
            width=0.67,
            height=0.72),
          Documentation(info="<HTML>
<p>
The input signal <b>tau</b> defines an external
torque in [Nm] which acts (with negative sign) at
a flange connector, i.e., the component connected to this
flange is driven by torque <b>tau</b>.</p>
<p>
The input signal can be provided from one of the signal generator
blocks of Modelica.Blocks.Sources.
</p>
<p><b>Release Notes:</b></p>
<ul>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.
</li>
</ul>
</HTML>
"),       Icon(
            Text(extent=[0, 130; 0, 70], string="%name"),
            Text(
              extent=[-62,-29; -141,-70],
              string="tau",
              style(color=0)),
            Line(points=[-88, 0; -64, 30; -36, 52; -2, 62; 28, 56; 48, 44; 64, 28;
                  76, 14; 86, 0], style(
                color=0,
                thickness=2,
                fillColor=0)),
            Polygon(points=[86, 0; 66, 58; 37, 27; 86, 0], style(
                color=0,
                fillColor=0,
                fillPattern=1)),
            Rectangle(extent=[-20, -80; 20, -120], style(color=8, fillColor=8)),
            Line(points=[-30, -30; 30, -30], style(color=0)),
            Line(points=[0, -30; 0, -90], style(color=0)),
            Line(points=[-30, -50; -10, -30], style(color=0)),
            Line(points=[-10, -50; 10, -30], style(color=0)),
            Line(points=[10, -50; 30, -30], style(color=0))),
          Diagram(
            Text(
              extent=[14, 86; 82, 73],
              string="rotation axis",
              style(color=10)),
            Polygon(points=[10, 80; -10, 85; -10, 75; 10, 80], style(color=10,
                  fillColor=10)),
            Line(points=[-80, 80; -9, 80], style(color=10, fillColor=10)),
            Line(points=[-88, 0; -64, 30; -36, 52; -2, 62; 28, 56; 48, 44; 64, 28;
                  76, 14; 80, 10], style(
                color=0,
                thickness=2,
                fillColor=0)),
            Polygon(points=[86, 0; 66, 58; 38, 28; 86, 0], style(
                color=0,
                fillColor=0,
                fillPattern=1))));
        Interfaces.Flange_a bearing annotation (extent=[-10, -110; 10, -90]);
      equation
        flange_b.tau = -tau;

        if cardinality(bearing) == 0 then
          bearing.phi = 0;
        else
          bearing.tau = tau;
        end if;
      end Torque;
    end Rotational;
  end Mechanics;

  package SIunits "Type definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Library2;

    package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Library2;

      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Library2;
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
"),   Icon(Text(
              extent=[-66, -13; 52, -67],
              string="[rev/min]",
              style(color=0))));
      end NonSIunits;
      annotation(preferedView="info", Icon(
          Text(
            extent=[-33, -7; -92, -67],
            string="°C",
            style(color=0, thickness=4)),
          Text(
            extent=[82, -7; 22, -67],
            string="K",
            style(color=0)),
          Line(points=[-26, -36; 6, -36], style(color=0)),
          Polygon(points=[6, -28; 6, -45; 26, -37; 6, -28], style(pattern=0,
                fillColor=0))), Documentation(info="<HTML>
<p>This package provides conversion functions from the non SI Units
defined in package Modelica.SIunits.Conversions.NonSIunits to the
corresponding SI Units defined in package Modelica.SIunits and vice
versa. It is recommended to use these functions in the following
way:</p>
<pre>
  <b>import</b> SI = Modelica.SIunits;
  <b>import</b> Modelica.SIunits.Conversions.*;
     ...
  <b>parameter</b> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
  <b>parameter</b> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
  <b>parameter</b> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                      // to radian per seconds
</pre>
<p>The following conversion functions are provided. Note, that all
of them have one Real input and one Real output argument:</p>
<table border=1 cellspacing=0 cellpadding=2>
<tr>
<th>Function</th>
<th>Description</th>
</tr>
<tr>
<td><b>to_degC</b><br>
<b>from_degC</b></td>
<td>Convert from Kelvin to degree Celsius<br>
Convert from degree Celsius to Kelvin</td>
</tr>
<tr>
<td><b>to_degF</b><br>
<b>from_degF</b></td>
<td>Convert from Kelvin to degree Fahrenheit<br>
Convert from degree Fahrenheit to Kelvin</td>
</tr>
<tr>
<td><b>to_degRk</b><br>
<b>from_degRk</b></td>
<td>Convert from Kelvin to degree Rankine<br>
Convert from degree Rankine to Kelvin</td>
</tr>
<tr>
<td><b>to_deg</b><br>
<b>from_deg</b></td>
<td>Convert from radian to degree<br>
Convert from degree to radian</td>
</tr>
<tr>
<td><b>to_rpm</b><br>
<b>from_rpm</b></td>
<td>Convert from radian per second to revolutions per minute<br>
Convert from revolutions per minute to radian per second</td>
</tr>
<tr>
<td><b>to_kmh</b><br>
<b>from_kmh</b></td>
<td>Convert from metre per second to kilometre per hour<br>
Convert from kilometre per hour to metre per second</td>
</tr>
<tr>
<td><b>to_day</b><br>
<b>from_day</b></td>
<td>Convert from second to day<br>
Convert from day to second</td>
</tr>
<tr>
<td><b>to_hour</b><br>
<b>from_hour</b></td>
<td>Convert from second to hour<br>
Convert from hour to second</td>
</tr>
<tr>
<td><b>to_minute</b><br>
<b>from_minute</b></td>
<td>Convert from second to minute<br>
Convert from minute to second</td>
</tr>
<tr>
<td><b>to_litre</b><br>
<b>from_litre</b></td>
<td>Convert from cubic metre to litre<br>
Convert from litre to cubic metre</td>
</tr>
<tr>
<td><b>to_kWh</b><br>
<b>from_kWh</b></td>
<td>Convert from Joule to kilo Watt hour<br>
Convert from kilo Watt hour to Joule</td>
</tr>
<tr>
<td><b>to_bar</b><br>
<b>from_bar</b></td>
<td>Convert from Pascal to bar<br>
Convert from bar to Pascal</td>
</tr>
<tr>
<td><b>to_gps</b><br>
<b>from_gps</b></td>
<td>Convert from kilogram per second to gram per second<br>
Convert from gram per second to kilogram per second</td>
</tr>
</table>
<p>There is the additional <b>partial</b> function <b>ConversionIcon</b>
in this package. It contains just the base icon for all the conversion
functions.</p>
</HTML>
"));
    end Conversions;

    type Angle = Real (
        final quantity="Angle",
        final unit="rad",
        displayUnit="deg");

    type Time = Real (final quantity="Time", final unit="s");

    type AngularVelocity = Real (
        final quantity="AngularVelocity",
        final unit="rad/s",
        displayUnit="rev/min");

    type AngularAcceleration = Real (final quantity="AngularAcceleration", final unit
        =      "rad/s2");

    type Frequency = Real (final quantity="Frequency", final unit="Hz");

    type MomentOfInertia = Real (final quantity="MomentOfInertia", final unit=
            "kg.m2");

    type Inertia = MomentOfInertia;

    type Torque = Real (final quantity="Torque", final unit="N.m");

    type Power = Real (final quantity="Power", final unit="W");
    annotation(preferedView="info",
      Window(
        x=0.08,
        y=0.04,
        width=0.58,
        height=0.84,
        library=1,
        autolayout=1),
      Invisible=true,
      Icon(Text(
          extent=[-63, -13; 45, -67],
          string="[kg.m2]",
          style(color=0))),
      Documentation(info="<html>
<p>This package provides predefined types, such as <i>Mass</i>,
<i>Length</i>, <i>Time</i>, based on the international standard
on units:</p>
<ul>
<li>ISO 31-1992 \"General principles concerning
    quantities, units and symbols\"</li>
<li>ISO 1000-1992 \"SI units and recommendations for the use
    of their multiples and of certain other units\".</li>
</ul>
<p>For more information on units, see also the book of
Francois Cardarelli \"Scientific Unit Conversion - A Practical
Guide to Metrication\"
(Springer 1997).</p>
<p>The following conventions are used in this package:</p>
<ul>
<li>Modelica quantity names are defined according to the recommendations
    of ISO 31. Some of these name are rather long, such as
    \"ThermodynamicTemperature\". Shorter alias names are defined, e.g.,
    \"type Temp_K = ThermodynamicTemperature;\".</li>
<li>Modelica units are defined according to the SI base units without
    multiples (only exception \"kg\").</li>
<li>For some quantities, more convenient units for an engineer are
    defined as \"displayUnit\", i.e., the default unit for display
    purposes (e.g., displayUnit=\"deg\" for quantity=\"Angle\").</li>
<li>The type name is identical to the quantity name, following
    the convention of type names.</li>
<li>All quantity and unit attributes are defined as final in order
    that they cannot be redefined to another value.</li>
<li>Similiar quantities, such as \"Length, Breadth, Height, Thickness,
    Radius\" are defined as the same quantity (here: \"Length\").</li>
<li>The ordering of the type declarations in this package follows ISO 31:
<pre>
  Chapter  1: <b>Space and Time</b>
  Chapter  2: <b>Periodic and Related Phenomena</b>
  Chapter  3: <b>Mechanics</b>
  Chapter  4: <b>Heat</b>
  Chapter  5: <b>Electricity and Magnetism</b>
  Chapter  6: <b>Light and Related Electro-Magnetic Radiations</b>
  Chapter  7: <b>Acoustics</b>
  Chapter  8: <b>Physical Chemistry</b>
  Chapter  9: <b>Atomic and Nuclear Physics</b>
  Chapter 10: <b>Nuclear Reactions and Ionizing Radiations</b>
  Chapter 11: (not defined in ISO 31-1992)
  Chapter 12: <b>Characteristic Numbers</b>
  Chapter 13: <b>Solid State Physics</b>
</pre>
</li>
<li>Conversion functions between SI and non-SI units are available in subpackage
    <b>Conversions</b>.</li>
</ul>
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
Copyright &copy; 1998-2005, Modelica Association and DLR
</p>
<p>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>

</HTML>",   revisions="<html>
<ul>
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
      Diagram(
        Rectangle(extent=[169, 86; 349, 236], style(fillColor=30, fillPattern=1)),
        Polygon(points=[169, 236; 189, 256; 369, 256; 349, 236; 169, 236], style(
              fillColor=30, fillPattern=1)),
        Polygon(points=[369, 256; 369, 106; 349, 86; 349, 236; 369, 256], style(
              fillColor=30, fillPattern=1)),
        Text(
          extent=[179, 226; 339, 196],
          string="Library",
          style(
            color=9,
            fillColor=0,
            fillPattern=1)),
        Text(
          extent=[206, 173; 314, 119],
          string="[kg.m2]",
          style(color=0)),
        Text(
          extent=[163, 320; 406, 264],
          string="Modelica.SIunits",
          style(color=1))));
  end SIunits;
end Modelica;

model Gear
  Modelica.Mechanics.Rotational.Fixed fixed1 annotation(Placement(visible=true,transformation(x=68.5231,y=-10.1052,scale=0.1)));
  Modelica.Mechanics.Rotational.SpringDamper springDamper1(c=10,d=1)    annotation(Placement(visible=true,transformation(x=43.3746,y=-10.1052,scale=0.1)));
  Modelica.Mechanics.Rotational.Inertia inertia1    annotation(Placement(visible=true,transformation(x=15.3445,y=-10.1052,scale=0.1)));
  Modelica.Mechanics.Rotational.SpringDamper springDamper2(c=1000,d=10)    annotation(Placement(visible=true,transformation(x=-38.3581,y=-10.1052,scale=0.1)));
  Modelica.Mechanics.Rotational.Inertia inertia2    annotation(Placement(visible=true,transformation(x=-65.3404,y=-10.1052,scale=0.1)));
  Modelica.Mechanics.Rotational.Torque torque1    annotation(Placement(visible=true,transformation(x=-36.2624,y=38.0961,scale=0.1)));
  Modelica.Blocks.Sources.Sine sine1    annotation(Placement(visible=true,transformation(x=-75.295,y=38.0962,scale=0.1)));
  Modelica.Mechanics.Rotational.Gear gear1(ratio=2)    annotation(Placement(visible=true,transformation(x=-12.1617,y=-10.1052,scale=0.1)));

equation
  connect(springDamper2.flange_b,gear1.flange_a) annotation(Line(visible=true,points={{-28.29,-9.95},{-22.27,-9.95}}));
  connect(gear1.flange_b,inertia1.flange_a) annotation(Line(visible=true,points={{-2.1,-9.95},{5.24,-9.95}}));
  connect(torque1.flange_b,inertia2.flange_a) annotation(Line(visible=true,points={{-26.2,38.25},{-75.45,-9.95}}));
  connect(sine1.y,torque1.tau) annotation(Line(visible=true,points={{-64.55,38.36},{-48.57,38.36}}));
  connect(inertia2.flange_b,springDamper2.flange_a) annotation(Line(visible=true,points={{-55.39,-9.84},{-48.57,-9.84}}));
  connect(inertia1.flange_b,springDamper1.flange_a) annotation(Line(visible=true,points={{25.3,-9.84},{33.16,-9.84}}));
  connect(springDamper1.flange_b,fixed1.flange_b) annotation(Line(visible=true,points={{53.59,-10.37},{69.05,-10.37}}));
end Gear;
// function Modelica.Math.sin
// input Real u(quantity = "Angle", unit = "rad", displayUnit = "deg");
// output Real y;
//
// external "C";
// end Modelica.Math.sin;
//
// function Modelica.Math.tempInterpol1
// input Real u "input value (first column of table)";
// input Real[:, :] table "table to be interpolated";
// input Integer icol "column of table to be interpolated";
// output Real y "interpolated input value (icol column of table)";
// protected Integer i;
// protected Integer n "number of rows of table";
// protected Real u1;
// protected Real u2;
// protected Real y1;
// protected Real y2;
// algorithm
//   n := size(table,1);
//   if n <= 1 then
//     y := table[1, icol];
//   else
//     if u <= table[1,1] then
//       i := 1;
//     else
//       i := 2;
//       while i < n AND u >= table[i, 1] loop
//         i := 1 + i;
//       end while;
//       i := i - 1;
//     end if;
//     u1 := table[i, 1];
//     u2 := table[1 + i, 1];
//     y1 := table[i, icol];
//     y2 := table[1 + i, icol];
//     assert( u2 > u1, "Table index must be increasing");
//     y := y1 + (y2 - y1) * (u - u1) / (u2 - u1);
//   end if;
// end Modelica.Math.tempInterpol1;
//
// class Gear
// parameter Real fixed1.phi0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Fixed offset angle of housing";
// Real fixed1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real fixed1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real springDamper1.phi_rel(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
// Real springDamper1.tau(quantity = "Torque", unit = "N.m") "Torque between flanges (= flange_b.tau)";
// Real springDamper1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real springDamper1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real springDamper1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real springDamper1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// parameter Real springDamper1.c(unit = "N.m/rad", min = 0.0) = 10.0 "Spring constant";
// parameter Real springDamper1.phi_rel0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Unstretched spring angle";
// parameter Real springDamper1.d(unit = "N.m.s/rad", min = 0.0) = 1.0 "Damping constant";
// Real springDamper1.w_rel(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between flange_b and flange_a";
// Real inertia1.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of component (= flange_a.phi = flange_b.phi)";
// Real inertia1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real inertia1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real inertia1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real inertia1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// parameter Real inertia1.J(quantity = "MomentOfInertia", unit = "kg.m2") = 1.0 "Moment of inertia";
// Real inertia1.w(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of component";
// Real inertia1.a(quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of component";
// Real springDamper2.phi_rel(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
// Real springDamper2.tau(quantity = "Torque", unit = "N.m") "Torque between flanges (= flange_b.tau)";
// Real springDamper2.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real springDamper2.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real springDamper2.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real springDamper2.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// parameter Real springDamper2.c(unit = "N.m/rad", min = 0.0) = 1000.0 "Spring constant";
// parameter Real springDamper2.phi_rel0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Unstretched spring angle";
// parameter Real springDamper2.d(unit = "N.m.s/rad", min = 0.0) = 10.0 "Damping constant";
// Real springDamper2.w_rel(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between flange_b and flange_a";
// Real inertia2.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of component (= flange_a.phi = flange_b.phi)";
// Real inertia2.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real inertia2.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real inertia2.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real inertia2.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// parameter Real inertia2.J(quantity = "MomentOfInertia", unit = "kg.m2") = 1.0 "Moment of inertia";
// Real inertia2.w(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of component";
// Real inertia2.a(quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of component";
// input Real torque1.tau(quantity = "Torque", unit = "N.m") "Torque driving the flange (a positive value accelerates the flange)";
// Real torque1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real torque1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real torque1.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real torque1.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// output Real sine1.y "Connector of Real output signal";
// parameter Real sine1.amplitude = 1.0 "Amplitude of sine wave";
// parameter Real sine1.freqHz(quantity = "Frequency", unit = "Hz") = 1.0 "Frequency of sine wave";
// parameter Real sine1.phase(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Phase of sine wave";
// parameter Real sine1.offset = 0.0 "Offset of output signal";
// parameter Real sine1.startTime(quantity = "Time", unit = "s") = 0.0 "Output = offset for time < startTime";
// protected constant Real sine1.pi = 3.14159265358979;
// Real gear1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.tau_support(quantity = "Torque", unit = "N.m");
// Real gear1.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.adapter.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.adapter.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.adapter.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.adapter.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// parameter Boolean gear1.adapter.bearingConnected = false;
// parameter Real gear1.ratio = 2.0 "transmission ratio (flange_a.phi/flange_b.phi)";
// parameter Real gear1.eta(min = 1e-60, max = 1.0) = 1.0 "Gear efficiency";
// parameter Real gear1.friction_pos[1,1] = 0.0 "[w,tau] positive sliding friction characteristic (w>=0)";
// parameter Real gear1.friction_pos[1,2] = 1.0 "[w,tau] positive sliding friction characteristic (w>=0)";
// parameter Real gear1.peak(min = 1.0) = 1.0 "peak*friction_pos[1,2] = maximum friction torque at zero velocity";
// parameter Real gear1.c(unit = "N.m/rad", min = 1e-60) = 100000.0 "Gear elasticity (spring constant)";
// parameter Real gear1.d(unit = "N.m.s/rad", min = 0.0) = 0.0 "(relative) gear damping";
// parameter Real gear1.b(quantity = "Angle", unit = "rad", displayUnit = "deg", min = 0.0) = 0.0 "Total backlash";
// Real gear1.gearRatio.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.gearRatio.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.gearRatio.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.gearRatio.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.gearRatio.tau_support(quantity = "Torque", unit = "N.m");
// Real gear1.gearRatio.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.gearRatio.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.gearRatio.phi_a(quantity = "Angle", unit = "rad", displayUnit = "deg");
// Real gear1.gearRatio.phi_b(quantity = "Angle", unit = "rad", displayUnit = "deg");
// parameter Real gear1.gearRatio.ratio = gear1.ratio "Transmission ratio (flange_a.phi/flange_b.phi)";
// Real gear1.gearEfficiency.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.gearEfficiency.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.gearEfficiency.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.gearEfficiency.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.gearEfficiency.tau_support(quantity = "Torque", unit = "N.m");
// Real gear1.gearEfficiency.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.gearEfficiency.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.gearEfficiency.phi_a(quantity = "Angle", unit = "rad", displayUnit = "deg");
// Real gear1.gearEfficiency.phi_b(quantity = "Angle", unit = "rad", displayUnit = "deg");
// parameter Real gear1.gearEfficiency.eta(min = 1e-60, max = 1.0) = gear1.eta "Efficiency";
// Real gear1.gearEfficiency.phi(quantity = "Angle", unit = "rad", displayUnit = "deg");
// Real gear1.gearEfficiency.power_a(quantity = "Power", unit = "W") "Energy flowing into flange_a (= power)";
// Boolean gear1.gearEfficiency.driving_a "True, if energy is flowing INTO and not out of flange flange_a";
// Real gear1.elastoBacklash.phi_rel(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
// Real gear1.elastoBacklash.tau(quantity = "Torque", unit = "N.m") "Torque between flanges (= flange_b.tau)";
// Real gear1.elastoBacklash.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.elastoBacklash.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.elastoBacklash.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.elastoBacklash.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// parameter Real gear1.elastoBacklash.b(quantity = "Angle", unit = "rad", displayUnit = "deg", min = 0.0) = gear1.b "Total backlash";
// parameter Real gear1.elastoBacklash.c(unit = "N.m/rad", min = 1e-60) = gear1.c "Spring constant (c > 0 required)";
// parameter Real gear1.elastoBacklash.phi_rel0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Unstretched spring angle";
// parameter Real gear1.elastoBacklash.d(unit = "N.m.s/rad", min = 0.0) = gear1.d "Damping constant";
// Real gear1.elastoBacklash.w_rel(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between flange_b and flange_a";
// protected Real gear1.elastoBacklash.b2(quantity = "Angle", unit = "rad", displayUnit = "deg") = gear1.elastoBacklash.b / 2.0;
// protected constant Real gear1.elastoBacklash.b_min(quantity = "Angle", unit = "rad", displayUnit = "deg") = 1e-10 "minimum backlash";
// Real gear1.bearingFriction.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.bearingFriction.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.bearingFriction.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.bearingFriction.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.bearingFriction.tau_support(quantity = "Torque", unit = "N.m");
// Real gear1.bearingFriction.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
// Real gear1.bearingFriction.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
// Real gear1.bearingFriction.phi_a(quantity = "Angle", unit = "rad", displayUnit = "deg");
// Real gear1.bearingFriction.phi_b(quantity = "Angle", unit = "rad", displayUnit = "deg");
// parameter Real gear1.bearingFriction.w_small(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") = 10000000000.0 "Relative angular velocity near to zero if jumps due to a reinit(..) of the velocity can occur (set to low value only if such impulses can occur)";
// Real gear1.bearingFriction.w_relfric(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between frictional surfaces";
// Real gear1.bearingFriction.a_relfric(quantity = "AngularAcceleration", unit = "rad/s2") "Relative angular acceleration between frictional surfaces";
// Real gear1.bearingFriction.tau(quantity = "Torque", unit = "N.m") "Friction torque (positive, if directed in opposite direction of w_rel)";
// Real gear1.bearingFriction.tau0(quantity = "Torque", unit = "N.m") "Friction torque for w=0 and forward sliding";
// Real gear1.bearingFriction.tau0_max(quantity = "Torque", unit = "N.m") "Maximum friction torque for w=0 and locked";
// Boolean gear1.bearingFriction.free "true, if frictional element is not active";
// Real gear1.bearingFriction.sa "Path parameter of friction characteristic tau = f(a_relfric)";
// Boolean gear1.bearingFriction.startForward(start = false, fixed = true) "true, if w_rel=0 and start of forward sliding or w_rel > w_small";
// Boolean gear1.bearingFriction.startBackward(start = false, fixed = true) "true, if w_rel=0 and start of backward sliding or w_rel < -w_small";
// Boolean gear1.bearingFriction.locked "true, if w_rel=0 and not sliding";
// constant Integer gear1.bearingFriction.Unknown = 3 "Value of mode is not known";
// constant Integer gear1.bearingFriction.Free = 2 "Element is not active";
// constant Integer gear1.bearingFriction.Forward = 1 "w_rel > 0 (forward sliding)";
// constant Integer gear1.bearingFriction.Stuck = 0 "w_rel = 0 (forward sliding, locked or backward sliding)";
// constant Integer gear1.bearingFriction.Backward = -1 "w_rel < 0 (backward sliding)";
// Integer gear1.bearingFriction.mode(min = -1, max = 3, start = 3, fixed = true);
// parameter Real gear1.bearingFriction.tau_pos[1,1] = gear1.friction_pos[1,1] "[w,tau] Positive sliding friction characteristic (w>=0)";
// parameter Real gear1.bearingFriction.tau_pos[1,2] = gear1.friction_pos[1,2] "[w,tau] Positive sliding friction characteristic (w>=0)";
// parameter Real gear1.bearingFriction.peak(min = 1.0) = gear1.peak "peak*tau_pos[1,2] = Maximum friction torque for w==0";
// Real gear1.bearingFriction.phi(quantity = "Angle", unit = "rad", displayUnit = "deg");
// Real gear1.bearingFriction.w(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of flange_a and flange_b";
// Real gear1.bearingFriction.a(quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of flange_a and flange_b";
// equation
//   fixed1.flange_b.phi = fixed1.phi0;
//   springDamper1.w_rel = der(springDamper1.phi_rel);
//   springDamper1.tau = springDamper1.c * (springDamper1.phi_rel - springDamper1.phi_rel0) + springDamper1.d * springDamper1.w_rel;
//   springDamper1.phi_rel = springDamper1.flange_b.phi - springDamper1.flange_a.phi;
//   springDamper1.flange_b.tau = springDamper1.tau;
//   springDamper1.flange_a.tau = -springDamper1.tau;
//   inertia1.w = der(inertia1.phi);
//   inertia1.a = der(inertia1.w);
//   inertia1.J * inertia1.a = inertia1.flange_a.tau + inertia1.flange_b.tau;
//   inertia1.flange_a.phi = inertia1.phi;
//   inertia1.flange_b.phi = inertia1.phi;
//   springDamper2.w_rel = der(springDamper2.phi_rel);
//   springDamper2.tau = springDamper2.c * (springDamper2.phi_rel - springDamper2.phi_rel0) + springDamper2.d * springDamper2.w_rel;
//   springDamper2.phi_rel = springDamper2.flange_b.phi - springDamper2.flange_a.phi;
//   springDamper2.flange_b.tau = springDamper2.tau;
//   springDamper2.flange_a.tau = -springDamper2.tau;
//   inertia2.w = der(inertia2.phi);
//   inertia2.a = der(inertia2.w);
//   inertia2.J * inertia2.a = inertia2.flange_a.tau + inertia2.flange_b.tau;
//   inertia2.flange_a.phi = inertia2.phi;
//   inertia2.flange_b.phi = inertia2.phi;
//   torque1.flange_b.tau = -torque1.tau;
//   torque1.bearing.phi = 0.0;
//   sine1.y = sine1.offset + (if time < sine1.startTime then 0.0 else sine1.amplitude * Modelica.Math.sin(6.28318530717959 * (sine1.freqHz * (time - sine1.startTime)) + sine1.phase));
//   gear1.adapter.flange_a.phi = gear1.adapter.flange_b.phi;
//   0.0 = gear1.adapter.flange_a.phi;
//   gear1.gearRatio.phi_a = gear1.gearRatio.ratio * gear1.gearRatio.phi_b;
//   0.0 = gear1.gearRatio.ratio * gear1.gearRatio.flange_a.tau + gear1.gearRatio.flange_b.tau;
//   gear1.gearRatio.bearing.tau = gear1.gearRatio.tau_support;
//   0.0 = gear1.gearRatio.flange_a.tau + (gear1.gearRatio.flange_b.tau + gear1.gearRatio.tau_support);
//   gear1.gearRatio.phi_a = gear1.gearRatio.flange_a.phi - gear1.gearRatio.bearing.phi;
//   gear1.gearRatio.phi_b = gear1.gearRatio.flange_b.phi - gear1.gearRatio.bearing.phi;
//   gear1.gearEfficiency.phi = gear1.gearEfficiency.phi_a;
//   gear1.gearEfficiency.phi = gear1.gearEfficiency.phi_b;
//   gear1.gearEfficiency.power_a = gear1.gearEfficiency.flange_a.tau * der(gear1.gearEfficiency.phi);
//   gear1.gearEfficiency.driving_a = gear1.gearEfficiency.power_a >= 0.0;
//   gear1.gearEfficiency.flange_b.tau = -(if gear1.gearEfficiency.driving_a then gear1.gearEfficiency.eta * gear1.gearEfficiency.flange_a.tau else gear1.gearEfficiency.flange_a.tau / gear1.gearEfficiency.eta);
//   gear1.gearEfficiency.bearing.tau = gear1.gearEfficiency.tau_support;
//   0.0 = gear1.gearEfficiency.flange_a.tau + (gear1.gearEfficiency.flange_b.tau + gear1.gearEfficiency.tau_support);
//   gear1.gearEfficiency.phi_a = gear1.gearEfficiency.flange_a.phi - gear1.gearEfficiency.bearing.phi;
//   gear1.gearEfficiency.phi_b = gear1.gearEfficiency.flange_b.phi - gear1.gearEfficiency.bearing.phi;
//   gear1.elastoBacklash.w_rel = der(gear1.elastoBacklash.phi_rel);
//   gear1.elastoBacklash.tau = if gear1.elastoBacklash.b2 > 1e-10 then if gear1.elastoBacklash.phi_rel > gear1.elastoBacklash.b2 then gear1.elastoBacklash.c * (gear1.elastoBacklash.phi_rel - gear1.elastoBacklash.phi_rel0 - gear1.elastoBacklash.b2) + gear1.elastoBacklash.d * gear1.elastoBacklash.w_rel else if gear1.elastoBacklash.phi_rel < -gear1.elastoBacklash.b2 then gear1.elastoBacklash.c * (gear1.elastoBacklash.phi_rel + (gear1.elastoBacklash.b2 + (-gear1.elastoBacklash.phi_rel0))) + gear1.elastoBacklash.d * gear1.elastoBacklash.w_rel else 0.0 else gear1.elastoBacklash.c * (gear1.elastoBacklash.phi_rel - gear1.elastoBacklash.phi_rel0) + gear1.elastoBacklash.d * gear1.elastoBacklash.w_rel;
//   gear1.elastoBacklash.phi_rel = gear1.elastoBacklash.flange_b.phi - gear1.elastoBacklash.flange_a.phi;
//   gear1.elastoBacklash.flange_b.tau = gear1.elastoBacklash.tau;
//   gear1.elastoBacklash.flange_a.tau = -gear1.elastoBacklash.tau;
//   gear1.bearingFriction.tau0 = Modelica.Math.tempInterpol1(0.0,{{gear1.bearingFriction.tau_pos[1,1],gear1.bearingFriction.tau_pos[1,2]}},2);
//   gear1.bearingFriction.tau0_max = gear1.bearingFriction.peak * gear1.bearingFriction.tau0;
//   gear1.bearingFriction.free = false;
//   gear1.bearingFriction.phi = gear1.bearingFriction.phi_a;
//   gear1.bearingFriction.phi = gear1.bearingFriction.phi_b;
//   gear1.bearingFriction.w = der(gear1.bearingFriction.phi);
//   gear1.bearingFriction.a = der(gear1.bearingFriction.w);
//   gear1.bearingFriction.w_relfric = gear1.bearingFriction.w;
//   gear1.bearingFriction.a_relfric = gear1.bearingFriction.a;
//   0.0 = gear1.bearingFriction.flange_a.tau + gear1.bearingFriction.flange_b.tau - gear1.bearingFriction.tau;
//   gear1.bearingFriction.tau = if gear1.bearingFriction.locked then gear1.bearingFriction.sa else if gear1.bearingFriction.startForward then Modelica.Math.tempInterpol1(gear1.bearingFriction.w,{{gear1.bearingFriction.tau_pos[1,1],gear1.bearingFriction.tau_pos[1,2]}},2) else if gear1.bearingFriction.startBackward then -Modelica.Math.tempInterpol1(-gear1.bearingFriction.w,{{gear1.bearingFriction.tau_pos[1,1],gear1.bearingFriction.tau_pos[1,2]}},2) else if pre(gear1.bearingFriction.mode) == 1 then Modelica.Math.tempInterpol1(gear1.bearingFriction.w,{{gear1.bearingFriction.tau_pos[1,1],gear1.bearingFriction.tau_pos[1,2]}},2) else -Modelica.Math.tempInterpol1(-gear1.bearingFriction.w,{{gear1.bearingFriction.tau_pos[1,1],gear1.bearingFriction.tau_pos[1,2]}},2);
//   gear1.bearingFriction.phi_b = gear1.bearingFriction.flange_b.phi - gear1.bearingFriction.bearing.phi;
//   gear1.bearingFriction.phi_a = gear1.bearingFriction.flange_a.phi - gear1.bearingFriction.bearing.phi;
//   0.0 = gear1.bearingFriction.flange_a.tau + (gear1.bearingFriction.flange_b.tau + gear1.bearingFriction.tau_support);
//   gear1.bearingFriction.bearing.tau = gear1.bearingFriction.tau_support;
//   gear1.bearingFriction.startForward = pre(gear1.bearingFriction.mode) == 0 AND (gear1.bearingFriction.sa > gear1.bearingFriction.tau0_max OR pre(gear1.bearingFriction.startForward) AND gear1.bearingFriction.sa > gear1.bearingFriction.tau0) OR pre(gear1.bearingFriction.mode) == -1 AND gear1.bearingFriction.w_relfric > gear1.bearingFriction.w_small OR initial() AND gear1.bearingFriction.w_relfric > 0.0;
//   gear1.bearingFriction.startBackward = pre(gear1.bearingFriction.mode) == 0 AND (gear1.bearingFriction.sa < -gear1.bearingFriction.tau0_max OR pre(gear1.bearingFriction.startBackward) AND gear1.bearingFriction.sa < -gear1.bearingFriction.tau0) OR pre(gear1.bearingFriction.mode) == 1 AND gear1.bearingFriction.w_relfric < -gear1.bearingFriction.w_small OR initial() AND gear1.bearingFriction.w_relfric < 0.0;
//   gear1.bearingFriction.locked =  NOT gear1.bearingFriction.free AND  NOT (pre(gear1.bearingFriction.mode) == 1 OR gear1.bearingFriction.startForward OR pre(gear1.bearingFriction.mode) == -1 OR gear1.bearingFriction.startBackward);
//   gear1.bearingFriction.a_relfric = if gear1.bearingFriction.locked then 0.0 else if gear1.bearingFriction.free then gear1.bearingFriction.sa else if gear1.bearingFriction.startForward then gear1.bearingFriction.sa - gear1.bearingFriction.tau0 else if gear1.bearingFriction.startBackward then gear1.bearingFriction.sa + gear1.bearingFriction.tau0 else if pre(gear1.bearingFriction.mode) == 1 then gear1.bearingFriction.sa - gear1.bearingFriction.tau0 else gear1.bearingFriction.sa + gear1.bearingFriction.tau0;
//   gear1.bearingFriction.mode = if gear1.bearingFriction.free then 2 else if (pre(gear1.bearingFriction.mode) == 1 OR pre(gear1.bearingFriction.mode) == 2 OR gear1.bearingFriction.startForward) AND gear1.bearingFriction.w_relfric > 0.0 then 1 else if (pre(gear1.bearingFriction.mode) == -1 OR pre(gear1.bearingFriction.mode) == 2 OR gear1.bearingFriction.startBackward) AND gear1.bearingFriction.w_relfric < 0.0 then -1 else 0;
//   gear1.tau_support = -gear1.adapter.flange_b.tau;
//   gear1.adapter.flange_a.tau + (-gear1.bearing.tau) = 0.0;
// gear1.adapter.flange_a.phi = gear1.bearing.phi;
//   gear1.bearingFriction.bearing.tau + (gear1.gearEfficiency.bearing.tau + (gear1.gearRatio.bearing.tau + gear1.adapter.flange_b.tau)) = 0.0;
// gear1.bearingFriction.bearing.phi = gear1.gearEfficiency.bearing.phi;
// gear1.gearEfficiency.bearing.phi = gear1.gearRatio.bearing.phi;
// gear1.gearRatio.bearing.phi = gear1.adapter.flange_b.phi;
//   gear1.elastoBacklash.flange_b.tau + (-gear1.flange_b.tau) = 0.0;
// gear1.elastoBacklash.flange_b.phi = gear1.flange_b.phi;
//   gear1.bearingFriction.flange_b.tau + gear1.elastoBacklash.flange_a.tau = 0.0;
// gear1.bearingFriction.flange_b.phi = gear1.elastoBacklash.flange_a.phi;
//   gear1.gearEfficiency.flange_b.tau + gear1.bearingFriction.flange_a.tau = 0.0;
// gear1.gearEfficiency.flange_b.phi = gear1.bearingFriction.flange_a.phi;
//   gear1.gearRatio.flange_b.tau + gear1.gearEfficiency.flange_a.tau = 0.0;
// gear1.gearRatio.flange_b.phi = gear1.gearEfficiency.flange_a.phi;
//   (-gear1.flange_a.tau) + gear1.gearRatio.flange_a.tau = 0.0;
// gear1.flange_a.phi = gear1.gearRatio.flange_a.phi;
//   springDamper1.flange_b.tau + fixed1.flange_b.tau = 0.0;
// springDamper1.flange_b.phi = fixed1.flange_b.phi;
//   inertia1.flange_b.tau + springDamper1.flange_a.tau = 0.0;
// inertia1.flange_b.phi = springDamper1.flange_a.phi;
//   inertia2.flange_b.tau + springDamper2.flange_a.tau = 0.0;
// inertia2.flange_b.phi = springDamper2.flange_a.phi;
// sine1.y = torque1.tau;
//   torque1.flange_b.tau + inertia2.flange_a.tau = 0.0;
// torque1.flange_b.phi = inertia2.flange_a.phi;
//   gear1.flange_b.tau + inertia1.flange_a.tau = 0.0;
// gear1.flange_b.phi = inertia1.flange_a.phi;
//   springDamper2.flange_b.tau + gear1.flange_a.tau = 0.0;
// springDamper2.flange_b.phi = gear1.flange_a.phi;
//   gear1.bearing.tau = 0.0;
//   torque1.bearing.tau = 0.0;
// end Gear;
// Result:
// function Modelica.Math.asin "inverse sine (-1 <= u <= 1)"
//   input Real u;
//   output Real y(quantity = "Angle", unit = "rad", displayUnit = "deg");
//
//   external "C" y = asin(u);
// end Modelica.Math.asin;
//
// function Modelica.Math.sin "sine"
//   input Real u(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   output Real y;
//
//   external "C" y = sin(u);
// end Modelica.Math.sin;
//
// function Modelica.Math.tempInterpol1 "temporary routine for linear interpolation (will be removed)"
//   input Real u "input value (first column of table)";
//   input Real[:, :] table "table to be interpolated";
//   input Integer icol "column of table to be interpolated";
//   output Real y "interpolated input value (icol column of table)";
//   protected Integer i;
//   protected Integer n "number of rows of table";
//   protected Real u1;
//   protected Real u2;
//   protected Real y1;
//   protected Real y2;
// algorithm
//   n := size(table, 1);
//   if n <= 1 then
//     y := table[1,icol];
//   else
//     if u <= table[1,1] then
//       i := 1;
//     else
//       i := 2;
//       while i < n and u >= table[i,1] loop
//         i := 1 + i;
//       end while;
//       i := -1 + i;
//     end if;
//     u1 := table[i,1];
//     u2 := table[1 + i,1];
//     y1 := table[i,icol];
//     y2 := table[1 + i,icol];
//     assert(u2 > u1, "Table index must be increasing");
//     y := y1 + (y2 - y1) * (u - u1) / (u2 - u1);
//   end if;
// end Modelica.Math.tempInterpol1;
//
// class Gear
//   parameter Real fixed1.phi0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Fixed offset angle of housing";
//   Real fixed1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real fixed1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real springDamper1.phi_rel(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
//   Real springDamper1.tau(quantity = "Torque", unit = "N.m") "Torque between flanges (= flange_b.tau)";
//   Real springDamper1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real springDamper1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real springDamper1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real springDamper1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real springDamper1.c(unit = "N.m/rad", min = 0.0) = 10.0 "Spring constant";
//   parameter Real springDamper1.phi_rel0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Unstretched spring angle";
//   parameter Real springDamper1.d(unit = "N.m.s/rad", min = 0.0) = 1.0 "Damping constant";
//   Real springDamper1.w_rel(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between flange_b and flange_a";
//   Real inertia1.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of component (= flange_a.phi = flange_b.phi)";
//   Real inertia1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real inertia1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real inertia1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real inertia1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real inertia1.J(quantity = "MomentOfInertia", unit = "kg.m2") = 1.0 "Moment of inertia";
//   Real inertia1.w(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of component";
//   Real inertia1.a(quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of component";
//   Real springDamper2.phi_rel(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
//   Real springDamper2.tau(quantity = "Torque", unit = "N.m") "Torque between flanges (= flange_b.tau)";
//   Real springDamper2.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real springDamper2.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real springDamper2.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real springDamper2.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real springDamper2.c(unit = "N.m/rad", min = 0.0) = 1000.0 "Spring constant";
//   parameter Real springDamper2.phi_rel0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Unstretched spring angle";
//   parameter Real springDamper2.d(unit = "N.m.s/rad", min = 0.0) = 10.0 "Damping constant";
//   Real springDamper2.w_rel(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between flange_b and flange_a";
//   Real inertia2.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of component (= flange_a.phi = flange_b.phi)";
//   Real inertia2.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real inertia2.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real inertia2.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real inertia2.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real inertia2.J(quantity = "MomentOfInertia", unit = "kg.m2") = 1.0 "Moment of inertia";
//   Real inertia2.w(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of component";
//   Real inertia2.a(quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of component";
//   Real torque1.tau(quantity = "Torque", unit = "N.m") "Torque driving the flange (a positive value accelerates the flange)";
//   Real torque1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real torque1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real torque1.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real torque1.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real sine1.y "Connector of Real output signal";
//   parameter Real sine1.amplitude = 1.0 "Amplitude of sine wave";
//   parameter Real sine1.freqHz(quantity = "Frequency", unit = "Hz") = 1.0 "Frequency of sine wave";
//   parameter Real sine1.phase(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Phase of sine wave";
//   parameter Real sine1.offset = 0.0 "Offset of output signal";
//   parameter Real sine1.startTime(quantity = "Time", unit = "s") = 0.0 "Output = offset for time < startTime";
//   protected constant Real sine1.pi = 3.141592653589793;
//   Real gear1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.tau_support(quantity = "Torque", unit = "N.m");
//   Real gear1.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.adapter.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.adapter.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.adapter.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.adapter.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Boolean gear1.adapter.bearingConnected = false;
//   parameter Real gear1.ratio = 2.0 "transmission ratio (flange_a.phi/flange_b.phi)";
//   parameter Real gear1.eta(min = 1e-60, max = 1.0) = 1.0 "Gear efficiency";
//   parameter Real gear1.friction_pos[1,1] = 0.0 "[w,tau] positive sliding friction characteristic (w>=0)";
//   parameter Real gear1.friction_pos[1,2] = 1.0 "[w,tau] positive sliding friction characteristic (w>=0)";
//   parameter Real gear1.peak(min = 1.0) = 1.0 "peak*friction_pos[1,2] = maximum friction torque at zero velocity";
//   parameter Real gear1.c(unit = "N.m/rad", min = 1e-60) = 100000.0 "Gear elasticity (spring constant)";
//   parameter Real gear1.d(unit = "N.m.s/rad", min = 0.0) = 0.0 "(relative) gear damping";
//   parameter Real gear1.b(quantity = "Angle", unit = "rad", displayUnit = "deg", min = 0.0) = 0.0 "Total backlash";
//   Real gear1.gearRatio.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.gearRatio.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.gearRatio.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.gearRatio.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.gearRatio.tau_support(quantity = "Torque", unit = "N.m");
//   Real gear1.gearRatio.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.gearRatio.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.gearRatio.phi_a(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   Real gear1.gearRatio.phi_b(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   parameter Real gear1.gearRatio.ratio = gear1.ratio "Transmission ratio (flange_a.phi/flange_b.phi)";
//   Real gear1.gearEfficiency.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.gearEfficiency.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.gearEfficiency.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.gearEfficiency.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.gearEfficiency.tau_support(quantity = "Torque", unit = "N.m");
//   Real gear1.gearEfficiency.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.gearEfficiency.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.gearEfficiency.phi_a(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   Real gear1.gearEfficiency.phi_b(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   parameter Real gear1.gearEfficiency.eta(min = 1e-60, max = 1.0) = gear1.eta "Efficiency";
//   Real gear1.gearEfficiency.phi(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   Real gear1.gearEfficiency.power_a(quantity = "Power", unit = "W") "Energy flowing into flange_a (= power)";
//   Boolean gear1.gearEfficiency.driving_a "True, if energy is flowing INTO and not out of flange flange_a";
//   Real gear1.elastoBacklash.phi_rel(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
//   Real gear1.elastoBacklash.tau(quantity = "Torque", unit = "N.m") "Torque between flanges (= flange_b.tau)";
//   Real gear1.elastoBacklash.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.elastoBacklash.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.elastoBacklash.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.elastoBacklash.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real gear1.elastoBacklash.b(quantity = "Angle", unit = "rad", displayUnit = "deg", min = 0.0) = gear1.b "Total backlash";
//   parameter Real gear1.elastoBacklash.c(unit = "N.m/rad", min = 1e-60) = gear1.c "Spring constant (c > 0 required)";
//   parameter Real gear1.elastoBacklash.phi_rel0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Unstretched spring angle";
//   parameter Real gear1.elastoBacklash.d(unit = "N.m.s/rad", min = 0.0) = gear1.d "Damping constant";
//   Real gear1.elastoBacklash.w_rel(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between flange_b and flange_a";
//   protected Real gear1.elastoBacklash.b2(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.5 * gear1.elastoBacklash.b;
//   protected constant Real gear1.elastoBacklash.b_min(quantity = "Angle", unit = "rad", displayUnit = "deg") = 1e-10 "minimum backlash";
//   Real gear1.bearingFriction.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.bearingFriction.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.bearingFriction.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.bearingFriction.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.bearingFriction.tau_support(quantity = "Torque", unit = "N.m");
//   Real gear1.bearingFriction.bearing.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real gear1.bearingFriction.bearing.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real gear1.bearingFriction.phi_a(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   Real gear1.bearingFriction.phi_b(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   parameter Real gear1.bearingFriction.w_small(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") = 10000000000.0 "Relative angular velocity near to zero if jumps due to a reinit(..) of the velocity can occur (set to low value only if such impulses can occur)";
//   Real gear1.bearingFriction.w_relfric(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between frictional surfaces";
//   Real gear1.bearingFriction.a_relfric(quantity = "AngularAcceleration", unit = "rad/s2") "Relative angular acceleration between frictional surfaces";
//   Real gear1.bearingFriction.tau(quantity = "Torque", unit = "N.m") "Friction torque (positive, if directed in opposite direction of w_rel)";
//   Real gear1.bearingFriction.tau0(quantity = "Torque", unit = "N.m") "Friction torque for w=0 and forward sliding";
//   Real gear1.bearingFriction.tau0_max(quantity = "Torque", unit = "N.m") "Maximum friction torque for w=0 and locked";
//   Boolean gear1.bearingFriction.free "true, if frictional element is not active";
//   Real gear1.bearingFriction.sa "Path parameter of friction characteristic tau = f(a_relfric)";
//   Boolean gear1.bearingFriction.startForward(start = false, fixed = true) "true, if w_rel=0 and start of forward sliding or w_rel > w_small";
//   Boolean gear1.bearingFriction.startBackward(start = false, fixed = true) "true, if w_rel=0 and start of backward sliding or w_rel < -w_small";
//   Boolean gear1.bearingFriction.locked "true, if w_rel=0 and not sliding";
//   constant Integer gear1.bearingFriction.Unknown = 3 "Value of mode is not known";
//   constant Integer gear1.bearingFriction.Free = 2 "Element is not active";
//   constant Integer gear1.bearingFriction.Forward = 1 "w_rel > 0 (forward sliding)";
//   constant Integer gear1.bearingFriction.Stuck = 0 "w_rel = 0 (forward sliding, locked or backward sliding)";
//   constant Integer gear1.bearingFriction.Backward = -1 "w_rel < 0 (backward sliding)";
//   Integer gear1.bearingFriction.mode(min = -1, max = 3, start = 3, fixed = true);
//   parameter Real gear1.bearingFriction.tau_pos[1,1] = gear1.friction_pos[1,1] "[w,tau] Positive sliding friction characteristic (w>=0)";
//   parameter Real gear1.bearingFriction.tau_pos[1,2] = gear1.friction_pos[1,2] "[w,tau] Positive sliding friction characteristic (w>=0)";
//   parameter Real gear1.bearingFriction.peak(min = 1.0) = gear1.peak "peak*tau_pos[1,2] = Maximum friction torque for w==0";
//   Real gear1.bearingFriction.phi(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   Real gear1.bearingFriction.w(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of flange_a and flange_b";
//   Real gear1.bearingFriction.a(quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of flange_a and flange_b";
// equation
//   fixed1.flange_b.phi = fixed1.phi0;
//   springDamper1.w_rel = der(springDamper1.phi_rel);
//   springDamper1.tau = springDamper1.c * (springDamper1.phi_rel - springDamper1.phi_rel0) + springDamper1.d * springDamper1.w_rel;
//   springDamper1.phi_rel = springDamper1.flange_b.phi - springDamper1.flange_a.phi;
//   springDamper1.flange_b.tau = springDamper1.tau;
//   springDamper1.flange_a.tau = -springDamper1.tau;
//   inertia1.w = der(inertia1.phi);
//   inertia1.a = der(inertia1.w);
//   inertia1.J * inertia1.a = inertia1.flange_a.tau + inertia1.flange_b.tau;
//   inertia1.flange_a.phi = inertia1.phi;
//   inertia1.flange_b.phi = inertia1.phi;
//   springDamper2.w_rel = der(springDamper2.phi_rel);
//   springDamper2.tau = springDamper2.c * (springDamper2.phi_rel - springDamper2.phi_rel0) + springDamper2.d * springDamper2.w_rel;
//   springDamper2.phi_rel = springDamper2.flange_b.phi - springDamper2.flange_a.phi;
//   springDamper2.flange_b.tau = springDamper2.tau;
//   springDamper2.flange_a.tau = -springDamper2.tau;
//   inertia2.w = der(inertia2.phi);
//   inertia2.a = der(inertia2.w);
//   inertia2.J * inertia2.a = inertia2.flange_a.tau + inertia2.flange_b.tau;
//   inertia2.flange_a.phi = inertia2.phi;
//   inertia2.flange_b.phi = inertia2.phi;
//   torque1.flange_b.tau = -torque1.tau;
//   torque1.bearing.phi = 0.0;
//   sine1.y = sine1.offset + (if time < sine1.startTime then 0.0 else sine1.amplitude * sin(6.283185307179586 * sine1.freqHz * (time - sine1.startTime) + sine1.phase));
//   gear1.adapter.flange_a.phi = gear1.adapter.flange_b.phi;
//   if gear1.adapter.bearingConnected then
//     0.0 = gear1.adapter.flange_a.tau + gear1.adapter.flange_b.tau;
//   else
//     0.0 = gear1.adapter.flange_a.phi;
//   end if;
//   gear1.gearRatio.phi_a = gear1.gearRatio.ratio * gear1.gearRatio.phi_b;
//   0.0 = gear1.gearRatio.ratio * gear1.gearRatio.flange_a.tau + gear1.gearRatio.flange_b.tau;
//   gear1.gearRatio.bearing.tau = gear1.gearRatio.tau_support;
//   0.0 = gear1.gearRatio.flange_a.tau + gear1.gearRatio.flange_b.tau + gear1.gearRatio.tau_support;
//   gear1.gearRatio.phi_a = gear1.gearRatio.flange_a.phi - gear1.gearRatio.bearing.phi;
//   gear1.gearRatio.phi_b = gear1.gearRatio.flange_b.phi - gear1.gearRatio.bearing.phi;
//   gear1.gearEfficiency.phi = gear1.gearEfficiency.phi_a;
//   gear1.gearEfficiency.phi = gear1.gearEfficiency.phi_b;
//   gear1.gearEfficiency.power_a = gear1.gearEfficiency.flange_a.tau * der(gear1.gearEfficiency.phi);
//   gear1.gearEfficiency.driving_a = gear1.gearEfficiency.power_a >= 0.0;
//   gear1.gearEfficiency.flange_b.tau = -(if gear1.gearEfficiency.driving_a then gear1.gearEfficiency.eta * gear1.gearEfficiency.flange_a.tau else gear1.gearEfficiency.flange_a.tau / gear1.gearEfficiency.eta);
//   gear1.gearEfficiency.bearing.tau = gear1.gearEfficiency.tau_support;
//   0.0 = gear1.gearEfficiency.flange_a.tau + gear1.gearEfficiency.flange_b.tau + gear1.gearEfficiency.tau_support;
//   gear1.gearEfficiency.phi_a = gear1.gearEfficiency.flange_a.phi - gear1.gearEfficiency.bearing.phi;
//   gear1.gearEfficiency.phi_b = gear1.gearEfficiency.flange_b.phi - gear1.gearEfficiency.bearing.phi;
//   gear1.elastoBacklash.w_rel = der(gear1.elastoBacklash.phi_rel);
//   gear1.elastoBacklash.tau = if gear1.elastoBacklash.b2 > 1e-10 then if gear1.elastoBacklash.phi_rel > gear1.elastoBacklash.b2 then gear1.elastoBacklash.c * (gear1.elastoBacklash.phi_rel + (-gear1.elastoBacklash.phi_rel0) - gear1.elastoBacklash.b2) + gear1.elastoBacklash.d * gear1.elastoBacklash.w_rel else if gear1.elastoBacklash.phi_rel < (-gear1.elastoBacklash.b2) then gear1.elastoBacklash.c * (gear1.elastoBacklash.phi_rel + gear1.elastoBacklash.b2 - gear1.elastoBacklash.phi_rel0) + gear1.elastoBacklash.d * gear1.elastoBacklash.w_rel else 0.0 else gear1.elastoBacklash.c * (gear1.elastoBacklash.phi_rel - gear1.elastoBacklash.phi_rel0) + gear1.elastoBacklash.d * gear1.elastoBacklash.w_rel;
//   gear1.elastoBacklash.phi_rel = gear1.elastoBacklash.flange_b.phi - gear1.elastoBacklash.flange_a.phi;
//   gear1.elastoBacklash.flange_b.tau = gear1.elastoBacklash.tau;
//   gear1.elastoBacklash.flange_a.tau = -gear1.elastoBacklash.tau;
//   gear1.bearingFriction.tau0 = Modelica.Math.tempInterpol1(0.0, {{gear1.bearingFriction.tau_pos[1,1], gear1.bearingFriction.tau_pos[1,2]}}, 2);
//   gear1.bearingFriction.tau0_max = gear1.bearingFriction.peak * gear1.bearingFriction.tau0;
//   gear1.bearingFriction.free = false;
//   gear1.bearingFriction.phi = gear1.bearingFriction.phi_a;
//   gear1.bearingFriction.phi = gear1.bearingFriction.phi_b;
//   gear1.bearingFriction.w = der(gear1.bearingFriction.phi);
//   gear1.bearingFriction.a = der(gear1.bearingFriction.w);
//   gear1.bearingFriction.w_relfric = gear1.bearingFriction.w;
//   gear1.bearingFriction.a_relfric = gear1.bearingFriction.a;
//   0.0 = gear1.bearingFriction.flange_a.tau + gear1.bearingFriction.flange_b.tau - gear1.bearingFriction.tau;
//   gear1.bearingFriction.tau = if gear1.bearingFriction.locked then gear1.bearingFriction.sa else if gear1.bearingFriction.startForward then Modelica.Math.tempInterpol1(gear1.bearingFriction.w, {{gear1.bearingFriction.tau_pos[1,1], gear1.bearingFriction.tau_pos[1,2]}}, 2) else if gear1.bearingFriction.startBackward then -Modelica.Math.tempInterpol1(-gear1.bearingFriction.w, {{gear1.bearingFriction.tau_pos[1,1], gear1.bearingFriction.tau_pos[1,2]}}, 2) else if pre(gear1.bearingFriction.mode) == 1 then Modelica.Math.tempInterpol1(gear1.bearingFriction.w, {{gear1.bearingFriction.tau_pos[1,1], gear1.bearingFriction.tau_pos[1,2]}}, 2) else -Modelica.Math.tempInterpol1(-gear1.bearingFriction.w, {{gear1.bearingFriction.tau_pos[1,1], gear1.bearingFriction.tau_pos[1,2]}}, 2);
//   gear1.bearingFriction.bearing.tau = gear1.bearingFriction.tau_support;
//   0.0 = gear1.bearingFriction.flange_a.tau + gear1.bearingFriction.flange_b.tau + gear1.bearingFriction.tau_support;
//   gear1.bearingFriction.phi_a = gear1.bearingFriction.flange_a.phi - gear1.bearingFriction.bearing.phi;
//   gear1.bearingFriction.phi_b = gear1.bearingFriction.flange_b.phi - gear1.bearingFriction.bearing.phi;
//   gear1.bearingFriction.startForward = pre(gear1.bearingFriction.mode) == 0 and (gear1.bearingFriction.sa > gear1.bearingFriction.tau0_max or pre(gear1.bearingFriction.startForward) and gear1.bearingFriction.sa > gear1.bearingFriction.tau0) or pre(gear1.bearingFriction.mode) == -1 and gear1.bearingFriction.w_relfric > gear1.bearingFriction.w_small or initial() and gear1.bearingFriction.w_relfric > 0.0;
//   gear1.bearingFriction.startBackward = pre(gear1.bearingFriction.mode) == 0 and (gear1.bearingFriction.sa < (-gear1.bearingFriction.tau0_max) or pre(gear1.bearingFriction.startBackward) and gear1.bearingFriction.sa < (-gear1.bearingFriction.tau0)) or pre(gear1.bearingFriction.mode) == 1 and gear1.bearingFriction.w_relfric < (-gear1.bearingFriction.w_small) or initial() and gear1.bearingFriction.w_relfric < 0.0;
//   gear1.bearingFriction.locked = not gear1.bearingFriction.free and not (pre(gear1.bearingFriction.mode) == 1 or gear1.bearingFriction.startForward or pre(gear1.bearingFriction.mode) == -1 or gear1.bearingFriction.startBackward);
//   gear1.bearingFriction.a_relfric = if gear1.bearingFriction.locked then 0.0 else if gear1.bearingFriction.free then gear1.bearingFriction.sa else if gear1.bearingFriction.startForward then gear1.bearingFriction.sa - gear1.bearingFriction.tau0 else if gear1.bearingFriction.startBackward then gear1.bearingFriction.sa + gear1.bearingFriction.tau0 else if pre(gear1.bearingFriction.mode) == 1 then gear1.bearingFriction.sa - gear1.bearingFriction.tau0 else gear1.bearingFriction.sa + gear1.bearingFriction.tau0;
//   gear1.bearingFriction.mode = if gear1.bearingFriction.free then 2 else if (pre(gear1.bearingFriction.mode) == 1 or pre(gear1.bearingFriction.mode) == 2 or gear1.bearingFriction.startForward) and gear1.bearingFriction.w_relfric > 0.0 then 1 else if (pre(gear1.bearingFriction.mode) == -1 or pre(gear1.bearingFriction.mode) == 2 or gear1.bearingFriction.startBackward) and gear1.bearingFriction.w_relfric < 0.0 then -1 else 0;
//   gear1.tau_support = -gear1.adapter.flange_b.tau;
//   fixed1.flange_b.tau + springDamper1.flange_b.tau = 0.0;
//   springDamper1.flange_a.tau + inertia1.flange_b.tau = 0.0;
//   inertia1.flange_a.tau + gear1.flange_b.tau = 0.0;
//   springDamper2.flange_a.tau + inertia2.flange_b.tau = 0.0;
//   springDamper2.flange_b.tau + gear1.flange_a.tau = 0.0;
//   inertia2.flange_a.tau + torque1.flange_b.tau = 0.0;
//   torque1.bearing.tau = 0.0;
//   gear1.bearing.tau = 0.0;
//   (-gear1.bearing.tau) + gear1.adapter.flange_a.tau = 0.0;
//   gear1.adapter.flange_b.tau + gear1.gearRatio.bearing.tau + gear1.gearEfficiency.bearing.tau + gear1.bearingFriction.bearing.tau = 0.0;
//   (-gear1.flange_a.tau) + gear1.gearRatio.flange_a.tau = 0.0;
//   gear1.gearRatio.flange_b.tau + gear1.gearEfficiency.flange_a.tau = 0.0;
//   gear1.gearEfficiency.flange_b.tau + gear1.bearingFriction.flange_a.tau = 0.0;
//   gear1.bearingFriction.flange_b.tau + gear1.elastoBacklash.flange_a.tau = 0.0;
//   (-gear1.flange_b.tau) + gear1.elastoBacklash.flange_b.tau = 0.0;
//   gear1.flange_a.phi = gear1.gearRatio.flange_a.phi;
//   gear1.gearEfficiency.flange_a.phi = gear1.gearRatio.flange_b.phi;
//   gear1.bearingFriction.flange_a.phi = gear1.gearEfficiency.flange_b.phi;
//   gear1.bearingFriction.flange_b.phi = gear1.elastoBacklash.flange_a.phi;
//   gear1.elastoBacklash.flange_b.phi = gear1.flange_b.phi;
//   gear1.adapter.flange_b.phi = gear1.bearingFriction.bearing.phi;
//   gear1.adapter.flange_b.phi = gear1.gearEfficiency.bearing.phi;
//   gear1.adapter.flange_b.phi = gear1.gearRatio.bearing.phi;
//   gear1.adapter.flange_a.phi = gear1.bearing.phi;
//   gear1.flange_a.phi = springDamper2.flange_b.phi;
//   gear1.flange_b.phi = inertia1.flange_a.phi;
//   inertia2.flange_a.phi = torque1.flange_b.phi;
//   sine1.y = torque1.tau;
//   inertia2.flange_b.phi = springDamper2.flange_a.phi;
//   inertia1.flange_b.phi = springDamper1.flange_a.phi;
//   fixed1.flange_b.phi = springDamper1.flange_b.phi;
// end Gear;
// endResult
