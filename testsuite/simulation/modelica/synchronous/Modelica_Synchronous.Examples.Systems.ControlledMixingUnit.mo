package Modelica_Synchronous  "Modelica_Synchronous (version 0.92.1) - Basic synchronous input/output control blocks
that are triggered by clocks"
  extends Modelica.Icons.Package;

  package Examples  "Library of examples to demonstrate the usage of package Modelica_Synchronous"
    extends Modelica.Icons.ExamplesPackage;

    package Systems  "Examples of complete systems"
      extends Modelica.Icons.ExamplesPackage;

      model ControlledMixingUnit  "Simple example of a mixing unit where a (discretized) nonlinear inverse plant model is used as feedforward controller"
        extends Modelica.Icons.Example;
        parameter .Modelica.SIunits.Frequency freq = 1 / 300 "Critical frequency of filter";
        parameter Real c0(unit = "mol/l") = 0.848 "Nominal concentration";
        parameter .Modelica.SIunits.Temperature T0 = 308.5 "Nominal temperature";
        parameter Real a1_inv = 0.2674;
        parameter Real a21_inv = 1.815;
        parameter Real a22_inv = 0.4682;
        parameter Real b_inv = 1.5476;
        parameter Real k0_inv = 1.05e14;
        parameter Real eps = 34.2894;
        parameter Real x10 = 0.42;
        parameter Real x10_inv = 0.6;
        parameter Real x20 = 0.01;
        parameter Real u0 = -0.0224;
        final parameter Real c_start(unit = "mol/l") = c0 * (1 - x10);
        final parameter Real c_inv_start(unit = "mol/l") = c0 * (1 - x10_inv);
        final parameter .Modelica.SIunits.Temperature T_start = T0 * (1 + x20);
        final parameter Real c_high_start(unit = "mol/l") = c0 * (1 - 0.72);
        final parameter Real T_c_start = T0 * (1 + u0);
        parameter Real pro = 1.5 "Deviations of plant to inverse plant parameters";
        final parameter Real a1 = a1_inv * pro;
        final parameter Real a21 = a21_inv * pro;
        final parameter Real a22 = a22_inv * pro;
        final parameter Real b = b_inv * pro;
        final parameter Real k0 = k0_inv * pro;
        Modelica_Synchronous.Examples.Systems.Utilities.ComponentsMixingUnit.MixingUnit invMixingUnit(c0 = c0, T0 = T0, a1 = a1_inv, a21 = a21_inv, a22 = a22_inv, b = b_inv, k0 = k0_inv, eps = eps, c(start = c_start, fixed = true), T(start = T_start, fixed = true, stateSelect = StateSelect.always), T_c(start = T_c_start, fixed = true));
        Modelica.Blocks.Math.Add add;
        Modelica.Blocks.Math.InverseBlockConstraints inverseBlockConstraints;
        Modelica_Synchronous.Examples.Systems.Utilities.ComponentsMixingUnit.MixingUnit mixingUnit(c(start = c_start, fixed = true), T(start = T_start, fixed = true), c0 = c0, T0 = T0, a1 = a1, a21 = a21, a22 = a22, b = b, k0 = k0, eps = eps);
        Modelica.Blocks.Math.Feedback feedback;
        Modelica.Blocks.Math.Gain gain(k = 20);
        Utilities.ComponentsMixingUnit.CriticalDamping filter(n = 3, f = freq, x(start = {0.49, 0.49, 0.49}, fixed = {true, false, false}));
        Modelica_Synchronous.RealSignals.Sampler.Hold hold1(y_start = 0);
        Modelica_Synchronous.RealSignals.Sampler.Sample sample1;
        Modelica_Synchronous.ClockSignals.Clocks.PeriodicRealClock periodicClock1(useSolver = true, period = 1, solverMethod = "ExplicitEuler");
        Modelica.Blocks.Sources.Step step(height = c_high_start - c_start, offset = c_start);
        RealSignals.Sampler.SampleClocked sample2;
      equation
        connect(feedback.y, gain.u);
        connect(gain.y, add.u2);
        connect(inverseBlockConstraints.y2, invMixingUnit.T_c);
        connect(invMixingUnit.c, inverseBlockConstraints.u2);
        connect(invMixingUnit.T, feedback.u1);
        connect(filter.y, inverseBlockConstraints.u1);
        connect(hold1.y, mixingUnit.T_c);
        connect(add.y, hold1.u);
        connect(sample1.u, mixingUnit.T);
        connect(sample1.y, feedback.u2);
        connect(inverseBlockConstraints.y1, add.u1);
        connect(sample2.u, step.y);
        connect(filter.u, sample2.y);
        connect(periodicClock1.y, sample2.clock);
        annotation(experiment(StopTime = 300));
      end ControlledMixingUnit;

      package Utilities
        extends Modelica.Icons.Package;

        package ComponentsMixingUnit
          extends Modelica.Icons.Package;

          model MixingUnit  "Mixing unit demo from Foellinger, Nichtlineare Regelungen II, p. 280"
            Modelica.Blocks.Interfaces.RealInput T_c(unit = "K") "Cooling temperature";
            Modelica.Blocks.Interfaces.RealOutput c(unit = "mol/l") "Concentration";
            Modelica.Blocks.Interfaces.RealOutput T(unit = "K") "Temperature in mixing unit";
            parameter Real c0(unit = "mol/l") = 0.848 "Nominal concentration";
            parameter .Modelica.SIunits.Temperature T0 = 308.5 "Nominal temperature";
            parameter Real a1 = 0.2674;
            parameter Real a21 = 1.815;
            parameter Real a22 = 0.4682;
            parameter Real b = 1.5476;
            parameter Real k0 = 1.05e14;
            parameter Real eps = 34.2894;
            Real gamma "Reaction speed";
          protected
            parameter .Modelica.SIunits.Time tau0 = 60;
            parameter Real wk0 = k0 / c0;
            parameter Real weps = eps * T0;
            parameter Real wa11 = a1 / tau0;
            parameter Real wa12 = c0 / tau0;
            parameter Real wa13 = c0 * a1 / tau0;
            parameter Real wa21 = a21 / tau0;
            parameter Real wa22 = a22 * T0 / tau0;
            parameter Real wa23 = T0 * (a21 - b) / tau0;
            parameter Real wb = b / tau0;
          equation
            gamma = c * wk0 * exp(-weps / T);
            der(c) = (-wa11 * c) - wa12 * gamma + wa13;
            der(T) = (-wa21 * T) + wa22 * gamma + wa23 + wb * T_c;
          end MixingUnit;

          block CriticalDamping  "Output the input signal filtered with an n-th order filter with critical damping"
            extends Modelica.Blocks.Interfaces.SISO;
            parameter Integer n = 2 "Order of filter";
            parameter Modelica.SIunits.Frequency f(start = 1) "Cut-off frequency";
            parameter Boolean normalized = true "= true, if amplitude at f_cut is 3 dB, otherwise unmodified filter";
            output Real[n] x(start = zeros(n)) "Filter states";
          protected
            parameter Real alpha = if normalized then sqrt(2 ^ (1 / n) - 1) else 1.0 "Frequency correction factor for normalized filter";
            parameter Real w = 2 * Modelica.Constants.pi * f / alpha;
          equation
            der(x[1]) = (u - x[1]) * w;
            for i in 2:n loop
              der(x[i]) = (x[i - 1] - x[i]) * w;
            end for;
            y = x[n];
          end CriticalDamping;
        end ComponentsMixingUnit;
      end Utilities;
    end Systems;
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
    end Interfaces;
  end RealSignals;

  package Types  "Library of types with choices, especially to build menus"
    extends Modelica.Icons.Package;
    type SolverMethod = String "Enumeration defining the integration method to solve differential equations in a clocked discretized continuous-time partition";
  end Types;
  annotation(version = "0.92.1", versionBuild = 0, versionDate = "2016-03-11", dateModified = "2016-03-03 18:16:00Z");
