package Modelica_Synchronous  "Modelica_Synchronous (version 0.92.1) - Basic synchronous input/output control blocks
that are triggered by clocks"
  extends Modelica.Icons.Package;

  package Examples  "Library of examples to demonstrate the usage of package Modelica_Synchronous"
    extends Modelica.Icons.ExamplesPackage;

    package Elementary  "Examples that are used for the documentation of the blocks"
      extends Modelica.Icons.ExamplesPackage;

      package RealSignals  "Examples that are used for the documentation of the Modelica_Synchronous.RealSignals sub-library"
        extends Modelica.Icons.ExamplesPackage;

        model UniformNoise  "Example of a UniformNoise block for Real signals"
          extends Modelica.Icons.Example;
          .Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample;
          .Modelica_Synchronous.ClockSignals.Clocks.PeriodicExactClock periodicClock(factor = 20, resolution = .Modelica_Synchronous.Types.Resolution.ms);
          .Modelica_Synchronous.RealSignals.Sampler.Utilities.Internal.UniformNoise uniformNoise;
          Modelica.Blocks.Sources.Constant const(k = 0);
        equation
          connect(periodicClock.y, sample.clock);
          connect(sample.y, uniformNoise.u);
          connect(const.y, sample.u);
          annotation(experiment(StopTime = 1.1));
        end UniformNoise;
      end RealSignals;
    end Elementary;
  end Examples;

  package ClockSignals  "Library of blocks for clocked signals"
    extends Modelica.Icons.Package;

    package Clocks  "Library of blocks that generate clocks"
      extends Modelica.Icons.SourcesPackage;

      block PeriodicExactClock  "Generates a periodic clock signal with a period defined by an Integer number with resolution"
        parameter Integer factor(min = 0) "Sample factor with respect to resolution" annotation(Evaluate = true);
        parameter Modelica_Synchronous.Types.Resolution resolution = .Modelica_Synchronous.Types.Resolution.ms "Clock resolution" annotation(Evaluate = true, __Dymola_editText = false);
        extends Modelica_Synchronous.ClockSignals.Interfaces.PartialPeriodicClock;
      protected
        constant Integer[8] conversionTable = {365 * 24 * 60 * 60, 24 * 60 * 60, 60 * 60, 60, 1, 1000, 1000 * 1000, 1000 * 1000 * 1000} "Table to convert from Resolution to Integer clock resolution";
        parameter Integer resolutionFactor = conversionTable[Integer(resolution)] annotation(Evaluate = true);
        Clock c annotation(HideResult = true);
      equation
        if resolution < .Modelica_Synchronous.Types.Resolution.s then
          c = subSample(Clock(factor), resolutionFactor);
        else
          c = superSample(Clock(factor), resolutionFactor);
        end if;
        if useSolver then
          y = Clock(c, solverMethod = solverMethod);
        else
          y = c;
        end if;
      end PeriodicExactClock;
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
      extends Modelica.Icons.Package;

      block SampleClocked  "Sample the continuous-time, Real input signal and provide it as clocked output signal. The clock is provided as input signal"
        extends Modelica_Synchronous.RealSignals.Interfaces.SamplerIcon;
        Modelica.Blocks.Interfaces.RealInput u "Connector of continuous-time, Real input signal";
        Modelica.Blocks.Interfaces.RealOutput y "Connector of clocked, Real output signal";
        Modelica_Synchronous.ClockSignals.Interfaces.ClockInput clock "Output signal y is associated with this clock input";
      equation
        y = sample(u, clock);
      end SampleClocked;

      package Utilities  "Utility components that are usually not directly used"
        extends Modelica.Icons.Package;

        package Internal  "Internal blocks and functions that are usually of no interest for the user"
          extends Modelica.Icons.Package;

          block UniformNoise  "Add band-limited uniform noise to a clocked signal"
            extends Modelica_Synchronous.RealSignals.Interfaces.PartialNoise;
            parameter Real noiseMax = 0.1 "Upper limit of noise band";
            parameter Real noiseMin = -noiseMax "Lower limit of noise band";
            parameter Integer[3] firstSeed(each min = 0, each max = 255) = {23, 87, 187} "Integer[3] defining random sequence; required element range: 0..255";
          protected
            Integer[3] seedState(start = firstSeed, each fixed = true) "State of seed" annotation(HideResult = true);
            Real noise "Noise in the range 0..1" annotation(HideResult = true);
          equation
            (noise, seedState) = Modelica_Synchronous.RealSignals.Sampler.Utilities.Internal.random(previous(seedState));
            y = u + noiseMin + (noiseMax - noiseMin) * noise;
          end UniformNoise;

          function random  "Pseudo random number generator"
            input Integer[3] seedIn "Integer vector defining random number sequence, e.g., {23,87,187}";
            output Real x "Random number between 0 and 1";
            output Integer[3] seedOut "Modified seed to be used for next call of random()";
          algorithm
            seedOut[1] := rem(171 * seedIn[1], 30269);
            seedOut[2] := rem(172 * seedIn[2], 30307);
            seedOut[3] := rem(170 * seedIn[3], 30323);
            if seedOut[1] == 0 then
              seedOut[1] := 1;
            else
            end if;
            if seedOut[2] == 0 then
              seedOut[2] := 1;
            else
            end if;
            if seedOut[3] == 0 then
              seedOut[3] := 1;
            else
            end if;
            x := rem(seedOut[1] / 30269.0 + seedOut[2] / 30307.0 + seedOut[3] / 30323.0, 1.0);
          end random;
        end Internal;
      end Utilities;
    end Sampler;

    package Interfaces  "Library of partial blocks for components with clocked Real signals"
      extends Modelica.Icons.InterfacesPackage;

      partial block SamplerIcon  "Basic graphical layout of block used for sampling of Real signals" end SamplerIcon;

      partial block PartialClockedSISO  "Block with clocked single input and clocked single output Real signals"
        extends Modelica_Synchronous.ClockSignals.Interfaces.ClockedBlockIcon;
        Modelica.Blocks.Interfaces.RealInput u "Connector of clocked, Real input signal";
        Modelica.Blocks.Interfaces.RealOutput y "Connector of clocked, Real output signal";
      end PartialClockedSISO;

      partial block PartialNoise  "Interface for SISO blocks with Real signals that add noise to the signal"
        extends Modelica_Synchronous.RealSignals.Interfaces.PartialClockedSISO;
      end PartialNoise;
    end Interfaces;
  end RealSignals;

  package Types  "Library of types with choices, especially to build menus"
    extends Modelica.Icons.Package;
    type SolverMethod = String "Enumeration defining the integration method to solve differential equations in a clocked discretized continuous-time partition";
    type Resolution = enumeration(y "y (year)", d "d (day)", h "h (hour)", m "min (minutes)", s "s (seconds)", ms "ms (milli seconds)", us "us (micro seconds)", ns "ns (nano seconds)") "Enumeration defining the resolution of a clocked signal";
  end Types;
  annotation(version = "0.92.1", versionBuild = 0, versionDate = "2016-03-11", dateModified = "2016-03-03 18:16:00Z");
end Modelica_Synchronous;

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
    end Interfaces;

    package Sources  "Library of signal source blocks generating Real and Boolean signals"
      extends Modelica.Icons.SourcesPackage;

      block Constant  "Generate constant signal of type Real"
        parameter Real k(start = 1) "Constant output value";
        extends .Modelica.Blocks.Interfaces.SO;
      equation
        y = k;
      end Constant;
    end Sources;

    package Icons  "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block  "Basic graphical layout of input/output block" end Block;
    end Icons;
  end Blocks;

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
  annotation(version = "3.2.2", versionBuild = 3, versionDate = "2016-04-03", dateModified = "2016-04-03 08:44:41Z");
end Modelica;

model UniformNoise_total  "Example of a UniformNoise block for Real signals"
  extends Modelica_Synchronous.Examples.Elementary.RealSignals.UniformNoise;
 annotation(experiment(StopTime = 1.1));
end UniformNoise_total;
