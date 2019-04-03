package Modelica "Modelica Standard Library - Version 3.2.1 (Build 2)"
extends Modelica.Icons.Package;

  package Blocks
  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Package;

    package Interfaces
    "Library of connectors and partial models for input/output blocks"
      import Modelica.SIunits;
      extends Modelica.Icons.InterfacesPackage;

      connector RealInput = input Real "'input Real' as connector";

      connector RealOutput = output Real "'output Real' as connector";

      connector BooleanInput = input Boolean "'input Boolean' as connector";

      connector BooleanOutput = output Boolean "'output Boolean' as connector";

      partial block SO "Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;

        RealOutput y "Connector of Real output signal";

      end SO;

      partial block partialBooleanSO
      "Partial block with 1 output Boolean signal"

        Blocks.Interfaces.BooleanOutput y "Connector of Boolean output signal";
        extends Modelica.Blocks.Icons.PartialBooleanBlock;


      end partialBooleanSO;
    end Interfaces;

    package Math
    "Library of Real mathematical functions as input/output blocks"
      import Modelica.SIunits;
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

      block RealToBoolean "Convert Real to Boolean signal"

        Blocks.Interfaces.RealInput u "Connector of Real input signal";
        extends Interfaces.partialBooleanSO;
        parameter Real threshold=0.5
        "Output signal y is true, if input u >= threshold";

      equation
        y = u >= threshold;
      end RealToBoolean;
    end Math;

    package Sources
    "Library of signal source blocks generating Real and Boolean signals"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
      extends Modelica.Icons.SourcesPackage;

      block Sine "Generate sine signal"
        parameter Real amplitude=1 "Amplitude of sine wave";
        parameter SIunits.Frequency freqHz(start=1) "Frequency of sine wave";
        parameter SIunits.Angle phase=0 "Phase of sine wave";
        parameter Real offset=0 "Offset of output signal";
        parameter SIunits.Time startTime=0
        "Output = offset for time < startTime";
        extends Interfaces.SO;
    protected
        constant Real pi=Modelica.Constants.pi;

      equation
        y = offset + (if time < startTime then 0 else amplitude*Modelica.Math.sin(2
          *pi*freqHz*(time - startTime) + phase));
      end Sine;
    end Sources;

    package Icons "Icons for Blocks"
        extends Modelica.Icons.IconsPackage;

        partial block Block "Basic graphical layout of input/output block"


        end Block;

      partial block PartialBooleanBlock
      "Basic graphical layout of logical block"

      end PartialBooleanBlock;
    end Icons;
  end Blocks;

  package Math
  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Package;

  package Icons "Icons for Math"
    extends Modelica.Icons.IconsPackage;

    partial function AxisLeft
    "Basic icon for mathematical function with y-axis on left side"

    end AxisLeft;

    partial function AxisCenter
    "Basic icon for mathematical function with y-axis in the center"

    end AxisCenter;
  end Icons;

  function sin "Sine"
    extends Modelica.Math.Icons.AxisLeft;
    input Modelica.SIunits.Angle u;
    output Real y;

  external "builtin" y=  sin(u);
  end sin;

  function asin "Inverse sine (-1 <= u <= 1)"
    extends Modelica.Math.Icons.AxisCenter;
    input Real u;
    output SI.Angle y;

  external "builtin" y=  asin(u);
  end asin;
  end Math;

  package Constants
  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Package;

    final constant Real pi=2*Modelica.Math.asin(1.0);
  end Constants;

  package Icons "Library of icons"
    extends Icons.Package;

    partial package Package "Icon for standard packages"

    end Package;

    partial package InterfacesPackage "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage "Icon for packages containing sources"
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;
  end Icons;

  package SIunits
  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Package;
      end NonSIunits;
    end Conversions;

    type Angle = Real (
        final quantity="Angle",
        final unit="rad",
        displayUnit="deg");

    type Time = Real (final quantity="Time", final unit="s");

    type Frequency = Real (final quantity="Frequency", final unit="Hz");
  end SIunits;
end Modelica;