end Modelica_Synchronous;

package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1.e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1.e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;
  annotation(Protection(access = Access.hide), version = "3.2.2", versionBuild = 0, versionDate = "2016-01-15", dateModified = "2016-01-15 08:44:41Z");
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.2"
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

      partial block SISO  "Single Input Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealInput u "Connector of Real input signal";
        RealOutput y "Connector of Real output signal";
      end SISO;

      partial block SI2SO  "2 Single Input / 1 Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealInput u1 "Connector of Real input signal 1";
        RealInput u2 "Connector of Real input signal 2";
        RealOutput y "Connector of Real output signal";
      end SI2SO;

      partial block SignalSource  "Base class for continuous signal source"
        extends SO;
        parameter Real offset = 0 "Offset of output signal y";
        parameter .Modelica.SIunits.Time startTime = 0 "Output y = offset for time < startTime";
      end SignalSource;
    end Interfaces;

    package Math  "Library of Real mathematical functions as input/output blocks"
      extends Modelica.Icons.Package;

      block InverseBlockConstraints  "Construct inverse model by requiring that two inputs and two outputs are identical"
        Modelica.Blocks.Interfaces.RealInput u1 "Input signal 1 (u1 = u2)";
        Modelica.Blocks.Interfaces.RealInput u2 "Input signal 2 (u1 = u2)";
        Modelica.Blocks.Interfaces.RealOutput y1 "Output signal 1 (y1 = y2)";
        Modelica.Blocks.Interfaces.RealOutput y2 "Output signal 2 (y1 = y2)";
      equation
        u1 = u2;
        y1 = y2;
        annotation(defaultConnectionStructurallyInconsistent = true);
      end InverseBlockConstraints;

      block Gain  "Output the product of a gain value with the input signal"
        parameter Real k(start = 1, unit = "1") "Gain value multiplied with input signal";
        .Modelica.Blocks.Interfaces.RealInput u "Input signal connector";
        .Modelica.Blocks.Interfaces.RealOutput y "Output signal connector";
      equation
        y = k * u;
      end Gain;

      block Feedback  "Output difference between commanded and feedback input"
        .Modelica.Blocks.Interfaces.RealInput u1;
        .Modelica.Blocks.Interfaces.RealInput u2;
        .Modelica.Blocks.Interfaces.RealOutput y;
      equation
        y = u1 - u2;
      end Feedback;

      block Add  "Output the sum of the two inputs"
        extends .Modelica.Blocks.Interfaces.SI2SO;
        parameter Real k1 = +1 "Gain of upper input";
        parameter Real k2 = +1 "Gain of lower input";
      equation
        y = k1 * u1 + k2 * u2;
      end Add;
    end Math;

    package Sources  "Library of signal source blocks generating Real and Boolean signals"
      extends Modelica.Icons.SourcesPackage;

      block Step  "Generate step signal of type Real"
        parameter Real height = 1 "Height of step";
        extends .Modelica.Blocks.Interfaces.SignalSource;
      equation
        y = offset + (if time < startTime then 0 else height);
      end Step;
    end Sources;

    package Icons  "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block  "Basic graphical layout of input/output block" end Block;
    end Icons;
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
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
    type Temperature = ThermodynamicTemperature;
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
  annotation(version = "3.2.2", versionBuild = 3, versionDate = "2016-04-03", dateModified = "2016-04-03 08:44:41Z");
end Modelica;

model ControlledMixingUnit_total  "Simple example of a mixing unit where a (discretized) nonlinear inverse plant model is used as feedforward controller"
  extends Modelica_Synchronous.Examples.Systems.ControlledMixingUnit;
 annotation(experiment(StopTime = 300));
end ControlledMixingUnit_total;
