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
      connector BooleanInput = input Boolean "'input Boolean' as connector";
      connector BooleanOutput = output Boolean "'output Boolean' as connector";
    end Interfaces;
  end Blocks;

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

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;
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
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
  annotation(version = "3.2.1", versionBuild = 4, versionDate = "2013-08-14", dateModified = "2015-09-30 09:15:00Z");
end Modelica;

package Modelica_Synchronous  "Modelica_Synchronous (version 0.92 Build 2) - Basic synchronous input/output control blocks
that are triggered by clocks"
  extends Modelica.Icons.Package;

  package Examples  "Library of examples to demonstrate the usage of package Modelica_Synchronous"
    extends Modelica.Icons.ExamplesPackage;

    package Elementary  "Examples that are used for the documentation of the blocks"
      extends Modelica.Icons.ExamplesPackage;

      package BooleanSignals  "Examples that are used for the documentation of the Modelica_Synchronous.BooleanSignals sub-library"
        extends Modelica.Icons.ExamplesPackage;

        model TimeBasedPulse  "Example of using the clocked simulation time based Boolean Pulse source block"
          extends Modelica.Icons.Example;
          .Modelica_Synchronous.BooleanSignals.TimeBasedSources.Pulse pulse(width = 50, period = 0.4, startTime = 0.1);
          .Modelica_Synchronous.ClockSignals.Clocks.PeriodicRealClock periodicClock1(period = 0.1);
          .Modelica_Synchronous.BooleanSignals.Sampler.AssignClock assignClock1;
        equation
          connect(periodicClock1.y, assignClock1.clock);
          connect(pulse.y, assignClock1.u);
          annotation(experiment(StopTime = 1.0));
        end TimeBasedPulse;
      end BooleanSignals;
    end Elementary;
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

  package BooleanSignals  "Library of clocked blocks for Boolean signals"
    extends Modelica.Icons.Package;

    package Sampler  "Library of sampler and hold blocks for Boolean signals"
      extends Modelica.Icons.Package;

      block AssignClock  "Assigns a clock to a clocked Boolean signal"
        Modelica.Blocks.Interfaces.BooleanInput u "Connector of clocked, Boolean input signal";
        Modelica.Blocks.Interfaces.BooleanOutput y "Connector of clocked, Boolean output signal";
        Modelica_Synchronous.ClockSignals.Interfaces.ClockInput clock;
      equation
        when clock then
          y = u;
        end when;
      end AssignClock;
    end Sampler;

    package TimeBasedSources  "Package of signal source blocks generating clocked simulation time based Boolean signals"
      extends Modelica.Icons.SourcesPackage;

      block Pulse  "Generate pulse signal of type Boolean"
        extends BooleanSignals.Interfaces.PartialClockedSO;
        parameter Real width(final min = Modelica.Constants.small, final max = 100) = 50 "Width of pulse in % of period";
        parameter Modelica.SIunits.Time period(final min = Modelica.Constants.small, start = 1) "Time for one period";
        parameter Modelica.SIunits.Time startTime = 0 "Time instant of first pulse";
      protected
        Modelica.SIunits.Time simTime;
        parameter Modelica.SIunits.Time Twidth = period * width / 100 "width of one pulse" annotation(HideResult = true);
        Modelica.SIunits.Time next(start = startTime, fixed = true) "next = startTime + n*period, for smallest n such that next>simTime";
      equation
        simTime = sample(time);
        next = if simTime >= previous(next) and previous(next) < simTime + period then previous(next) + period else previous(next);
        y = simTime >= previous(next) or simTime <= next - period + Twidth;
      end Pulse;
    end TimeBasedSources;

    package Interfaces  "Library of partial blocks for components with clocked Boolean signals"
      extends Modelica.Icons.InterfacesPackage;

      partial block PartialClockedSO  "Block with clocked single output Boolean signals"
        extends Modelica_Synchronous.ClockSignals.Interfaces.ClockedBlockIcon;
        Modelica.Blocks.Interfaces.BooleanOutput y "Connector of clocked, Real output signal";
      end PartialClockedSO;
    end Interfaces;
  end BooleanSignals;

  package Types  "Library of types with choices, especially to build menus"
    extends Modelica.Icons.Package;
    type SolverMethod = String "Enumeration defining the integration method to solve differential equations in a clocked discretized continuous-time partition";
  end Types;
  annotation(version = "0.92", versionBuild = 2, versionDate = "2013-09-19", dateModified = "2015-09-09 18:16:00Z");
end Modelica_Synchronous;

model TimeBasedPulse_total  "Example of using the clocked simulation time based Boolean Pulse source block"
  extends Modelica_Synchronous.Examples.Elementary.BooleanSignals.TimeBasedPulse;
 annotation(experiment(StopTime = 1.0));
end TimeBasedPulse_total;