package Modelica_Synchronous "Modelica_Synchronous (version 0.92.1) - Basic synchronous input/output control blocks
that are triggered by clocks"
extends Modelica.Icons.Package;

  package ClockSignals "Library of blocks for clocked signals"
    extends Modelica.Icons.Package;

    package Clocks "Library of blocks that generate clocks"
      extends Modelica.Icons.SourcesPackage;

      block PeriodicExactClock
      "Generates a periodic clock signal with a period defined by an Integer number with resolution"
        import R = Modelica_Synchronous.Types.Resolution;

        parameter Integer factor(min=0)
        "Sample factor with respect to resolution";
        parameter Modelica_Synchronous.Types.Resolution resolution=R.ms
        "Clock resolution";
        extends
        Modelica_Synchronous.ClockSignals.Interfaces.PartialPeriodicClock;
    protected
        constant Integer conversionTable[8]={365*24*60*60, 24*60*60, 60*60, 60, 1, 1000, 1000*1000, 1000*1000*1000}
        "Table to convert from Resolution to Integer clock resolution";
        parameter Integer resolutionFactor = conversionTable[Integer(resolution)];
        Clock c;
      equation
        if resolution < R.s then
           c = subSample(Clock(factor), resolutionFactor);
        else
           c = superSample(Clock(factor), resolutionFactor);
        end if;

        if useSolver then
           y = Clock(c, solverMethod=solverMethod);
        else
           y = c;
        end if;

      end PeriodicExactClock;

      block EventClock
      "Generates a clock signal when the Boolean input changes from false to true"
        extends Modelica_Synchronous.ClockSignals.Interfaces.PartialClock;
        Modelica.Blocks.Interfaces.BooleanInput u;
      equation
        if useSolver then
           y = Clock(Clock(u), solverMethod=solverMethod);
        else
           y = Clock(u);
        end if;

      end EventClock;
    end Clocks;

    package Sampler
    "Library of blocks that sub-, super-, shift-sample clock signals"
      extends Modelica.Icons.Package;

      block SubSample
      "Sub-sample the input clock and provide it as output clock"
        parameter Integer factor(min=1) "Sub-sampling factor (>= 1)";

        Modelica_Synchronous.ClockSignals.Interfaces.ClockInput u
        "Connector of a clock as input signal";
        Modelica_Synchronous.ClockSignals.Interfaces.ClockOutput y
        "Connector of a clock as output signal (clock y is slower as clock of u)";
      equation
        y = subSample(u,factor);

      end SubSample;

      block SuperSample
      "Super-sample the input clock and provide it as output clock"
        parameter Integer factor(min=1) "Super-sampling factor (>= 1)";

        Modelica_Synchronous.ClockSignals.Interfaces.ClockInput u
        "Connector of a clock as input signal";
        Modelica_Synchronous.ClockSignals.Interfaces.ClockOutput y
        "Connector of a clock as output signal (clock y is faster as clock of u)";
      equation
        y = superSample(u,factor);

      end SuperSample;
    end Sampler;

    package Interfaces
    "Library of connectors and partial blocks with clock signals"
      extends Modelica.Icons.InterfacesPackage;

    connector ClockInput = input Clock "'input Clock' as connector";

    connector ClockOutput = output Clock "'output Clock' as connector";

      partial block PartialClock
      "Icon, connector, and solver method of a block that generates a clock"

        parameter Boolean useSolver = false
        "= true, if solverMethod shall be explicitely defined";
        parameter Modelica_Synchronous.Types.SolverMethod solverMethod="ExplicitEuler"
        "Integration method used for discretized continuous-time partitions";
        Modelica_Synchronous.ClockSignals.Interfaces.ClockOutput y;

      end PartialClock;

      partial block PartialPeriodicClock
      "Icon, connector, and solver method of a block that generates a periodic clock"
        extends Modelica_Synchronous.ClockSignals.Interfaces.PartialClock;

      end PartialPeriodicClock;
    end Interfaces;
  end ClockSignals;

  package RealSignals "Library of clocked blocks for Real signals"
    extends Modelica.Icons.Package;

    package Sampler "Library of sampler and hold blocks for Real signals"
      extends Modelica.Icons.Package;

      block SampleClocked
      "Sample the continuous-time, Real input signal and provide it as clocked output signal. The clock is provided as input signal"
        extends Modelica_Synchronous.RealSignals.Interfaces.SamplerIcon;
        Modelica.Blocks.Interfaces.RealInput u
        "Connector of continuous-time, Real input signal";
        Modelica.Blocks.Interfaces.RealOutput y
        "Connector of clocked, Real output signal";
        Modelica_Synchronous.ClockSignals.Interfaces.ClockInput clock
        "Output signal y is associated with this clock input";

      equation
        y = sample(u,clock);

      end SampleClocked;

      block ShiftSample
      "Shift the clocked Real input signal by a fraction of the last interval and and provide it as clocked output signal"

        parameter Integer shiftCounter(min=0)=0 "Numerator of shifting formula";
        parameter Integer resolution(min=1)=1 "Denominator of shifting formula";

        Modelica.Blocks.Interfaces.RealInput u
        "Connector of clocked, Real input signal";
        Modelica.Blocks.Interfaces.RealOutput y
        "Connector of clocked, Real output signal";
      equation
           y = shiftSample(u,shiftCounter,resolution);
      end ShiftSample;
    end Sampler;

    package Interfaces
    "Library of partial blocks for components with clocked Real signals"
      extends Modelica.Icons.InterfacesPackage;

      partial block SamplerIcon
      "Basic graphical layout of block used for sampling of Real signals"

      end SamplerIcon;
    end Interfaces;
  end RealSignals;

  package Types "Library of types with choices, especially to build menus"
  extends Modelica.Icons.Package;

    type SolverMethod = String
    "Enumeration defining the integration method to solve differential equations in a clocked discretized continuous-time partition";

    type Resolution = enumeration(
      y "y (year)",
      d "d (day)",
      h "h (hour)",
      m "min (minutes)",
      s "s (seconds)",
      ms "ms (milli seconds)",
      us "us (micro seconds)",
      ns "ns (nano seconds)")
    "Enumeration defining the resolution of a clocked signal";
  end Types;
