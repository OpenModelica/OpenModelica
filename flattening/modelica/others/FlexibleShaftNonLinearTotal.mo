// name:     FlexibleShaft
// keywords: Rotational Mechanics, Arrays of components.
// status:   correct
//
// This is an application example for a flexible rotational axis.
//


model ShaftElement "Element of a flexible one dimensional shaft"
   import Modelica.Mechanics.Rotational.Inertia;
   import Modelica.Mechanics.Rotational.NonLinearSpringDamper;
   import Modelica.Mechanics.Rotational.Interfaces;

   extends Interfaces.TwoFlanges;

   Inertia inertia1;
   NonLinearSpringDamper springDamper1(c=500,d=5);
equation
   connect(inertia1.flange_b, springDamper1.flange_a);
   connect(inertia1.flange_a,flange_a);
   connect(springDamper1.flange_b,flange_b);
end ShaftElement;

package Modelica "Modelica Standard Library"
extends Icons.Library;
annotation (
  Window(
    x=0.02,
    y=0.01,
    width=0.2,
    height=0.57,
    library=1,
    autolayout=1),
  Documentation(info="
<HTML>
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
The Modelica package is <b>free</b> software and can be redistributed and/or
modified under the terms of the Modelica License and the accompanying
disclaimer, displayed at the end of this documentation.
</p>

<p>
The Modelica package consists currently of the following subpackages
</p>

<pre>
   <b>Constants</b>   Mathematical and physical constants (pi, eps, h, ...)
   <b>Icons</b>       Icon definitions of general interest
   <b>Math</b>        Mathematical functions (such as sin, cos)
   <b>SIunits</b>     SI-unit type definitions (such as Voltage, Torque)

   <b>Blocks</b>      Input/output blocks.
   <b>Electrical</b>  Electric and electronic components.
   <b>Mechanics</b>   Mechanical components
               (currently: 1D-rotational and 1D-translational components)
   <b>Thermal</b>     Thermal components
               (currently: 1-D heat transfer with lumped elements)
</pre>

<p>
In the Modelica package the following conventions are used:
</p>

<ul>
<li>
Class and instance names are written in upper and lower case
letters, e.g., \"ElectricCurrent\". An underscore is only used
at the end of a name to characterize a lower or upper index,
e.g., body_low_up.<br><br>
</li>

<li>
Type names start always with an upper case letter.
Instance names start always with a lower case letter with only
a few exceptions, such as \"T\" for a temperature instance,
if this is common sense.<br><br>
</li>

<li>
A package XXX has its interface definitions in subpackage
XXX.Interfaces, e.g., Electrical.Interfaces. <br><br>
</li>

<li>
Preferred instance names for connectors:
<pre>
  p,n: positive and negative side of a partial model.
  a,b: side \"a\" and side \"b\" of a partial model
       (= connectors are completely equivalent).
</pre>
</li>
</ul>
<br><br>

<dl>
<dt><b>Main Author:</b>
<dd>People from the Modelica Association<br>
    Homepage: <a href=\"http://www.Modelica.org\">http://www.Modelica.org</a>
</dl>
<br>

<p><b>Release Notes:</b></p>
<ul>
<li><i>Version 1.5 (December 16, 2002)</i><br>
    Encapsulated all example models, added new package
    <b>Thermal.HeatTransfer</b> for modeling of lumped
    heat transfer, added model <b>LossyGear</b> in Mechanics.Rotational
    to model gear efficiency and bearing friction according to a new
    theory in a robust way, added 10 new models in Electrical.Analog and
    added several other new models and improved existing models. In total,
    55 new components have been added. A
    <a href=\"../Documentation/ChangeNotes1.5.html\">description</a>
    of the changes is available.
    </li>
<li><i>Version 1.4.1 (June 28, 2001)</i><br>
    Several minor bugs fixed. New models:
    Modelica.Blocks.Interfaces.IntegerInPort/IntegerOutPort,
    Modelica.Blocks.Math.TwoInputs/TwoOutputs
    Modelica.Electrical.Analog.Ideal.IdealOpAmp3Pin,
    Modelica.Mechanics.Rotational.Move,
    Modelica.Mechanics.Translational.Move.
    </li>

<li><i>Version 1.4.1beta1 (February 12, 2001)</i><br>
    Adapted to Modelica 1.4</li>

<li><i>Version 1.3.2beta2 (June 20, 2000)</i><br>
    <ul>
    <li>New subpackage Modelica.Mechanics.<b>Translational</b></li>

    <li>Changes to Modelica.Mechanics.<b>Rotational</b>:<br>
       New elements:
<pre>
   IdealGearR2T    Ideal gear transforming rotational in translational motion.
   Position        Forced movement of a flange with a reference angle
                   given as input signal
   RelativeStates  Definition of relative state variables
</pre>
</li>

    <li>Changes to Modelica.<b>SIunits</b>:<br>
      Introduced new types:<br>
      type Temperature = ThermodynamicTemperature;<br>
      types DerDensityByEnthalpy, DerDensityByPressure,
      DerDensityByTemperature, DerEnthalpyByPressure,
      DerEnergyByDensity, DerEnergyByPressure<br>
      Attribute \"final\" removed from min and max values
      in order that these values can still be changed to narrow
      the allowed range of values.<br>
      Quantity=\"Stress\" removed from type \"Stress\", in order
      that a type \"Stress\" can be connected to a type \"Pressure\".</li>

    <li>Changes to Modelica.<b>Icons</b>:<br>
       New icons for motors and gearboxes.</li>

    <li>Changes to Modelica.<b>Blocks.Interfaces</b>:<br>
       Introduced a replaceable signal type into
       Blocks.Interfaces.InPort/OutPort:
<pre>
   replaceable type SignalType = Real
</pre>
       in order that the type of the signal of an input/output block
       can be changed to a physical type, for example:

<pre>
   Sine sin1(outPort(redeclare type SignalType=Modelica.SIunits.Torque))
</pre>
      </li></ul>
</li>


<li><i>Version 1.3.1 (Dec. 13, 1999)</i><br>
First official release of the library.</li>
</ul>
<br>

<p><b>THE MODELICA LICENSE</b> (Version 1.1 of June 30, 2000)</p>

<p>Redistribution and use in source and binary forms, with or without
modification are permitted, provided that the following conditions are met:
<ol>
<li>
The author and copyright notices in the source files, these license conditions
and the disclaimer below are (a) retained and (b) reproduced in the documentation
provided with the distribution.</li>

<li>
Modifications of the original source files are allowed, provided that a
prominent notice is inserted in each changed file and the accompanying
documentation, stating how and when the file was modified, and provided
that the conditions under (1) are met.</li>

<li>
It is not allowed to charge a fee for the original version or a modified
version of the software, besides a reasonable fee for distribution and support.
Distribution in aggregate with other (possibly commercial) programs
as part of a larger (possibly commercial) software distribution is permitted,
provided that it is not advertised as a product of your own.</li>
</ol>

<p><b>DISCLAIMER</b>
<p>The software (sources, binaries, etc.) in their original or in a modified
form are provided
\"as is\" and the copyright holders assume no responsibility for its contents
what so ever. Any express or implied warranties, including, but not
limited to, the implied warranties of merchantability and fitness for a
particular purpose are <b>disclaimed</b>. <b>In no event</b> shall the
copyright holders, or any party who modify and/or redistribute the package,
<b>be liable</b> for any direct, indirect, incidental, special, exemplary, or
consequential damages, arising in any way out of the use of this software,
even if advised of the possibility of such damage.
</p>
<br>

<p><b>Copyright &copy; 1999-2002, Modelica Association.</b></p>

</HTML>
"));

  package Blocks "Library for basic input/output control blocks"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;
  annotation (
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
  Discrete      Discrete control blocks (not yet available)
  Logical       Logical and relational operations on Boolean signals
                (not yet available)
  Nonlinear     Discontinuous or non-differentiable algebraic
                control blocks
  Math          Mathematical functions as input/output blocks
  Sources       Sources such as signal generators
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

<p><b>Release Notes:</b></p>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New subpackage Examples, additional components.
       </li>
<li><i>June 20, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
       Michael Tiller:<br>
       Introduced a replaceable signal type into
       Blocks.Interfaces.InPort/OutPort:
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

    package Interfaces "Connectors and partial models for input/output blocks"
      extends Modelica.Icons.Library;
      annotation (Window(
          x=0.05,
          y=0.09,
          width=0.72,
          height=0.71,
          library=1,
          autolayout=1),
        Documentation(info="<HTML>
<p>
This package contains interface definitions for
<b>continuous</b> input/output blocks. In particular it
contains the following <b>connector</b> classes:
</p>

<pre>
  <b>InPort</b>           Connector with input        signals of type Real.
  <b>OutPort</b>          Connector with output       signals of type Real.
  <b>BooleanInPort</b>    Connector with input        signals of type Boolean.
  <b>BooleanOutPort</b>   Connector with output       signals of type Boolean.
  <b>IntegerInPort</b>    Connector with input        signals of type Integer.
  <b>IntegerOutPort</b>   Connector with output       signals of type Integer.

  <b>RealPort</b>         Connector with input/output signals of type Real.
  <b>BooleanPort</b>      Connector with input/output signals of type Real.
  <b>IntegerPort</b>      Connector with input/output signals of type Real.
</pre>

<p>The following <b>partial</b> block classes are provided
to model <b>continuous</b> control blocks:</p>

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

<p><b>Release Notes:</b></p>
<ul>
<li><i>Oct. 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Added several new interfaces. <a href=\"../Documentation/ChangeNotes.html\">Detailed description</a> available.
<li><i>Oct. 24, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       RealInputSignal renamed to InPort. RealOutputSignal renamed to
       OutPort. GraphBlock renamed to BlockIcon. SISOreal renamed to
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

      connector InPort "Connector with input signals of type Real"
        parameter Integer n=1 "Dimension of signal vector";
        replaceable type SignalType = Real "type of signal";
        input SignalType signal[n] "Real input signals";

        annotation (
          Coordsys(extent=[-100, -100; 100, 100]),
          Icon(Polygon(points=[-100, 100; 100, 0; -100, -100; -100, 100], style(
                  color=3, fillColor=3))),
          Diagram(Polygon(points=[-100, 100; 100, 0; -100, -100; -100, 100], style(
                  color=3, fillColor=3)), Text(
              extent=[-100, -120; 100, -220],
              string="%name",
              style(color=3))),
          Terminal(Polygon(points=[-100, 100; 100, 0; -100, -100; -100, 100], style(
                 color=3, fillColor=3))));
      end InPort;

      connector OutPort "Connector with output signals of type Real"
        parameter Integer n=1 "Dimension of signal vector";
        replaceable type SignalType = Real "type of signal";
        output SignalType signal[n] "Real output signals";

        annotation (
          Coordsys(extent=[-100, -100; 100, 100]),
          Icon(Polygon(points=[-100, 100; 100, 0; -100, -100; -100, 100], style(
                  color=3, fillColor=7))),
          Diagram(Polygon(points=[-100, 100; 100, 0; -100, -100; -100, 100], style(
                  color=3, fillColor=7)), Text(
              extent=[-100, -120; 100, -220],
              string="%name",
              style(color=3))),
          Terminal(Polygon(points=[-100, 100; 100, 0; -100, -100; -100, 100], style(
                 color=3, fillColor=7))));
      end OutPort;

      partial block BlockIcon "Basic graphical layout of continuous block"
        annotation (Icon(Rectangle(extent=[-100, -100; 100, 100], style(color=3,
                  fillColor=7)), Text(extent=[-150, 150; 150, 110], string="%name")));
      end BlockIcon;

      partial block MO "Multiple Output continuous control block"
        extends BlockIcon;

        parameter Integer nout(min=1) = 1 "Number of outputs";
        OutPort outPort(final n=nout) "Connector of Real output signals"
          annotation (extent=[100, -10; 120, 10]);
        annotation (
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[2, 2],
            component=[20, 20]),
          Window(
            x=0.13,
            y=0.03,
            width=0.6,
            height=0.6),
          Documentation(info="
"));
        output Real y[nout];
      equation
        y = outPort.signal;
      end MO;

      partial block SignalSource "Base class for continuous signal source"
        extends MO;
        parameter Real offset[:]={0} "offset of output signal";
        parameter SI.Time startTime[:]={0}
        "output = offset for time < startTime";
      end SignalSource;
    end Interfaces;

    package Sources
    "Signal source blocks generating Real, Integer and Boolean signals"
      extends Modelica.Icons.Library;
      annotation (Window(
          x=0.06,
          y=0.1,
          width=0.43,
          height=0.65,
          library=1,
          autolayout=1),
        Documentation(info="<html>
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
</pre>

<p>The following <b>sources</b> are provided to generate <b>Boolean</b> signals:</p>

<pre>
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
All sources are <b>vectorized</b>. This means that the output
is a vector of signals. The number of outputs is in correspondance
to the lenght of the parameter vectors defining the signals. Examples:
</p>

<pre>
    // output.signal[1] = 2*sin(2*pi*2.1);
    // output.signal[2] = 3*sin(2*pi*2.3);
    Modelica.Blocks.Sources.Sine s1(amplitude={2,3}, freqHz={2.1,2.2});

    // output.signal[1] = 3*sin(2*pi*2.1);
    // output.signal[2] = 3*sin(2*pi*2.3);
    Modelica.Blocks.Sources.Sine s2(amplitude={3}, freqHz={2.1,2.3});
</pre>

<p>
The first instance s1 consists of two sinusoidal output signals
with the given amplitudes and frequencies. The second instance s2
consists also of two sinusoidal output signals. Since the
amplitudes are the same for all output signals of s2, this value
has to be provided only once. This approached is used for all
parameters of signal sources: Whenever only a scalar value is
provided for one parameter, then this value is used for all output
signals.
</p>

<p>
All Real source signals (with the exception of the Constant source)
have at least the following two parameters:
</p>

<pre>
   <b>offset</b>       Value which is added to all signal values.
   <b>startTime</b>    Start time of signal. For time < startTime,
                the output is set to offset.
</pre>

<p>
The <b>offset</b> parameter is especially useful in order to shift
the corresponding source, such that at initial time the system
is stationary. To determine the corresponding value of offset,
usually requires a trimming calculation.
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
       Integer sources added. Step, TimeTable and BooleanStep slightly changed
       (see <a href=\"../Documentation/ChangeNotes.html\">Change Notes</a>).</li>

<li><i>November 8, 1999</i>
       by <a href=\"http://www.eas.iis.fhg.de/~clauss/\">Christoph Clau&szlig;</a>,
       <a href=\"http://www.eas.iis.fhg.de/~schneider/\">Andr&eacute; Schneider</a> and
       <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
       (nperiod=-1 is an infinite number of periods).</li>

<li><i>October 31, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>,
       <a href=\"http://www.eas.iis.fhg.de/~clauss/\">Christoph Clau&szlig;</a> and
       <a href=\"http://www.eas.iis.fhg.de/~schneider/\">Andr&eacute; Schneider</a>:
       All sources vectorized. New sources: ExpSine, Trapezoid,
       BooleanConstant, BooleanStep, BooleanPulse, SampleTrigger.
       Improved documentation, especially detailed description of
       signals in diagram layer.</li>

<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
<br>


<p><b>Copyright &copy; 1999-2002, Modelica Association, DLR and Fraunhofer-Gesellschaft.</b></p>

<p><i>
The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i></p>
</HTML>
"));

      block Step "Generate step signals of type Real"
        parameter Real height[:]={1} "Heights of steps";
        extends Interfaces.SignalSource(final nout=max([size(height, 1); size(
              offset, 1); size(startTime, 1)]));
    protected
        parameter Real p_height[nout]=(if size(height, 1) == 1 then ones(nout)*
            height[1] else height);
        parameter Real p_offset[nout]=(if size(offset, 1) == 1 then ones(nout)*
            offset[1] else offset);
        parameter SI.Time p_startTime[nout]=(if size(startTime, 1) == 1 then ones(
            nout)*startTime[1] else startTime);
        annotation (Icon(
            Line(points=[-80, 68; -80, -80], style(color=8)),
            Polygon(points=[-80, 90; -88, 68; -72, 68; -80, 90], style(color=8,
                  fillColor=8)),
            Line(points=[-90, -70; 82, -70], style(color=8)),
            Polygon(points=[90, -70; 68, -62; 68, -78; 90, -70], style(color=8,
                  fillColor=8)),
            Line(points=[-80, -70; 0, -70; 0, 50; 80, 50], style(color=0)),
            Text(
              extent=[-150, -150; 150, -110],
              string="startTime=%startTime",
              style(color=0))), Diagram(
            Polygon(points=[-80, 90; -88, 68; -72, 68; -80, 90], style(color=8,
                  fillColor=8)),
            Line(points=[-80, 68; -80, -80], style(color=8)),
            Line(points=[-80, -18; 0, -18; 0, 50; 80, 50], style(color=0, thickness=
                   2)),
            Line(points=[-90, -70; 82, -70], style(color=8)),
            Polygon(points=[90, -70; 68, -62; 68, -78; 90, -70], style(color=8,
                  fillColor=8)),
            Text(
              extent=[70, -80; 94, -100],
              string="time",
              style(color=9)),
            Text(
              extent=[-21, -72; 25, -90],
              string="startTime",
              style(color=9)),
            Line(points=[0, -17; 0, -71], style(color=8, pattern=2)),
            Text(
              extent=[-68, -36; -22, -54],
              string="offset",
              style(color=9)),
            Line(points=[-13, 50; -13, -17], style(
                color=8,
                pattern=1,
                thickness=1,
                arrow=0)),
            Polygon(points=[2, 50; -19, 50; 2, 50], style(color=8, pattern=2)),
            Polygon(points=[-13, -17; -16, -4; -10, -4; -13, -17; -13, -17], style(
                color=8,
                fillColor=8,
                fillPattern=1)),
            Polygon(points=[-13, 50; -16, 37; -9, 37; -13, 50], style(
                color=8,
                fillColor=8,
                fillPattern=1)),
            Text(
              extent=[-68, 26; -22, 8],
              string="height",
              style(color=9)),
            Polygon(points=[-13, -69; -16, -56; -10, -56; -13, -69; -13, -69],
                style(
                color=8,
                fillColor=8,
                fillPattern=1)),
            Line(points=[-13, -18; -13, -70], style(
                color=8,
                pattern=1,
                thickness=1,
                arrow=0)),
            Polygon(points=[-13, -18; -16, -31; -9, -31; -13, -18], style(
                color=8,
                fillColor=8,
                fillPattern=1)),
            Text(
              extent=[-72, 100; -31, 80],
              string="outPort",
              style(color=9))));
      equation
        for i in 1:nout loop
          outPort.signal[i] = p_offset[i] + (if time < p_startTime[i] then 0 else
            p_height[i]);
        end for;
      end Step;
    end Sources;
  end Blocks;

  package Icons "Icon definitions"
    annotation (
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

  package Mechanics "Library for mechanical systems"
  extends Modelica.Icons.Library2;
  annotation (
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
   <b>Rotational</b>     1-dimensional rotational mechanical components.
   <b>Translational</b>  1-dimensional translational mechanical components.
</pre>

<p>
It is planned to add a subpackage for multibody systems to
model 3-dimensional mechanical systems.
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

    package Rotational "1-dimensional rotational mechanical components"
      import SI = Modelica.SIunits;
      extends Modelica.Icons.Library2;
      annotation (Window(
          x=0.05,
          y=0.09,
          width=0.43,
          height=0.63,
          library=1,
          autolayout=1),
       Documentation(info="<html>
<p>
<b>Content</b><br><br>
1. Overview of library Modelica.Mechanics.Rotational<br>
2. Components of the library<br>
3. Flange connectors<br>
4. Sign conventions<br>
5. User-defined components<br>
6. Requirements for simulation tools
</p><br>

<p><b>1. Overview of library Modelica.Mechanics.Rotational</b></p>

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
<b>unknowns</b> are of type Real, <b>Integer</b> or <b>Boolean</b>.
Provided appropriate numerical algorithms for the solution of such types of
systems are available in the simulation tool, the simulation of
(dynamically) coupled friction elements of this library is
<b>efficient</b> and <b>reliable</b>.
</p>

<IMG SRC=\"../Images/drive1.gif\" ALT=\"drive1\">

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
library can be <b>connected</b> together in an <b>arbitrary</b> way. E.g. it is
possible to connect two springs or two shafts with inertia directly
together, see figure below.
</p>

<IMG SRC=\"../Images/driveConnections.gif\" ALT=\"driveConnections\">

<br><br>


<p><b>2. Components of the library</b></p>

<p>
This package contains the following model components:
</p>

<pre>
   <b>Examples</b>         Sublibrary containing example models.
   <b>Interfaces</b>       Sublibrary containing interface definitions.
   <b>Inertia</b>          Rotational component with inertia.
   <b>IdealGear</b>        Ideal gear transforming rotational in rotational motion.
   <b>IdealPlanetary</b>   Ideal standard planetary gear.
   <b>IdealGearR2T</b>     Ideal gear transforming rotational in translational motion.
   <b>Spring</b>           Linear spring.
   <b>Damper</b>           Linear damper.
   <b>SpringDamper</b>     Linear spring and linear damper in parallel connection.
   <b>ElastoBacklash</b>   Linear spring, linear damper and backlash in series
                    connection (backlash is modeled with elasticity).
   <b>BearingFriction</b>  Coulomb friction in the bearings.
   <b>Clutch</b>           Frictional clutch where the clutch pressure force is an
                    input signal (= Coulomb friction between two flanges).
   <b>OneWayClutch</b>     Parallel connection of free wheel and clutch
   <b>Brake</b>            Frictional brake where the brake pressure force is an
                    input signal (= Coulomb friction between flange
                    and housing).
   <b>LossyGear</b>        Gear with mesh efficiency and bearing friction
                    (stuck/rolling possible)
   <b>GearEfficiency</b>   Efficiency of a gearbox.
   <b>Gear</b>             Realistic model of a gearbox (taking into account
                    efficiency, bearing friction, elasticity, damping, backlash)
   <b>GearNew</b>          Realistic model of a gearbox (taking into account
                    efficiency, bearing friction, elasticity, damping, backlash),
                    based on new component LossyGear
   <b>Position</b>         Forced movement of a flange with a reference angle
                    given as input signal (positive angle for
                    positive input signal).
   <b>Accelerate</b>       Forced movement of a flange with an angular acceleration
                    given as input signal (positive acceleration for
                    positive input signal).
   <b>Move</b>             Forced movement of a flange according to an angle, speed
                    and angular acceleration given as input signals.
   <b>Fixed</b>            Fixing flange in housing at a predefined angle.
   <b>Torque</b>           External torque defined as input signal which accelerates
                    the connected flange for positive input signal.
   <b>RelativeStates</b>   Definition of relative state variables
   <b>Sensors</b>          Sublibrary containing ideal sensors to measure
                    flange variables.
</pre>

<p><b>3. Flange connectors</b></p>

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
     w = der(phi);    a = der(w);

</pre>


<p><b>4. Sign conventions</b></p>

<p>
The variables of a component of this library can be accessed in the
usual way. However, since most of these variables are basically elements
of <b>vectors</b>, i.e., have a direction, the question arises how the
signs of variables shall be interpreted. The basic idea is explained
at hand of the following figure:
</p>

<IMG SRC=\"../Images/drive2.gif\" ALT=\"drive2\">

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

<IMG SRC=\"../Images/drive3.gif\" ALT=\"drive3\">

<p>
The cut-torques <tt>J2.flange_a.tau, J4.flange_a.tau, J6.flange_b.tau</tt>
of the right inertias are all identical and are directed into the
direction of rotation if the values are positive. Similiarily,
the angular velocities <tt>J2.w, J4.w, J6.w</tt> of the right inertias
are all identical and are also directed into the
direction of rotation if the values are positive. Some special
cases are shown in the next figure:
</p>

<IMG SRC=\"../Images/drive4.gif\" ALT=\"drive4\">

<p>
In the upper part of the figure, two variants of the connection of an
external torque and an inertia are shown. In both cases, a positive
signal input into the torque component accelerates the inertias
<tt>inertia1, inertia2</tt> into the positive axis of rotation,
i.e., the angular accelerations <tt>inertia1.a, inertia2.a</tt>
are positive and are directed along the \"axis of rotation\" arrow.
In the lower part of the figure the connection of inertias with
a planetary gear are shown. Note, that the three flanges of the
planetary gearbox are located along the axis of rotation and that
the axis direction determines the positive rotation along these
flanges. As a result, the positive rotation for <tt>inertia4, inertia6</tt>
is as indicated with the additional grey arrows.
</p><br>


<p><b>5. User-defined components</b></p>

<p>
In this section some hints are given to define your own
1-dimensional rotational components which are compatible with the
elements of this package.
It is convenient to define a new
component by inheritance from one of the following base classes,
which are defined in sublibrary Interfaces:
</p>

<pre>
  <b>Rigid</b>            Rigid connection of two rotational 1D flanges
                   (used for elements with inertia).
  <b>Compliant</b>        Compliant connection of two rotational 1D flanges
                   (used for force laws such as a spring or a damper).
  <b>TwoFlanges</b>       General connection of two rotational 1D flanges
                   (used for gearboxes).
  <b>AbsoluteSensor</b>   Measure absolute flange variables.
  <b>RelativeSensor</b>   Measure relative flange variables.
</pre>

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

<IMG SRC=\"../Images/driveAxis.gif\" ALT=\"driveAxis\">

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

<IMG SRC=\"../Images/inertias.gif\" ALT=\"inertias\">

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
Note, that the simple rule stated in section 4. (Sign conventions)
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
</p><br>


<p><b>6. Requirements for simulation tools</b></p>

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
Coulomb friction elements <b>BearingFriction, Clutch, Brake</b> when
the elements become stuck:
</p>

<IMG SRC=\"../Images/driveConnections2.gif\" ALT=\"driveConnections2\">

<p>
In the figure above two typical situations are shown: In the upper part of
the figure, the series connection of rigidly attached BearingFriction and
Clutch components are shown. This does not hurt, because the BearingFriction
element can lock the relative motion between the element and the housing,
whereas the clutch element can lock the relative motion between the two
connected flanges. Contrary, the drive train in the lower part of the figure
may give rise to simulation problems, because the BearingFriction element
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
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New components <b>LossyGear</b> (with corresponding examples) and <b>GearNew</b>.<br>
       Interface <b>FrictionBase</b> adapted to new initialization.</li>
<li><i>June 19, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New elements:
<pre>
   IdealGearR2T    Ideal gear transforming rotational in translational motion.
   Position        Forced movement of a flange with a reference angle
                   given as input signal
   RelativeStates  Definition of relative state variables
</pre>
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
       Advice given from P. Beater, H. Elmqvist, S.E.-Mattsson, H. Olsson
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
<br>


<p><b>Copyright &copy; 1999-2002, 2000-2002, Modelica Association and DLR.</b></p>

<p><i>
The Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i></p>

</HTML>
"),     Icon(
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
        annotation (Window(
            x=0.07,
            y=0.13,
            width=0.43,
            height=0.52,
            library=1,
            autolayout=1),Documentation(info="<html>
<p>
This package contains connectors and partial models for 1D rotational mechanical
components. In particular
</p>

<pre>
  <b>Flange_a</b>         Left flange of a component.
  <b>Flange_b</b>         Right flange of a component.
  <b>Rigid</b>            Rigid connection of two rotational 1D flanges
                   (used for elements with inertia).
  <b>Compliant</b>        Compliant connection of two rotational 1D flanges
                   (used for force laws such as a spring or a damper).
  <b>TwoFlanges</b>       Component with two rotational 1D flanges
  <b>AbsoluteSensor</b>   Base class to measure absolute flange variables.
  <b>Relative Sensor</b>  Base class to measure relative flange variables.
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

<p><b>Copyright &copy; 1999-2002, Modelica Association and DLR.</b></p>

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
          annotation (
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
"),         Icon(Rectangle(extent=[-100, -100; 100, 100], style(color=0, fillColor=
                      10))),
            Diagram(Rectangle(extent=[-100, -100; 100, 100], style(color=0,
                    fillColor=10)), Text(
                extent=[-100, -120; 100, -220],
                string="%name",
                style(color=0))),
            Terminal(Rectangle(extent=[-100, -100; 100, 100], style(color=0,
                    fillColor=10))));
        end Flange_a;

        connector Flange_b "1D rotational flange (non-filled square icon)"
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
          annotation (
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
"),         Icon(Rectangle(extent=[-100, -100; 100, 100], style(color=0, fillColor=
                      7))),
            Diagram(Rectangle(extent=[-100, -100; 100, 100], style(color=0,
                    fillColor=7)), Text(
                extent=[-100, -120; 100, -220],
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
It is used e.g. to built up parts of a drive train consisting
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
      end Interfaces;

      model Inertia "1D-rotational component with inertia"
        extends Interfaces.Rigid;
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
            Rectangle(extent=[-90, 10; -50, -10], style(
                color=0,
                gradient=2,
                fillColor=8)),
            Rectangle(extent=[50, 10; 90, -10], style(
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
            Rectangle(extent=[-90, 10; -50, -10], style(
                color=0,
                gradient=2,
                fillColor=8)),
            Rectangle(extent=[50, 10; 90, -10], style(
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
      equation
        w = der(phi);
        a = der(w);
        J*a = flange_a.tau + flange_b.tau;
      end Inertia;

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
            Text(extent=[-124, 126; 125, 65], string="%name=%c")),
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
            Line(points=[-90, 0; -80, 0], style(color=0)),
            Line(points=[90, 0; 80, 0], style(color=0)),
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

      model NonLinearSpringDamper "Linear 1D rotational spring and damper in parallel"
        extends Interfaces.Compliant;
        parameter Real c(final unit="N.m/rad", final min=0) "Spring constant";
        parameter SI.Angle phi_rel0=0 "Unstretched spring angle";
        parameter Real d(
          final unit="N.m.s/rad",
          final min=0) = 0 "Damping constant";
        SI.AngularVelocity w_rel
        "Relative angular velocity between flange_b and flange_a";
  SI.Angle phi_abs=phi_rel-phi_rel0;
      equation
        w_rel = der(phi_rel);
        tau = c*(phi_abs) + sqrt(abs(phi_abs))*(phi_abs)*(phi_abs)*(phi_abs)/exp(abs(phi_abs)) + d*w_rel +w_rel*w_rel/exp(abs(w_rel));
      end NonLinearSpringDamper;

      model Torque "Input signal acting as external torque on a flange"
        SI.Torque tau "Torque (a positive value accelerates the flange)";
        Modelica.Blocks.Interfaces.InPort inPort(final n=1)
        "Connector of input signal used as torque"   annotation (extent=[-140, -20;
                -100, 20]);
        Interfaces.Flange_b flange_b "(Right) flange" annotation (extent=[90, -10;
              110, 10]);
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
The input signal <b>inPort.signal[1]</b> defines an external
torque <b>tau</b> in [Nm] which acts (with negative sign) at
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
              extent=[-100, -40; 10, -90],
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
                fillPattern=1))),
          Diagram(
            Text(extent=[-124, 37; -95, 13], string="tau"),
            Text(
              extent=[15, -71; 83, -84],
              string="rotation axis",
              style(color=10)),
            Polygon(points=[11, -77; -9, -72; -9, -82; 11, -77], style(color=10,
                  fillColor=10)),
            Line(points=[-79, -77; -8, -77], style(color=10, fillColor=10)),
            Line(points=[-88, 0; -64, 30; -36, 52; -2, 62; 28, 56; 48, 44; 64, 28;
                  76, 14; 80, 10], style(
                color=0,
                thickness=2,
                fillColor=0)),
            Polygon(points=[86, 0; 66, 58; 38, 28; 86, 0], style(
                color=0,
                fillColor=0,
                fillPattern=1))));
      equation
        tau = inPort.signal[1];
        flange_b.tau = -tau;
      end Torque;
    end Rotational;
  end Mechanics;

  package SIunits "Type definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Library2;

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

    type MomentOfInertia = Real (final quantity="MomentOfInertia", final unit=
            "kg.m2");

    type Inertia = MomentOfInertia;

    type Torque = Real (final quantity="Torque", final unit="N.m");
    annotation (
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

model FlexibleShaft "model of a flexible shaft"
  extends Modelica.Mechanics.Rotational.Interfaces.TwoFlanges;
  parameter Integer n(min=1) = 2 "number of shaft elements";
  ShaftElement shaft[n];
equation
  for i in 2:n loop
    connect(shaft[i-1].flange_b,shaft[i].flange_a);
  end for;
  connect(shaft[1].flange_a,flange_a);
  connect(shaft[n].flange_b,flange_b);
end FlexibleShaft;

model ShaftTest
  FlexibleShaft shaft(n=2);
  Modelica.Mechanics.Rotational.Torque src;
  Modelica.Blocks.Sources.Step c;
equation
  connect(shaft.flange_a,src.flange_b);
  connect(c.outPort,src.inPort);
end ShaftTest;
// Result:
// class ShaftTest
//   Real shaft.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real shaft.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Integer shaft.n(min = 1) = 2 "number of shaft elements";
//   Real shaft.shaft[1].flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[1].flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real shaft.shaft[1].flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[1].flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real shaft.shaft[1].inertia1.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of component (= flange_a.phi = flange_b.phi)";
//   Real shaft.shaft[1].inertia1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[1].inertia1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real shaft.shaft[1].inertia1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[1].inertia1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real shaft.shaft[1].inertia1.J(quantity = "MomentOfInertia", unit = "kg.m2") = 1.0 "Moment of inertia";
//   Real shaft.shaft[1].inertia1.w(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of component";
//   Real shaft.shaft[1].inertia1.a(quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of component";
//   Real shaft.shaft[1].springDamper1.phi_rel(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
//   Real shaft.shaft[1].springDamper1.tau(quantity = "Torque", unit = "N.m") "Torque between flanges (= flange_b.tau)";
//   Real shaft.shaft[1].springDamper1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[1].springDamper1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real shaft.shaft[1].springDamper1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[1].springDamper1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real shaft.shaft[1].springDamper1.c(unit = "N.m/rad", min = 0.0) = 500.0 "Spring constant";
//   parameter Real shaft.shaft[1].springDamper1.phi_rel0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Unstretched spring angle";
//   parameter Real shaft.shaft[1].springDamper1.d(unit = "N.m.s/rad", min = 0.0) = 5.0 "Damping constant";
//   Real shaft.shaft[1].springDamper1.w_rel(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between flange_b and flange_a";
//   Real shaft.shaft[1].springDamper1.phi_abs(quantity = "Angle", unit = "rad", displayUnit = "deg") = shaft.shaft[1].springDamper1.phi_rel - shaft.shaft[1].springDamper1.phi_rel0;
//   Real shaft.shaft[2].flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[2].flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real shaft.shaft[2].flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[2].flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real shaft.shaft[2].inertia1.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of component (= flange_a.phi = flange_b.phi)";
//   Real shaft.shaft[2].inertia1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[2].inertia1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real shaft.shaft[2].inertia1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[2].inertia1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real shaft.shaft[2].inertia1.J(quantity = "MomentOfInertia", unit = "kg.m2") = 1.0 "Moment of inertia";
//   Real shaft.shaft[2].inertia1.w(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Absolute angular velocity of component";
//   Real shaft.shaft[2].inertia1.a(quantity = "AngularAcceleration", unit = "rad/s2") "Absolute angular acceleration of component";
//   Real shaft.shaft[2].springDamper1.phi_rel(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
//   Real shaft.shaft[2].springDamper1.tau(quantity = "Torque", unit = "N.m") "Torque between flanges (= flange_b.tau)";
//   Real shaft.shaft[2].springDamper1.flange_a.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[2].springDamper1.flange_a.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   Real shaft.shaft[2].springDamper1.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real shaft.shaft[2].springDamper1.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Real shaft.shaft[2].springDamper1.c(unit = "N.m/rad", min = 0.0) = 500.0 "Spring constant";
//   parameter Real shaft.shaft[2].springDamper1.phi_rel0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Unstretched spring angle";
//   parameter Real shaft.shaft[2].springDamper1.d(unit = "N.m.s/rad", min = 0.0) = 5.0 "Damping constant";
//   Real shaft.shaft[2].springDamper1.w_rel(quantity = "AngularVelocity", unit = "rad/s", displayUnit = "rev/min") "Relative angular velocity between flange_b and flange_a";
//   Real shaft.shaft[2].springDamper1.phi_abs(quantity = "Angle", unit = "rad", displayUnit = "deg") = shaft.shaft[2].springDamper1.phi_rel - shaft.shaft[2].springDamper1.phi_rel0;
//   Real src.tau(quantity = "Torque", unit = "N.m") "Torque (a positive value accelerates the flange)";
//   parameter Integer src.inPort.n = 1 "Dimension of signal vector";
//   Real src.inPort.signal[1] "Real input signals";
//   Real src.flange_b.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   Real src.flange_b.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   parameter Integer c.nout(min = 1) = 1 "Number of outputs";
//   parameter Integer c.outPort.n = c.nout "Dimension of signal vector";
//   Real c.outPort.signal[1] "Real output signals";
//   Real c.y[1];
//   parameter Real c.offset[1] = 0.0 "offset of output signal";
//   parameter Real c.startTime[1](quantity = "Time", unit = "s") = 0.0 "output = offset for time < startTime";
//   parameter Real c.height[1] = 1.0 "Heights of steps";
//   protected parameter Real c.p_height[1] = c.height[1];
//   protected parameter Real c.p_offset[1] = c.offset[1];
//   protected parameter Real c.p_startTime[1](quantity = "Time", unit = "s") = c.startTime[1];
// equation
//   shaft.shaft[1].inertia1.w = der(shaft.shaft[1].inertia1.phi);
//   shaft.shaft[1].inertia1.a = der(shaft.shaft[1].inertia1.w);
//   shaft.shaft[1].inertia1.J * shaft.shaft[1].inertia1.a = shaft.shaft[1].inertia1.flange_a.tau + shaft.shaft[1].inertia1.flange_b.tau;
//   shaft.shaft[1].inertia1.flange_a.phi = shaft.shaft[1].inertia1.phi;
//   shaft.shaft[1].inertia1.flange_b.phi = shaft.shaft[1].inertia1.phi;
//   shaft.shaft[1].springDamper1.w_rel = der(shaft.shaft[1].springDamper1.phi_rel);
//   shaft.shaft[1].springDamper1.tau = shaft.shaft[1].springDamper1.c * shaft.shaft[1].springDamper1.phi_abs + sqrt(abs(shaft.shaft[1].springDamper1.phi_abs)) * shaft.shaft[1].springDamper1.phi_abs ^ 3.0 * exp(-abs(shaft.shaft[1].springDamper1.phi_abs)) + shaft.shaft[1].springDamper1.d * shaft.shaft[1].springDamper1.w_rel + shaft.shaft[1].springDamper1.w_rel ^ 2.0 * exp(-abs(shaft.shaft[1].springDamper1.w_rel));
//   shaft.shaft[1].springDamper1.phi_rel = shaft.shaft[1].springDamper1.flange_b.phi - shaft.shaft[1].springDamper1.flange_a.phi;
//   shaft.shaft[1].springDamper1.flange_b.tau = shaft.shaft[1].springDamper1.tau;
//   shaft.shaft[1].springDamper1.flange_a.tau = -shaft.shaft[1].springDamper1.tau;
//   shaft.shaft[2].inertia1.w = der(shaft.shaft[2].inertia1.phi);
//   shaft.shaft[2].inertia1.a = der(shaft.shaft[2].inertia1.w);
//   shaft.shaft[2].inertia1.J * shaft.shaft[2].inertia1.a = shaft.shaft[2].inertia1.flange_a.tau + shaft.shaft[2].inertia1.flange_b.tau;
//   shaft.shaft[2].inertia1.flange_a.phi = shaft.shaft[2].inertia1.phi;
//   shaft.shaft[2].inertia1.flange_b.phi = shaft.shaft[2].inertia1.phi;
//   shaft.shaft[2].springDamper1.w_rel = der(shaft.shaft[2].springDamper1.phi_rel);
//   shaft.shaft[2].springDamper1.tau = shaft.shaft[2].springDamper1.c * shaft.shaft[2].springDamper1.phi_abs + sqrt(abs(shaft.shaft[2].springDamper1.phi_abs)) * shaft.shaft[2].springDamper1.phi_abs ^ 3.0 * exp(-abs(shaft.shaft[2].springDamper1.phi_abs)) + shaft.shaft[2].springDamper1.d * shaft.shaft[2].springDamper1.w_rel + shaft.shaft[2].springDamper1.w_rel ^ 2.0 * exp(-abs(shaft.shaft[2].springDamper1.w_rel));
//   shaft.shaft[2].springDamper1.phi_rel = shaft.shaft[2].springDamper1.flange_b.phi - shaft.shaft[2].springDamper1.flange_a.phi;
//   shaft.shaft[2].springDamper1.flange_b.tau = shaft.shaft[2].springDamper1.tau;
//   shaft.shaft[2].springDamper1.flange_a.tau = -shaft.shaft[2].springDamper1.tau;
//   src.tau = src.inPort.signal[1];
//   src.flange_b.tau = -src.tau;
//   c.outPort.signal[1] = c.p_offset[1] + (if time < c.p_startTime[1] then 0.0 else c.p_height[1]);
//   c.y[1] = c.outPort.signal[1];
//   assert(c.outPort.n == src.inPort.n, "automatically generated from connect");
//   shaft.flange_a.tau + src.flange_b.tau = 0.0;
//   shaft.flange_b.tau = 0.0;
//   shaft.shaft[2].flange_a.tau + shaft.shaft[1].flange_b.tau = 0.0;
//   (-shaft.flange_b.tau) + shaft.shaft[2].flange_b.tau = 0.0;
//   (-shaft.shaft[2].flange_a.tau) + shaft.shaft[2].inertia1.flange_a.tau = 0.0;
//   shaft.shaft[2].inertia1.flange_b.tau + shaft.shaft[2].springDamper1.flange_a.tau = 0.0;
//   (-shaft.shaft[2].flange_b.tau) + shaft.shaft[2].springDamper1.flange_b.tau = 0.0;
//   shaft.shaft[2].inertia1.flange_b.phi = shaft.shaft[2].springDamper1.flange_a.phi;
//   shaft.shaft[2].flange_a.phi = shaft.shaft[2].inertia1.flange_a.phi;
//   shaft.shaft[2].flange_b.phi = shaft.shaft[2].springDamper1.flange_b.phi;
//   (-shaft.flange_a.tau) + shaft.shaft[1].flange_a.tau = 0.0;
//   (-shaft.shaft[1].flange_a.tau) + shaft.shaft[1].inertia1.flange_a.tau = 0.0;
//   shaft.shaft[1].inertia1.flange_b.tau + shaft.shaft[1].springDamper1.flange_a.tau = 0.0;
//   (-shaft.shaft[1].flange_b.tau) + shaft.shaft[1].springDamper1.flange_b.tau = 0.0;
//   shaft.shaft[1].inertia1.flange_b.phi = shaft.shaft[1].springDamper1.flange_a.phi;
//   shaft.shaft[1].flange_a.phi = shaft.shaft[1].inertia1.flange_a.phi;
//   shaft.shaft[1].flange_b.phi = shaft.shaft[1].springDamper1.flange_b.phi;
//   shaft.shaft[1].flange_b.phi = shaft.shaft[2].flange_a.phi;
//   shaft.flange_a.phi = shaft.shaft[1].flange_a.phi;
//   shaft.flange_b.phi = shaft.shaft[2].flange_b.phi;
//   shaft.flange_a.phi = src.flange_b.phi;
//   c.outPort.signal[1] = src.inPort.signal[1];
// end ShaftTest;
// endResult
