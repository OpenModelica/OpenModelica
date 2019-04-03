// name:     BC5 - LimIntegrator component
// keywords: LimIntegrator
// status:   correct
//
// Testing instantiation of the LimIntegrator component.
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

       block LimIntegrator "Integrator with limited values of the outputs"
          parameter Real k[:]={1} "Integrator gains";
          parameter Real outMax[:]={1} "Upper limits of outputs";
          parameter Real outMin[:]=-outMax "Lower limits of outputs";
          parameter Real y0[:]=zeros(size(k,1)) "Start values of integrators";
          extends Interfaces.MIMOs(final n=max([size(k,1); size(outMax,1); size(outMin,1)]),y(start=y0));

    protected
          parameter Real p_k[n]=if size(k,1) == 1 then
             ones(n)*k[1] else
             k;
          parameter Real p_outMax[n]=if size(outMax,1) == 1 then
             ones(n)*outMax[1] else
             outMax;
          parameter Real p_outMin[n]=if size(outMin,1) == 1 then
             ones(n)*outMin[1] else
             outMin;
          annotation (Documentation(info="<html>
 <p>
 This blocks computes <b>y</b>=outPort.signal element-wise as <i>integral</i>
 of the input <b>u</b>=inPort.signal multiplied with the gain <i>k</i>. If the
 integral reaches a given upper or lower <i>limit</i> and the
 input will drive the integral outside of this bound, the
 integration is halted and only restarted if the input drives
 the integral away from the bounds.
 </p>

 <p><b>Release Notes:</b></p>
 <ul>
 <li><i>Nov. 4, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Vectorized.</li>
 <li><i>June 30, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized.
 </li>
 </ul>

 <p><b>Copyright &copy; 1999-2002, Modelica Association and DLR.</b></p>
 </HTML>
 "),    Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Line(points={{-80.,78.},{-80.,-90.}},color={192,192,192}),Polygon(points={{-80.,90.},{-88.,68.},{-72.,68.},{-80.,90.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-90.,-80.},{82.,-80.}},color={192,192,192}),Polygon(points={{90.,-80.},{68.,-72.},{68.,-88.},{90.,-80.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-80.,-80.},{20.,20.},{80.,20.}},color={0,0,255}),Text(extent={{0.,-10.},{60.,-70.}},textString="I",fillColor={192,192,192}),Text(extent={{-150.,-150.},{150.,-110.}},textString="k=%k",fillColor={0,0,0})}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-60.,60.},{60.,-60.}},lineColor={0,0,255}),Text(extent={{-54.,46.},{-4.,-48.}},textString="lim",fillColor={0,0,0}),Line(points={{-100.,0.},{-60.,0.}},color={0,0,255}),Line(points={{60.,0.},{100.,0.}},color={0,0,255}),Text(extent={{-8.,60.},{60.,2.}},textString="k",fillColor={0,0,0}),Text(extent={{-8.,-2.},{60.,-60.}},textString="s",fillColor={0,0,0}),Line(points={{4.,0.},{46.,0.}},color={0,0,0})}));

       equation
          for i in 1:n loop
             der(y[i]) = if y[i] < p_outMin[i] and u[i] < 0 or y[i] > p_outMax[i] and u[i] > 0 then
                0 else
                p_k[i]*u[i];
          end for;
       end LimIntegrator;
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

       block Constant "Generate constant signals of type Real"
          parameter Real k[:]={1} "Constant output values";
          extends Interfaces.MO(final nout=size(k,1));
          annotation (Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Line(points={{-80.,68.},{-80.,-80.}},color={192,192,192}),Polygon(points={{-80.,90.},{-88.,68.},{-72.,68.},{-80.,90.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-90.,-70.},{82.,-70.}},color={192,192,192}),Polygon(points={{90.,-70.},{68.,-62.},{68.,-78.},{90.,-70.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-80.,0.},{80.,0.}},color={0,0,0}),Text(extent={{-150.,-150.},{150.,-110.}},textString="k=%k",fillColor={0,0,0})}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Polygon(points={{-80.,90.},{-88.,68.},{-72.,68.},{-80.,90.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-80.,68.},{-80.,-80.}},color={192,192,192}),Line(points={{-80.,0.},{80.,0.}},color={0,0,0},thickness=0.5),Line(points={{-90.,-70.},{82.,-70.}},color={192,192,192}),Polygon(points={{90.,-70.},{68.,-62.},{68.,-78.},{90.,-70.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Text(extent={{-75.,94.},{-22.,76.}},textString="outPort",fillColor={160,160,160}),Text(extent={{70.,-80.},{94.,-100.}},textString="time",fillColor={160,160,160}),Text(extent={{-101.,8.},{-81.,-12.}},textString="k",fillColor={160,160,160})}));

       equation
          outPort.signal = k;
       end Constant;
    end Sources;
  end Blocks;

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

model BC5
  Modelica.Blocks.Continuous.LimIntegrator limIntegrator1 annotation(Placement(visible=true,
        transformation(                                                                                    x=9.58127,y=7.44637,scale=0.1)));
  Modelica.Blocks.Sources.Constant constant1 annotation(Placement(visible=true,
        transformation(                                                                       x=-33.3808,y=7.44637,scale=0.1)));

equation
  connect(constant1.outPort,limIntegrator1.inPort) annotation(Line(visible=true,points={{-21.59,8.49},{-3.25,8.49}}));
end BC5;
// class BC5
// parameter Integer limIntegrator1.n = 1 "Number of inputs (= number of outputs)";
// parameter Integer limIntegrator1.inPort.n = limIntegrator1.n "Dimension of signal vector";
// input Real limIntegrator1.inPort.signal[1] "Real input signals";
// parameter Integer limIntegrator1.outPort.n = limIntegrator1.n "Dimension of signal vector";
// output Real limIntegrator1.outPort.signal[1] "Real output signals";
// output Real limIntegrator1.y[1](start = limIntegrator1.y0[1]) "Output signals";
// protected Real limIntegrator1.u[1] = limIntegrator1.inPort.signal[1] "Input signals";
// parameter Real limIntegrator1.k[1] = 1.0 "Integrator gains";
// parameter Real limIntegrator1.outMax[1] = 1.0 "Upper limits of outputs";
// parameter Real limIntegrator1.outMin[1] = -limIntegrator1.outMax[1] "Lower limits of outputs";
// parameter Real limIntegrator1.y0[1] = 0.0 "Start values of integrators";
// protected parameter Real limIntegrator1.p_k[1] = limIntegrator1.k[1];
// protected parameter Real limIntegrator1.p_outMax[1] = limIntegrator1.outMax[1];
// protected parameter Real limIntegrator1.p_outMin[1] = limIntegrator1.outMin[1];
// parameter Integer constant1.nout(min = 1) = 1 "Number of outputs";
// parameter Integer constant1.outPort.n = constant1.nout "Dimension of signal vector";
// output Real constant1.outPort.signal[1] "Real output signals";
// output Real constant1.y[1];
// parameter Real constant1.k[1] = 1.0 "Constant output values";
// equation
//   der(limIntegrator1.y[1]) = if limIntegrator1.y[1] < limIntegrator1.p_outMin[1] AND limIntegrator1.u[1] < 0.0 OR limIntegrator1.y[1] > limIntegrator1.p_outMax[1] AND limIntegrator1.u[1] > 0.0 then 0.0 else limIntegrator1.p_k[1] * limIntegrator1.u[1];
//   limIntegrator1.y[1] = limIntegrator1.outPort.signal[1];
//   constant1.outPort.signal[1] = constant1.k[1];
//   constant1.y[1] = constant1.outPort.signal[1];
// assert(constant1.outPort.n == limIntegrator1.inPort.n,"automatically generated from connect");
// constant1.outPort.signal[1] = limIntegrator1.inPort.signal[1];
// end BC5;
// Result:
// class BC5
//   parameter Integer limIntegrator1.n = 1 "Number of inputs (= number of outputs)";
//   parameter Integer limIntegrator1.inPort.n = limIntegrator1.n "Dimension of signal vector";
//   Real limIntegrator1.inPort.signal[1] "Real input signals";
//   parameter Integer limIntegrator1.outPort.n = limIntegrator1.n "Dimension of signal vector";
//   Real limIntegrator1.outPort.signal[1] "Real output signals";
//   Real limIntegrator1.y[1](start = limIntegrator1.y0[1]) "Output signals";
//   protected Real limIntegrator1.u[1] "Input signals";
//   parameter Real limIntegrator1.k[1] = 1.0 "Integrator gains";
//   parameter Real limIntegrator1.outMax[1] = 1.0 "Upper limits of outputs";
//   parameter Real limIntegrator1.outMin[1] = -limIntegrator1.outMax[1] "Lower limits of outputs";
//   parameter Real limIntegrator1.y0[1] = 0.0 "Start values of integrators";
//   protected parameter Real limIntegrator1.p_k[1] = limIntegrator1.k[1];
//   protected parameter Real limIntegrator1.p_outMax[1] = limIntegrator1.outMax[1];
//   protected parameter Real limIntegrator1.p_outMin[1] = limIntegrator1.outMin[1];
//   parameter Integer constant1.nout(min = 1) = 1 "Number of outputs";
//   parameter Integer constant1.outPort.n = constant1.nout "Dimension of signal vector";
//   Real constant1.outPort.signal[1] "Real output signals";
//   Real constant1.y[1];
//   parameter Real constant1.k[1] = 1.0 "Constant output values";
// equation
//   limIntegrator1.u = {limIntegrator1.inPort.signal[1]};
//   der(limIntegrator1.y[1]) = if limIntegrator1.y[1] < limIntegrator1.p_outMin[1] and limIntegrator1.u[1] < 0.0 or limIntegrator1.y[1] > limIntegrator1.p_outMax[1] and limIntegrator1.u[1] > 0.0 then 0.0 else limIntegrator1.p_k[1] * limIntegrator1.u[1];
//   limIntegrator1.y[1] = limIntegrator1.outPort.signal[1];
//   constant1.outPort.signal[1] = constant1.k[1];
//   constant1.y[1] = constant1.outPort.signal[1];
//   assert(constant1.outPort.n == limIntegrator1.inPort.n, "automatically generated from connect");
//   constant1.outPort.signal[1] = limIntegrator1.inPort.signal[1];
// end BC5;
// endResult
