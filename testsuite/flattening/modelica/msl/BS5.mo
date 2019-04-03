// name:     BS5 - KinematicPTP component
// keywords: KinematicPTP
// status:   correct
//
// Testing instantiation of the KinematicPTP component.
//
package Modelica "Modelica Standard Library"
   extends Icons.Library;
   annotation (Documentation(info="
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
     annotation (Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),Icon(
        coordinateSystem(                                                                            extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-32.,-6.},{16.,-35.}},lineColor={0,0,0}),Rectangle(extent={{-32.,-56.},{16.,-85.}},lineColor={0,0,0}),Line(points={{16.,-20.},{49.,-20.},{49.,-71.},{16.,-71.}},color={0,0,0}),Line(points={{-32.,-72.},{-64.,-72.},{-64.,-21.},{-32.,-21.}},color={0,0,0}),Polygon(points={{16.,-71.},{29.,-67.},{29.,-74.},{16.,-71.}},lineColor={0,0,0},fillColor={0,0,0},fillPattern=FillPattern.Solid),Polygon(points={{-32.,-21.},{-46.,-17.},{-46.,-25.},{-32.,-21.}},lineColor={0,0,0},fillColor={0,0,0},fillPattern=FillPattern.Solid)}),
      Documentation(                                                                                                    info="<html>
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

    package Continuous "Continuous control blocks with internal states"
       extends Modelica.Icons.Library;
       annotation (Documentation(info="<html>
 <p>
 This package contains basic <b>continuous</b> input/output blocks.
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
 <li><i>June 30, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized a first version, based on an existing Dymola library
        of Dieter Moormann and Hilding Elmqvist.
 </li>
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

       block Der "Derivative of input (= analytic differentations)"
          extends Interfaces.MIMOs;
          annotation (Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),Icon(
            coordinateSystem(                                                                             extent={{-100.,-100.},{100.,100.}}),graphics={Text(extent={{-80.,76.},{80.,-82.}},textString="der()",fillColor={0,0,255})}),
          Documentation(                                                                                                    info="<HTML>
 <p>
 Defines that the output (= outPort.signal) is the <i>derivative</i>
 of the input (=inPort.signal). Note, that Modelica.Blocks.Continuous.Derivative
 computes the derivative in an approximate sense, where this block computes
 the derivative exactly. This requires that the input signals are differentiated
 by the Modelica translator, if these derivatives are not yet present in
 the model.
 </p>
 </HTML>"));

       equation
          for i in 1:n loop
             y[i] = der(u[i]);
          end for;
       end Der;
    end Continuous;

    package Interfaces "Connectors and partial models for input/output blocks"
       extends Modelica.Icons.Library;
       annotation (Documentation(info="<HTML>
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
        Added several new interfaces. <a href=\"../Documentation/ChangeNotes1.5.html\">Detailed description</a> available.
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
          annotation (Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Polygon(points={{-100.,100.},{100.,0.},{-100.,-100.},{-100.,100.}},lineColor={0,0,255},fillColor={0,0,255},fillPattern=FillPattern.Solid)}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Polygon(points={{-100.,100.},{100.,0.},{-100.,-100.},{-100.,100.}},lineColor={0,0,255},fillColor={0,0,255},fillPattern=FillPattern.Solid),Text(extent={{-100.,-120.},{100.,-220.}},textString="%name",fillColor={0,0,255})}));
       end InPort;

       connector OutPort "Connector with output signals of type Real"
          parameter Integer n=1 "Dimension of signal vector";
          replaceable type SignalType = Real "type of signal";
          output SignalType signal[n] "Real output signals";
          annotation (Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Polygon(points={{-100.,100.},{100.,0.},{-100.,-100.},{-100.,100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid)}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Polygon(points={{-100.,100.},{100.,0.},{-100.,-100.},{-100.,100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid),Text(extent={{-100.,-120.},{100.,-220.}},textString="%name",fillColor={0,0,255})}));
       end OutPort;

       partial block BlockIcon "Basic graphical layout of continuous block"
          annotation (Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),Icon(
            coordinateSystem(                                                                             extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-100.,-100.},{100.,100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid),Text(extent={{-150.,150.},{150.,110.}},textString="%name",fillColor={0,0,255})}));
       end BlockIcon;

       partial block MO "Multiple Output continuous control block"
          extends BlockIcon;
          parameter Integer nout(min=1)=1 "Number of outputs";
          OutPort outPort(final n=nout) "Connector of Real output signals" annotation (Placement(
            transformation(                                                                                     x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          annotation (Documentation(info="
 "));
          output Real y[nout];

       equation
          y = outPort.signal;
       end MO;

       partial block MIMOs
      "Multiple Input Multiple Output continuous control block with same number of inputs and outputs"
          extends BlockIcon;
          parameter Integer n=1 "Number of inputs (= number of outputs)";
          InPort inPort(final n=n) "Connector of Real input signals" annotation (Placement(
            transformation(                                                                               x=-120.,y=0.,scale=0.2,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=-120.,y=0.,scale=0.2,
              aspectRatio =                                                                                                    1.)));
          OutPort outPort(final n=n) "Connector of Real output signals" annotation (Placement(
            transformation(                                                                                  x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          output Real y[n] "Output signals";
          annotation (Documentation(info="<HTML>
 <p>
 Block has a continuous input and a continuous output signal vector
 where the signal sizes of the input and output vector are identical.
 </p>
 </HTML>
 "));

    protected
          Real u[:]=inPort.signal "Input signals";

       equation
          y = outPort.signal;
       end MIMOs;
    end Interfaces;

    package Sources
    "Signal source blocks generating Real, Integer and Boolean signals"
       extends Modelica.Icons.Library;
       annotation (Documentation(info="<html>
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
        (see <a href=\"../Documentation/ChangeNotes1.5.html\">Change Notes</a>).</li>

 <li><i>November 8, 1999</i>
        by <a href=\"http://people.eas.iis.fhg.de/Christoph.Clauss/\">Christoph Clau&szlig;</a>,
        <a href=\"http://people.eas.iis.fhg.de/Andre.Schneider/\">Andr&eacute; Schneider</a> and
        <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
        (nperiod=-1 is an infinite number of periods).</li>

 <li><i>October 31, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>,
        <a href=\"http://people.eas.iis.fhg.de/Christoph.Clauss/\">Christoph Clau&szlig;</a> and
        <a href=\"http://people.eas.iis.fhg.de/Andre.Schneider/\">Andr&eacute; Schneider</a>:
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

       block KinematicPTP
      "Move as fast as possible along a distance within given kinematic constraints"
          parameter Real deltaq[:]={1} "Distance to move";
          parameter Real qd_max[:](final min=Modelica.Constants.small)={1}
        "Maximum velocities der(q)";
          parameter Real qdd_max[:](final min=Modelica.Constants.small)={1}
        "Maximum accelerations der(qd)";
          parameter SI.Time startTime=0 "Time instant at which movement starts";
          extends Interfaces.MO(final nout=max([size(deltaq,1); size(qd_max,1); size(qdd_max,1)]));

    protected
          parameter Real p_deltaq[nout]=if size(deltaq,1) == 1 then
             ones(nout)*deltaq[1] else
             deltaq;
          parameter Real p_qd_max[nout]=if size(qd_max,1) == 1 then
             ones(nout)*qd_max[1] else
             qd_max;
          parameter Real p_qdd_max[nout]=if size(qdd_max,1) == 1 then
             ones(nout)*qdd_max[1] else
             qdd_max;
          Real sd_max;
          Real sdd_max;
          Real sdd;
          Real aux1[nout];
          Real aux2[nout];
          SI.Time Ta1;
          SI.Time Ta2;
          SI.Time Tv;
          SI.Time Te;
          Boolean noWphase;
          annotation (Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Line(points={{-80.,78.},{-80.,-82.}},color={192,192,192}),Polygon(points={{-80.,90.},{-88.,68.},{-72.,68.},{-80.,88.},{-80.,90.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-90.,0.},{82.,0.}},color={192,192,192}),Polygon(points={{90.,0.},{68.,8.},{68.,-8.},{90.,0.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-80.,0.},{-70.,0.},{-70.,70.},{-30.,70.},{-30.,0.},{20.,0.},{20.,-70.},{60.,-70.},{60.,0.},{68.,0.}},color={0,0,0},thickness=0.25),Text(extent={{2.,80.},{80.,20.}},textString="acc",fillColor={192,192,192}),Text(extent={{-150.,-150.},{150.,-110.}},textString="deltaq=%deltaq",fillColor={0,0,0})}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-100.,-100.},{100.,100.}},lineColor={0,0,255},fillColor={0,0,0},fillPattern=FillPattern.Solid),Line(points={{-80.,78.},{-80.,-82.}},color={192,192,192}),Polygon(points={{-80.,90.},{-88.,68.},{-72.,68.},{-80.,88.},{-80.,90.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-90.,0.},{82.,0.}},color={192,192,192}),Polygon(points={{90.,0.},{68.,8.},{68.,-8.},{90.,0.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-80.,0.},{-70.,0.},{-70.,70.},{-30.,70.},{-30.,0.},{20.,0.},{20.,-70.},{60.,-70.},{60.,0.},{68.,0.}},color={0,0,0},thickness=0.5),Text(extent={{-76.,98.},{-19.,83.}},textString="acceleration",fillColor={192,192,192}),Text(extent={{69.,24.},{91.,12.}},textString="time",fillColor={192,192,192})}),
          Documentation(                                                                                                    info="<html>
 <p>
 The goal is to move as <b>fast</b> as possible along a distance
 <b>deltaq</b>
 under given <b>kinematical constraints</b>. The distance can be a positional or
 angular range. In robotics such a movement is called <b>PTP</b> (Point-To-Point).
 This source block generates the <b>acceleration</b> qdd of this signal
 as output. After integrating the output two times, the position q is
 obtained. The signal is constructed in such a way that it is not possible
 to move faster, given the <b>maximally</b> allowed <b>velocity</b> qd_max and
 the <b>maximally</b> allowed <b>acceleration</b> qdd_max.
 </p>

 <p>
 If several distances are given (vector deltaq has more than 1 element),
 an acceleration output vector is constructed such that all signals
 are in the same periods in the acceleration, constant velocity
 and deceleration phase. This means that only one of the signals
 is at its limits whereas the others are sychnronized in such a way
 that the end point is reached at the same time instant.
 </p>

 <p>
 This element is useful to generate a reference signal for a controller
 which controls a drive train or in combination with model
 Modelica.Mechanics.Rotational.<b>Accelerate</b> to drive
 a flange according to a given acceleration.
 </p>

 <p><b>Release Notes:</b></p>
 <ul>
 <li><i>June 27, 2001</i>
        by Bernhard Bachmann.<br>
        Bug fixed that element is also correct if startTime is not zero.</li>

 <li><i>Nov. 3, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Vectorized and moved from Rotational to Blocks.Sources.</li>

 <li><i>June 29, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        realized.</li>
 </ul>

 </HTML>
 "));

       equation
          for i in 1:nout loop
             aux1[i] = p_deltaq[i]/p_qd_max[i];
             aux2[i] = p_deltaq[i]/p_qdd_max[i];
          end for;
          sd_max = 1/max(abs(aux1));
          sdd_max = 1/max(abs(aux2));
          Ta1 = sqrt(1/sdd_max);
          Ta2 = sd_max/sdd_max;
          noWphase = Ta2 >= Ta1;
          Tv = if noWphase then
             Ta1 else
             1/sd_max;
          Te = if noWphase then
             Ta1+Ta1 else
             Tv+Ta2;
          sdd = if time < startTime then
             0 else
             if noWphase then
                if time < Ta1+startTime then
                   sdd_max else
                   if time < Te+startTime then
                      -sdd_max else
                      0 else
                if time < Ta2+startTime then
                   sdd_max else
                   if time < Tv+startTime then
                      0 else
                      if time < Te+startTime then
                         -sdd_max else
                         0;
          outPort.signal = p_deltaq*sdd;
       end KinematicPTP;
    end Sources;
  end Blocks;

  package Constants "Mathematical constants and constants of nature"
     import SI = Modelica.SIunits;
     import NonSI = Modelica.SIunits.Conversions.NonSIunits;
     extends Modelica.Icons.Library2;

     constant Real small=1.e-60
    "Smallest number such that small and -small are representable on the machine";
     annotation (Documentation(info="<html>
 <p>
 This package provides often needed constants from mathematics, machine
 dependent constants and constants from nature. The latter constants
 (name, value, description) are from the following source:
 </p>

 <dl>
 <dt>Peter J. Mohr and Barry N. Taylor (1999):
 <dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 1998</b>.
        Journal of Physical and Chemical Reference Data, Vol. 28, No. 6, 1999 and
        Reviews of Modern Physics, Vol. 72, No. 2, 2000. See also
        <a href=\"http://physics.nist.gov/cuu/Constants/\">
                  http://physics.nist.gov/cuu/Constants/</a>
 </dl>
 <br>

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
 <li><i>Dec. 9, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Constants updated according to 1998 CODATA values. Using names, values
        and description text from this source. Included magnetic and
        electric constant.</li>
 <li><i>Sept. 18, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Constants EPS, INF, SMALL introduced.</li>
 <li><i>Nov 15, 1997</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized.</li>
 </ul>
 <br>


 <p><b>Copyright &copy; 1999-2002, Modelica Association and DLR.</b></p>

 <p><i>
 The Modelica package is free software; it can be redistributed and/or modified
 under the terms of the <b>Modelica license</b>, see the license conditions
 and the accompanying <b>disclaimer</b> in the documentation of package
 Modelica in file \"Modelica/package.mo\".
 </i></p>
 </HTML>
 "),  Invisible=true,Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Line(points={{-34.,-38.},{12.,-38.}},color={0,0,0},thickness=0.5),Line(points={{-20.,-38.},{-24.,-48.},{-28.,-56.},{-34.,-64.}},color={0,0,0},thickness=0.5),Line(points={{-2.,-38.},{2.,-46.},{8.,-56.},{14.,-64.}},color={0,0,0},thickness=0.5)}),Diagram(
        coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{200.,162.},{380.,312.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{200.,312.},{220.,332.},{400.,332.},{380.,312.},{200.,312.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{400.,332.},{400.,182.},{380.,162.},{380.,312.},{400.,332.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Text(extent={{210.,302.},{370.,272.}},textString="Library",fillColor={160,160,160},fillPattern=FillPattern.Solid),Line(points={{266.,224.},{312.,224.}},color={0,0,0},thickness=1.),Line(points={{280.,224.},{276.,214.},{272.,206.},{266.,198.}},color={0,0,0},thickness=1.),Line(points={{298.,224.},{302.,216.},{308.,206.},{314.,198.}},color={0,0,0},thickness=1.),Text(extent={{152.,412.},{458.,334.}},textString="Modelica.Constants",fillColor={255,0,0})}));
  end Constants;

  package Icons "Icon definitions"
     annotation (Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),Icon(
        coordinateSystem(                                                                            extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-100.,-100.},{80.,50.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{-100.,50.},{-80.,70.},{100.,70.},{80.,50.},{-100.,50.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{100.,70.},{100.,-80.},{80.,-100.},{80.,50.},{100.,70.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Text(extent={{-120.,135.},{120.,70.}},textString="%name",fillColor={255,0,0}),Text(extent={{-90.,40.},{70.,10.}},textString="Library",fillColor={160,160,160},fillPattern=FillPattern.Solid),Rectangle(extent={{-100.,-100.},{80.,50.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{-100.,50.},{-80.,70.},{100.,70.},{80.,50.},{-100.,50.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{100.,70.},{100.,-80.},{80.,-100.},{80.,50.},{100.,70.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Text(extent={{-90.,40.},{70.,10.}},textString="Library",fillColor={160,160,160},fillPattern=FillPattern.Solid),Polygon(points={{-64.,-20.},{-50.,-4.},{50.,-4.},{36.,-20.},{-64.,-20.},{-64.,-20.}},lineColor={0,0,0},fillColor={192,192,192},fillPattern=FillPattern.Solid),Rectangle(extent={{-64.,-20.},{36.,-84.}},lineColor={0,0,0},fillColor={192,192,192},fillPattern=FillPattern.Solid),Text(extent={{-60.,-24.},{32.,-38.}},textString="Library",fillColor={128,128,128},fillPattern=FillPattern.Solid),Polygon(points={{50.,-4.},{50.,-70.},{36.,-84.},{36.,-20.},{50.,-4.}},lineColor={0,0,0},fillColor={192,192,192},fillPattern=FillPattern.Solid)}),
      Documentation(                                                                                                    info="<html>
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
        annotation (Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),Icon(
          coordinateSystem(                                                                             extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-100.,-100.},{80.,50.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{-100.,50.},{-80.,70.},{100.,70.},{80.,50.},{-100.,50.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{100.,70.},{100.,-80.},{80.,-100.},{80.,50.},{100.,70.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Text(extent={{-85.,35.},{65.,-85.}},textString="Library",fillColor={0,0,255}),Text(extent={{-120.,122.},{120.,73.}},textString="%name",fillColor={255,0,0})}));
     end Library;

     partial package Library2
    "Icon for library where additional icon elements shall be added"
        annotation (Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),Icon(
          coordinateSystem(                                                                             extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-100.,-100.},{80.,50.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{-100.,50.},{-80.,70.},{100.,70.},{80.,50.},{-100.,50.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{100.,70.},{100.,-80.},{80.,-100.},{80.,50.},{100.,70.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Text(extent={{-120.,125.},{120.,70.}},textString="%name",fillColor={255,0,0}),Text(extent={{-90.,40.},{70.,10.}},textString="Library",fillColor={160,160,160},fillPattern=FillPattern.Solid)}));
     end Library2;
  end Icons;

  package SIunits "Type definitions based on SI units according to ISO 31-1992"
     extends Modelica.Icons.Library2;

     package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
        extends Modelica.Icons.Library2;

        package NonSIunits "Type definitions of non SI units"
           extends Modelica.Icons.Library2;
           annotation (Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),
            Documentation(                                                                         info="<HTML>
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
 "),
          Icon(
           coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Text(extent={{-66.,-13.},{52.,-67.}},textString="[rev/min]",fillColor={0,0,0})}));
        end NonSIunits;
        annotation (Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),Icon(
           coordinateSystem(                                                                            extent={{-100.,-100.},{100.,100.}}),graphics={Text(extent={{-33.,-7.},{-92.,-67.}},textString="DegreeC",fillColor={0,0,0},lineThickness=1.),Text(extent={{82.,-7.},{22.,-67.}},textString="K",fillColor={0,0,0}),Line(points={{-26.,-36.},{6.,-36.}},color={0,0,0}),Polygon(points={{6.,-28.},{6.,-45.},{26.,-37.},{6.,-28.}},pattern=LinePattern.None,fillColor={0,0,0},fillPattern=FillPattern.Solid,lineColor={0,0,255})}),
         Documentation(                                                                                                    info="<HTML>
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

     type Time = Real (
                      final quantity="Time",final unit="s");
     annotation (Invisible=true,Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Text(extent={{-63.,-13.},{45.,-67.}},textString="[kg.m2]",fillColor={0,0,0})}),
      Documentation(                                                                                                    info="<html>

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

 </HTML>"),  Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{169.,86.},{349.,236.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{169.,236.},{189.,256.},{369.,256.},{349.,236.},{169.,236.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Polygon(points={{369.,256.},{369.,106.},{349.,86.},{349.,236.},{369.,256.}},fillColor={235,235,235},fillPattern=FillPattern.Solid,lineColor={0,0,255}),Text(extent={{179.,226.},{339.,196.}},textString="Library",fillColor={160,160,160},fillPattern=FillPattern.Solid),Text(extent={{206.,173.},{314.,119.}},textString="[kg.m2]",fillColor={0,0,0}),Text(extent={{163.,320.},{406.,264.}},textString="Modelica.SIunits",fillColor={255,0,0})}));
  end SIunits;
end Modelica;

model BS5
  Modelica.Blocks.Continuous.Der der1 annotation(Placement(visible=true,
        transformation(                                                                x=29.3942,y=8.31657,scale=0.1)));
  Modelica.Blocks.Sources.KinematicPTP kinematicPTP1 annotation(Placement(visible=true,
        transformation(                                                                               x=-14.3989,y=11.3578,scale=0.1)));

equation
  connect(kinematicPTP1.outPort,der1.inPort) annotation(Line(visible=true,points={{-4.67,11.36},{16.62,8.32}}));
end BS5;
// class BS5
// parameter Integer der1.n = 1 "Number of inputs (= number of outputs)";
// parameter Integer der1.inPort.n = der1.n "Dimension of signal vector";
// input Real der1.inPort.signal[1] "Real input signals";
// parameter Integer der1.outPort.n = der1.n "Dimension of signal vector";
// output Real der1.outPort.signal[1] "Real output signals";
// output Real der1.y[1] "Output signals";
// protected Real der1.u[1] = der1.inPort.signal[1] "Input signals";
// parameter Integer kinematicPTP1.nout(min = 1) = 1 "Number of outputs";
// parameter Integer kinematicPTP1.outPort.n = kinematicPTP1.nout "Dimension of signal vector";
// output Real kinematicPTP1.outPort.signal[1] "Real output signals";
// output Real kinematicPTP1.y[1];
// parameter Real kinematicPTP1.deltaq[1] = 1.0 "Distance to move";
// parameter Real kinematicPTP1.qd_max[1](min = 1e-60) = 1.0 "Maximum velocities der(q)";
// parameter Real kinematicPTP1.qdd_max[1](min = 1e-60) = 1.0 "Maximum accelerations der(qd)";
// parameter Real kinematicPTP1.startTime(quantity = "Time", unit = "s") = 0.0 "Time instant at which movement starts";
// protected parameter Real kinematicPTP1.p_deltaq[1] = kinematicPTP1.deltaq[1];
// protected parameter Real kinematicPTP1.p_qd_max[1] = kinematicPTP1.qd_max[1];
// protected parameter Real kinematicPTP1.p_qdd_max[1] = kinematicPTP1.qdd_max[1];
// protected Real kinematicPTP1.sd_max;
// protected Real kinematicPTP1.sdd_max;
// protected Real kinematicPTP1.sdd;
// protected Real kinematicPTP1.aux1[1];
// protected Real kinematicPTP1.aux2[1];
// protected Real kinematicPTP1.Ta1(quantity = "Time", unit = "s");
// protected Real kinematicPTP1.Ta2(quantity = "Time", unit = "s");
// protected Real kinematicPTP1.Tv(quantity = "Time", unit = "s");
// protected Real kinematicPTP1.Te(quantity = "Time", unit = "s");
// protected Boolean kinematicPTP1.noWphase;
// equation
//   der1.y[1] = der(der1.u[1]);
//   der1.y[1] = der1.outPort.signal[1];
//   kinematicPTP1.aux1[1] = kinematicPTP1.p_deltaq[1] / kinematicPTP1.p_qd_max[1];
//   kinematicPTP1.aux2[1] = kinematicPTP1.p_deltaq[1] / kinematicPTP1.p_qdd_max[1];
//   kinematicPTP1.sd_max = 1.0 / max({abs(kinematicPTP1.aux1[1])});
//   kinematicPTP1.sdd_max = 1.0 / max({abs(kinematicPTP1.aux2[1])});
//   kinematicPTP1.Ta1 = sqrt(1.0 / kinematicPTP1.sdd_max);
//   kinematicPTP1.Ta2 = kinematicPTP1.sd_max / kinematicPTP1.sdd_max;
//   kinematicPTP1.noWphase = kinematicPTP1.Ta2 >= kinematicPTP1.Ta1;
//   kinematicPTP1.Tv = if kinematicPTP1.noWphase then kinematicPTP1.Ta1 else 1.0 / kinematicPTP1.sd_max;
//   kinematicPTP1.Te = if kinematicPTP1.noWphase then 2.0 * kinematicPTP1.Ta1 else kinematicPTP1.Tv + kinematicPTP1.Ta2;
//   kinematicPTP1.sdd = if time < kinematicPTP1.startTime then 0.0 else if kinematicPTP1.noWphase then if time < kinematicPTP1.Ta1 + kinematicPTP1.startTime then kinematicPTP1.sdd_max else if time < kinematicPTP1.Te + kinematicPTP1.startTime then -kinematicPTP1.sdd_max else 0.0 else if time < kinematicPTP1.Ta2 + kinematicPTP1.startTime then kinematicPTP1.sdd_max else if time < kinematicPTP1.Tv + kinematicPTP1.startTime then 0.0 else if time < kinematicPTP1.Te + kinematicPTP1.startTime then -kinematicPTP1.sdd_max else 0.0;
//   kinematicPTP1.outPort.signal[1] = kinematicPTP1.sdd * kinematicPTP1.p_deltaq[1];
//   kinematicPTP1.y[1] = kinematicPTP1.outPort.signal[1];
// assert(kinematicPTP1.outPort.n == der1.inPort.n,"automatically generated from connect");
// kinematicPTP1.outPort.signal[1] = der1.inPort.signal[1];
// end BS5;
// Result:
// class BS5
//   parameter Integer der1.n = 1 "Number of inputs (= number of outputs)";
//   parameter Integer der1.inPort.n = der1.n "Dimension of signal vector";
//   Real der1.inPort.signal[1] "Real input signals";
//   parameter Integer der1.outPort.n = der1.n "Dimension of signal vector";
//   Real der1.outPort.signal[1] "Real output signals";
//   Real der1.y[1] "Output signals";
//   protected Real der1.u[1] "Input signals";
//   parameter Integer kinematicPTP1.nout(min = 1) = 1 "Number of outputs";
//   parameter Integer kinematicPTP1.outPort.n = kinematicPTP1.nout "Dimension of signal vector";
//   Real kinematicPTP1.outPort.signal[1] "Real output signals";
//   Real kinematicPTP1.y[1];
//   parameter Real kinematicPTP1.deltaq[1] = 1.0 "Distance to move";
//   parameter Real kinematicPTP1.qd_max[1](min = 1e-60) = 1.0 "Maximum velocities der(q)";
//   parameter Real kinematicPTP1.qdd_max[1](min = 1e-60) = 1.0 "Maximum accelerations der(qd)";
//   parameter Real kinematicPTP1.startTime(quantity = "Time", unit = "s") = 0.0 "Time instant at which movement starts";
//   protected parameter Real kinematicPTP1.p_deltaq[1] = kinematicPTP1.deltaq[1];
//   protected parameter Real kinematicPTP1.p_qd_max[1] = kinematicPTP1.qd_max[1];
//   protected parameter Real kinematicPTP1.p_qdd_max[1] = kinematicPTP1.qdd_max[1];
//   protected Real kinematicPTP1.sd_max;
//   protected Real kinematicPTP1.sdd_max;
//   protected Real kinematicPTP1.sdd;
//   protected Real kinematicPTP1.aux1[1];
//   protected Real kinematicPTP1.aux2[1];
//   protected Real kinematicPTP1.Ta1(quantity = "Time", unit = "s");
//   protected Real kinematicPTP1.Ta2(quantity = "Time", unit = "s");
//   protected Real kinematicPTP1.Tv(quantity = "Time", unit = "s");
//   protected Real kinematicPTP1.Te(quantity = "Time", unit = "s");
//   protected Boolean kinematicPTP1.noWphase;
// equation
//   der1.u = {der1.inPort.signal[1]};
//   der1.y[1] = der(der1.u[1]);
//   der1.y[1] = der1.outPort.signal[1];
//   kinematicPTP1.aux1[1] = kinematicPTP1.p_deltaq[1] / kinematicPTP1.p_qd_max[1];
//   kinematicPTP1.aux2[1] = kinematicPTP1.p_deltaq[1] / kinematicPTP1.p_qdd_max[1];
//   kinematicPTP1.sd_max = 1.0 / abs(kinematicPTP1.aux1[1]);
//   kinematicPTP1.sdd_max = 1.0 / abs(kinematicPTP1.aux2[1]);
//   kinematicPTP1.Ta1 = sqrt(1.0 / kinematicPTP1.sdd_max);
//   kinematicPTP1.Ta2 = kinematicPTP1.sd_max / kinematicPTP1.sdd_max;
//   kinematicPTP1.noWphase = kinematicPTP1.Ta2 >= kinematicPTP1.Ta1;
//   kinematicPTP1.Tv = if kinematicPTP1.noWphase then kinematicPTP1.Ta1 else 1.0 / kinematicPTP1.sd_max;
//   kinematicPTP1.Te = if kinematicPTP1.noWphase then 2.0 * kinematicPTP1.Ta1 else kinematicPTP1.Tv + kinematicPTP1.Ta2;
//   kinematicPTP1.sdd = if time < kinematicPTP1.startTime then 0.0 else if kinematicPTP1.noWphase then if time < kinematicPTP1.Ta1 + kinematicPTP1.startTime then kinematicPTP1.sdd_max else if time < kinematicPTP1.Te + kinematicPTP1.startTime then -kinematicPTP1.sdd_max else 0.0 else if time < kinematicPTP1.Ta2 + kinematicPTP1.startTime then kinematicPTP1.sdd_max else if time < kinematicPTP1.Tv + kinematicPTP1.startTime then 0.0 else if time < kinematicPTP1.Te + kinematicPTP1.startTime then -kinematicPTP1.sdd_max else 0.0;
//   kinematicPTP1.outPort.signal[1] = kinematicPTP1.p_deltaq[1] * kinematicPTP1.sdd;
//   kinematicPTP1.y[1] = kinematicPTP1.outPort.signal[1];
//   assert(kinematicPTP1.outPort.n == der1.inPort.n, "automatically generated from connect");
//   der1.inPort.signal[1] = kinematicPTP1.outPort.signal[1];
// end BS5;
// [flattening/modelica/msl/BS5.mo:686:42-686:70:writable] Warning: Non-array modification '1e-60' for array component, possibly due to missing 'each'.
// [flattening/modelica/msl/BS5.mo:688:43-688:71:writable] Warning: Non-array modification '1e-60' for array component, possibly due to missing 'each'.
//
// endResult
