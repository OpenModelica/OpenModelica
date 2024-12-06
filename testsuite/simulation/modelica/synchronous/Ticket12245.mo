package CRML_test
  package Spec_doc
    package ClockConstructors
      partial model ClockConstructors
        Utilities.BooleanConnector b;
        Utilities.ClockConnector clock;
        CRML.Blocks.Events.ClockEvent clockEvent;
        CRML.Blocks.Events.ShowEvent c;
      equation
        connect(b, clockEvent.u);
        connect(clockEvent.y, clock);
        connect(c.u, b);
      end ClockConstructors;

      model ClockConstructors_externals
        CRML.Blocks.Logical.BooleanPulse boolean4Constant1;
        CRML.ETL.Connectors.BooleanOutput b;
      equation
        connect(boolean4Constant1.y, b);
      end ClockConstructors_externals;

      model ClockConstructors_verif
        extends ClockConstructors;
        ClockConstructors_externals externals;
      equation
        b = externals.b;
        annotation(experiment(StopTime = 14));
      end ClockConstructors_verif;
    end ClockConstructors;
  end Spec_doc;

  package Utilities
    connector BooleanConnector = Boolean "'Boolean' as acausal connector";
    connector ClockConnector = Clock "'Clock' as acausal connector";
  end Utilities;
end CRML_test;

package CRML
  package Blocks
    package Events "Events blocks"
      block ClockEvent "Generates a clock signal when the Boolean input changes from false to true"
      protected
        Boolean z;
      public
        ETL.Connectors.BooleanInput u;
        ETL.Connectors.ClockOutput y;
      initial equation
        pre(u) = false;
      equation
        z = edge(u);
        y = Clock(z);
      end ClockEvent;

      block ClockToBoolean "Transform clock to clocked Boolean (output is true if clock is active)"
        ETL.Connectors.BooleanOutput y "Clocked Boolean output signal";
        ETL.Connectors.ClockInput u;
      equation
        when u then
          y = true;
        end when;
      end ClockToBoolean;

      block ShowEvent "Event visualizer"
        ETL.Connectors.BooleanInput u(start = false, fixed = true);
        ClockEvent eventClock;
        ClockToBoolean clockToBoolean;
        ETL.Connectors.BooleanOutput y;
      equation
        connect(u, eventClock.u);
        connect(clockToBoolean.u, eventClock.y);
        connect(clockToBoolean.y, y);
      end ShowEvent;
    end Events;

    package Logical "Logical blocks"
      block BooleanPulse "Generate pulse signal of type Boolean"
        parameter Real width = 0.5 "Width of pulse (s)";
        parameter Real period = 1 "Time for one period (s)";
        parameter Real startTime = 0 "Output = false for time < startTime";
      protected
        Real tick;
      public
        ETL.Connectors.BooleanInput reset "Reset signal";
        ETL.Connectors.BooleanOutput y annotation(extent = [100, -10; 120, 10]);
      initial equation
        if (cardinality(reset) == 0) then
          tick = startTime;
        else
          tick = Modelica.Constants.inf;
        end if;
      equation
        if (cardinality(reset) == 0) then
          reset = false;
        end if;
        when {time >= pre(tick) + period, reset} then
          tick = time;
        end when;
        y = (time > tick) and (time <= tick + width);
      end BooleanPulse;
    end Logical;
  end Blocks;

  package ETL
    package Connectors
      connector BooleanInput = input Boolean "'Boolean' as input";
      connector BooleanOutput = output Boolean "'Boolean' as output";
      connector ClockInput = input Clock "'input Clock' as connector";
      connector ClockOutput = output Clock "'output Clock' as connector";
    end Connectors;
  end ETL;
end CRML;

package ModelicaServices "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine "Machine dependent constants"
    extends Modelica.Icons.Package;
    final constant Real eps = 1e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1e60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;
  annotation(version = "4.0.0", versionDate = "2020-06-04", dateModified = "2020-06-04 11:00:00Z");
end ModelicaServices;

package Modelica "Modelica Standard Library - Version 4.0.0"
  extends Modelica.Icons.Package;

  package Math "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Icons "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function asin "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u "Independent variable";
      output Modelica.Units.SI.Angle y "Dependent variable y=asin(u)";
      external "builtin" y = asin(u);
    end asin;

    function exp "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u "Independent variable";
      output Real y "Dependent variable y=exp(u)";
      external "builtin" y = exp(u);
    end exp;
  end Math;

  package Constants "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;
    import Modelica.Units.NonSI;
    final constant Real pi = 2*Modelica.Math.asin(1.0);
    final constant Real inf = ModelicaServices.Machine.inf "Biggest Real number such that inf and -inf are representable on the machine";
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant SI.ElectricCharge q = 1.602176634e-19 "Elementary charge";
    final constant Real h(final unit = "J.s") = 6.62607015e-34 "Planck constant";
    final constant Real k(final unit = "J/K") = 1.380649e-23 "Boltzmann constant";
    final constant Real N_A(final unit = "1/mol") = 6.02214076e23 "Avogadro constant";
    final constant Real mu_0(final unit = "N/A2") = 4*pi*1.00000000055e-7 "Magnetic constant";
  end Constants;

  package Icons "Library of icons"
    extends Icons.Package;

    partial package Package "Icon for standard packages" end Package;

    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;
  end Icons;

  package Units "Library of type and unit definitions"
    extends Modelica.Icons.Package;

    package SI "Library of SI unit definitions"
      extends Modelica.Icons.Package;
      type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
      type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
      type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
      type ElectricCharge = Real(final quantity = "ElectricCharge", final unit = "C");
      type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    end SI;

    package NonSI "Type definitions of non SI and other units"
      extends Modelica.Icons.Package;
      type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use Modelica.Units.SI.TemperatureDifference)" annotation(absoluteValue = true);
    end NonSI;
  end Units;
  annotation(version = "4.0.0", versionDate = "2020-06-04", dateModified = "2020-06-04 11:00:00Z");
end Modelica;

model ClockConstructors_verif_total
  extends CRML_test.Spec_doc.ClockConstructors.ClockConstructors_verif;
 annotation(experiment(StopTime = 14));
end ClockConstructors_verif_total;
