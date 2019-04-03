// XogenyTest and Sensors are licensed under a [Creative Commons Attribution 3.0 Unported License](https://creativecommons.org/licenses/by/3.0/deed.en_US).
// See https://github.com/xogeny/XogenyTest https://github.com/xogeny/Sensors

package Modelica
  extends Modelica.Icons.Package;

  package Blocks
    extends Modelica.Icons.Package;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real;
      connector RealOutput = output Real;

      partial block SO
        extends Modelica.Blocks.Icons.Block;
        RealOutput y;
      end SO;
    end Interfaces;

    package Sources
      extends Modelica.Icons.SourcesPackage;

      block Sine
        parameter Real amplitude = 1;
        parameter .Modelica.SIunits.Frequency freqHz(start = 1);
        parameter .Modelica.SIunits.Angle phase = 0;
        parameter Real offset = 0;
        parameter .Modelica.SIunits.Time startTime = 0;
        extends .Modelica.Blocks.Interfaces.SO;
      protected
        constant Real pi = Modelica.Constants.pi;
      equation
        y = offset + (if time < startTime then 0 else amplitude * Modelica.Math.sin(2 * pi * freqHz * (time - startTime) + phase));
      end Sine;
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

    function atan2
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1;
      input Real u2;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = atan2(u1, u2);
    end atan2;

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
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
end Modelica;

package XogenyTest
  function assertValue
    input Real actual;
    input Real expected;
    input Real eps = 1e-7;
    input String name = "";
  algorithm
    assert(abs(actual - expected) <= eps, (if name <> "" then "Test " + name + " failed.\n" else "") + "The actual value (" + String(actual) + ") was not within " + String(eps) + " of the expected value (" + String(expected) + ").") annotation(Inline = true);
  end assertValue;

  model AssertFinal
    parameter Real expected;
    parameter Real eps = 1e-6;
    input Real actual;
  algorithm
    when terminal() then
      assertValue(actual, expected, eps);
    end when;
  end AssertFinal;
end XogenyTest;

package Sensors
  package SignalProcessing
    model FourierAnalysis
      parameter Modelica.SIunits.Frequency F0;
      parameter Integer n;
      Modelica.Blocks.Interfaces.RealInput u;
      Modelica.Blocks.Interfaces.RealOutput a0;
      Modelica.Blocks.Interfaces.RealOutput[n] a;
      Modelica.Blocks.Interfaces.RealOutput[n] b;
    protected
      parameter Modelica.SIunits.Time dt = 1.0 / F0;
      Real[n] s = array(sin(2 * .Modelica.Constants.pi * F0 * i * time) for i in 1:n);
      Real[n] c = array(cos(2 * .Modelica.Constants.pi * F0 * i * time) for i in 1:n);
      Real a0i;
      Real[n] ai;
      Real[n] bi;
      Real f;
    public
      Modelica.Blocks.Interfaces.RealOutput[n] mag;
      Modelica.Blocks.Interfaces.RealOutput[n] phase;
    initial equation
      a0i = 0;
      ai = zeros(n);
      bi = zeros(n);
    equation
      der(a0i) = 2 * u;
      der(ai) = 2 * u * c;
      der(bi) = 2 * u * s;
      f = a0 / 2 + a * c + b * s;
      when sample(0, dt) then
        a0 = pre(a0i);
        a = pre(ai);
        b = pre(bi);
        reinit(a0i, 0);
        for i in 1:n loop
          reinit(ai[i], 0);
          reinit(bi[i], 0);
        end for;
      end when;
      mag = array(sqrt(a[i] ^ 2 + b[i] ^ 2) for i in 1:n);
      phase = array(.Modelica.Math.atan2(b[i], a[i]) for i in 1:n);
    end FourierAnalysis;
  end SignalProcessing;

  package Tests
    package FourierAnalysis
      model TestSine
        SignalProcessing.FourierAnalysis analysis(F0 = 1, n = 5);
        Modelica.Blocks.Sources.Sine sine(freqHz = 3, amplitude = 1, offset = 1);
        XogenyTest.AssertFinal check_b(expected = sine.amplitude, actual = analysis.b[3]);
        XogenyTest.AssertFinal offset_check(expected = 2 * sine.offset, actual = analysis.a0);
        XogenyTest.AssertFinal check_a(expected = 0, actual = analysis.a[1]);
      equation
        connect(sine.y, analysis.u);
      end TestSine;
    end FourierAnalysis;
  end Tests;
end Sensors;

model TestSine
  extends Sensors.Tests.FourierAnalysis.TestSine;
  annotation(experiment(StopTime = 5, Tolerance = 1e-008));
end TestSine;
