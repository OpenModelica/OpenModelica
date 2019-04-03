// name:     BC6 - LimPID component
// keywords: LimPID
// status:   correct
//
// Testing instantiation of the LimPID component.
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

       block Integrator "Output the integral of the input signals"
          parameter Real k[:]={1} "Integrator gains";
          parameter Real y0[:]=zeros(size(k,1)) "Start values of integrators";
          extends Interfaces.MIMOs(final n=size(k,1),y(start=y0));
          annotation (Documentation(info="<html>
 <p>
 This blocks computes output <b>y</b>=outPort.signal element-wise as
 <i>integral</i> of the input <b>u</b>=inPort.signal multiplied with
 the gain <i>k</i>:
 </p>

 <pre>
              k[i]
      y[i] = ------ u[i]
               s
 </pre>

 <p><b>Release Notes:</b></p>
 <ul>
 <li><i>Nov. 4, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Vectorized.</li>
 <li><i>June 30, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized.</li>
 </ul>
 </HTML>
 "),    Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Line(points={{-80.,78.},{-80.,-90.}},color={192,192,192}),Polygon(points={{-80.,90.},{-88.,68.},{-72.,68.},{-80.,90.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-90.,-80.},{82.,-80.}},color={192,192,192}),Polygon(points={{90.,-80.},{68.,-72.},{68.,-88.},{90.,-80.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Text(extent={{0.,-10.},{60.,-70.}},textString="I",fillColor={192,192,192}),Text(extent={{-150.,-150.},{150.,-110.}},textString="k=%k",fillColor={0,0,0}),Line(points={{-80.,-80.},{80.,80.}},color={0,0,255})}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-60.,60.},{60.,-60.}},lineColor={0,0,255}),Line(points={{-100.,0.},{-60.,0.}},color={0,0,255}),Line(points={{60.,0.},{100.,0.}},color={0,0,255}),Text(extent={{-36.,60.},{32.,2.}},textString="k",fillColor={0,0,0}),Text(extent={{-32.,0.},{36.,-58.}},textString="s",fillColor={0,0,0}),Line(points={{-46.,0.},{46.,0.}},color={0,0,0})}));

       equation
          for i in 1:size(k,1) loop
             der(y[i]) = k[i]*u[i];
          end for;
       end Integrator;

       block Derivative "Approximated derivative block"
          parameter Real k[:]={1} "Gains";
          parameter SI.Time T[:](min=fill(Modelica.Constants.small,size(T,1)))={0.01}
        "Time constants (T>0 required; T=0 is ideal derivative block)";
          extends Interfaces.MIMOs(final n=max([size(k,1); size(T,1)]));
          output Real x[n] "State of block";

    protected
          parameter Real p_k[n]=if size(k,1) == 1 then
             ones(n)*k[1] else
             k;
          parameter Real p_T[n]=if size(T,1) == 1 then
             ones(n)*T[1] else
             T;
          annotation (Documentation(info="<html>
 <p>
 This blocks defines the transfer function between the
 input u=inPort.signal and the output y=outPort.signal
 element-wise as <i>approximated derivative</i>:
 </p>

 <pre>
              k[i] * s
      y[i] = ------------ * u[i]
             T[i] * s + 1
 </pre>

 <p>
 If you would like to be able to change easily between different
 transfer functions (FirstOrder, SecondOrder, ... ) by changing
 parameters, use the general block <b>TransferFunction</b> instead
 and model a derivative block with parameters<br>
 b = {k,0}, a = {T, 1}.
 </p>

 <p><b>Release Notes:</b></p>
 <ul>
 <li><i>Nov. 15, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Special handling, if k is zero. Introduced, in order that
        the D-part of the PID controllers can be set to zero without
        introducing numerical problems.</li>

 <li><i>Nov. 4, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Vectorized.</li>
 <li><i>June 30, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized.</li>
 </ul>

 </HTML>
 "),    Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Line(points={{-80.,78.},{-80.,-90.}},color={192,192,192}),Polygon(points={{-80.,90.},{-88.,68.},{-72.,68.},{-80.,90.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-90.,-80.},{82.,-80.}},color={192,192,192}),Polygon(points={{90.,-80.},{68.,-72.},{68.,-88.},{90.,-80.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-80.,-80.},{-80.,60.},{-70.,17.95},{-60.,-11.46},{-50.,-32.05},{-40.,-46.45},{-30.,-56.53},{-20.,-63.58},{-10.,-68.51},{0.,-71.96},{10.,-74.37},{20.,-76.06},{30.,-77.25},{40.,-78.07},{50.,-78.65},{60.,-79.06}},color={0,0,255}),Text(extent={{0.,0.},{60.,60.}},textString="DT1",fillColor={192,192,192}),Text(extent={{-150.,-150.},{150.,-110.}},textString="k=%k",fillColor={0,0,0})}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Text(extent={{-54.,52.},{50.,10.}},textString="k s",fillColor={0,0,0}),Text(extent={{-54.,-6.},{52.,-52.}},textString="T s + 1",fillColor={0,0,0}),Line(points={{-50.,0.},{50.,0.}},color={0,0,0}),Rectangle(extent={{-60.,60.},{60.,-60.}},lineColor={0,0,255}),Line(points={{-100.,0.},{-60.,0.}},color={0,0,255}),Line(points={{60.,0.},{100.,0.}},color={0,0,255})}));

       equation
          for i in 1:n loop
             der(x[i]) = if noEvent(abs(p_k[i]) >= Modelica.Constants.eps) then
                (u[i]-x[i])/p_T[i] else
                0;
             y[i] = if noEvent(abs(p_k[i]) >= Modelica.Constants.eps) then
                p_k[i]/p_T[i]*(u[i]-x[i]) else
                0;
          end for;
       end Derivative;

       block LimPID
      "PID controller with limited output, anti-windup compensation and setpoint weighting"
          extends Interfaces.SVcontrol;
          parameter Real k(min=0)=1 "Gain of PID block";
          parameter SI.Time Ti(min=Modelica.Constants.small)=0.5
        "Time constant of Integrator block";
          parameter SI.Time Td(min=0)=0.1 "Time constant of Derivative block";
          parameter Real yMax=1 "Upper limit of output";
          parameter Real yMin=-yMax "Lower limit of output";
          parameter Real wp(min=0)=1
        "Set-point weight for Proportional block (0..1)";
          parameter Real wd(min=0)=0
        "Set-point weight for Derivative block (0..1)";
          parameter Real Ni(min=100*Modelica.Constants.eps)=0.9
        "Ni*Ti is time constant of anti-windup compensation";
          parameter Real Nd(min=100*Modelica.Constants.eps)=10
        "The higher Nd, the more ideal the derivative block";
          Nonlinear.Limiter limiter(uMax={yMax},uMin={yMin}) annotation (Placement(
            transformation(                                                                       x=80.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=80.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          annotation (Diagram(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),Icon(
            coordinateSystem(                                                                             extent={{-100.,-100.},{100.,100.}}),graphics={Line(points={{-80.,78.},{-80.,-90.}},color={192,192,192}),Polygon(points={{-80.,90.},{-88.,68.},{-72.,68.},{-80.,90.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-90.,-80.},{82.,-80.}},color={192,192,192}),Polygon(points={{90.,-80.},{68.,-72.},{68.,-88.},{90.,-80.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-80.,-80.},{-80.,50.},{-80.,-20.},{30.,60.},{80.,60.}},color={0,0,255}),Text(extent={{-20.,-20.},{80.,-60.}},textString="PID",fillColor={192,192,192})}),
          Documentation(                                                                                                    info="<HTML>
 <p>
 This is a PID controller incorporating several practical aspects.
 It is designed according to chapter 3 of the book
 </p>

 <pre>
    K. Astroem, T. Haegglund: PID Controllers: Theory, Design, and Tuning.
                              2nd edition, 1995.
 </pre>

 <p>
 Besides the additive <b>proportional, integral</b> and <b>derivative</b>
 part of this controller, the following practical aspects are included:
 </p>

 <ul>
 <li> The output of this controller is limited. If the controller is
      in its limits, anti-windup compensation is activated to drive
      the integrator state to zero. </li>

 <li> The high-frequency gain of the derivative part is limited
      to avoid excessive amplification of measurement noise.</li>

 <li> Setpoint weighting is present, which allows to weight
      the setpoint in the proportional and the derivative part
      independantly from the measurement. The controller will respond
      to load disturbances and measurement noise independantly of this setting
      (parameters wp, wd). However, setpoint changes will depend on this
      setting. For example, it is useful to set the setpoint weight wd
      for the derivative part to zero, if steps may occur in the
      setpoint signal.</li>
 </ul>

 <p><b>Release Notes:</b></p>
 <ul>
 <li><i>Aug. 7, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized.</li>
 </ul>

 </HTML>
 "));
          Math.Add addP(k1=wp,k2=-1) annotation (Placement(transformation(x=-70.,y=50.,scale=0.1,
              aspectRatio =                                                                                  1.),
            iconTransformation(                                                                                                    x=-70.,y=50.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          Math.Add addD(k1=wd,k2=-1) annotation (Placement(transformation(x=-70.,y=0.,scale=0.1,
              aspectRatio =                                                                                 1.),
            iconTransformation(                                                                                                    x=-70.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          Math.Gain P annotation (Placement(transformation(x=-30.,y=50.,scale=0.1,
              aspectRatio =                                                                   1.),
            iconTransformation(                                                                                      x=-30.,y=50.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          Integrator I(k={1/Ti}) annotation (Placement(transformation(x=-30.,y=-50.,scale=0.1,
              aspectRatio =                                                                               1.),
            iconTransformation(                                                                                                  x=-30.,y=-50.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          Derivative D(k={Td},T={max([Td/Nd,1.e-14])}) annotation (Placement(
            transformation(                                                                 x=-30.,y=0.,scale=0.1,
              aspectRatio =                                                                                                   1.),
            iconTransformation(                                                                                                    x=-30.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          Math.Gain gainPID(k={k}) annotation (Placement(transformation(x=40.,y=0.,scale=0.1,
              aspectRatio =                                                                              1.),
            iconTransformation(                                                                                                 x=40.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          Math.Add3 addPID annotation (Placement(transformation(x=10.,y=0.,scale=0.1,
              aspectRatio =                                                                      1.),
            iconTransformation(                                                                                         x=10.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          Math.Add3 addI(k2=-1) annotation (Placement(transformation(x=-70.,y=-50.,scale=0.1,
              aspectRatio =                                                                              1.),
            iconTransformation(                                                                                                 x=-70.,y=-50.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          Math.Add addSat(k2=-1) annotation (Placement(transformation(x=80.,y=-50.,scale=0.1,
              aspectRatio =                                                                              1.,rotation=-90),
            iconTransformation(                                                                                                    x=80.,y=-50.,scale=0.1,
              aspectRatio =                                                                                                    1.,rotation=-90)));
          Math.Gain gainTrack(k={1/(k*Ni)}) annotation (Placement(
            transformation(                                                      x=30.,y=-70.,scale=0.1,
              aspectRatio =                                                                                         1.,
              flipHorizontal =                                                                                                    true),
            iconTransformation(                                                                                                    x=30.,y=-70.,scale=0.1,
              aspectRatio =                                                                                                    1.,
              flipHorizontal =                                                                                                    true)));

       equation
          assert(yMax >= yMin,"PID: Limits must be consistent");
          connect(inPort_s, addP.inPort1) annotation (Line(points={{-102.,0.},{-96.,0.},{-96.,56.},{-80.,56.}},color={0,0,255}));
          connect(inPort_m, addP.inPort2) annotation (Line(points={{0.,-100.},{0.,-92.},{-92.,-92.},{-92.,44.},{-80.,44.}},thickness=0.5,color={0,0,255}));
          connect(inPort_s, addD.inPort1) annotation (Line(points={{-102.,0.},{-96.,0.},{-96.,6.},{-82.,6.}},color={0,0,255}));
          connect(inPort_m, addD.inPort2) annotation (Line(points={{0.,-100.},{0.,-92.},{-92.,-92.},{-92.,-6.},{-82.,-6.},{-82.,-6.}},thickness=0.5,color={0,0,255}));
          connect(inPort_s, addI.inPort1) annotation (Line(points={{-100.,0.},{-96.,0.},{-96.,-42.},{-82.,-42.}},color={0,0,255}));
          connect(inPort_m, addI.inPort2) annotation (Line(points={{0.,-104.},{0.,-92.},{-92.,-92.},{-92.,-50.},{-80.,-50.}},thickness=0.5,color={0,0,255}));
          connect(gainTrack.outPort, addI.inPort3) annotation (Line(points={{20.,-70.},{-88.,-70.},{-88.,-58.},{-80.,-58.}},color={0,0,255}));
          connect(addP.outPort, P.inPort) annotation (Line(points={{-60.,50.},{-40.,50.},{-40.,50.}},color={0,0,255}));
          connect(addD.outPort, D.inPort) annotation (Line(points={{-60.,0.},{-50.,0.}},color={0,0,255}));
          connect(addI.outPort, I.inPort) annotation (Line(points={{-58.,-50.},{-40.,-50.}},color={0,0,255}));
          connect(P.outPort, addPID.inPort1) annotation (Line(points={{-18.,50.},{-10.,50.},{-10.,8.},{0.,8.}},color={0,0,255}));
          connect(D.outPort, addPID.inPort2) annotation (Line(points={{-20.,0.},{-2.,0.},{-2.,0.}},color={0,0,255}));
          connect(I.outPort, addPID.inPort3) annotation (Line(points={{-18.,-50.},{-10.,-50.},{-10.,-8.},{-2.,-8.},{-2.,-8.}},color={0,0,255}));
          connect(addPID.outPort, gainPID.inPort) annotation (Line(points={{21.,0.},{28.,0.}},color={0,0,255}));
          connect(gainPID.outPort, addSat.inPort2) annotation (Line(points={{50.,0.},{60.,0.},{60.,-30.},{74.,-30.},{74.,-40.}},color={0,0,255}));
          connect(addSat.outPort, gainTrack.inPort) annotation (Line(points={{80.,-62.},{80.,-70.},{42.,-70.}},color={0,0,255}));
          connect(gainPID.outPort, limiter.inPort) annotation (Line(points={{50.,0.},{70.,0.}},color={0,0,255}));
          connect(limiter.outPort, outPort) annotation (Line(points={{90.,0.},{100.,0.}},color={0,0,255}));
          connect(limiter.outPort, addSat.inPort1) annotation (Line(points={{90.,0.},{94.,0.},{94.,-20.},{86.,-20.},{86.,-40.}},color={0,0,255}));
       end LimPID;
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

       partial block MI2MO
      "2 Multiple Input / Multiple Output continuous control block"
          extends BlockIcon;
          parameter Integer n=1 "Dimension of input and output vectors.";
          InPort inPort1(final n=n) "Connector 1 of Real input signals" annotation (Placement(
            transformation(                                                                                  x=-120.,y=60.,scale=0.2,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=-120.,y=60.,scale=0.2,
              aspectRatio =                                                                                                    1.)));
          InPort inPort2(final n=n) "Connector 2 of Real input signals" annotation (Placement(
            transformation(                                                                                  x=-120.,y=-60.,scale=0.2,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=-120.,y=-60.,scale=0.2,
              aspectRatio =                                                                                                    1.)));
          OutPort outPort(final n=n) "Connector of Real output signals" annotation (Placement(
            transformation(                                                                                  x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          output Real y[n] "Output signals";
          annotation (Documentation(info="
 Block has two Input vectors inPort1.signal and inPort2.signal and one
 output vector outPort.signal. All vectors have the same number of elements.
 "));

    protected
          Real u1[:]=inPort1.signal "Input signals 1";
          Real u2[:]=inPort2.signal "Input signals 2";

       equation
          y = outPort.signal;
       end MI2MO;

       partial block SVcontrol "Single-Variable continuous controller"
          extends BlockIcon;

    protected
          Real u_s "Scalar setpoint input signal";
          Real u_m "Scalar measurement input signal";

    public
          InPort inPort_s(final n=1) "Connector of setpoint input signal" annotation (Placement(
            transformation(                                                                                    x=-120.,y=0.,scale=0.2,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=-120.,y=0.,scale=0.2,
              aspectRatio =                                                                                                    1.)));
          InPort inPort_m(final n=1) "Connector of measurement input signal" annotation (Placement(
            transformation(                                                                                       x=0.,y=-120.,scale=0.2,
              aspectRatio =                                                                                                    1.,rotation=-90,
              flipHorizontal =                                                                                                    true,
              flipVertical =                                                                                                    true),
            iconTransformation(                                                                                                    x=0.,y=-120.,scale=0.2,
              aspectRatio =                                                                                                    1.,rotation=-90,
              flipHorizontal =                                                                                                    true,
              flipVertical =                                                                                                    true)));
          OutPort outPort(final n=1) "Connector of actuator output signal" annotation (Placement(
            transformation(                                                                                     x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          output Real y "Scalar actuator output signal";
          annotation (Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}})),Diagram(
            coordinateSystem(                                                                             extent={{-100.,-100.},{100.,100.}}),graphics={Text(extent={{-102.,34.},{-142.,24.}},textString="(setpoint)",fillColor={0,0,255}),Text(extent={{100.,24.},{140.,14.}},textString="(actuator)",fillColor={0,0,255}),Text(extent={{-83.,-112.},{-33.,-102.}},textString=" (measurement)",fillColor={0,0,255})}));

       equation
          u_s = inPort_s.signal[1];
          u_m = inPort_m.signal[1];
          y = outPort.signal[1];
       end SVcontrol;
    end Interfaces;

    package Math "Mathematical functions as input/output blocks"
       extends Modelica.Icons.Library;
       annotation (Documentation(info="<html>
 <p>
 This package contains basic <b>mathematical operations</b>,
 such as summation and multiplication, and basic <b>mathematical
 functions</b>, such as <b>sqrt</b> and <b>sin</b>, as
 input/output blocks. All blocks of this library can be either
 connected with continuous blocks or with sampled-data blocks.
 In particular the following operations and functions are
 provided:
 </p>

 <pre>   <b>TwoInputs</b>     Change causality of input signals.
    <b>TwoOutputs</b>    Change causality of output signals.
    <b>Gain</b>          Output the input multiplied by a scalar gain
    <b>MatrixGain</b>    Output the product of a gain matrix with the input
    <b>Sum</b>           Output the sum of the elements of the input vector
    <b>Feedback</b>      Output difference between commanded and feedback input
    <b>Add</b>           Output the sum of the two inputs
    <b>Add3</b>          Output the sum of the three inputs
    <b>Product</b>       Output product of the two inputs
    <b>Division</b>      Output first input divided by second input
    <b>Abs</b>           Output the absolute value of the input
    <b>Sign</b>          Output the sign of the input
    <b>Sqrt</b>          Output the square root of the input
    <b>Sin</b>           Output the sine of the input
    <b>Cos</b>           Output the cosine of the input
    <b>Tan</b>           Output the tangent of the input
    <b>Asin</b>          Output the arc sine of the input
    <b>Acos</b>          Output the arc cosine of the input
    <b>Atan</b>          Output the arc tangent of the input
    <b>Atan2</b>         Output atan(u1/u2) of the inputs u1 and u2
    <b>Sinh</b>          Output the hyperbolic sine of the input
    <b>Cosh</b>          Output the hyperbolic cosine of the input
    <b>Tanh</b>          Output the hyperbolic tangent of the input
    <b>Exp</b>           Output the exponential (base e) of the input
    <b>Log</b>           Output the natural (base e) logarithm of the input
    <b>Log10</b>         Output the base 10 logarithm of the input
    <b>RealToInteger</b> Output the nearest Integer value to the input
    <b>IntegerToReal</b> Output the input as Real value
    <b>Max</b>           Output the maximum of the two inputs
    <b>Min</b>           Output the minimum of the two inputs
    <b>Edge</b>          Set output to true at rising edge of the input
    <b>BooleanChange</b> Set output to true when Boolean input changes
    <b>IntegerChange</b> Set output to true when Integer input changes
 </pre>

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
        New blocks added: RealToInteger, IntegerToReal, Max, Min, Edge, BooleanChange, IntegerChange.
 <li><i>August 7, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized (partly based on an existing Dymola library
        of Dieter Moormann and Hilding Elmqvist).
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

       block Gain
      "Output the element-wise product of a gain vector with the input signal vector"
          parameter Real k[:]={1}
        "Gain vector multiplied element-wise with input vector";

    protected
          Real u[size(k,1)] "Input signals";
          Real y[size(k,1)] "Output signals";

    public
          Interfaces.InPort inPort(final n=size(k,1)) "Input signal connector" annotation (Placement(
            transformation(                                                                                         x=-120.,y=0.,scale=0.2,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=-120.,y=0.,scale=0.2,
              aspectRatio =                                                                                                    1.)));
          Interfaces.OutPort outPort(final n=size(k,1))
        "Output signal connector"                                                 annotation (Placement(
            transformation(                                                                                            x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          annotation (Documentation(info="<html>
 <p>
 This block computes the output <b>y</b>=outPort.signal as
 <i>element-wise product</i> of gain <i>k</i> with the
 input <b>u</b> = inPort.signal:
 </p>

 <pre>    y[i] = k[i] * u[i];
 </pre>

 <p><b>Release Notes:</b></p>
 <ul>
 <li><i>August 7, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized.
 </li>
 </ul>

 </HTML>
 "),    Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Polygon(points={{-100.,-100.},{-100.,100.},{100.,0.},{-100.,-100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid),Text(extent={{-150.,-140.},{150.,-100.}},textString="k=%k",fillColor={0,0,0}),Text(extent={{-150.,140.},{150.,100.}},textString="%name",fillColor={0,0,255})}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Polygon(points={{-100.,-100.},{-100.,100.},{100.,0.},{-100.,-100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid),Text(extent={{-76.,38.},{0.,-34.}},textString="k",fillColor={0,0,255})}));

       equation
          u = inPort.signal;
          y = outPort.signal;
          for i in 1:size(k,1) loop
             y[i] = k[i]*u[i];
          end for;
       end Gain;

       block Add "Output the sum of the two inputs"
          extends Interfaces.MI2MO;
          parameter Real k1=1 "Gain of upper input";
          parameter Real k2=1 "Gain of lower input";
          annotation (Documentation(info="<html>
 <p>
 This block computes the output <b>y</b>=outPort.signal as <i>sum</i> of the
 two input signals <b>u1</b>=inPort1.signal and <b>u2</b>=inPort2.signal:
 </p>

 <pre>    <b>y</b> = k1*<b>u1</b> + k2*<b>u2</b>;
 </pre>

 <p>
 Example:
 </p>

 <pre>     parameter:   n = 2, k1= +2, k2= -3

   results in the following equations:

      y[1] = 2 * u1[1] - 3 * u2[1]
      y[2] = 2 * u1[2] - 3 * u2[2]
 </pre>

 <p><b>Release Notes:</b></p>
 <ul>
 <li><i>August 7, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized.
 </li>
 </ul>

 </HTML>
 "),    Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Text(extent={{-98.,-52.},{7.,-92.}},textString="%k2",fillColor={0,0,0}),Text(extent={{-100.,90.},{5.,50.}},textString="%k1",fillColor={0,0,0}),Text(extent={{-150.,150.},{150.,110.}},textString="%name",fillColor={0,0,255}),Line(points={{-100.,60.},{-40.,60.},{-30.,40.}},color={0,0,255}),Ellipse(extent={{-50.,50.},{50.,-50.}},lineColor={0,0,255}),Line(points={{-100.,-60.},{-40.,-60.},{-30.,-40.}},color={0,0,255}),Line(points={{-15.,-25.99},{15.,25.99}},color={0,0,0}),Rectangle(extent={{-100.,-100.},{100.,100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid),Line(points={{50.,0.},{100.,0.}},color={0,0,255}),Line(points={{-100.,60.},{-74.,24.},{-44.,24.}},color={0,0,255}),Line(points={{-100.,-60.},{-74.,-28.},{-42.,-28.}},color={0,0,255}),Ellipse(extent={{-50.,50.},{50.,-50.}},lineColor={0,0,255}),Line(points={{50.,0.},{100.,0.}},color={0,0,255}),Text(extent={{-38.,34.},{38.,-34.}},textString="+",fillColor={0,0,0}),Text(extent={{-100.,52.},{5.,92.}},textString="%k1",fillColor={0,0,0}),Text(extent={{-100.,-52.},{5.,-92.}},textString="%k2",fillColor={0,0,0})}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-100.,-100.},{100.,100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid),Text(extent={{-98.,-52.},{7.,-92.}},textString="%k2",fillColor={0,0,0}),Text(extent={{-100.,90.},{5.,50.}},textString="%k1",fillColor={0,0,0}),Line(points={{-100.,60.},{-40.,60.},{-30.,40.}},color={0,0,255}),Ellipse(extent={{-50.,50.},{50.,-50.}},lineColor={0,0,255}),Line(points={{-100.,-60.},{-40.,-60.},{-30.,-40.}},color={0,0,255}),Line(points={{-15.,-25.99},{15.,25.99}},color={0,0,0}),Rectangle(extent={{-100.,-100.},{100.,100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid),Line(points={{50.,0.},{100.,0.}},color={0,0,255}),Line(points={{-100.,60.},{-74.,24.},{-44.,24.}},color={0,0,255}),Line(points={{-100.,-60.},{-74.,-28.},{-42.,-28.}},color={0,0,255}),Ellipse(extent={{-50.,50.},{50.,-50.}},lineColor={0,0,255}),Line(points={{50.,0.},{100.,0.}},color={0,0,255}),Text(extent={{-38.,34.},{38.,-34.}},textString="+",fillColor={0,0,0}),Text(extent={{-100.,52.},{5.,92.}},textString="k1",fillColor={0,0,0}),Text(extent={{-100.,-52.},{5.,-92.}},textString="k2",fillColor={0,0,0})}));

       equation
          y = k1*u1+k2*u2;
       end Add;

       block Add3 "Output the sum of the three inputs"
          extends Interfaces.BlockIcon;
          parameter Real k1=1 "Gain of upper input";
          parameter Real k2=1 "Gain of middle input";
          parameter Real k3=1 "Gain of lower input";
          parameter Integer n=1 "Dimension of input and output vectors.";
          Interfaces.InPort inPort1(final n=n)
        "Connector 1 of Real input signals"                                        annotation (Placement(
            transformation(                                                                                             x=-120.,y=80.,scale=0.2,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=-120.,y=80.,scale=0.2,
              aspectRatio =                                                                                                    1.)));
          Interfaces.InPort inPort2(final n=n)
        "Connector 2 of Real input signals"                                        annotation (Placement(
            transformation(                                                                                             x=-120.,y=0.,scale=0.2,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=-120.,y=0.,scale=0.2,
              aspectRatio =                                                                                                    1.)));
          Interfaces.InPort inPort3(final n=n)
        "Connector 3 of Real input signals"                                        annotation (Placement(
            transformation(                                                                                             x=-120.,y=-80.,scale=0.2,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=-120.,y=-80.,scale=0.2,
              aspectRatio =                                                                                                    1.)));
          Interfaces.OutPort outPort(final n=n)
        "Connector of Real output signals"                                         annotation (Placement(
            transformation(                                                                                             x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.),
            iconTransformation(                                                                                                    x=110.,y=0.,scale=0.1,
              aspectRatio =                                                                                                    1.)));
          annotation (Documentation(info="<html>
 <p>
 This block computes the output <b>y</b>=outPort.signal as <i>sum</i> of the
 three input signals <b>u1</b>=inPort1.signal, <b>u2</b>=inPort2.signal
 and <b>u3</b>=inPort3.signal:
 </p>

 <pre>    <b>y</b> = k1*<b>u1</b> + k2*<b>u2</b> + k3*<b>u3</b>;
 </pre>

 <p>
 Example:
 </p>

 <pre>     parameter:   n = 2, k1= +2, k2= -3, k3=1;

   results in the following equations:

      y[1] = 2 * u1[1] - 3 * u2[1] + u3[1];
      y[2] = 2 * u1[2] - 3 * u2[2] + u3[2];
 </pre>

 <p><b>Release Notes:</b></p>
 <ul>
 <li><i>August 7, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized.
 </li>
 </ul>

 </HTML>
 "),    Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Text(extent={{-100.,50.},{5.,90.}},textString="%k1",fillColor={0,0,0}),Text(extent={{-100.,-20.},{5.,20.}},textString="%k2",fillColor={0,0,0}),Text(extent={{-100.,-50.},{5.,-90.}},textString="%k3",fillColor={0,0,0}),Text(extent={{2.,36.},{100.,-44.}},textString="+",fillColor={0,0,0})}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Rectangle(extent={{-100.,-100.},{100.,100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid),Text(extent={{-100.,50.},{5.,90.}},textString="%k1",fillColor={0,0,0}),Text(extent={{-100.,-20.},{5.,20.}},textString="%k2",fillColor={0,0,0}),Text(extent={{-100.,-50.},{5.,-90.}},textString="%k3",fillColor={0,0,0}),Text(extent={{2.,36.},{100.,-44.}},textString="+",fillColor={0,0,0}),Rectangle(extent={{-100.,-100.},{100.,100.}},lineColor={0,0,255},fillColor={255,255,255},fillPattern=FillPattern.Solid),Text(extent={{-100.,50.},{5.,90.}},textString="k1",fillColor={0,0,0}),Text(extent={{-100.,-20.},{5.,20.}},textString="k2",fillColor={0,0,0}),Text(extent={{-100.,-50.},{5.,-90.}},textString="k3",fillColor={0,0,0}),Text(extent={{2.,36.},{100.,-44.}},textString="+",fillColor={0,0,0})}));

       equation
          outPort.signal = (k1*inPort1.signal+k2*inPort2.signal)+k3*inPort3.signal;
       end Add3;
    end Math;

    package Nonlinear
    "Discontinuous or non-differentiable algebraic control blocks"
       extends Modelica.Icons.Library;
       annotation (Documentation(info="<html>
 <p>
 This package contains <b>discontinuous</b> and
 <b>non-differentiable, algebraic</b> input/output blocks.
 In particular the following blocks are provided:
 </p>

 <pre>
    <b>Limiter</b>           Limit the range of a signal to fixed limits.
    <b>VariableLimiter</b>   Limit the range of a signal to variable limits.
    <b>DeadZone</b>          Provide a region of zero output.
 </pre>

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
        by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
        New block VariableLimiter added.
 <li><i>August 22, 1999</i>
        by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
        Realized, based on an existing Dymola library
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

       block Limiter "Limit the range of a signal"
          parameter Real uMax[:]={1} "Upper limits of input signals";
          parameter Real uMin[size(uMax,1)](max=uMax)=-uMax
        "Lower limits of input signals";
          extends Interfaces.MIMOs(final n=size(uMax,1));
          annotation (Documentation(info="<html>
 <p>
 The Limiter block passes its input signal as output signal
 as long as the input is within the specified upper and lower
 limits. If this is not the case, the corresponding limit is passed
 as output.
 </p>
 </HTML>
 "),    Icon(coordinateSystem(extent={{-100.,-100.},{100.,100.}}),graphics={Line(points={{0.,-90.},{0.,68.}},color={192,192,192}),Polygon(points={{0.,90.},{-8.,68.},{8.,68.},{0.,90.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-90.,0.},{68.,0.}},color={192,192,192}),Polygon(points={{90.,0.},{68.,-8.},{68.,8.},{90.,0.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-80.,-70.},{-50.,-70.},{50.,70.},{80.,70.}},color={0,0,0}),Text(extent={{-150.,-150.},{150.,-110.}},textString="uMax=%uMax",fillColor={0,0,0}),Text(extent={{-150.,150.},{150.,110.}},textString="%name",fillColor={0,0,255})}),Diagram(
            coordinateSystem(                                                                                                    extent={{-100.,-100.},{100.,100.}}),graphics={Line(points={{0.,-60.},{0.,50.}},color={192,192,192}),Polygon(points={{0.,60.},{-5.,50.},{5.,50.},{0.,60.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-60.,0.},{50.,0.}},color={192,192,192}),Polygon(points={{60.,0.},{50.,-5.},{50.,5.},{60.,0.}},lineColor={192,192,192},fillColor={192,192,192},fillPattern=FillPattern.Solid),Line(points={{-50.,-40.},{-30.,-40.},{30.,40.},{50.,40.}},color={0,0,0}),Text(extent={{46.,-6.},{68.,-18.}},textString="inPort",fillColor={128,128,128}),Text(extent={{-30.,70.},{-5.,50.}},textString="outPort",fillColor={128,128,128}),Text(extent={{-58.,-54.},{-28.,-42.}},textString="uMin",fillColor={128,128,128}),Text(extent={{26.,40.},{66.,56.}},textString="uMax",fillColor={128,128,128})}));

       equation
          for i in 1:n loop
             y[i] = if u[i] > uMax[i] then
                uMax[i] else
                if u[i] < uMin[i] then
                   uMin[i] else
                   u[i];
          end for;
       end Limiter;
    end Nonlinear;

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

  package Constants "Mathematical constants and constants of nature"
     import SI = Modelica.SIunits;
     import NonSI = Modelica.SIunits.Conversions.NonSIunits;
     extends Modelica.Icons.Library2;

     constant Real eps=1.e-15 "Biggest number such that 1.0 + eps = 1.0";

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

model BC6
  Modelica.Blocks.Continuous.LimPID limPID1 annotation(Placement(visible=true,
        transformation(                                                                      x=15.7088,y=14.7031,scale=0.1)));
  Modelica.Blocks.Sources.Constant constant1    annotation(Placement(visible=true,
        transformation(                                                                          x=-22.6102,y=13.4866,scale=0.1)));

equation
  connect(constant1.outPort,limPID1.inPort_s) annotation(Line(visible=true,points={{-11.66,13.79},{1.11,15.62}}));
end BC6;

// Result:
// class BC6
//   protected Real limPID1.u_s "Scalar setpoint input signal";
//   protected Real limPID1.u_m "Scalar measurement input signal";
//   parameter Integer limPID1.inPort_s.n = 1 "Dimension of signal vector";
//   Real limPID1.inPort_s.signal[1] "Real input signals";
//   parameter Integer limPID1.inPort_m.n = 1 "Dimension of signal vector";
//   Real limPID1.inPort_m.signal[1] "Real input signals";
//   parameter Integer limPID1.outPort.n = 1 "Dimension of signal vector";
//   Real limPID1.outPort.signal[1] "Real output signals";
//   Real limPID1.y "Scalar actuator output signal";
//   parameter Real limPID1.k(min = 0.0) = 1.0 "Gain of PID block";
//   parameter Real limPID1.Ti(quantity = "Time", unit = "s", min = 1e-60) = 0.5 "Time constant of Integrator block";
//   parameter Real limPID1.Td(quantity = "Time", unit = "s", min = 0.0) = 0.1 "Time constant of Derivative block";
//   parameter Real limPID1.yMax = 1.0 "Upper limit of output";
//   parameter Real limPID1.yMin = -limPID1.yMax "Lower limit of output";
//   parameter Real limPID1.wp(min = 0.0) = 1.0 "Set-point weight for Proportional block (0..1)";
//   parameter Real limPID1.wd(min = 0.0) = 0.0 "Set-point weight for Derivative block (0..1)";
//   parameter Real limPID1.Ni(min = 1e-13) = 0.9 "Ni*Ti is time constant of anti-windup compensation";
//   parameter Real limPID1.Nd(min = 1e-13) = 10.0 "The higher Nd, the more ideal the derivative block";
//   parameter Integer limPID1.limiter.n = 1 "Number of inputs (= number of outputs)";
//   parameter Integer limPID1.limiter.inPort.n = limPID1.limiter.n "Dimension of signal vector";
//   Real limPID1.limiter.inPort.signal[1] "Real input signals";
//   parameter Integer limPID1.limiter.outPort.n = limPID1.limiter.n "Dimension of signal vector";
//   Real limPID1.limiter.outPort.signal[1] "Real output signals";
//   Real limPID1.limiter.y[1] "Output signals";
//   protected Real limPID1.limiter.u[1] "Input signals";
//   parameter Real limPID1.limiter.uMax[1] = limPID1.yMax "Upper limits of input signals";
//   parameter Real limPID1.limiter.uMin[1](max = limPID1.limiter.uMax[1]) = limPID1.yMin "Lower limits of input signals";
//   parameter Integer limPID1.addP.n = 1 "Dimension of input and output vectors.";
//   parameter Integer limPID1.addP.inPort1.n = limPID1.addP.n "Dimension of signal vector";
//   Real limPID1.addP.inPort1.signal[1] "Real input signals";
//   parameter Integer limPID1.addP.inPort2.n = limPID1.addP.n "Dimension of signal vector";
//   Real limPID1.addP.inPort2.signal[1] "Real input signals";
//   parameter Integer limPID1.addP.outPort.n = limPID1.addP.n "Dimension of signal vector";
//   Real limPID1.addP.outPort.signal[1] "Real output signals";
//   Real limPID1.addP.y[1] "Output signals";
//   protected Real limPID1.addP.u1[1] "Input signals 1";
//   protected Real limPID1.addP.u2[1] "Input signals 2";
//   parameter Real limPID1.addP.k1 = limPID1.wp "Gain of upper input";
//   parameter Real limPID1.addP.k2 = -1.0 "Gain of lower input";
//   parameter Integer limPID1.addD.n = 1 "Dimension of input and output vectors.";
//   parameter Integer limPID1.addD.inPort1.n = limPID1.addD.n "Dimension of signal vector";
//   Real limPID1.addD.inPort1.signal[1] "Real input signals";
//   parameter Integer limPID1.addD.inPort2.n = limPID1.addD.n "Dimension of signal vector";
//   Real limPID1.addD.inPort2.signal[1] "Real input signals";
//   parameter Integer limPID1.addD.outPort.n = limPID1.addD.n "Dimension of signal vector";
//   Real limPID1.addD.outPort.signal[1] "Real output signals";
//   Real limPID1.addD.y[1] "Output signals";
//   protected Real limPID1.addD.u1[1] "Input signals 1";
//   protected Real limPID1.addD.u2[1] "Input signals 2";
//   parameter Real limPID1.addD.k1 = limPID1.wd "Gain of upper input";
//   parameter Real limPID1.addD.k2 = -1.0 "Gain of lower input";
//   parameter Real limPID1.P.k[1] = 1.0 "Gain vector multiplied element-wise with input vector";
//   protected Real limPID1.P.u[1] "Input signals";
//   protected Real limPID1.P.y[1] "Output signals";
//   parameter Integer limPID1.P.inPort.n = 1 "Dimension of signal vector";
//   Real limPID1.P.inPort.signal[1] "Real input signals";
//   parameter Integer limPID1.P.outPort.n = 1 "Dimension of signal vector";
//   Real limPID1.P.outPort.signal[1] "Real output signals";
//   parameter Integer limPID1.I.n = 1 "Number of inputs (= number of outputs)";
//   parameter Integer limPID1.I.inPort.n = limPID1.I.n "Dimension of signal vector";
//   Real limPID1.I.inPort.signal[1] "Real input signals";
//   parameter Integer limPID1.I.outPort.n = limPID1.I.n "Dimension of signal vector";
//   Real limPID1.I.outPort.signal[1] "Real output signals";
//   Real limPID1.I.y[1](start = limPID1.I.y0[1]) "Output signals";
//   protected Real limPID1.I.u[1] "Input signals";
//   parameter Real limPID1.I.k[1] = 1.0 / limPID1.Ti "Integrator gains";
//   parameter Real limPID1.I.y0[1] = 0.0 "Start values of integrators";
//   parameter Integer limPID1.D.n = 1 "Number of inputs (= number of outputs)";
//   parameter Integer limPID1.D.inPort.n = limPID1.D.n "Dimension of signal vector";
//   Real limPID1.D.inPort.signal[1] "Real input signals";
//   parameter Integer limPID1.D.outPort.n = limPID1.D.n "Dimension of signal vector";
//   Real limPID1.D.outPort.signal[1] "Real output signals";
//   Real limPID1.D.y[1] "Output signals";
//   protected Real limPID1.D.u[1] "Input signals";
//   parameter Real limPID1.D.k[1] = limPID1.Td "Gains";
//   parameter Real limPID1.D.T[1](quantity = "Time", unit = "s", min = 1e-60) = max(limPID1.Td / limPID1.Nd, 1e-14) "Time constants (T>0 required; T=0 is ideal derivative block)";
//   Real limPID1.D.x[1] "State of block";
//   protected parameter Real limPID1.D.p_k[1] = limPID1.D.k[1];
//   protected parameter Real limPID1.D.p_T[1] = limPID1.D.T[1];
//   parameter Real limPID1.gainPID.k[1] = limPID1.k "Gain vector multiplied element-wise with input vector";
//   protected Real limPID1.gainPID.u[1] "Input signals";
//   protected Real limPID1.gainPID.y[1] "Output signals";
//   parameter Integer limPID1.gainPID.inPort.n = 1 "Dimension of signal vector";
//   Real limPID1.gainPID.inPort.signal[1] "Real input signals";
//   parameter Integer limPID1.gainPID.outPort.n = 1 "Dimension of signal vector";
//   Real limPID1.gainPID.outPort.signal[1] "Real output signals";
//   parameter Real limPID1.addPID.k1 = 1.0 "Gain of upper input";
//   parameter Real limPID1.addPID.k2 = 1.0 "Gain of middle input";
//   parameter Real limPID1.addPID.k3 = 1.0 "Gain of lower input";
//   parameter Integer limPID1.addPID.n = 1 "Dimension of input and output vectors.";
//   parameter Integer limPID1.addPID.inPort1.n = limPID1.addPID.n "Dimension of signal vector";
//   Real limPID1.addPID.inPort1.signal[1] "Real input signals";
//   parameter Integer limPID1.addPID.inPort2.n = limPID1.addPID.n "Dimension of signal vector";
//   Real limPID1.addPID.inPort2.signal[1] "Real input signals";
//   parameter Integer limPID1.addPID.inPort3.n = limPID1.addPID.n "Dimension of signal vector";
//   Real limPID1.addPID.inPort3.signal[1] "Real input signals";
//   parameter Integer limPID1.addPID.outPort.n = limPID1.addPID.n "Dimension of signal vector";
//   Real limPID1.addPID.outPort.signal[1] "Real output signals";
//   parameter Real limPID1.addI.k1 = 1.0 "Gain of upper input";
//   parameter Real limPID1.addI.k2 = -1.0 "Gain of middle input";
//   parameter Real limPID1.addI.k3 = 1.0 "Gain of lower input";
//   parameter Integer limPID1.addI.n = 1 "Dimension of input and output vectors.";
//   parameter Integer limPID1.addI.inPort1.n = limPID1.addI.n "Dimension of signal vector";
//   Real limPID1.addI.inPort1.signal[1] "Real input signals";
//   parameter Integer limPID1.addI.inPort2.n = limPID1.addI.n "Dimension of signal vector";
//   Real limPID1.addI.inPort2.signal[1] "Real input signals";
//   parameter Integer limPID1.addI.inPort3.n = limPID1.addI.n "Dimension of signal vector";
//   Real limPID1.addI.inPort3.signal[1] "Real input signals";
//   parameter Integer limPID1.addI.outPort.n = limPID1.addI.n "Dimension of signal vector";
//   Real limPID1.addI.outPort.signal[1] "Real output signals";
//   parameter Integer limPID1.addSat.n = 1 "Dimension of input and output vectors.";
//   parameter Integer limPID1.addSat.inPort1.n = limPID1.addSat.n "Dimension of signal vector";
//   Real limPID1.addSat.inPort1.signal[1] "Real input signals";
//   parameter Integer limPID1.addSat.inPort2.n = limPID1.addSat.n "Dimension of signal vector";
//   Real limPID1.addSat.inPort2.signal[1] "Real input signals";
//   parameter Integer limPID1.addSat.outPort.n = limPID1.addSat.n "Dimension of signal vector";
//   Real limPID1.addSat.outPort.signal[1] "Real output signals";
//   Real limPID1.addSat.y[1] "Output signals";
//   protected Real limPID1.addSat.u1[1] "Input signals 1";
//   protected Real limPID1.addSat.u2[1] "Input signals 2";
//   parameter Real limPID1.addSat.k1 = 1.0 "Gain of upper input";
//   parameter Real limPID1.addSat.k2 = -1.0 "Gain of lower input";
//   parameter Real limPID1.gainTrack.k[1] = 1.0 / (limPID1.Ni * limPID1.k) "Gain vector multiplied element-wise with input vector";
//   protected Real limPID1.gainTrack.u[1] "Input signals";
//   protected Real limPID1.gainTrack.y[1] "Output signals";
//   parameter Integer limPID1.gainTrack.inPort.n = 1 "Dimension of signal vector";
//   Real limPID1.gainTrack.inPort.signal[1] "Real input signals";
//   parameter Integer limPID1.gainTrack.outPort.n = 1 "Dimension of signal vector";
//   Real limPID1.gainTrack.outPort.signal[1] "Real output signals";
//   parameter Integer constant1.nout(min = 1) = 1 "Number of outputs";
//   parameter Integer constant1.outPort.n = constant1.nout "Dimension of signal vector";
//   Real constant1.outPort.signal[1] "Real output signals";
//   Real constant1.y[1];
//   parameter Real constant1.k[1] = 1.0 "Constant output values";
// equation
//   limPID1.limiter.u = {limPID1.limiter.inPort.signal[1]};
//   limPID1.limiter.y[1] = if limPID1.limiter.u[1] > limPID1.limiter.uMax[1] then limPID1.limiter.uMax[1] else if limPID1.limiter.u[1] < limPID1.limiter.uMin[1] then limPID1.limiter.uMin[1] else limPID1.limiter.u[1];
//   limPID1.limiter.y[1] = limPID1.limiter.outPort.signal[1];
//   limPID1.addP.u1 = {limPID1.addP.inPort1.signal[1]};
//   limPID1.addP.u2 = {limPID1.addP.inPort2.signal[1]};
//   limPID1.addP.y[1] = limPID1.addP.u1[1] * limPID1.addP.k1 + limPID1.addP.u2[1] * limPID1.addP.k2;
//   limPID1.addP.y[1] = limPID1.addP.outPort.signal[1];
//   limPID1.addD.u1 = {limPID1.addD.inPort1.signal[1]};
//   limPID1.addD.u2 = {limPID1.addD.inPort2.signal[1]};
//   limPID1.addD.y[1] = limPID1.addD.u1[1] * limPID1.addD.k1 + limPID1.addD.u2[1] * limPID1.addD.k2;
//   limPID1.addD.y[1] = limPID1.addD.outPort.signal[1];
//   limPID1.P.u[1] = limPID1.P.inPort.signal[1];
//   limPID1.P.y[1] = limPID1.P.outPort.signal[1];
//   limPID1.P.y[1] = limPID1.P.k[1] * limPID1.P.u[1];
//   limPID1.I.u = {limPID1.I.inPort.signal[1]};
//   der(limPID1.I.y[1]) = limPID1.I.k[1] * limPID1.I.u[1];
//   limPID1.I.y[1] = limPID1.I.outPort.signal[1];
//   limPID1.D.u = {limPID1.D.inPort.signal[1]};
//   der(limPID1.D.x[1]) = if noEvent(abs(limPID1.D.p_k[1]) >= 1e-15) then (limPID1.D.u[1] - limPID1.D.x[1]) / limPID1.D.p_T[1] else 0.0;
//   limPID1.D.y[1] = if noEvent(abs(limPID1.D.p_k[1]) >= 1e-15) then limPID1.D.p_k[1] * (limPID1.D.u[1] - limPID1.D.x[1]) / limPID1.D.p_T[1] else 0.0;
//   limPID1.D.y[1] = limPID1.D.outPort.signal[1];
//   limPID1.gainPID.u[1] = limPID1.gainPID.inPort.signal[1];
//   limPID1.gainPID.y[1] = limPID1.gainPID.outPort.signal[1];
//   limPID1.gainPID.y[1] = limPID1.gainPID.k[1] * limPID1.gainPID.u[1];
//   limPID1.addPID.outPort.signal[1] = limPID1.addPID.inPort1.signal[1] * limPID1.addPID.k1 + limPID1.addPID.inPort2.signal[1] * limPID1.addPID.k2 + limPID1.addPID.inPort3.signal[1] * limPID1.addPID.k3;
//   limPID1.addI.outPort.signal[1] = limPID1.addI.inPort1.signal[1] * limPID1.addI.k1 + limPID1.addI.inPort2.signal[1] * limPID1.addI.k2 + limPID1.addI.inPort3.signal[1] * limPID1.addI.k3;
//   limPID1.addSat.u1 = {limPID1.addSat.inPort1.signal[1]};
//   limPID1.addSat.u2 = {limPID1.addSat.inPort2.signal[1]};
//   limPID1.addSat.y[1] = limPID1.addSat.u1[1] * limPID1.addSat.k1 + limPID1.addSat.u2[1] * limPID1.addSat.k2;
//   limPID1.addSat.y[1] = limPID1.addSat.outPort.signal[1];
//   limPID1.gainTrack.u[1] = limPID1.gainTrack.inPort.signal[1];
//   limPID1.gainTrack.y[1] = limPID1.gainTrack.outPort.signal[1];
//   limPID1.gainTrack.y[1] = limPID1.gainTrack.k[1] * limPID1.gainTrack.u[1];
//   assert(limPID1.yMax >= limPID1.yMin, "PID: Limits must be consistent");
//   assert(limPID1.inPort_s.n == limPID1.addP.inPort1.n, "automatically generated from connect");
//   assert(limPID1.inPort_m.n == limPID1.addP.inPort2.n, "automatically generated from connect");
//   assert(limPID1.inPort_s.n == limPID1.addD.inPort1.n, "automatically generated from connect");
//   assert(limPID1.inPort_m.n == limPID1.addD.inPort2.n, "automatically generated from connect");
//   assert(limPID1.inPort_s.n == limPID1.addI.inPort1.n, "automatically generated from connect");
//   assert(limPID1.inPort_m.n == limPID1.addI.inPort2.n, "automatically generated from connect");
//   assert(limPID1.gainTrack.outPort.n == limPID1.addI.inPort3.n, "automatically generated from connect");
//   assert(limPID1.addP.outPort.n == limPID1.P.inPort.n, "automatically generated from connect");
//   assert(limPID1.addD.outPort.n == limPID1.D.inPort.n, "automatically generated from connect");
//   assert(limPID1.addI.outPort.n == limPID1.I.inPort.n, "automatically generated from connect");
//   assert(limPID1.P.outPort.n == limPID1.addPID.inPort1.n, "automatically generated from connect");
//   assert(limPID1.D.outPort.n == limPID1.addPID.inPort2.n, "automatically generated from connect");
//   assert(limPID1.I.outPort.n == limPID1.addPID.inPort3.n, "automatically generated from connect");
//   assert(limPID1.addPID.outPort.n == limPID1.gainPID.inPort.n, "automatically generated from connect");
//   assert(limPID1.gainPID.outPort.n == limPID1.addSat.inPort2.n, "automatically generated from connect");
//   assert(limPID1.addSat.outPort.n == limPID1.gainTrack.inPort.n, "automatically generated from connect");
//   assert(limPID1.gainPID.outPort.n == limPID1.limiter.inPort.n, "automatically generated from connect");
//   assert(limPID1.limiter.outPort.n == limPID1.outPort.n, "automatically generated from connect");
//   assert(limPID1.limiter.outPort.n == limPID1.addSat.inPort1.n, "automatically generated from connect");
//   limPID1.u_s = limPID1.inPort_s.signal[1];
//   limPID1.u_m = limPID1.inPort_m.signal[1];
//   limPID1.y = limPID1.outPort.signal[1];
//   constant1.outPort.signal[1] = constant1.k[1];
//   constant1.y[1] = constant1.outPort.signal[1];
//   assert(constant1.outPort.n == limPID1.inPort_s.n, "automatically generated from connect");
//   limPID1.addD.inPort1.signal[1] = limPID1.addI.inPort1.signal[1];
//   limPID1.addD.inPort1.signal[1] = limPID1.addP.inPort1.signal[1];
//   limPID1.addD.inPort1.signal[1] = limPID1.inPort_s.signal[1];
//   limPID1.addD.inPort2.signal[1] = limPID1.addI.inPort2.signal[1];
//   limPID1.addD.inPort2.signal[1] = limPID1.addP.inPort2.signal[1];
//   limPID1.addD.inPort2.signal[1] = limPID1.inPort_m.signal[1];
//   limPID1.addI.inPort3.signal[1] = limPID1.gainTrack.outPort.signal[1];
//   limPID1.P.inPort.signal[1] = limPID1.addP.outPort.signal[1];
//   limPID1.D.inPort.signal[1] = limPID1.addD.outPort.signal[1];
//   limPID1.I.inPort.signal[1] = limPID1.addI.outPort.signal[1];
//   limPID1.P.outPort.signal[1] = limPID1.addPID.inPort1.signal[1];
//   limPID1.D.outPort.signal[1] = limPID1.addPID.inPort2.signal[1];
//   limPID1.I.outPort.signal[1] = limPID1.addPID.inPort3.signal[1];
//   limPID1.addPID.outPort.signal[1] = limPID1.gainPID.inPort.signal[1];
//   limPID1.addSat.inPort2.signal[1] = limPID1.gainPID.outPort.signal[1];
//   limPID1.addSat.inPort2.signal[1] = limPID1.limiter.inPort.signal[1];
//   limPID1.addSat.outPort.signal[1] = limPID1.gainTrack.inPort.signal[1];
//   limPID1.addSat.inPort1.signal[1] = limPID1.limiter.outPort.signal[1];
//   limPID1.addSat.inPort1.signal[1] = limPID1.outPort.signal[1];
//   constant1.outPort.signal[1] = limPID1.inPort_s.signal[1];
// end BC6;
// endResult
