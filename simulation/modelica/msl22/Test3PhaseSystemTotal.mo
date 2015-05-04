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
  version="2.1",
  versionDate="2004-11-11",
  conversion(
    from(version="1.6",
         ModelicaAdditions(version="1.5"),
         MultiBody(version="1.0.1"),
         MultiBody(version="1.0"),
         Matrices(version="0.8"),
         script="Scripts/ConvertModelica_from_1.6_to_2.1.mos"),
    from(version="2.1 Beta1", script="Scripts/ConvertModelica_from_2.1Beta1_to_2.1.mos")),
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
<li> <a href=\"Modelica://Modelica.UsersGuide\">Modelica.UsersGuide</a>
     discusses the most important aspects of this library.</li>
<li><a href=\"Modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
    summarizes the changes of new versions of this package.</li>
<li> Packages <b>Examples</b> in the various subpackages, provide
     demos of the corresponding subpackage.</li>
</ul>
<p>
The Modelica package consists currently of the following subpackages
</p>
<pre>
   <b>Blocks</b>      Input/output blocks.
   <b>Constants</b>   Mathematical and physical constants (pi, eps, h, ...)
   <b>Electrical</b>  Electric and electronic components
               (Analog, Digital, Machines, MultiPhase)
   <b>Icons</b>       Icon definitions of general interest
   <b>Math</b>        Mathematical functions
               (such as sin, cos, solve, eigenValues)
   <b>Mechanics</b>   Mechanical components
               (1D-rotational, 1D-translational, 3D multi-body)
   <b>SIunits</b>     SI-unit type definitions (such as Voltage, Torque)
   <b>StateGraph</b>  Hierarchical state machines (similiar power as StateCharts)
   <b>Thermal</b>     Thermal components
               (1-D heat transfer with lumped elements)
   <b>Utilities</b>   Utility functions especially for scripting
               (Files, Streams, Strings, System)
</pre>
<p>
Copyright &copy; 1998-2004, Modelica Association.
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
<p><b>Copyright &copy; 1999-2004, Modelica Association and DLR.</b></p>
<p><i>
The Modelica package Modelica.Blocks is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.
</i></p>
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

        partial block SignalSource "Base class for continuous signal source"
          extends SO;
          parameter Real offset=0 "offset of output signal";
          parameter SIunits.Time startTime=0
        "output = offset for time < startTime";
        end SignalSource;
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

<p><b>Copyright &copy; 1999-2004, Modelica Association and DLR.</b></p>

