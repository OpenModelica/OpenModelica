package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1.e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1.e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;
  annotation(Protection(access = Access.hide), version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z");
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.1 (Build 4)"
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector";
      connector RealOutput = output Real "'output Real' as connector";

      partial block SO  "Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealOutput y "Connector of Real output signal";
      end SO;
    end Interfaces;

    package Math  "Library of Real mathematical functions as input/output blocks"
      extends Modelica.Icons.Package;

      block Feedback  "Output difference between commanded and feedback input"
        .Modelica.Blocks.Interfaces.RealInput u1;
        .Modelica.Blocks.Interfaces.RealInput u2;
        .Modelica.Blocks.Interfaces.RealOutput y;
      equation
        y = u1 - u2;
      end Feedback;
    end Math;

    package Sources  "Library of signal source blocks generating Real and Boolean signals"
      extends Modelica.Icons.SourcesPackage;

      block Ramp  "Generate ramp signal"
        parameter Real height = 1 "Height of ramps";
        parameter Modelica.SIunits.Time duration(min = 0.0, start = 2) "Duration of ramp (= 0.0 gives a Step)";
        parameter Real offset = 0 "Offset of output signal";
        parameter Modelica.SIunits.Time startTime = 0 "Output = offset for time < startTime";
        extends .Modelica.Blocks.Interfaces.SO;
      equation
        y = offset + (if time < startTime then 0 else if time < startTime + duration then (time - startTime) * height / duration else height);
      end Ramp;
    end Sources;

    package Icons  "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block  "Basic graphical layout of input/output block" end Block;
    end Icons;
  end Blocks;

  package Mechanics  "Library of 1-dim. and 3-dim. mechanical components (multi-body, rotational, translational)"
    extends Modelica.Icons.Package;

    package Rotational  "Library to model 1-dimensional, rotational mechanical systems"
      extends Modelica.Icons.Package;

      package Components  "Components for 1D rotational mechanical drive trains"
        extends Modelica.Icons.Package;

        model Inertia  "1D-rotational component with inertia"
          Rotational.Interfaces.Flange_a flange_a "Left flange of shaft";
          Rotational.Interfaces.Flange_b flange_b "Right flange of shaft";
          parameter .Modelica.SIunits.Inertia J(min = 0, start = 1) "Moment of inertia";
          parameter StateSelect stateSelect = StateSelect.default "Priority to use phi and w as states" annotation(HideResult = true);
          .Modelica.SIunits.Angle phi(stateSelect = stateSelect) "Absolute rotation angle of component";
          .Modelica.SIunits.AngularVelocity w(stateSelect = stateSelect) "Absolute angular velocity of component (= der(phi))";
          .Modelica.SIunits.AngularAcceleration a "Absolute angular acceleration of component (= der(w))";
        equation
          phi = flange_a.phi;
          phi = flange_b.phi;
          w = der(phi);
          a = der(w);
          J * a = flange_a.tau + flange_b.tau;
        end Inertia;
      end Components;

      package Sensors  "Sensors to measure variables in 1D rotational mechanical components"
        extends Modelica.Icons.SensorsPackage;

        model SpeedSensor  "Ideal sensor to measure the absolute flange angular velocity"
          extends Rotational.Interfaces.PartialAbsoluteSensor;
          Modelica.Blocks.Interfaces.RealOutput w(unit = "rad/s") "Absolute angular velocity of flange as output signal";
        equation
          w = der(flange.phi);
        end SpeedSensor;
      end Sensors;

      package Sources  "Sources to drive 1D rotational mechanical components"
        extends Modelica.Icons.SourcesPackage;

        model Torque  "Input signal acting as external torque on a flange"
          extends Modelica.Mechanics.Rotational.Interfaces.PartialElementaryOneFlangeAndSupport2;
          Modelica.Blocks.Interfaces.RealInput tau(unit = "N.m") "Accelerating torque acting at flange (= -flange.tau)";
        equation
          flange.tau = -tau;
        end Torque;
      end Sources;

      package Interfaces  "Connectors and partial models for 1D rotational mechanical components"
        extends Modelica.Icons.InterfacesPackage;

        connector Flange_a  "1-dim. rotational flange of a shaft (filled square icon)"
          .Modelica.SIunits.Angle phi "Absolute rotation angle of flange";
          flow .Modelica.SIunits.Torque tau "Cut torque in the flange";
        end Flange_a;

        connector Flange_b  "1-dim. rotational flange of a shaft (non-filled square icon)"
          .Modelica.SIunits.Angle phi "Absolute rotation angle of flange";
          flow .Modelica.SIunits.Torque tau "Cut torque in the flange";
        end Flange_b;

        connector Support  "Support/housing of a 1-dim. rotational shaft"
          .Modelica.SIunits.Angle phi "Absolute rotation angle of the support/housing";
          flow .Modelica.SIunits.Torque tau "Reaction torque in the support/housing";
        end Support;

        partial model PartialElementaryOneFlangeAndSupport2  "Partial model for a component with one rotational 1-dim. shaft flange and a support used for textual modeling, i.e., for elementary models"
          parameter Boolean useSupport = false "= true, if support flange enabled, otherwise implicitly grounded" annotation(Evaluate = true, HideResult = true);
          Flange_b flange "Flange of shaft";
          Support support(phi = phi_support, tau = -flange.tau) if useSupport "Support/housing of component";
        protected
          Modelica.SIunits.Angle phi_support "Absolute angle of support flange";
        equation
          if not useSupport then
            phi_support = 0;
          end if;
        end PartialElementaryOneFlangeAndSupport2;

        partial model PartialAbsoluteSensor  "Partial model to measure a single absolute flange variable"
          extends Modelica.Icons.RotationalSensor;
          Flange_a flange "Flange of shaft from which sensor information shall be measured";
        equation
          0 = flange.tau;
        end PartialAbsoluteSensor;
      end Interfaces;
    end Rotational;
  end Mechanics;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function asin  "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u);
    end asin;

    function exp  "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
    end exp;
  end Math;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real small = ModelicaServices.Machine.small "Smallest number such that small and -small are representable on the machine";
    final constant .Modelica.SIunits.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
  end Constants;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial package ExamplesPackage  "Icon for packages containing runnable examples"
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial model Example  "Icon for runnable examples" end Example;

    partial package Package  "Icon for standard packages" end Package;

    partial package InterfacesPackage  "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage  "Icon for packages containing sources"
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package SensorsPackage  "Icon for packages containing sensors"
      extends Modelica.Icons.Package;
    end SensorsPackage;

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial class RotationalSensor  "Icon representing a round measurement device" end RotationalSensor;
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
      end NonSIunits;
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Time = Real(final quantity = "Time", final unit = "s");
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type AngularAcceleration = Real(final quantity = "AngularAcceleration", final unit = "rad/s2");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type MomentOfInertia = Real(final quantity = "MomentOfInertia", final unit = "kg.m2");
    type Inertia = MomentOfInertia;
    type Torque = Real(final quantity = "Torque", final unit = "N.m");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
  annotation(version = "3.2.1", versionBuild = 4, versionDate = "2013-08-14", dateModified = "2015-09-30 09:15:00Z");
end Modelica;

package Modelica_Synchronous  "Modelica_Synchronous (version 0.92 Build 2) - Basic synchronous input/output control blocks
that are triggered by clocks"
  extends Modelica.Icons.Package;

  package Examples  "Library of examples to demonstrate the usage of package Modelica_Synchronous"
    extends Modelica.Icons.ExamplesPackage;

    package SimpleControlledDrive  "Examples based on a simple controlled drive with different ways to define the sampling"
      extends Modelica.Icons.ExamplesPackage;

      model ClockedWithDiscreteTextbookController  "Simple controlled drive with discrete textbook controller (period is not used in the controller)"
        extends Modelica.Icons.Example;
        Modelica.Mechanics.Rotational.Components.Inertia load(J = 10, phi(fixed = true, start = 0), w(fixed = true, start = 0));
        Modelica.Mechanics.Rotational.Sensors.SpeedSensor speed;
        Modelica.Blocks.Sources.Ramp ramp(duration = 2);
        Modelica.Blocks.Math.Feedback feedback;
        Modelica.Mechanics.Rotational.Sources.Torque torque;
        Modelica_Synchronous.RealSignals.Periodic.PI PI(Td = 1, x(fixed = true), kd = 110);
        Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample2;
        Modelica_Synchronous.RealSignals.Sampler.Hold hold1;
        Modelica_Synchronous.RealSignals.Sampler.Sample sample1;
        Modelica_Synchronous.ClockSignals.Clocks.PeriodicRealClock periodicClock(period = 0.1);
      equation
        connect(speed.flange, load.flange_b);
        connect(torque.flange, load.flange_a);
        connect(feedback.y, PI.u);
        connect(ramp.y, sample2.u);
        connect(sample2.y, feedback.u1);
        connect(PI.y, hold1.u);
        connect(hold1.y, torque.tau);
        connect(sample1.u, speed.w);
        connect(feedback.u2, sample1.y);
        connect(periodicClock.y, sample2.clock);
        annotation(experiment(StopTime = 5));
      end ClockedWithDiscreteTextbookController;
    end SimpleControlledDrive;
  end Examples;

  package ClockSignals  "Library of blocks for clocked signals"
    extends Modelica.Icons.Package;

    package Clocks  "Library of blocks that generate clocks"
      extends Modelica.Icons.SourcesPackage;

      block PeriodicRealClock  "Generates a periodic clock signal with a period defined by a Real number"
        parameter Modelica.SIunits.Time period "Period of clock (defined as Real number)" annotation(Evaluate = true);
        extends Modelica_Synchronous.ClockSignals.Interfaces.PartialPeriodicClock;
      equation
        if useSolver then
          y = Clock(Clock(period), solverMethod = solverMethod);
        else
          y = Clock(period);
        end if;
      end PeriodicRealClock;
    end Clocks;

    package Interfaces  "Library of connectors and partial blocks with clock signals"
      extends Modelica.Icons.InterfacesPackage;
      connector ClockInput = input Clock "'input Clock' as connector";
      connector ClockOutput = output Clock "'output Clock' as connector";

      partial block PartialClock  "Icon, connector, and solver method of a block that generates a clock"
        parameter Boolean useSolver = false "= true, if solverMethod shall be explicitely defined" annotation(Evaluate = true);
        parameter Modelica_Synchronous.Types.SolverMethod solverMethod = "ExplicitEuler" "Integration method used for discretized continuous-time partitions";
        Modelica_Synchronous.ClockSignals.Interfaces.ClockOutput y;
      end PartialClock;

      partial block PartialPeriodicClock  "Icon, connector, and solver method of a block that generates a periodic clock"
        extends Modelica_Synchronous.ClockSignals.Interfaces.PartialClock;
      end PartialPeriodicClock;

      partial block ClockedBlockIcon  "Basic graphical layout of block where at least one input or output is a clocked variable" end ClockedBlockIcon;
    end Interfaces;
  end ClockSignals;

  package RealSignals  "Library of clocked blocks for Real signals"
    extends Modelica.Icons.Package;

    package Sampler  "Library of sampler and hold blocks for Real signals"
      block Sample  "Sample the continuous-time, Real input signal and provide it as clocked output signal (clock is infered)"
        extends Modelica_Synchronous.RealSignals.Interfaces.PartialSISOSampler;
      equation
        y = sample(u);
      end Sample;

      extends Modelica.Icons.Package;

      block SampleClocked  "Sample the continuous-time, Real input signal and provide it as clocked output signal. The clock is provided as input signal"
        extends Modelica_Synchronous.RealSignals.Interfaces.SamplerIcon;
        Modelica.Blocks.Interfaces.RealInput u "Connector of continuous-time, Real input signal";
        Modelica.Blocks.Interfaces.RealOutput y "Connector of clocked, Real output signal";
        Modelica_Synchronous.ClockSignals.Interfaces.ClockInput clock "Output signal y is associated with this clock input";
      equation
        y = sample(u, clock);
      end SampleClocked;

      block Hold  "Hold the clocked, Real input signal and provide it as continuous-time output signal (zero order hold)"
        extends Modelica_Synchronous.RealSignals.Interfaces.PartialSISOHold;
      equation
        y = hold(u);
      end Hold;
    end Sampler;

    package Periodic  "Library of blocks that are designed to operate only on periodically clocked signals (mainly described by z transforms)"
      extends Modelica.Icons.Package;

      block PI  "Discrete-time PI controller"
        extends Modelica_Synchronous.RealSignals.Interfaces.PartialClockedSISO;
        parameter Real kd "Gain of discrete PI controller";
        parameter Real Td(min = Modelica.Constants.small) "Time constant of discrete PI controller";
        output Real x(start = 0) "Discrete PI state";
      equation
        when Clock() then
          x = previous(x) + u / Td;
          y = kd * (x + u);
        end when;
      end PI;
    end Periodic;

    package Interfaces  "Library of partial blocks for components with clocked Real signals"
      extends Modelica.Icons.InterfacesPackage;

      partial block SamplerIcon  "Basic graphical layout of block used for sampling of Real signals" end SamplerIcon;

      partial block PartialSISOSampler  "Basic block used for sampling of Real signals"
        extends Modelica_Synchronous.RealSignals.Interfaces.SamplerIcon;
        Modelica.Blocks.Interfaces.RealInput u "Connector of continuous-time, Real input signal";
        Modelica.Blocks.Interfaces.RealOutput y "Connector of clocked, Real output signal";
      end PartialSISOSampler;

      partial block PartialSISOHold  "Basic block used for zero order hold of Real signals"
        parameter Real y_start = 0.0 "Value of output y before the first tick of the clock associated to input u";
        Modelica.Blocks.Interfaces.RealInput u(final start = y_start) "Connector of clocked, Real input signal";
        Modelica.Blocks.Interfaces.RealOutput y "Connector of continuous-time, Real output signal";
      end PartialSISOHold;

      partial block PartialClockedSISO  "Block with clocked single input and clocked single output Real signals"
        extends Modelica_Synchronous.ClockSignals.Interfaces.ClockedBlockIcon;
        Modelica.Blocks.Interfaces.RealInput u "Connector of clocked, Real input signal";
        Modelica.Blocks.Interfaces.RealOutput y "Connector of clocked, Real output signal";
      end PartialClockedSISO;
    end Interfaces;
  end RealSignals;

  package Types  "Library of types with choices, especially to build menus"
    extends Modelica.Icons.Package;
    type SolverMethod = String "Enumeration defining the integration method to solve differential equations in a clocked discretized continuous-time partition";
  end Types;
  annotation(version = "0.92", versionBuild = 2, versionDate = "2013-09-19", dateModified = "2015-09-09 18:16:00Z");
end Modelica_Synchronous;

model ClockedWithDiscreteTextbookController_total  "Simple controlled drive with discrete textbook controller (period is not used in the controller)"
  extends Modelica_Synchronous.Examples.SimpleControlledDrive.ClockedWithDiscreteTextbookController;
 annotation(experiment(StopTime = 5));
end ClockedWithDiscreteTextbookController_total;
