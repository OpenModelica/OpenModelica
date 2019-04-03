// name:     ModifiersOnExtends.mo [BUG: #2727]
// keywords: extends modifier handling
// status:   correct
//
// check that modifiers on extends are not lost
//

package Bug
  model M1
    replaceable Modelica.Blocks.Sources.Clock clock;
  end M1;

  model M2
    extends M1(clock(offset = 10), clock(startTime = 20));
  end M2;

  model M3
    extends M2(redeclare Modelica.Blocks.Sources.ExpSine clock);
  end M3;
end Bug;

package ModelicaServices
  extends Modelica.Icons.Package;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15;
    final constant Real small = 1.e-60;
    final constant Real inf = 1.e+60;
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax();
  end Machine;
end ModelicaServices;

package Modelica
  extends Modelica.Icons.Package;

  package Blocks
    extends Modelica.Icons.Package;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;
      connector RealOutput = output Real;

      partial block SO
        extends Modelica.Blocks.Icons.Block;
        RealOutput y;
      end SO;
    end Interfaces;

    package Sources
      extends Modelica.Icons.SourcesPackage;

      block Clock
        parameter Modelica.SIunits.Time offset = 0;
        parameter Modelica.SIunits.Time startTime = 0;
        extends .Modelica.Blocks.Interfaces.SO;
      equation
        y = offset + (if time < startTime then 0 else time - startTime);
      end Clock;

      block ExpSine
        parameter Real amplitude = 1;
        parameter .Modelica.SIunits.Frequency freqHz(start = 2);
        parameter .Modelica.SIunits.Angle phase = 0;
        parameter .Modelica.SIunits.Damping damping(start = 1);
        parameter Real offset = 0;
        parameter .Modelica.SIunits.Time startTime = 0;
        extends .Modelica.Blocks.Interfaces.SO;
      protected
        constant Real pi = Modelica.Constants.pi;
      equation
        y = offset + (if time < startTime then 0 else amplitude * Modelica.Math.exp(-(time - startTime) * damping) * Modelica.Math.sin(2 * pi * freqHz * (time - startTime) + phase));
      end ExpSine;
    end Sources;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial block Block  end Block;
    end Icons;
  end Blocks;

  package Math
    extends Modelica.Icons.Package;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft  end AxisLeft;

      partial function AxisCenter  end AxisCenter;
    end Icons;

    function sin
      extends Modelica.Math.Icons.AxisLeft;
      input Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = sin(u);
    end sin;

    function asin
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u);
    end asin;

    function exp
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
    end exp;
  end Math;

  package Constants
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant .Modelica.SIunits.Velocity c = 299792458;
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7;
  end Constants;

  package Icons
    extends Icons.Package;

    partial package Package  end Package;

    partial package InterfacesPackage
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package IconsPackage
      extends Modelica.Icons.Package;
    end IconsPackage;
  end Icons;

  package SIunits
    extends Modelica.Icons.Package;

    package Conversions
      extends Modelica.Icons.Package;

      package NonSIunits
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC");
      end NonSIunits;
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Time = Real(final quantity = "Time", final unit = "s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type DampingCoefficient = Real(final quantity = "DampingCoefficient", final unit = "s-1");
    type Damping = DampingCoefficient;
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
end Modelica;

model M
  extends Bug.M3;
end M;

// Result:
// class M
//   Real clock.y;
//   parameter Real clock.amplitude = 1.0;
//   parameter Real clock.freqHz(quantity = "Frequency", unit = "Hz", start = 2.0);
//   parameter Real clock.phase(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0;
//   parameter Real clock.damping(quantity = "DampingCoefficient", unit = "s-1", start = 1.0);
//   parameter Real clock.offset = 10.0;
//   parameter Real clock.startTime(quantity = "Time", unit = "s") = 20.0;
//   protected constant Real clock.pi = 3.141592653589793;
// equation
//   clock.y = clock.offset + (if time < clock.startTime then 0.0 else clock.amplitude * exp((clock.startTime - time) * clock.damping) * sin(6.283185307179586 * clock.freqHz * (time - clock.startTime) + clock.phase));
// end M;
// endResult