<p><i>
The Modelica package is free software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i></p>
</html>
",   revisions="<html>
<p><b>Release Notes:</b></p>
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

  package Electrical "Library for electrical models"
  extends Modelica.Icons.Library2;
  annotation(preferedView="info",
    Documentation(info="<html>
<p>
This library contains electrical components to build up analog and digital circuits.
The library is currently structured in the following sublibraries:
</p>
<ul>
<li>Package <b>Analog</b> for basic analog electrical components.</li>
<li>Package <b>Digital</b> for 2-, 3-, 4-, and 9-value logic of digital circuits.</li>
<li>Package <b>MultiPhase</b> for electrical
    components with 2, 3 or more phases.</li>
<li>Package <b>Machines</b> to model electrical motors and generators,
    especially three phase induction machines such as an
    asynchronous motor.</li>
</ul>
<p>
</HTML>
"),  Window(
      x=0.03,
      y=0.03,
      width=0.13,
      height=0.29,
      library=1,
      autolayout=1),
    Icon(
      Rectangle(extent=[-29, -13; 3, -27], style(color=0)),
      Line(points=[37, -58; 62, -58], style(color=0)),
      Line(points=[36, -49; 61, -49], style(color=0)),
      Line(points=[-78, -50; -43, -50], style(color=0)),
      Line(points=[-67, -55; -55, -55], style(color=0)),
      Line(points=[-61, -50; -61, -20; -29, -20], style(color=0)),
      Line(points=[3, -20; 48, -20; 48, -49], style(color=0)),
      Line(points=[48, -58; 48, -78; -61, -78; -61, -55], style(color=0))));

    package Analog "Library for analog electrical models"
      import SI = Modelica.SIunits;
    extends Modelica.Icons.Library2;
    annotation(preferedView="info", Window(
        x=0.05,
        y=0.06,
        width=0.16,
        height=0.58,
        library=1,
        autolayout=1),
      Documentation(info="<html>
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
Copyright &copy; 1998-2002, Modelica Association and Fraunhofer-Gesellschaft.<br>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".</i><br>
<p>
</dl>
</HTML>
"));

      package Basic
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Window(
             x=0.03,
             y=0.04,
             width=0.54,
             height=0.35,
             library=1,
             autolayout=1),
      Documentation(info="<HTML>
<p>
This package contains basic analog electrical components:
<ul>
<li>Ground</li>
<li>Resistor</li>
<li>HeatingResistor</li>
<li>Conductor</li>
<li>Capacitor</li>
<li>Inductor</li>
<li>SaturatingInductor</li>
<li>Transformer</li>
<li>Gyrator</li>
<li>EMF (Electroc-Motoric-Force)</li>
<li>Linear controlled sources (VCV, VCC, CCV, CCC)</li>
<li>OpAmp</li>
<li>VariableResistor, VariableConductor,
    VariableCapacitor, VariableInductor</li>
</ul>
</p>
</HTML>
",       revisions="<html>
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
</html>"));

        model Ground "Ground node"
          annotation (
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Documentation(info="<HTML>
<P>
Ground of an electrical circuit. The potential at the
ground node is zero. Every electrical circuit has to contain
at least one ground object.
</P>
</HTML>
"),         Icon(
              Line(points=[-60, 50; 60, 50]),
              Line(points=[-40, 30; 40, 30]),
              Line(points=[-20, 10; 20, 10]),
              Line(points=[0, 90; 0, 50]),
              Text(extent=[-144,-60; 138,0],     string="%name")),
            Diagram(
              Line(points=[-60, 50; 60, 50], style(thickness=2)),
              Line(points=[-40, 30; 40, 30], style(thickness=2)),
              Line(points=[-20, 10; 20, 10], style(thickness=2)),
              Line(points=[0,96; 0,50],   style(thickness=2)),
              Text(extent=[-24, -38; 22, -6], string="p.v=0")),
            Window(
              x=0.23,
              y=0.23,
              width=0.59,
              height=0.63));
          Interfaces.Pin p annotation (extent=[-10, 110; 10, 90], rotation=-90);
        equation
          p.v = 0;
        end Ground;

        model Resistor "Ideal linear electrical resistor"
          extends Interfaces.OnePort;
          parameter SI.Resistance R=1 "Resistance";
          annotation (
            Documentation(info="<HTML>
<P>
The linear resistor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by <i>i*R = v</i>.
The Resistance <i>R</i> is allowed to be positive, zero, or negative.
</P>
</HTML>
"),         Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Icon(
              Rectangle(extent=[-70, 30; 70, -30], style(
                  color=3,
                  fillColor=7,
                  fillPattern=1)),
              Line(points=[-90, 0; -70, 0]),
              Line(points=[70, 0; 90, 0]),
              Text(
                extent=[-144,-60; 144,-100],
                string="R=%R",
                style(color=0)),
              Text(extent=[-144,40; 144,100],   string="%name")),
            Diagram(
              Rectangle(extent=[-70, 30; 70, -30]),
              Line(points=[-96,0; -70,0]),
              Line(points=[70,0; 96,0])),
            Window(
              x=0.2,
              y=0.06,
              width=0.62,
              height=0.69));
        equation
          R*i = v;
        end Resistor;

        model Inductor "Ideal linear electrical inductor"
          extends Interfaces.OnePort;
          parameter SI.Inductance L=1 "Inductance";
          annotation (
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Documentation(info="<HTML>
<P>
The linear inductor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by  <i>v = L * di/dt</i>.
The Inductance <i>L</i> is allowed to be positive, zero, or negative.
</p>
</HTML>
"),         Icon(
              Ellipse(extent=[-60, -15; -30, 15]),
              Ellipse(extent=[-30, -15; 0, 15]),
              Ellipse(extent=[0, -15; 30, 15]),
              Ellipse(extent=[30, -15; 60, 15]),
              Rectangle(extent=[-60, -30; 60, 0], style(color=7, fillColor=7)),
              Line(points=[60, 0; 90, 0]),
              Line(points=[-90, 0; -60, 0]),
              Text(
                extent=[-138,-60; 144,-102],
                string="L=%L",
                style(color=0)),
              Text(extent=[-146,38; 148,100],   string="%name")),
            Diagram(
              Ellipse(extent=[-60, -15; -30, 15]),
              Ellipse(extent=[-30, -15; 0, 15]),
              Ellipse(extent=[0, -15; 30, 15]),
              Ellipse(extent=[30, -15; 60, 15]),
              Rectangle(extent=[-60, -30; 60, 0], style(color=7, fillColor=7)),
              Line(points=[60,0; 96,0]),
              Line(points=[-96,0; -60,0])),
            Window(
              x=0.3,
              y=0.12,
              width=0.6,
              height=0.6));
        equation
          L*der(i) = v;
        end Inductor;
      end Basic;

      package Interfaces
        extends Modelica.Icons.Library;
        annotation(preferedView="info", Window(
            x=0.03,
            y=0.04,
            width=0.21,
            height=0.49,
            library=1,
            autolayout=1),Documentation(info="<html>
<p>
This package contains connectors and interfaces (partial models) for
analog electrical components.
</p>
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
Copyright &copy; 1998-2002, Modelica Association and Fraunhofer-Gesellschaft.<br>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".</i><br>
<p>
</dl>
</HTML>
"));

        connector Pin "Pin of an electrical component"
          SI.Voltage v "Potential at the pin";
          flow SI.Current i "Current flowing into the pin";
          annotation (defaultComponentName="pin",
            Icon(Rectangle(extent=[-100, 100; 100, -100], style(color=3, fillColor=3))),
            Diagram(Rectangle(extent=[-40,40; 40,-40], style(color=3, fillColor=
                     3)), Text(
                extent=[-160,110; 40,50],
                string="%name",
                style(color=3))));
        end Pin;

        connector PositivePin "Positive pin of an electric component"
          SI.Voltage v "Potential at the pin";
          flow SI.Current i "Current flowing into the pin";
          annotation (defaultComponentName="pin_p",
            Documentation(info="<html><p>Connectors PositivePin
and NegativePin are nearly identical.
The only difference is that the icons are different in order
to identify more easily the pins of a component. Usually,
connector PositivePin is used for the positive and
connector NegativePin for the negative pin of an electrical
component.</p></html>"),
            Icon(Rectangle(extent=[-100, 100; 100, -100], style(color=3, fillColor=3))),
            Diagram(Rectangle(extent=[-40,40; 40,-40], style(color=3, fillColor=
                     3)), Text(
                extent=[-160,110; 40,50],
                string="%name",
                style(color=3))));
        end PositivePin;

        connector NegativePin "Negative pin of an electric component"
          SI.Voltage v "Potential at the pin";
          flow SI.Current i "Current flowing into the pin";
          annotation (defaultComponentName="pin_n",
            Documentation(info="<html><p>Connectors PositivePin
and NegativePin are nearly identical.
The only difference is that the icons are different in order
to identify more easily the pins of a component. Usually,
connector PositivePin is used for the positive and
connector NegativePin for the negative pin of an electrical
component.</p></html>"),
            Icon(Rectangle(extent=[-100, 100; 100, -100], style(
                  color=3,
                  gradient=0,
                  fillColor=7,
                  fillPattern=1))),
            Diagram(Rectangle(extent=[-40,40; 40,-40], style(
                  color=3,
                  fillColor=7,
                  fillPattern=1)), Text(extent=[-40,110; 160,50], string=
                    "%name")),
            Terminal(Rectangle(extent=[-100, 100; 100, -100], style(color=3))));
        end NegativePin;

        partial model OnePort
        "Component with two electrical pins p and n and current i from p to n"

          SI.Voltage v "Voltage drop between the two pins (= p.v - n.v)";
          SI.Current i "Current flowing from pin p to pin n";
          annotation (
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[2, 2],
              component=[20, 20]),
            Documentation(info="<HTML>
<P>
Superclass of elements which have <b>two</b> electrical pins:
the positive pin connector <i>p</i>, and the negative pin
connector <i>n</i>. It is assumed that the current flowing
into pin p is identical to the current flowing out of pin n.
This current is provided explicitly as current i.
</P>
</HTML>
"),         Diagram(
              Line(points=[-110, 20; -85, 20], style(color=9, fillColor=9)),
              Polygon(points=[-95, 23; -85, 20; -95, 17; -95, 23], style(
                  color=9,
                  fillColor=9,
                  fillPattern=1)),
              Line(points=[90, 20; 115, 20], style(color=9, fillColor=9)),
              Line(points=[-125, 0; -115, 0], style(color=9)),
              Line(points=[-120, -5; -120, 5], style(color=9)),
              Text(
                extent=[-110, 25; -90, 45],
                string="i",
                style(color=9)),
              Polygon(points=[105, 23; 115, 20; 105, 17; 105, 23], style(
                  color=9,
                  fillColor=9,
                  fillPattern=1)),
              Line(points=[115, 0; 125, 0], style(color=9)),
              Text(
                extent=[90, 45; 110, 25],
                string="i",
                style(color=9))),
            Window(
              x=0.33,
              y=0.04,
              width=0.63,
              height=0.67));
          PositivePin p annotation (extent=[-110, -10; -90, 10]);
          NegativePin n annotation (extent=[110, -10; 90, 10]);
        equation
          v = p.v - n.v;
          0 = p.i + n.i;
          i = p.i;
        end OnePort;

        partial model VoltageSource "Interface for voltage sources"
          extends OnePort;

          parameter SI.Voltage offset=0 "Voltage offset";
          parameter SI.Time startTime=0 "Time offset";
          annotation (
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[1, 1],
              component=[20, 20]),
            Icon(
              Ellipse(extent=[-50, 50; 50, -50], style(
                  color=0,
                  rgbcolor={0,0,0},
                  fillColor=7,
                  rgbfillColor={255,255,255})),
              Text(extent=[-150,80; 150,120], string="%name"),
              Line(points=[-90,0; 90,0], style(color=0, rgbcolor={0,0,0}))),
            Window(
              x=0.31,
              y=0.09,
              width=0.6,
              height=0.6));
          replaceable Modelica.Blocks.Interfaces.SignalSource signalSource(
              final offset = offset, final startTime=startTime)
          annotation (extent=[70, 70; 90, 90]);
        equation
          v = signalSource.y;
        end VoltageSource;
      end Interfaces;

      package Sources
        extends Modelica.Icons.Library;
        annotation(preferedView="info",
          Window(
            x=0.03,
            y=0.04,
            width=0.50,
            height=0.60,
            library=1,
            autolayout=1),Documentation(info="<html>
<p>
This package contains time-dependend and controlled voltage and current sources.
</p>
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
Copyright &copy; 1998-2002, Modelica Association and Fraunhofer-Gesellschaft.<br>
<i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".</i><br>
<p>
</dl>
</HTML>
"));

        model SineVoltage "Sine voltage source"
          parameter SI.Voltage V=1 "Amplitude of sine wave";
          parameter SI.Angle phase=0 "Phase of sine wave";
          parameter SI.Frequency freqHz=1 "Frequency of sine wave";
          extends Interfaces.VoltageSource(redeclare
            Modelica.Blocks.Sources.Sine signalSource(
              amplitude=V,
              freqHz=freqHz,
              phase=phase));
          annotation (
            Coordsys(
              extent=[-100, -100; 100, 100],
              grid=[1, 1],
              component=[20, 20]),
            Window(
              x=0.37,
              y=0.06,
              width=0.6,
              height=0.6),
            Icon(Line(points=[-70, 0; -60.2, 29.9; -53.8, 46.5; -48.2, 58.1; -43.3,
                    65.2; -38.3, 69.2; -33.4, 69.8; -28.5, 67; -23.6, 61; -18.6, 52;
                    -13, 38.6; -5.98, 18.6; 8.79, -26.9; 15.1, -44; 20.8, -56.2; 25.7,
                      -64; 30.6, -68.6; 35.5, -70; 40.5, -67.9; 45.4, -62.5; 50.3, -
                    54.1; 55.9, -41.3; 63, -21.7; 70, 0], style(color=8))),
            Diagram(
              Line(points=[-80, -90; -80, 84], style(color=8)),
              Polygon(points=[-80, 100; -86, 84; -74, 84; -80, 100], style(color=8,
                    fillColor=8)),
              Line(points=[-99, -40; 85, -40], style(color=8)),
              Polygon(points=[101, -40; 85, -34; 85, -46; 101, -40], style(color=8,
                    fillColor=8)),
              Line(points=[-40, 0; -31.6, 34.2; -26.1, 53.1; -21.3, 66.4; -17.1, 74.6;
                      -12.9, 79.1; -8.64, 79.8; -4.42, 76.6; -0.201, 69.7; 4.02, 59.4;
                      8.84, 44.1; 14.9, 21.2; 27.5, -30.8; 33, -50.2; 37.8, -64.2; 42,
                      -73.1; 46.2, -78.4; 50.5, -80; 54.7, -77.6; 58.9, -71.5; 63.1,
                    -61.9; 67.9, -47.2; 74, -24.8; 80, 0], style(color=0, thickness=2)),
              Line(points=[-41, -2; -80, -2], style(color=0, thickness=2)),
              Text(
                extent=[-106, -11; -60, -29],
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
              Line(points=[-9, 79; 43, 79], style(color=8, pattern=2)),
              Line(points=[-42, -1; 50, 0], style(color=8, pattern=2)),
              Polygon(points=[33, 80; 30, 67; 37, 67; 33, 80], style(
                  color=8,
                  fillColor=8,
                  fillPattern=1)),
              Text(
                extent=[37, 57; 83, 39],
                string="V",
                style(color=9)),
              Polygon(points=[33, 1; 30, 14; 36, 14; 33, 1; 33, 1], style(
                  color=8,
                  fillColor=8,
                  fillPattern=1)),
              Line(points=[33, 79; 33, 0], style(
                  color=8,
                  pattern=1,
                  thickness=1,
                  arrow=0)),
              Text(
                extent=[-69, 109; -4, 83],
                string="v = p.v - n.v",
                style(color=9))));
        end SineVoltage;
      end Sources;
    end Analog;
  end Electrical;

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
<br>
<p><b>Release Notes:</b></p>
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
<p><b>Copyright &copy; 1999-2002, Modelica Association and DLR.</b></p>
<p><i>
The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i></p>
</HTML>
"));

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
<br>
<p><b>Release Notes:</b></p>
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
<br>
<p><b>Copyright &copy; 1999-2002, Modelica Association and DLR.</b></p>
<p><i>
The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i></p>
</HTML>
"));

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
  end Math;

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

    type Frequency = Real (final quantity="Frequency", final unit="Hz");

    type ElectricCurrent = Real (final quantity="ElectricCurrent", final unit="A");

    type Current = ElectricCurrent;

    type ElectricPotential = Real (final quantity="ElectricPotential", final unit
        =  "V");

    type Voltage = ElectricPotential;

    type Inductance = Real (
        final quantity="Inductance",
        final unit="H");

    type Resistance = Real (
        final quantity="Resistance",
        final unit="Ohm",
        min=0);
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
<br>
<p><b>Release Notes:</b></p>
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
<br>
<p><b>Copyright &copy; 1999-2002, Modelica Association and DLR.</b></p>
<p><i>The Modelica package is free software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".</i></p>
</HTML>"),
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

package Test3PhaseSystems

  connector dq0
    Real u_dq0[3];
    flow Real i_dq0[3];
  end dq0;

  model LR
  constant Real pi=Modelica.Constants.pi;
  Real theta;
  Real P[3,3];

  dq0 dq0_1 annotation (extent=[-88,-10; -68,10]);
  dq0 dq0_2 annotation (extent=[70,-12; 90,8]);
public
    Modelica.Electrical.Analog.Basic.Resistor R1(R=.5)
      annotation (extent=[8,26; 28,46]);
    Modelica.Electrical.Analog.Basic.Inductor I1(i.fixed=false) annotation (extent=[-26,26; -6,
        46]);
    Modelica.Electrical.Analog.Basic.Resistor R2(R=.5)
      annotation (extent=[10,0; 30,20]);
    Modelica.Electrical.Analog.Basic.Inductor I2(i.fixed=false) annotation (extent=[-26,0; -6,
        20]);
    Modelica.Electrical.Analog.Basic.Resistor R3(R=.5)
      annotation (extent=[10,-24; 30,-4]);
    Modelica.Electrical.Analog.Basic.Inductor I3(i.fixed=false)
      annotation (extent=[-24,-24; -4,-4]);
  abc2_a_b_c abc_1 annotation (extent=[-60,-60; -40,60]);
  abc2_a_b_c abc_2 annotation (extent=[60,-60; 40,60]);
  equation
    connect(I2.n,R2. p)
      annotation (points=[-6,10; 10,10],style(color=3, rgbcolor={0,0,255}));
    connect(I1.n,R1. p)
      annotation (points=[-6,36; 8,36], style(color=3, rgbcolor={0,0,255}));
    connect(I3.n,R3. p)
      annotation (points=[-4,-14; 10,-14],style(color=3, rgbcolor={0,0,255}));
  annotation (Diagram);
    theta = 2*pi*time;
    P = sqrt(2)/sqrt(3)*
      [sin(theta), sin(theta+2*pi/3), sin(theta+4*pi/3);
       cos(theta), cos(theta+2*pi/3), cos(theta+4*pi/3);
       1/sqrt(2), 1/sqrt(2), 1/sqrt(2)];

    dq0_1.u_dq0 = P*abc_1.u_abc;
    dq0_1.i_dq0 = P*abc_1.i_abc;

    dq0_2.u_dq0 = P*abc_2.u_abc;
    dq0_2.i_dq0 = P*abc_2.i_abc;

  connect(I3.p, abc_1.pin_c) annotation (points=[-24,-14; -34,-14; -34,-13.2;
        -43.8,-13.2], style(color=3, rgbcolor={0,0,255}));
  connect(I2.p, abc_1.pin_b) annotation (points=[-26,10; -34,10; -34,10.8;
        -43.8,10.8], style(color=3, rgbcolor={0,0,255}));
  connect(I1.p, abc_1.pin_a)
    annotation (points=[-26,36; -43.8,36], style(color=3, rgbcolor={0,0,255}));
  connect(R3.n, abc_2.pin_c) annotation (points=[30,-14; 40,-14; 40,-13.2; 43.8,
        -13.2], style(color=3, rgbcolor={0,0,255}));
  connect(R2.n, abc_2.pin_b) annotation (points=[30,10; 40,10; 40,10.8; 43.8,
        10.8], style(color=3, rgbcolor={0,0,255}));
  connect(R1.n, abc_2.pin_a)
    annotation (points=[28,36; 43.8,36], style(color=3, rgbcolor={0,0,255}));
  initial equation
    der(dq0_1.i_dq0)={0,0,0};
  end LR;
annotation (uses(Modelica(version="2.1")));

  model abc2_a_b_c
  Real u_abc[3]={pin_a.v,pin_b.v,pin_c.v};
  Real i_abc[3]={pin_a.i,pin_b.i,pin_c.i};
  Modelica.Electrical.Analog.Interfaces.Pin pin_a
    annotation (extent=[52,50; 72,70]);
  Modelica.Electrical.Analog.Interfaces.Pin pin_b
    annotation (extent=[52,8; 72,28]);
  Modelica.Electrical.Analog.Interfaces.Pin pin_c
    annotation (extent=[52,-32; 72,-12]);
  annotation (Diagram);
  end abc2_a_b_c;

  model VS
  constant Real pi=Modelica.Constants.pi;
  parameter Real shift=0;
  Real theta;
  Real P[3,3];

  dq0 dq0_1 annotation (extent=[-72,12; -52,32]);
    Modelica.Electrical.Analog.Sources.SineVoltage SS1(phase=shift)
      annotation (extent=[70,50; 90,70], rotation=0);
    Modelica.Electrical.Analog.Sources.SineVoltage SS2(phase=2*pi/3 + shift)
                 annotation (extent=[70,10; 90,30],rotation=0);
    Modelica.Electrical.Analog.Sources.SineVoltage SS3(phase=4*pi/3 + shift)
                 annotation (extent=[70,-30; 90,-10], rotation=0);
    Modelica.Electrical.Analog.Basic.Ground G
      annotation (extent=[80,-74; 100,-54]);
  abc2_a_b_c abc_1 annotation (extent=[-20,-60; 0,80]);
  equation
    connect(SS1.n,SS2. n)
      annotation (points=[90,60; 90,20], style(color=3, rgbcolor={0,0,255}));
    connect(SS2.n,SS3. n)
      annotation (points=[90,20; 90,-20], style(color=3, rgbcolor={0,0,255}));
    connect(SS3.n,G. p)
      annotation (points=[90,-20; 90,-54], style(color=3, rgbcolor={0,0,255}));
  annotation (Diagram);
    theta = 2*pi*time;
    P = sqrt(2)/sqrt(3)*
      [sin(theta), sin(theta+2*pi/3), sin(theta+4*pi/3);
       cos(theta), cos(theta+2*pi/3), cos(theta+4*pi/3);
       1/sqrt(2), 1/sqrt(2), 1/sqrt(2)];

    dq0_1.u_dq0 = P*abc_1.u_abc;
    dq0_1.i_dq0 = P*abc_1.i_abc;
  connect(SS1.p, abc_1.pin_a) annotation (points=[70,60; 34,60; 34,52; -3.8,52],
      style(color=3, rgbcolor={0,0,255}));
  connect(SS2.p, abc_1.pin_b) annotation (points=[70,20; 33.1,20; 33.1,22.6;
        -3.8,22.6], style(color=3, rgbcolor={0,0,255}));
  connect(SS3.p, abc_1.pin_c) annotation (points=[70,-20; 32,-20; 32,-5.4; -3.8,
        -5.4], style(color=3, rgbcolor={0,0,255}));
  end VS;

  model Test3PhaseSystem
  VS VS1 annotation (extent=[-60,20; -80,40]);
  VS VS2(shift=0.4) annotation (extent=[60,20; 80,40]);
  LR LR1 annotation (extent=[-40,20; -20,40]);
  annotation (Diagram);
  LR LR2 annotation (extent=[0,20; 20,40]);
  equation
  connect(VS1.dq0_1, LR1.dq0_1) annotation (points=[-63.8,32.2; -40.9,32.2;
        -40.9,30; -37.8,30], style(color=3, rgbcolor={0,0,255}));
  connect(LR1.dq0_2, LR2.dq0_1) annotation (points=[-22,29.8; -10,29.8; -10,30;
        2.2,30], style(color=3, rgbcolor={0,0,255}));
  connect(LR2.dq0_2, VS2.dq0_1) annotation (points=[18,29.8; 42,29.8; 42,32.2;
        63.8,32.2], style(color=3, rgbcolor={0,0,255}));
  //initial equation
    //der(LR1.dq0_1.i_dq0)={0,0,0};

  end Test3PhaseSystem;
end Test3PhaseSystems;
