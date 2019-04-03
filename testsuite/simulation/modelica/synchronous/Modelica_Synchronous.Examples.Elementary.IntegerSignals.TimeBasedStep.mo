package Modelica  "Modelica Standard Library - Version 3.2.1 (Build 4)"
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector IntegerInput = input Integer "'input Integer' as connector";
      connector IntegerOutput = output Integer "'output Integer' as connector";
    end Interfaces;
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
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;
    type Time = Real(final quantity = "Time", final unit = "s");
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

      package IntegerSignals  "Examples that are used for the documentation of the Modelica_Synchronous.IntegerSignals sub-library"
        extends Modelica.Icons.ExamplesPackage;

        model TimeBasedStep  "Example of using the clocked simulation time based Integer Step source block"
          extends Modelica.Icons.Example;
          .Modelica_Synchronous.IntegerSignals.TimeBasedSources.Step step(height = 3, offset = 1, startTime = 0.2);
          .Modelica_Synchronous.ClockSignals.Clocks.PeriodicRealClock periodicClock1(period = 0.1);
          .Modelica_Synchronous.IntegerSignals.Sampler.AssignClock assignClock1;
        equation
          connect(step.y, assignClock1.u);
          connect(periodicClock1.y, assignClock1.clock);
          annotation(experiment(StopTime = 1.0));
        end TimeBasedStep;
      end IntegerSignals;
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

  package IntegerSignals  "Library of clocked blocks for Integer signals"
    extends Modelica.Icons.Package;

    package Sampler  "Library of sampler and hold blocks for Integer signals"
      extends Modelica.Icons.Package;

      block AssignClock  "Assigns a clock to a clocked Integer signal"
        Modelica.Blocks.Interfaces.IntegerInput u "Connector of clocked, Integer input signal";
        Modelica.Blocks.Interfaces.IntegerOutput y "Connector of clocked, Integer output signal";
        Modelica_Synchronous.ClockSignals.Interfaces.ClockInput clock;
      equation
        when clock then
          y = u;
        end when;
      end AssignClock;
    end Sampler;

    package TimeBasedSources  "Package of signal source blocks generating clocked simulation time based Integer signals"
      extends Modelica.Icons.SourcesPackage;

      block Step  "Generate step signal of type Integer"
        extends Interfaces.PartialClockedSO;
        parameter Integer height = 1 "Height of step";
        parameter Integer offset = 0 "Offset of output signal y";
        parameter Modelica.SIunits.Time startTime = 0 "Output y = offset for time < startTime";
      protected
        Modelica.SIunits.Time simTime;
      equation
        simTime = sample(time);
        y = offset + (if simTime < startTime then 0 else height);
      end Step;
    end TimeBasedSources;

    package Interfaces  "Library of partial blocks for components with clocked Integer signals"
      extends Modelica.Icons.InterfacesPackage;

      partial block PartialClockedSO  "Block with clocked single output Integer signal"
        extends Modelica_Synchronous.ClockSignals.Interfaces.ClockedBlockIcon;
        Modelica.Blocks.Interfaces.IntegerOutput y "Connector of clocked, Real output signal";
      end PartialClockedSO;
    end Interfaces;
  end IntegerSignals;

  package Types  "Library of types with choices, especially to build menus"
    extends Modelica.Icons.Package;
    type SolverMethod = String "Enumeration defining the integration method to solve differential equations in a clocked discretized continuous-time partition";
  end Types;
  annotation(version = "0.92", versionBuild = 2, versionDate = "2013-09-19", dateModified = "2015-09-09 18:16:00Z");
end Modelica_Synchronous;

model TimeBasedStep_total  "Example of using the clocked simulation time based Integer Step source block"
  extends Modelica_Synchronous.Examples.Elementary.IntegerSignals.TimeBasedStep;
 annotation(experiment(StopTime = 1.0));
end TimeBasedStep_total;