end Modelica_Synchronous;

model MultipleBaseClocks
    discrete Real x( start=0);
  Modelica_Synchronous.ClockSignals.Clocks.PeriodicExactClock clock1(resolution=
       Modelica_Synchronous.Types.Resolution.ms, factor=10);
Modelica_Synchronous.ClockSignals.Sampler.SubSample subSample(factor=4);
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample1;
  Modelica.Blocks.Sources.Sine sine(freqHz=2,
    offset=0.1,
    startTime=0);
  Modelica_Synchronous.ClockSignals.Clocks.PeriodicExactClock clock2(resolution=
       Modelica_Synchronous.Types.Resolution.ms, factor=20);
Modelica_Synchronous.ClockSignals.Sampler.SuperSample superSample(factor=2);
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample2;
  Modelica_Synchronous.ClockSignals.Clocks.PeriodicExactClock clock3(resolution=
       Modelica_Synchronous.Types.Resolution.ms, factor=15);
  Modelica_Synchronous.RealSignals.Sampler.ShiftSample shiftSample1(
      shiftCounter=1, resolution=2);
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample3;

  Modelica_Synchronous.ClockSignals.Clocks.EventClock eventClock;
  Modelica.Blocks.Math.RealToBoolean realToBoolean(threshold=0.5);
  Modelica_Synchronous.ClockSignals.Clocks.EventClock eventClock1;
  Modelica.Blocks.Math.RealToBoolean realToBoolean1(threshold=0.2);
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample4(y(start=0));
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample5;
  Modelica_Synchronous.ClockSignals.Clocks.PeriodicExactClock clock4(resolution=
       Modelica_Synchronous.Types.Resolution.ms, factor=8);
equation

  when Clock(3,10) then
    x = previous(x)+2;
  end when;

  connect(clock1.y, subSample.u);
  connect(subSample.y,sample1. clock);
  connect(clock2.y, superSample.u);
  connect(superSample.y, sample2.clock);
  connect(sample3.y, shiftSample1.u);
  connect(clock3.y, sample3.clock);
  connect(eventClock.u, realToBoolean.y);
  connect(realToBoolean.u, sine.y);
  connect(sample2.u, sine.y);
  connect(sample3.u, sine.y);
  connect(eventClock1.u, realToBoolean1.y);
  connect(realToBoolean1.u, sine.y);
  connect(eventClock.y, sample4.clock);

  connect(sample4.u, sine.y);
  connect(eventClock1.y, sample5.clock);
  connect(sample5.u, sine.y);
  connect(sample1.u, sine.y);
end MultipleBaseClocks;
