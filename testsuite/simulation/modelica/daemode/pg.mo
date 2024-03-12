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

operator record Complex "Complex number with overloaded operators"
  replaceable Real re "Real part of complex number";
  replaceable Real im "Imaginary part of complex number";

  encapsulated operator 'constructor' "Constructor"
    function fromReal "Construct Complex from Real"
      import Complex;
      input Real re "Real part of complex number";
      input Real im = 0 "Imaginary part of complex number";
      output Complex result(re = re, im = im) "Complex number";
    algorithm
      annotation(Inline = true);
    end fromReal;
  end 'constructor';

  encapsulated operator function '0' "Zero-element of addition (= Complex(0))"
    import Complex;
    output Complex result "Complex(0)";
  algorithm
    result := Complex(0);
    annotation(Inline = true);
  end '0';

  encapsulated operator '-' "Unary and binary minus"
    function negate "Unary minus (multiply complex number by -1)"
      import Complex;
      input Complex c1 "Complex number";
      output Complex c2 "= -c1";
    algorithm
      c2 := Complex(-c1.re, -c1.im);
      annotation(Inline = true);
    end negate;

    function subtract "Subtract two complex numbers"
      import Complex;
      input Complex c1 "Complex number 1";
      input Complex c2 "Complex number 2";
      output Complex c3 "= c1 - c2";
    algorithm
      c3 := Complex(c1.re - c2.re, c1.im - c2.im);
      annotation(Inline = true);
    end subtract;
  end '-';

  encapsulated operator '*' "Multiplication"
    function multiply "Multiply two complex numbers"
      import Complex;
      input Complex c1 "Complex number 1";
      input Complex c2 "Complex number 2";
      output Complex c3 "= c1*c2";
    algorithm
      c3 := Complex(c1.re*c2.re - c1.im*c2.im, c1.re*c2.im + c1.im*c2.re);
      annotation(Inline = true);
    end multiply;

    function scalarProduct "Scalar product c1*c2 of two complex vectors"
      import Complex;
      input Complex c1[:] "Vector of Complex numbers 1";
      input Complex c2[size(c1, 1)] "Vector of Complex numbers 2";
      output Complex c3 "= c1*c2";
    algorithm
      c3 := Complex(0);
      for i in 1:size(c1, 1) loop
        c3 := c3 + c1[i]*c2[i];
      end for;
      annotation(Inline = true);
    end scalarProduct;
  end '*';

  encapsulated operator function '+' "Add two complex numbers"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1 + c2";
  algorithm
    c3 := Complex(c1.re + c2.re, c1.im + c2.im);
    annotation(Inline = true);
  end '+';

  encapsulated operator function '/' "Divide two complex numbers"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1/c2";
  algorithm
    c3 := Complex((+c1.re*c2.re + c1.im*c2.im)/(c2.re*c2.re + c2.im*c2.im), (-c1.re*c2.im + c1.im*c2.re)/(c2.re*c2.re + c2.im*c2.im));
    annotation(Inline = true);
  end '/';

  encapsulated operator function '^' "Complex power of complex number"
    import Complex;
    input Complex c1 "Complex number";
    input Complex c2 "Complex exponent";
    output Complex c3 "= c1^c2";
  protected
    Real lnz = 0.5*log(c1.re*c1.re + c1.im*c1.im);
    Real phi = atan2(c1.im, c1.re);
    Real re = lnz*c2.re - phi*c2.im;
    Real im = lnz*c2.im + phi*c2.re;
  algorithm
    c3 := Complex(exp(re)*cos(im), exp(re)*sin(im));
    annotation(Inline = true);
  end '^';

  encapsulated operator function '==' "Test whether two complex numbers are identical"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Boolean result "c1 == c2";
  algorithm
    result := c1.re == c2.re and c1.im == c2.im;
    annotation(Inline = true);
  end '==';

  encapsulated operator function '<>' "Test whether two complex numbers are not identical"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Boolean result "c1 <> c2";
  algorithm
    result := c1.re <> c2.re or c1.im <> c2.im;
    annotation(Inline = true);
  end '<>';

  encapsulated operator function 'String' "Transform Complex number into a String representation"
    import Complex;
    input Complex c "Complex number to be transformed in a String representation";
    input String name = "j" "Name of variable representing sqrt(-1) in the string";
    input Integer significantDigits = 6 "Number of significant digits that are shown";
    output String s = "";
  algorithm
    s := String(c.re, significantDigits = significantDigits);
    if c.im <> 0 then
      if c.im > 0 then
        s := s + " + ";
      else
        s := s + " - ";
      end if;
      s := s + String(abs(c.im), significantDigits = significantDigits) + "*" + name;
    else
    end if;
    annotation(Inline = true);
  end 'String';
  annotation(version = "4.0.0", versionDate = "2020-06-04", dateModified = "2020-06-04 11:00:00Z");
end Complex;

package Modelica "Modelica Standard Library - Version 3.2.3"
  extends Modelica.Icons.Package;

  package Blocks "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Interfaces "Library of connectors and partial models for input/output blocks"
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

      partial block SISO "Single Input Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealInput u "Connector of Real input signal";
        RealOutput y "Connector of Real output signal";
      end SISO;
    end Interfaces;

    package Math "Library of Real mathematical functions as input/output blocks"
      import Modelica.SIunits;
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

      block Gain "Output the product of a gain value with the input signal"
        parameter Real k(start = 1, unit = "1") "Gain value multiplied with input signal";
        Interfaces.RealInput u "Input signal connector";
        Interfaces.RealOutput y "Output signal connector";
      equation
        y = k*u;
      end Gain;

      block Feedback "Output difference between commanded and feedback input"
        Interfaces.RealInput u1;
        Interfaces.RealInput u2;
        Interfaces.RealOutput y;
      equation
        y = u1 - u2;
      end Feedback;
    end Math;

    package Nonlinear "Library of discontinuous or non-differentiable algebraic control blocks"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

      block Limiter "Limit the range of a signal"
        parameter Real uMax(start = 1) "Upper limits of input signals";
        parameter Real uMin = -uMax "Lower limits of input signals";
        parameter Boolean strict = false "= true, if strict limits with noEvent(..)" annotation(Evaluate = true);
        parameter Types.LimiterHomotopy homotopyType = Modelica.Blocks.Types.LimiterHomotopy.Linear "Simplified model for homotopy-based initialization" annotation(Evaluate = true);
        parameter Boolean limitsAtInit = true "Has no longer an effect and is only kept for backwards compatibility (the implementation uses now the homotopy operator)" annotation(Evaluate = true);
        extends Interfaces.SISO;
      protected
        Real simplifiedExpr "Simplified expression for homotopy-based initialization";
      equation
        assert(uMax >= uMin, "Limiter: Limits must be consistent. However, uMax (=" + String(uMax) + ") < uMin (=" + String(uMin) + ")");
        simplifiedExpr = (if homotopyType == Types.LimiterHomotopy.Linear then u else if homotopyType == Types.LimiterHomotopy.UpperLimit then uMax else if homotopyType == Types.LimiterHomotopy.LowerLimit then uMin else 0);
        if strict then
          if homotopyType == Types.LimiterHomotopy.NoHomotopy then
            y = smooth(0, noEvent(if u > uMax then uMax else if u < uMin then uMin else u));
          else
            y = homotopy(actual = smooth(0, noEvent(if u > uMax then uMax else if u < uMin then uMin else u)), simplified = simplifiedExpr);
          end if;
        else
          if homotopyType == Types.LimiterHomotopy.NoHomotopy then
            y = smooth(0, if u > uMax then uMax else if u < uMin then uMin else u);
          else
            y = homotopy(actual = smooth(0, if u > uMax then uMax else if u < uMin then uMin else u), simplified = simplifiedExpr);
          end if;
        end if;
      end Limiter;
    end Nonlinear;

    package Sources "Library of signal source blocks generating Real, Integer and Boolean signals"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
      extends Modelica.Icons.SourcesPackage;

      block RealExpression "Set output signal to a time varying Real expression"
        Modelica.Blocks.Interfaces.RealOutput y = 0.0 "Value of Real output";
      end RealExpression;

      block BooleanExpression "Set output signal to a time varying Boolean expression"
        Modelica.Blocks.Interfaces.BooleanOutput y = false "Value of Boolean output";
      end BooleanExpression;

      block Constant "Generate constant signal of type Real"
        parameter Real k(start = 1) "Constant output value";
        extends Interfaces.SO;
      equation
        y = k;
      end Constant;
    end Sources;

    package Types "Library of constants, external objects and types with choices, especially to build menus"
      extends Modelica.Icons.TypesPackage;
      type LimiterHomotopy = enumeration(NoHomotopy "Homotopy is not used", Linear "Simplified model without limits", UpperLimit "Simplified model fixed at upper limit", LowerLimit "Simplified model fixed at lower limit") "Enumeration defining use of homotopy in limiter components" annotation(Evaluate = true);
    end Types;

    package Icons "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block "Basic graphical layout of input/output block" end Block;
    end Icons;
  end Blocks;

  package Math "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Icons "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft "Basic icon for mathematical function with y-axis on left side" end AxisLeft;

      partial function AxisCenter "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function sin "Sine"
      extends Modelica.Math.Icons.AxisLeft;
      input Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = sin(u);
    end sin;

    function cos "Cosine"
      extends Modelica.Math.Icons.AxisLeft;
      input SI.Angle u;
      output Real y;
      external "builtin" y = cos(u);
    end cos;

    function asin "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output SI.Angle y;
      external "builtin" y = asin(u);
    end asin;

    function atan2 "Four quadrant inverse tangent"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1;
      input Real u2;
      output SI.Angle y;
      external "builtin" y = atan2(u1, u2);
    end atan2;

    function atan3 "Four quadrant inverse tangent (select solution that is closest to given angle y0)"
      import Modelica.Math;
      import Modelica.Constants.pi;
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1;
      input Real u2;
      input Modelica.SIunits.Angle y0 = 0 "y shall be in the range: -pi < y-y0 <= pi";
      output Modelica.SIunits.Angle y;
    protected
      constant Real pi2 = 2*pi;
      Real w;
    algorithm
      w := Math.atan2(u1, u2);
      if y0 == 0 then
        y := w;
      else
        y := w + pi2*integer((pi + y0 - w)/pi2);
      end if;
    end atan3;

    function exp "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
    end exp;
  end Math;

  package ComplexMath "Library of complex mathematical functions (e.g., sin, cos) and of functions operating on complex vectors and matrices"
    extends Modelica.Icons.Package;

    function 'abs' "Absolute value of complex number"
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      output Real result "= abs(c)";
    algorithm
      result := (c.re^2 + c.im^2)^0.5;
      annotation(Inline = true);
    end 'abs';

    function arg "Phase angle of complex number"
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      input Modelica.SIunits.Angle phi0 = 0 "Phase angle phi shall be in the range: -pi < phi-phi0 < pi";
      output Modelica.SIunits.Angle phi "= phase angle of c";
    algorithm
      phi := Modelica.Math.atan3(c.im, c.re, phi0);
      annotation(Inline = true);
    end arg;

    function conj "Conjugate of complex number"
      extends Modelica.Icons.Function;
      input Complex c1 "Complex number";
      output Complex c2 "= c1.re - j*c1.im";
    algorithm
      c2 := Complex(c1.re, -c1.im);
      annotation(Inline = true);
    end conj;

    function real "Real part of complex number"
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      output Real r "= c.re";
    algorithm
      r := c.re;
      annotation(Inline = true);
    end real;

    function fromPolar "Complex from polar representation"
      extends Modelica.Icons.Function;
      input Real len "abs of complex";
      input Modelica.SIunits.Angle phi "arg of complex";
      output Complex c "= len*cos(phi) + j*len*sin(phi)";
    algorithm
      c := Complex(len*Modelica.Math.cos(phi), len*Modelica.Math.sin(phi));
      annotation(Inline = true);
    end fromPolar;
  end ComplexMath;

  package Constants "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Package;
    final constant Real pi = 2*Modelica.Math.asin(1.0);
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant SI.FaradayConstant F = 9.648533289e4 "Faraday constant, C/mol (previous value: 9.64853399e4)";
    final constant Real N_A(final unit = "1/mol") = 6.022140857e23 "Avogadro constant (previous value: 6.0221415e23)";
    final constant Real mue_0(final unit = "N/A2") = 4*pi*1.e-7 "Magnetic constant";
  end Constants;

  package Icons "Library of icons"
    extends Icons.Package;

    partial package ExamplesPackage "Icon for packages containing runnable examples"
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial model Example "Icon for runnable examples" end Example;

    partial package Package "Icon for standard packages" end Package;

    partial package BasesPackage "Icon for packages containing base classes"
      extends Modelica.Icons.Package;
    end BasesPackage;

    partial package InterfacesPackage "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage "Icon for packages containing sources"
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package UtilitiesPackage "Icon for utility packages"
      extends Modelica.Icons.Package;
    end UtilitiesPackage;

    partial package TypesPackage "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial function Function "Icon for functions" end Function;
  end Icons;

  package SIunits "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Conversions "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
      end NonSIunits;
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Time = Real(final quantity = "Time", final unit = "s");
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type Power = Real(final quantity = "Power", final unit = "W");
    type ElectricCurrent = Real(final quantity = "ElectricCurrent", final unit = "A");
    type Current = ElectricCurrent;
    type ElectricCharge = Real(final quantity = "ElectricCharge", final unit = "C");
    type ElectricPotential = Real(final quantity = "ElectricPotential", final unit = "V");
    type Voltage = ElectricPotential;
    type Resistance = Real(final quantity = "Resistance", final unit = "Ohm");
    type Reactance = Resistance;
    type Conductance = Real(final quantity = "Conductance", final unit = "S");
    type Susceptance = Conductance;
    type ActivePower = Real(final quantity = "Power", final unit = "W");
    type ApparentPower = Real(final quantity = "Power", final unit = "V.A");
    type ReactivePower = Real(final quantity = "Power", final unit = "var");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    type PerUnit = Real(unit = "1");
    operator record ComplexCurrent = Complex(redeclare Modelica.SIunits.Current re "Real part of complex current", redeclare Modelica.SIunits.Current im "Imaginary part of complex current") "Complex electrical current";
    operator record ComplexVoltage = Complex(redeclare Modelica.SIunits.Voltage re "Imaginary part of complex voltage", redeclare Modelica.SIunits.Voltage im "Real part of complex voltage") "Complex electrical voltage";
    operator record ComplexAdmittance = Complex(redeclare Conductance re "Real part of complex admittance (conductance)", redeclare Susceptance im "Imaginary part of complex admittance (susceptance)") "Complex electrical admittance";
    operator record ComplexPower = Complex(redeclare ActivePower re "Real part of complex power (active power)", redeclare ReactivePower im "Imaginary part of complex power (reactive power)") "Complex electrical power";
  end SIunits;
  annotation(version = "3.2.3", versionBuild = 4, versionDate = "2019-01-23", dateModified = "2020-06-04 11:00:00Z");
end Modelica;

package PowerGrids
  extends Modelica.Icons.Package;
  import SI = Modelica.SIunits;
  import CM = Modelica.ComplexMath;

  package Examples
    extends Modelica.Icons.ExamplesPackage;

    package IEEE14bus "Classical IEEE14 bus network"
      extends Modelica.Icons.ExamplesPackage;

      model IEEE14busStaticNetwork "Dynamic model of the IEEE 14-bus system, operating in steady-state"
        extends Modelica.Icons.Example;
        inner PowerGrids.Electrical.System systemPowerGrids(initOpt = PowerGrids.Types.Choices.InitializationOption.globalSteadyStateFixedPowerFlow, referenceFrequency = PowerGrids.Types.Choices.ReferenceFrequency.fixedReferenceGenerator);
        PowerGrids.Electrical.Buses.ReferenceBus bus1(SNom = 100e6, UNom = 69e3, UStart = 69e3*1.0598);
        PowerGrids.Electrical.Buses.Bus bus2(SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Buses.Bus bus3(SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Buses.Bus bus4(SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Buses.Bus bus5(SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Buses.Bus bus6(SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Buses.Bus bus7(SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Buses.Bus bus8(SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Buses.Bus bus9(SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Buses.Bus bus10(SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Buses.Bus bus11(SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Buses.Bus bus12(SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Buses.Bus bus13(SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Buses.Bus bus14(SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L1to2(portVariablesPhases = true, R = 0.922682, X = 2.81708, G = 0, B = 0.00110901, SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Branches.LineConstantImpedanceWithBreakers L1to5(portVariablesPhases = true, R = 2.57237, X = 10.6189, G = 0, B = 0.0010334, SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L2to3(portVariablesPhases = true, R = 2.23719, X = 9.42535, G = 0, B = 0.000919975, SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L2to4(portVariablesPhases = true, R = 2.76662, X = 8.3946, G = 0, B = 0.000714136, SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L2to5(portVariablesPhases = true, R = 2.71139, X = 8.27843, G = 0, B = 0.000726738, SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L3to4(portVariablesPhases = true, R = 3.19035, X = 8.14274, G = 0, B = 0.000268851, SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L4to5(portVariablesPhases = true, R = 0.635593, X = 2.00486, G = 0, B = 0, SNom = 100e6, UNom = 69e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L6to11(portVariablesPhases = true, R = 0.18088, X = 0.378785, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L6to12(R = 0.23407, portVariablesPhases = true, X = 0.487165, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L6to13(portVariablesPhases = true, R = 0.125976, X = 0.248086, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L7to8(portVariablesPhases = true, R = 0, X = 0.33546, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L7to9(portVariablesPhases = true, R = 0, X = 0.209503, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L9to10(portVariablesPhases = true, R = 0.060579, X = 0.160922, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L9to14(portVariablesPhases = true, R = 0.242068, X = 0.514912, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L10to11(portVariablesPhases = true, R = 0.156256, X = 0.365778, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L12to13(portVariablesPhases = true, R = 0.42072, X = 0.380651, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.LineConstantImpedance L13to14(portVariablesPhases = true, R = 0.325519, X = 0.662763, G = 0, B = 0, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load2(alpha = 1.5, beta = 2.5, PRefConst = 21.7e6, QRefConst = 12.7e6, SNom = 100e6, UNom = 69e3, URef = 72.105e3, UStart = 72.0866e3, UPhaseStart = -0.087);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load3(alpha = 1.5, beta = 2.5, PRefConst = 94.2e6, QRefConst = 19.1e6, SNom = 100e6, UNom = 69e3, URef = 69.69e3, UStart = 69.685e3, UPhaseStart = -0.22231);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load4(alpha = 1.5, beta = 2.5, PRefConst = 47.8e6, QRefConst = -3.9e6, SNom = 100e6, UNom = 69e3, URef = 70.2756e3, UStart = 70.2049e3, UPhaseStart = -0.180223);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load5(alpha = 1.5, beta = 2.5, PRefConst = 7.6e6, QRefConst = 1.6e6, SNom = 100e6, UNom = 69e3, URef = 70.4552e3, UStart = 70.3898e3, UPhaseStart = -0.153511);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load6(alpha = 1.5, beta = 2.5, PRefConst = 11.2e6, QRefConst = 7.5e6, SNom = 100e6, UNom = 13.8e3, URef = 14.766e3, UStart = 14.7347e3, UPhaseStart = -0.249364);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load9(alpha = 1.5, beta = 2.5, PRefConst = 29.5e6, QRefConst = 16.6e6, SNom = 100e6, UNom = 13.8e3, URef = 14.5966e3, UStart = 14.5624e3, UPhaseStart = -0.261599);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load10(alpha = 1.5, beta = 2.5, PRefConst = 9e6, QRefConst = 5.8e6, SNom = 100e6, UNom = 13.8e3, URef = 14.5241e3, UStart = 14.4903e3, UPhaseStart = -0.264445);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load11(alpha = 1.5, beta = 2.5, PRefConst = 3.5e6, QRefConst = 1.8e6, SNom = 100e6, UNom = 13.8e3, URef = 14.5959e3, UStart = 14.5633e3, UPhaseStart = -0.259223);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load12(alpha = 1.5, beta = 2.5, PRefConst = 6.1e6, QRefConst = 1.6e6, SNom = 100e6, UNom = 13.8e3, URef = 14.499e3, UStart = 14.5308e3, UPhaseStart = -0.264428);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load13(alpha = 1.5, beta = 2.5, PRefConst = 13.8e6, QRefConst = 5.8e6, SNom = 100e6, UNom = 13.8e3, URef = 14.5634e3, UStart = 14.4648e3, UPhaseStart = -0.265952);
        PowerGrids.Electrical.Loads.LoadPQVoltageDependence Load14(alpha = 1.5, beta = 2.5, PRefConst = 14.9e6, QRefConst = 5e6, SNom = 100e6, UNom = 13.8e3, URef = 14.3062e3, UStart = 14.2714e3, UPhaseStart = -0.281002);
        PowerGrids.Electrical.Banks.CapacitorBankFixed Cbank9(B = 0.099769, SNom = 100e6, UNom = 13.8e3);
        PowerGrids.Electrical.Branches.TransformerFixedRatio T4to7(R = 0, X = 0.398248, B = 0, G = 0, rFixed = 0.204082, SNom = 100e6, UNomA = 69e3, UNomB = 13.8e3);
        PowerGrids.Electrical.Branches.TransformerFixedRatio T4to9(R = 0, X = 1.05919, B = 0, G = 0, rFixed = 0.208333, SNom = 100e6, UNomA = 69.0e3, UNomB = 13.8e3);
        PowerGrids.Electrical.Branches.TransformerFixedRatio T5to6(R = 0, X = 0.479948, B = 0, G = 0, rFixed = 0.212766, SNom = 100e6, UNomA = 69e3, UNomB = 13.8e3);
        PowerGrids.Electrical.Branches.TransformerFixedRatio Tgen1(portVariablesPhases = true, R = 0, X = 0.393146, B = 0, G = 0, rFixed = 2.875, SNom = 1211e6, UNomA = 24e3, UNomB = 69e3);
        PowerGrids.Electrical.Branches.TransformerFixedRatioWithBreaker Tgen2(portVariablesPhases = true, R = 0, X = 0.425089, B = 0, G = 0, rFixed = 2.875, SNom = 1120e6, UNomA = 24e3, UNomB = 69e3);
        PowerGrids.Electrical.Branches.TransformerFixedRatio Tgen3(portVariablesPhases = true, R = 0, X = 0.288545, B = 0, G = 0, rFixed = 3.45, SNom = 1650e6, UNomA = 20e3, UNomB = 69e3);
        PowerGrids.Electrical.Branches.TransformerFixedRatio Tgen8(portVariablesPhases = true, R = 0, X = 0.076176, B = 0, G = 0, rFixed = 0.766667, SNom = 250e6, UNomA = 18e3, UNomB = 13.8e3);
        PowerGrids.Examples.IEEE14bus.ControlledGeneratorIEEE GEN1(GEN(DPu = 0.0, H = 5.4, Tppd0 = 0.08, xpdPu = 0.384, Tpd0 = 8.094, raPu = 0.002796, xpqPu = 0.393, Tppq0 = 0.084, Tpq0 = 1.572, xppdPu = 0.264, xdPu = 2.22, xlPu = 0.202, xppqPu = 0.262, xqPu = 2.22, PNom = 1090e6, SNom = 1211e6, UNom = 24e3, PStart = -232.37e6, QStart = 15.7473e6, UStart = 25.4068e3, UPhaseStart = 0.0171006));
        PowerGrids.Examples.IEEE14bus.ControlledGeneratorIEEE GEN2(GEN(DPu = 0.0, H = 5.4, Tppd0 = 0.058, xpdPu = 0.407, Tpd0 = 9.651, raPu = 0.00357, xpqPu = 0.454, Tppq0 = 0.06, Tpq0 = 1.009, xppdPu = 0.3, xdPu = 2.57, xlPu = 0.219, xppqPu = 0.301, xqPu = 2.57, PNom = 1008e6, SNom = 1120e6, UNom = 24e3, PStart = -40e6, QStart = -42.7306e6, UStart = 25.1608e3, UPhaseStart = -0.0837392));
        PowerGrids.Examples.IEEE14bus.SynchronousCondenser GEN3(GEN(DPu = 0.0, H = 5.625, Tppd0 = 0.065, xpdPu = 0.509, Tpd0 = 10.041, raPu = 0.00316, xpqPu = 0.601, Tppq0 = 0.094, Tpq0 = 1.22, xppdPu = 0.354, xdPu = 2.81, xlPu = 0.256, xppqPu = 0.377, xqPu = 2.62, PNom = 1485e6, SNom = 1650e6, UNom = 20e3, PStart = 0.0, QStart = -25.3998e6, UStart = 20.229e3, UPhaseStart = -0.22231));
        PowerGrids.Examples.IEEE14bus.SynchronousCondenser GEN6(GEN(xpqPu = 0.225, Tpq0 = 3.0, DPu = 0.0, H = 4.975, Tppd0 = 0.04, xpdPu = 0.225, Tpd0 = 3.0, raPu = 0.004, Tppq0 = 0.06, xppdPu = 0.154, xdPu = 0.75, xlPu = 0.102, xppqPu = 0.154, xqPu = 0.45, PNom = 71.8e6, SNom = 80.0e6, UNom = 13.8e3, PStart = 0, QStart = -15.0186e6, UStart = 14.7347e3, UPhaseStart = -0.249364));
        PowerGrids.Examples.IEEE14bus.SynchronousCondenser GEN8(GEN(xpqPu = 0.31, Tpq0 = 8.4, DPu = 0.0, H = 2.748, Tppd0 = 0.096, xpdPu = 0.31, Tpd0 = 8.4, raPu = 0.004, Tppq0 = 0.1, xppdPu = 0.275, xdPu = 1.53, xlPu = 0.11, xppqPu = 0.346, xqPu = 0.99, PNom = 242e6, SNom = 250e6, UNom = 18e3, PStart = 0, QStart = -16.2253e6, UStart = 19.6461e3, UPhaseStart = -0.233851));
      equation
        connect(bus12.terminal, L6to12.terminalB);
        connect(L12to13.terminalA, bus12.terminal);
        connect(L12to13.terminalB, bus13.terminal);
        connect(L6to12.terminalA, bus6.terminal);
        connect(L6to13.terminalA, bus6.terminal);
        connect(L6to13.terminalB, bus13.terminal);
        connect(bus13.terminal, L6to13.terminalB);
        connect(L6to11.terminalA, bus6.terminal);
        connect(L6to11.terminalB, bus11.terminal);
        connect(L13to14.terminalA, bus13.terminal);
        connect(L13to14.terminalB, bus14.terminal);
        connect(L9to14.terminalB, bus14.terminal);
        connect(L9to14.terminalA, bus9.terminal);
        connect(L10to11.terminalB, bus11.terminal);
        connect(L10to11.terminalA, bus10.terminal);
        connect(L9to10.terminalB, bus10.terminal);
        connect(L9to10.terminalA, bus9.terminal);
        connect(L7to8.terminalA, bus7.terminal);
        connect(L7to9.terminalA, bus7.terminal);
        connect(L7to9.terminalB, bus9.terminal);
        connect(L7to8.terminalB, bus8.terminal);
        connect(T4to9.terminalA, bus4.terminal);
        connect(T4to9.terminalB, bus9.terminal);
        connect(T5to6.terminalB, bus6.terminal);
        connect(T5to6.terminalA, bus5.terminal);
        connect(L1to2.terminalA, bus1.terminal);
        connect(L1to2.terminalB, bus2.terminal);
        connect(L1to5.terminalA, bus1.terminal);
        connect(L1to5.terminalB, bus5.terminal);
        connect(L2to5.terminalB, bus5.terminal);
        connect(L4to5.terminalB, bus5.terminal);
        connect(L2to5.terminalA, bus2.terminal);
        connect(L2to4.terminalA, bus2.terminal);
        connect(L3to4.terminalB, bus4.terminal);
        connect(L3to4.terminalA, bus3.terminal);
        connect(L2to4.terminalB, bus4.terminal);
        connect(L4to5.terminalA, bus4.terminal);
        connect(L2to3.terminalB, bus3.terminal);
        connect(Tgen8.terminalB, bus8.terminal);
        connect(Tgen3.terminalB, bus3.terminal);
        connect(Tgen2.terminalB, bus2.terminal);
        connect(Tgen1.terminalB, bus1.terminal);
        connect(Load12.terminal, bus12.terminal);
        connect(bus13.terminal, Load13.terminal);
        connect(Load14.terminal, bus14.terminal);
        connect(Load11.terminal, bus11.terminal);
        connect(Load10.terminal, bus10.terminal);
        connect(Cbank9.terminal, bus9.terminal);
        connect(Load9.terminal, bus9.terminal);
        connect(Load6.terminal, bus6.terminal);
        connect(Load5.terminal, bus5.terminal);
        connect(Load3.terminal, bus3.terminal);
        connect(Load2.terminal, bus2.terminal);
        connect(L2to3.terminalA, bus2.terminal);
        connect(Tgen1.terminalA, GEN1.terminal);
        connect(GEN2.terminal, Tgen2.terminalA);
        connect(Tgen3.terminalA, GEN3.terminal);
        connect(GEN8.terminal, Tgen8.terminalA);
        connect(Load4.terminal, bus4.terminal);
        connect(GEN6.terminal, bus6.terminal);
        connect(T4to7.terminalA, bus4.terminal);
        connect(T4to7.terminalB, bus7.terminal);
        connect(GEN1.omega, systemPowerGrids.omegaRefIn);
        annotation(experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-6, Interval = 0.002));
      end IEEE14busStaticNetwork;

      model IEEE14busGen2Disconnection "Simulation of the disconnection of generator 2 at t = 1 s"
        extends IEEE14busStaticNetwork(Tgen2(useBreaker = true));
        Modelica.Blocks.Sources.BooleanExpression Gen2BreakerState(y = time < 1);
      equation
        connect(Gen2BreakerState.y, Tgen2.breakerStatusIn);
        annotation(experiment(StartTime = 0, StopTime = 40, Tolerance = 1e-6, Interval = 0.04));
      end IEEE14busGen2Disconnection;

      model ControlledGeneratorIEEE "Model of controlled generator for the IEEE 14-bus benchmark - synchronous machine with proportional regulations"
        extends Icons.Machine;
        PowerGrids.Electrical.Machines.SynchronousMachine4Windings GEN(portVariablesPhases = true);
        PowerGrids.Interfaces.TerminalAC terminal;
        Electrical.Controls.ExcitationSystems.VRProportional AVR(Ka = 20, VcPuStart = GEN.UStart/GEN.UNom, VrMax = 5, VrMin = -5);
        Electrical.Controls.TurbineGovernors.GoverProportional GOV(KGover = 5, PMaxPu = 1, PMinPu = 0, PPuStart = -GEN.PStart/GEN.PNom);
        PowerGrids.Controls.FreeOffset PmRefPu(use_u = true);
        Controls.FreeOffset VrefPu(use_u = true);
        Modelica.Blocks.Sources.RealExpression VrefPuDef(y = 1);
        Modelica.Blocks.Sources.RealExpression PmRefPuDef(y = -GEN.PStart/GEN.PNom);
        Modelica.Blocks.Interfaces.RealOutput omega;
      equation
        connect(GEN.terminal, terminal);
        connect(GOV.omegaPu, GEN.omegaPu);
        connect(AVR.VcPu, GEN.VPu);
        connect(AVR.efdPu, GEN.ufPuIn);
        connect(GOV.PMechPu, GEN.PmPu);
        connect(PmRefPu.y, GOV.PmRefPu);
        connect(VrefPu.y, AVR.VrefPu);
        connect(VrefPuDef.y, VrefPu.u);
        connect(GEN.PPu, GOV.PPu);
        connect(PmRefPuDef.y, PmRefPu.u);
        connect(GEN.omega, omega);
      end ControlledGeneratorIEEE;

      model SynchronousCondenser "Model of a synchronous condenser for the IEEE-14 bus system"
        extends Icons.Machine;
        PowerGrids.Electrical.Machines.SynchronousMachine4Windings GEN(portVariablesPhases = true);
        PowerGrids.Interfaces.TerminalAC terminal;
        Electrical.Controls.ExcitationSystems.VRProportional AVR(Ka = 20, VcPuStart = GEN.UStart/GEN.UNom, VrMax = 5, VrMin = -5);
        Controls.FreeOffset VrefPu(use_u = true);
        Modelica.Blocks.Sources.RealExpression VrefPuDef(y = 1);
        Modelica.Blocks.Sources.RealExpression PmPu(y = 0);
        Modelica.Blocks.Interfaces.RealOutput omega;
      equation
        connect(GEN.terminal, terminal);
        connect(AVR.VcPu, GEN.VPu);
        connect(AVR.efdPu, GEN.ufPuIn);
        connect(VrefPu.y, AVR.VrefPu);
        connect(VrefPuDef.y, VrefPu.u);
        connect(GEN.omega, omega);
        connect(PmPu.y, GEN.PmPu);
      end SynchronousCondenser;
    end IEEE14bus;
  end Examples;

  package Electrical "Electrical components"
    extends Modelica.Icons.Package;

    model System "System object"
      import PowerGrids.Types.Choices.ReferenceFrequency;
      import PowerGrids.Types.Choices.InitializationOption;
      parameter SI.Frequency fNom = 50 "Nominal system frequency";
      parameter ReferenceFrequency referenceFrequency = ReferenceFrequency.nominalFrequency "Choice of reference frequency for generators";
      parameter InitializationOption initOpt = InitializationOption.globalSteadyStateFixedSetPoints "Initialization option";
      final parameter SI.AngularVelocity omegaNom = fNom*2*Modelica.Constants.pi "Nominal system angular frequency";
      Modelica.Blocks.Interfaces.RealInput omegaRefIn(unit = "rad/s") if referenceFrequency == ReferenceFrequency.fixedReferenceGenerator "Reference frequency input";
      Types.AngularVelocity omegaRef = omegaRefInternal "Reference frequency";
    protected
      Modelica.Blocks.Interfaces.RealInput omegaRefInternal(unit = "rad/s") "Protected connector for conditional connector handling";
    initial equation
      assert(not referenceFrequency == ReferenceFrequency.adaptiveReferenceGenerators, "Adaptive reference generators option not yet implemented");
    equation
      connect(omegaRefIn, omegaRefInternal) "Effective only if omegaRefIn is instantiated";
      if referenceFrequency == ReferenceFrequency.nominalFrequency then
        omegaRefInternal = omegaNom;
      end if;
      annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "
    Your model is using an outer \"systemPowerGrids\" component but
    an inner \"systemPowerGrids\" component is not defined.
    For simulation drag PowerGrids.Electrical.System into your model
    to specify system-wide settings.");
    end System;

    package Branches "Branch component package"
      extends Modelica.Icons.Package;

      model LineConstantImpedance "Transmission line with constant impedance"
        extends BaseClasses.PiNetwork(UNomA = UNom, UNomB = UNomA);
        extends Icons.Line;
        parameter Types.Voltage UNom(start = 400e3) "Nominal/rated voltage";
        parameter Types.Resistance R "Series resistance";
        parameter Types.Reactance X "Series reactance";
        parameter Types.Conductance G = 0 "Shunt conductance";
        parameter Types.Susceptance B = 0 "Shunt susceptance";
      equation
        k = Complex(1);
        Y = 1/Complex(R, X);
        YA = Complex(G/2, B/2);
        YB = Complex(G/2, B/2);
      end LineConstantImpedance;

      model LineConstantImpedanceWithBreakers "Transmission line with constant impedance and breakers"
        extends BaseClasses.PiNetwork(UNomA = UNom, UNomB = UNomA);
        extends Icons.Line;
        encapsulated type BreakersState = enumeration(AcBc "Both breakers at port A and at port B closed", AcBo "Breaker at port A closed, breaker at port B open", AoBc "Breaker at port A open, breaker at port B closed", AoBo "Both breakers at port A and at port B open");
        parameter Boolean useBreakerA = false "Use breaker at port A";
        parameter Boolean useBreakerB = false "Use breaker at port B";
        parameter Types.Voltage UNom(start = 400e3) "Nominal/rated voltage";
        parameter Types.Resistance R "Series resistance";
        parameter Types.Resistance X "Series reactance";
        parameter Types.Conductance G = 0 "Shunt conductance";
        parameter Types.Conductance B = 0 "Shunt susceptance";
        parameter Boolean breakerAStatusStart = true "Breaker A start status - true means breaker closed";
        parameter Boolean breakerBStatusStart = true "Breaker B start status - true means breaker closed";
        final parameter Types.ComplexAdmittance Yseries = 1/Complex(R, X) "Series admittance" annotation(Evaluate = true);
        final parameter Types.ComplexAdmittance Yshunt = Complex(G/2, B/2) "Shunt admittance at port A/B";
        final parameter Types.ComplexAdmittance YbreakerOpen = Yseries*Yshunt/(Yseries + Yshunt) "Total admittance when breaker A/B is open" annotation(Evaluate = true);
        Types.ComplexAdmittance Y_actual "Actual series admittance";
        Types.ComplexAdmittance YA_actual "Actual shunt admittance at port A";
        Types.ComplexAdmittance YB_actual "Actual shunt admittance at port B";
        BreakersState breakerStatus(start = BreakersState.AcBc) "Breakers current status";
        Modelica.Blocks.Interfaces.BooleanInput breakerStatusA if useBreakerA "Breaker status at port A - true means breaker closed";
        Modelica.Blocks.Interfaces.BooleanInput breakerStatusB if useBreakerB "Breaker status at port B - true means breaker closed";
      protected
        Modelica.Blocks.Interfaces.BooleanInput breakerStatusInternalA(start = breakerAStatusStart, fixed = true) "Vreaker status at port A";
        Modelica.Blocks.Interfaces.BooleanInput breakerStatusInternalB(start = breakerBStatusStart, fixed = true) "Breaker status at port B";
      initial algorithm
        if breakerAStatusStart then
          if breakerBStatusStart then
            breakerStatus := BreakersState.AcBc;
          else
            breakerStatus := BreakersState.AcBo;
          end if;
        else
          if breakerBStatusStart then
            breakerStatus := BreakersState.AoBc;
          else
            breakerStatus := BreakersState.AoBo;
          end if;
        end if;
      equation
        if breakerStatus == BreakersState.AcBc then
          Y_actual = Yseries;
          YA_actual = Yshunt;
          YB_actual = Yshunt;
        elseif breakerStatus == BreakersState.AcBo then
          Y_actual = Complex(0);
          YB_actual = Complex(0);
          YA_actual = YbreakerOpen;
        elseif breakerStatus == BreakersState.AoBc then
          Y_actual = Complex(0);
          YA_actual = Complex(0);
          YB_actual = YbreakerOpen;
        else
          Y_actual = Complex(0);
          YB_actual = Complex(0);
          YA_actual = Complex(0);
        end if;
        k = Complex(1);
        Y = Y_actual;
        YA = YA_actual;
        YB = YB_actual;
        connect(breakerStatusA, breakerStatusInternalA);
        connect(breakerStatusB, breakerStatusInternalB);
        if not useBreakerA then
          breakerStatusInternalA = true "Breaker closed";
        end if;
        if not useBreakerB then
          breakerStatusInternalB = true "Breaker closed";
        end if;
      algorithm
        when breakerStatus == BreakersState.AcBc and not pre(breakerStatusInternalB) then
          breakerStatus := BreakersState.AcBo "AcBc to AcBo";
        elsewhen breakerStatus == BreakersState.AcBc and not pre(breakerStatusInternalA) then
          breakerStatus := BreakersState.AoBc "AcBc to AoBc";
        elsewhen breakerStatus == BreakersState.AcBo and not pre(breakerStatusInternalA) then
          breakerStatus := BreakersState.AoBo "AcBo to AoBo";
        elsewhen breakerStatus == BreakersState.AoBc and not pre(breakerStatusInternalB) then
          breakerStatus := BreakersState.AoBo "AoBc to AoBo";
        elsewhen breakerStatus == BreakersState.AoBo and pre(breakerStatusInternalA) then
          breakerStatus := BreakersState.AcBo "AoBo to AcBo";
        elsewhen breakerStatus == BreakersState.AoBo and pre(breakerStatusInternalB) then
          breakerStatus := BreakersState.AoBc "AoBo to AoBc";
        elsewhen breakerStatus == BreakersState.AcBo and pre(breakerStatusInternalB) then
          breakerStatus := BreakersState.AcBc "AcBo to AcBc";
        elsewhen breakerStatus == BreakersState.AoBc and pre(breakerStatusInternalA) then
          breakerStatus := BreakersState.AcBc "AoBc to AcBc";
        end when;
      end LineConstantImpedanceWithBreakers;

      model TransformerFixedRatio "Transformer with fixed voltage ratio"
        extends BaseClasses.PiNetwork;
        extends Icons.Transformer;
        parameter SI.PerUnit rFixed = 1 "Fixed transformer ratio VB/VA";
        parameter SI.Angle thetaFixed = 0 "Fixed phase lead of VB w.r.t. VA";
        parameter Types.Resistance R = 0 "Series resistance on B side";
        parameter Types.Reactance X = 0 "Series reactance on B side";
        parameter Types.Conductance G = 0 "Shunt conductance on B side";
        parameter Types.Susceptance B = 0 "Shunt susceptance on B side";
      equation
        k = CM.fromPolar(rFixed, thetaFixed);
        Y = Complex(1)/Complex(R, X);
        YA = Complex(0);
        YB = Complex(G, B);
      end TransformerFixedRatio;

      model TransformerFixedRatioWithBreaker
        extends BaseClasses.PiNetwork;
        extends Icons.Transformer;
        encapsulated type BreakersState = enumeration(Bc "breaker closed", Bo "breaker open");
        parameter Boolean useBreaker = false "Use breaker (port b)";
        parameter SI.PerUnit rFixed = 1 "Fixed transformer ratio VB/VA";
        parameter SI.Angle thetaFixed = 0 "Fixed phase lead of VB w.r.t. VA";
        parameter Types.Resistance R "Series resistance on B side";
        parameter Types.Reactance X "Series reactance on B side";
        parameter Types.Conductance G = 0 "Shunt conductance on B side";
        parameter Types.Susceptance B = 0 "Shunt susceptance on B side";
        parameter Boolean breakerStatusStart = true "Breaker start status - true means breaker closed";
        final parameter Types.ComplexAdmittance Yseries = Complex(1)/Complex(R, X) "Series admittance" annotation(Evaluate = true);
        final parameter Types.ComplexAdmittance Yshunt = Complex(G, B) "Shunt admittance at port B";
        final parameter Types.ComplexAdmittance YbreakerOpen = Yseries*Yshunt/(Yseries + Yshunt) "Total admittance when breaker is open (port B)" annotation(Evaluate = true);
        Types.ComplexAdmittance Y_actual "Actual series admittance";
        Types.ComplexAdmittance YA_actual "Actual shunt admittance at port A";
        Types.ComplexAdmittance YB_actual "Actual shunt admittance at port B";
        BreakersState breakerStatus(start = BreakersState.Bc) "breacker current status";
        Modelica.Blocks.Interfaces.BooleanInput breakerStatusIn if useBreaker "Breaker Status (port B) - true means breaker closed";
      protected
        Modelica.Blocks.Interfaces.BooleanInput breakerStatusInInternal(start = breakerStatusStart, fixed = true) "breaker Status (port B)";
      initial algorithm
        if breakerStatusStart then
          breakerStatus := BreakersState.Bc;
        else
          breakerStatus := BreakersState.Bo;
        end if;
      equation
        if breakerStatus == BreakersState.Bc then
          Y_actual = Yseries;
          YA_actual = Complex(0);
          YB_actual = Yshunt;
        else
          Y_actual = Complex(0);
          YA_actual = YbreakerOpen;
          YB_actual = Complex(0);
        end if;
        k = CM.fromPolar(rFixed, thetaFixed);
        Y = Y_actual;
        YA = YA_actual;
        YB = YB_actual;
        connect(breakerStatusIn, breakerStatusInInternal);
        if not useBreaker then
          breakerStatusInInternal = true "Breaker closed";
        end if;
      algorithm
        when breakerStatus == BreakersState.Bc and not pre(breakerStatusInInternal) then
          breakerStatus := BreakersState.Bo "Bc to Bo";
        elsewhen breakerStatus == BreakersState.Bo and pre(breakerStatusInInternal) then
          breakerStatus := BreakersState.Bc "Bo to Bc";
        end when;
      end TransformerFixedRatioWithBreaker;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        partial model PiNetwork "Generic Pi-Network base model"
          extends Electrical.BaseClasses.TwoPortAC;
          Types.ComplexAdmittance Y "Series admittance";
          Types.ComplexAdmittance YA "Shunt admittance at port a";
          Types.ComplexAdmittance YB "Shunt admittance at port b";
          Types.ComplexPerUnit k "Complex ratio of ideal transformer at port A (vB/vA)";
          Types.ComplexVoltage vA(re(nominal = portA.VBase), im(nominal = portA.VBase)) = portA.v;
          Types.ComplexVoltage vB(re(nominal = portB.VBase), im(nominal = portB.VBase)) = portB.v;
          Types.ComplexCurrent iA(re(nominal = portA.IBase), im(nominal = portA.IBase)) = portA.i;
          Types.ComplexCurrent iB(re(nominal = portB.IBase), im(nominal = portB.IBase)) = portB.i;
          Types.ComplexVoltage vAt(re(nominal = portB.VBase), im(nominal = portB.VBase));
          Types.ComplexVoltage vz(re(nominal = portB.VBase), im(nominal = portB.VBase));
          Types.ComplexCurrent iAt(re(nominal = portB.IBase), im(nominal = portB.IBase));
          Types.ComplexCurrent iAs(re(nominal = portB.IBase), im(nominal = portB.IBase));
          Types.ComplexCurrent iBs(re(nominal = portB.IBase), im(nominal = portB.IBase));
          Types.ComplexCurrent iz(re(nominal = portB.IBase), im(nominal = portB.IBase));
        equation
          iAt = iz + iAs;
          iBs = iz + iB;
          vAt = vz + vB;
          vAt = k*vA;
          iA = CM.conj(k)*iAt;
          iAs = YA*vAt;
          iBs = YB*vB;
          iz = Y*vz;
        end PiNetwork;
      end BaseClasses;
    end Branches;

    package Buses "Bus models"
      extends Modelica.Icons.Package;

      model Bus "Bus model"
        extends PowerGrids.Electrical.BaseClasses.OnePortAC(final PStart = 0, final QStart = 0);
        extends Icons.Bus;
      equation
        port.i = Complex(0);
      end Bus;

      model ReferenceBus "Reference bus for an isolated grid"
        extends PowerGrids.Electrical.BaseClasses.OnePortAC;
        extends Icons.Bus;
        import PowerGrids.Types.Choices.InitializationOption;
        parameter Boolean setPhaseOnly = false "= true if only the initial voltage phase is to be set";
        parameter InitializationOption initOpt = systemPowerGrids.initOpt "Initialization option";
        final parameter Types.ComplexPerUnit nStart = CM.fromPolar(1, UPhaseStart) "Unit phasor with angle UPhaseStart";
        final parameter Types.ActivePower PSlack(fixed = false) "Constant slack active power leaving system through bus";
        final parameter Types.ReactivePower QSlack(fixed = false) "Constant slack reactive power leaving system through bus";
      initial equation
        if not setPhaseOnly then
          port.u = CM.fromPolar(UStart, UPhaseStart) "Set initial bus voltage, phase-to-phase";
        else
          port.u.re*nStart.im = port.u.im*nStart.re "port.u has the same phase as nStart";
          QSlack = 0 "No reactive power leaving system through bus";
        end if;
        assert(abs(PSlack)/SNom < 0.01, "The active power flowing into or out of the reference bus is above 0.01 pu.\n" + "You probably need a better balancing of the active power generators in the system.\n" + "Please check the documentation of ReferenceBus for further reference", AssertionLevel.warning);
        assert(abs(QSlack)/SNom < 0.01, "The reactive power flowing into or out of the reference bus is above 0.01 pu.\n" + "You probably need a better setup of excitation voltages, or you can set setPhaseOnly = true.\n" + "Please check the documentation of ReferenceBus for further reference", AssertionLevel.warning);
      equation
        port.P = PSlack;
        port.Q = QSlack;
      end ReferenceBus;
    end Buses;

    package Loads "Load models"
      extends Modelica.Icons.Package;

      model LoadPQVoltageDependence "Load model with voltage dependent P and Q"
        extends PowerGrids.Electrical.BaseClasses.OnePortAC(final portVariablesPu = true, PStart = PRefConst, QStart = QRefConst);
        extends Icons.Load;
        parameter Types.PerUnit alpha = 0 "Exponential of voltage ratio for actual P calculation";
        parameter Types.PerUnit beta = 0 "Exponential of voltage ratio for actual Q calculation";
        parameter Types.ActivePower PRefConst = 0 "Constant active power entering the load at reference voltage";
        parameter Types.ReactivePower QRefConst = 0 "Constant reactive power entering the load at reference voltage";
        parameter Types.Voltage URef = UNom "Reference value of phase-to-phase voltage";
        Types.ActivePower PRef(nominal = SNom) = PRefConst "Active power at reference voltage, the default binding can be changed when instantiating";
        Types.ActivePower QRef(nominal = SNom) = QRefConst "Reactive power at reference voltage, the default binding can be changed when instantiating";
        Types.PerUnit U_URef(start = UStart/UNom) "Ratio between voltage and reference voltage";
      equation
        U_URef = port.U/URef;
        port.P = PRef*U_URef^alpha;
        port.Q = QRef*U_URef^beta;
      end LoadPQVoltageDependence;
    end Loads;

    package Banks "Models of capacitor banks"
      extends Modelica.Icons.Package;

      model CapacitorBankFixed "Capacitor bank with fixed capacitance"
        extends Icons.CapacitorBank;
        extends BaseClasses.ShuntConductance(Y = Complex(0, B));
        parameter Types.Susceptance B = 0 "Capacitor bank susceptance";
      end CapacitorBankFixed;
    end Banks;

    package Machines "Synchronous machine models"
      extends Modelica.Icons.Package;

      model SynchronousMachine4Windings "Synchronous machine with four windings - external parameters"
        extends SynchronousMachine4WindingsInternalParameters(final LdPu(fixed = false, min = 1e-3, start = 0.1), final MdPu(fixed = false, min = 1e-3, start = 1), final rfPu(fixed = false, min = 1e-5, start = 0.001), final rDPu(fixed = false, min = 1e-4, start = 0.01), final LfPu(fixed = false, min = 1e-3, start = 0.1), final LDPu(fixed = false, min = 1e-3, start = 0.2), final mrcPu(fixed = false), final LqPu(fixed = false, min = 1e-3, start = 0.1), final MqPu(fixed = false, min = 1e-3, start = 1), final rQ1Pu(fixed = false, min = 1e-5, start = 0.01), final rQ2Pu(fixed = false, min = 1e-5, start = 0.001), final LQ1Pu(fixed = false, min = 1e-3, start = 0.5), final LQ2Pu(fixed = false, min = 1e-3, start = 0.1), final thetaStart = UPhaseStart + atan2(xqPu*IStartPu*cosPhiStart - raPu*IStartPu*sinPhiStart, VStartPu + raPu*IStartPu*cosPhiStart + xqPu*IStartPu*sinPhiStart));
        parameter Types.PerUnit xlPu "Stator leakage in p.u.";
        parameter Types.PerUnit xdPu "Direct axis reactance in p.u.";
        parameter Types.PerUnit xpdPu "Direct axis transient reactance in p.u.";
        parameter Types.PerUnit xppdPu "Direct axis sub-transient reactance p.u.";
        parameter Types.Time Tpd0 "Direct axis, open circuit transient time constant";
        parameter Types.Time Tppd0 "Direct axis, open circuit sub-transient time constant";
        parameter Types.PerUnit xqPu "Quadrature axis reactance in p.u.";
        parameter Types.PerUnit xpqPu "Quadrature axis transient reactance in p.u.";
        parameter Types.PerUnit xppqPu "Quadrature axis sub-transient reactance in p.u.";
        parameter Types.Time Tpq0 "Open circuit quadrature axis transient time constant";
        parameter Types.Time Tppq0 "Open circuit quadrature axis sub-transient time constant";
        parameter Types.Choices.TimeConstantsApproximation timeConstApprox = PowerGrids.Types.Choices.TimeConstantsApproximation.classicalDefinition "Approximation of time constants for internal parameter computation";
        final parameter Types.PerUnit T1dPu(fixed = false, min = 0, start = 1000);
        final parameter Types.PerUnit T2dPu(fixed = false, min = 0, start = 100);
        final parameter Types.PerUnit T3dPu(fixed = false, min = 0, start = 10);
        final parameter Types.PerUnit T4dPu(fixed = false, min = 0, start = 1000);
        final parameter Types.PerUnit T5dPu(fixed = false, min = 0, start = 100);
        final parameter Types.PerUnit T6dPu(fixed = false, min = 0, start = 10);
        final parameter Types.PerUnit T1qPu(fixed = false, min = 0, start = 1000);
        final parameter Types.PerUnit T2qPu(fixed = false, min = 0, start = 100);
        final parameter Types.PerUnit T3qPu(fixed = false, min = 0, start = 10);
        final parameter Types.PerUnit T4qPu(fixed = false, min = 0, start = 100);
        final parameter Types.PerUnit T5qPu(fixed = false, min = 0, start = 100);
        final parameter Types.PerUnit T6qPu(fixed = false, min = 0, start = 10);
        final parameter Types.Time Tpd(fixed = false, min = 0, start = 10);
        final parameter Types.Time Tppd(fixed = false, min = 0, start = 0.1);
        final parameter Types.Time Tpq(fixed = false, min = 0, start = 1);
        final parameter Types.Time Tppq(fixed = false, min = 0, start = 0.1);
        final parameter Types.PerUnit cosPhiStart = abs(PStart)/sqrt(PStart^2 + QStart^2 + 1e-9*SNom) "Start value of power factor cos(phi)";
        final parameter Types.PerUnit sinPhiStart = sqrt(1 - cosPhiStart^2) "Start value of sin(phi)";
        final parameter Types.PerUnit VStartPu = port.VStart/port.VBase "Start value of voltage modulus in p.u.";
        final parameter Types.PerUnit IStartPu = port.IStart/port.IBase "Start value of current modulus in p.u.";
      initial equation
        LqPu = xlPu;
        LdPu = xlPu;
        MdPu + LdPu = xdPu;
        T1dPu = (MdPu + LfPu)/rfPu;
        T2dPu = (MdPu + LDPu)/rDPu;
        T3dPu = (LDPu + MdPu*LfPu/(MdPu + LfPu))/rDPu;
        T4dPu = (LfPu + MdPu*LdPu/(MdPu + LdPu))/rfPu;
        T5dPu = (LDPu + MdPu*LdPu/(MdPu + LdPu))/rDPu;
        T6dPu = (LDPu + MdPu*LdPu*LfPu/(MdPu*LdPu + MdPu*LfPu + LdPu*LfPu))/rDPu;
        if timeConstApprox == Types.Choices.TimeConstantsApproximation.classicalDefinition then
          Tpd0*omegaBase = T1dPu;
          Tppd0*omegaBase = T3dPu;
          Tpd*omegaBase = T4dPu;
          Tppd*omegaBase = T6dPu;
        elseif timeConstApprox == Types.Choices.TimeConstantsApproximation.accurateEstimation then
          Tpd0*omegaBase = homotopy(T1dPu + T2dPu, T1dPu);
          Tppd0*omegaBase = homotopy(T1dPu*T3dPu/(T1dPu + T2dPu), T3dPu);
          Tpd*omegaBase = homotopy(T4dPu + T5dPu, T4dPu);
          Tppd*omegaBase = homotopy(T4dPu*T6dPu/(T4dPu + T5dPu), T6dPu);
        else
          Tpd0*omegaBase = homotopy(Functions.largerTimeConstant(T1dPu + T2dPu, T1dPu*T3dPu), T1dPu);
          Tppd0*omegaBase = homotopy(Functions.smallerTimeConstant(T1dPu + T2dPu, T1dPu*T3dPu), T3dPu);
          Tpd*omegaBase = homotopy(Functions.largerTimeConstant(T4dPu + T5dPu, T4dPu*T6dPu), T4dPu);
          Tppd*omegaBase = homotopy(Functions.smallerTimeConstant(T4dPu + T5dPu, T4dPu*T6dPu), T6dPu);
        end if;
        xpdPu = xdPu*Tpd/Tpd0;
        xppdPu = xpdPu*Tppd/Tppd0;
        MqPu + LqPu = xqPu;
        T1qPu = (MqPu + LQ1Pu)/rQ1Pu;
        T2qPu = (MqPu + LQ2Pu)/rQ2Pu;
        T3qPu = (LQ2Pu + MqPu*LQ1Pu/(MqPu + LQ1Pu))/rQ2Pu;
        T4qPu = (LQ1Pu + MqPu*LqPu/(MqPu + LqPu))/rQ1Pu;
        T5qPu = (LQ2Pu + MqPu*LqPu/(MqPu + LqPu))/rQ2Pu;
        T6qPu = (LQ2Pu + MqPu*LqPu*LQ1Pu/(MqPu*LqPu + MqPu*LQ1Pu + LqPu*LQ1Pu))/rQ2Pu;
        if timeConstApprox == Types.Choices.TimeConstantsApproximation.classicalDefinition then
          Tpq0*omegaBase = T1qPu;
          Tpq*omegaBase = T4qPu;
          Tppq0*omegaBase = T3qPu;
          Tppq*omegaBase = T6qPu;
        elseif timeConstApprox == Types.Choices.TimeConstantsApproximation.accurateEstimation then
          Tpq0*omegaBase = homotopy(T1qPu + T2qPu, T1qPu);
          Tppq0*omegaBase = homotopy(T1qPu*T3qPu/(T1qPu + T2qPu), T3qPu);
          Tpq*omegaBase = homotopy(T4qPu + T5qPu, T4qPu);
          Tppq*omegaBase = homotopy(T4qPu*T6qPu/(T4qPu + T5qPu), T6qPu);
        else
          Tpq0*omegaBase = homotopy(Functions.largerTimeConstant(T1qPu + T2qPu, T1qPu*T3qPu), T1qPu);
          Tppq0*omegaBase = homotopy(Functions.smallerTimeConstant(T1qPu + T2qPu, T1qPu*T3qPu), T3qPu);
          Tpq*omegaBase = homotopy(Functions.largerTimeConstant(T4qPu + T5qPu, T4qPu*T6qPu), T4qPu);
          Tppq*omegaBase = homotopy(Functions.smallerTimeConstant(T4qPu + T5qPu, T4qPu*T6qPu), T6qPu);
        end if;
        xpqPu = xqPu*Tpq/Tpq0;
        xppqPu = xpqPu*Tppq/Tppq0;
        mrcPu = 0;
      end SynchronousMachine4Windings;

      model SynchronousMachine4WindingsInternalParameters "Synchronous machine with 4 windings - internal parameters"
        extends BaseClasses.OnePortACdqPU(final generatorConvention = true, localInit = if initOpt == InitializationOption.localSteadyStateFixedPowerFlow then LocalInitializationOption.PV else LocalInitializationOption.none);
        extends Icons.Machine;
        import PowerGrids.Types.Choices.InitializationOption;
        import PowerGrids.Types.Choices.LocalInitializationOption;
        parameter Types.ActivePower PNom = SNom "Nominal active (turbine) power";
        parameter Types.PerUnit raPu "Armature resistance in p.u.";
        parameter Types.PerUnit LdPu "Direct axis stator leakage in p.u.";
        parameter Types.PerUnit MdPu "Direct axis mutual inductance in p.u.";
        parameter Types.PerUnit mrcPu "Canay's mutual inductance in p.u.";
        parameter Types.PerUnit LDPu "Direct axis damper leakage in p.u.";
        parameter Types.PerUnit rDPu "Resistance of the direct axis damper in p.u.";
        parameter Types.PerUnit LfPu "Excitation winding leakage in p.u.";
        parameter Types.PerUnit rfPu "Resistance of the excitation windings in p.u.";
        parameter Types.PerUnit LqPu "Quadrature axis stator leakage in p.u.";
        parameter Types.PerUnit MqPu "Quadrature axis mutual inductance in p.u.";
        parameter Types.PerUnit LQ1Pu "Quadrature axis 1st damper leakage in p.u.";
        parameter Types.PerUnit rQ1Pu "Quadrature axis 2nd damper leakage in p.u.";
        parameter Types.PerUnit LQ2Pu "Leakage of quadrature axis 2nd damper in p.u.";
        parameter Types.PerUnit rQ2Pu "Resistance of quadrature axis 2nd damper in p.u.";
        parameter Types.PerUnit DPu = 0 "Damping coefficient of the swing equation in p.u.";
        parameter Modelica.SIunits.Time H "Kinetic constant = kinetic energy / rated power";
        parameter Types.Choices.ExcitationPuType excitationPuType = PowerGrids.Types.Choices.ExcitationPuType.nominalStatorVoltageNoLoad "Choice of excitation base voltage";
        parameter Boolean neglectTransformerTerms = true "Neglect the transformer terms in the Park equations";
        parameter Boolean referenceGenerator = false "True if reference generator in an isolated synchronous system";
        parameter Types.Choices.InitializationOption initOpt = systemPowerGrids.initOpt "Initialization option";
        final parameter SI.AngularVelocity omegaBase = systemPowerGrids.omegaNom "Base angular frequency value";
        final parameter Types.PerUnit kuf(fixed = false) "Scaling factor for excitation p.u. voltage";
        constant Types.PerUnit omegaNomPu = 1 "Nominal frequency in p.u.";
        final parameter Types.PerUnit lambdadPuStart(fixed = false) "Start value of lambdadPu";
        final parameter Types.PerUnit lambdaqPuStart(fixed = false) "Start value of lambdaqPu";
        final parameter Types.PerUnit ufPuStart(fixed = false) "Start value of exciter voltage in p.u. (Kundur base)";
        final parameter Types.PerUnit ufPuInStart(fixed = false) "Start value of input exciter voltage in p.u. (user-selcted base";
        final parameter Types.PerUnit ifPuStart(fixed = false) "Start value of ifPu";
        Modelica.Blocks.Interfaces.RealInput PmPu(unit = "1") "Input mechanical power in p.u. (base PNom)";
        Modelica.Blocks.Interfaces.RealInput ufPuIn(unit = "1", start = ufPuInStart) "Input voltage of exciter winding in p.u. (user-selected base voltage)";
        Modelica.Blocks.Interfaces.RealOutput omega(unit = "rad/s") "Angular frequency in rad/s for system object";
        Modelica.Blocks.Interfaces.RealOutput omegaPu(start = 1) "Angular frequency in p.u.";
        Types.PerUnit iDPu(start = 0) "Current of direct axis damper in p.u";
        Types.PerUnit ifPu(start = ifPuStart) "Current of excitation winding in p.u.";
        Types.PerUnit iQ1Pu(start = 0) "Current of quadrature axis 1st damper in p.u.";
        Types.PerUnit iQ2Pu(start = 0) "Current of quadrature axis 2nd damper in p.u.";
        Types.PerUnit ufPu(start = ufPuStart) "Voltage of exciter winding in p.u. (base voltage as per Kundur)";
        Types.PerUnit lambdadPu(start = lambdadPuStart) "Flux of direct axis in p.u.";
        Types.PerUnit lambdaqPu(start = lambdaqPuStart) "Flux of quadrature axis in p.u.";
        Types.PerUnit lambdaDPu "Flux of direct axis damper in p.u";
        Types.PerUnit lambdafPu "Flux of excitation winding in p.u.";
        Types.PerUnit lambdaQ1Pu "Flux of quadrature axis 1st damper in p.u.";
        Types.PerUnit lambdaQ2Pu "Flux of quadrature axis 1st damper in p.u.";
        Types.PerUnit omegaRefPu = systemPowerGrids.omegaRef/systemPowerGrids.omegaNom "Reference frequency in p.u.";
        Types.PerUnit CmPu(start = -PStart/SNom) "Mechanical torque in p.u. (base PNom/omegaBase)";
        Types.PerUnit CePu(start = -PStart/SNom) "Electrical torque in p.u. (base SNom/omegaBase)";
        Types.PerUnit PePu(start = -PStart/SNom) "Electrical power in p.u. (base SNom)";
        Types.PerUnit PePuPNom = PePu*SNom/PNom "Electrical active power in p.u. (base PNom)";
        Types.Frequency f = systemPowerGrids.fNom*omegaPu "Frequency of rotation of d-q axes";
        Modelica.Blocks.Interfaces.RealOutput VPu "Port voltage magnitude [pu]";
        Modelica.Blocks.Interfaces.RealOutput PPu "Active Power Production [pu base PNom]";
      initial equation
        if excitationPuType == Types.Choices.ExcitationPuType.Kundur then
          kuf = 1 "Choice of per-unit as per Kundur textbook";
        else
          kuf = rfPu/MdPu "Base voltage gives 1 p.u. air-gap stator voltage at no load";
        end if;
        udPuStart = raPu*idPuStart - omegaNomPu*lambdaqPuStart;
        uqPuStart = raPu*iqPuStart + omegaNomPu*lambdadPuStart;
        lambdadPuStart = (MdPu + LdPu)*idPuStart + MdPu*ifPuStart;
        ufPuStart = rfPu*ifPuStart;
        ufPuInStart = ufPuStart/kuf;
        if initOpt == InitializationOption.noInit then
        else
          omegaPu = omegaNomPu;
          der(omegaPu) = 0;
          if not neglectTransformerTerms then
            der(lambdadPu) = 0;
            der(lambdaqPu) = 0;
          end if;
          der(lambdafPu) = 0;
          der(lambdaDPu) = 0;
          der(lambdaQ1Pu) = 0;
          der(lambdaQ2Pu) = 0;
        end if;
      equation
        lambdadPu = (MdPu + LdPu)*idPu + MdPu*ifPu + MdPu*iDPu;
        lambdafPu = MdPu*idPu + (MdPu + LfPu + mrcPu)*ifPu + (MdPu + mrcPu)*iDPu;
        lambdaDPu = MdPu*idPu + (MdPu + mrcPu)*ifPu + (MdPu + LDPu + mrcPu)*iDPu;
        lambdaqPu = (MqPu + LqPu)*iqPu + MqPu*iQ1Pu + MqPu*iQ2Pu;
        lambdaQ1Pu = MqPu*iqPu + (MqPu + LQ1Pu)*iQ1Pu + MqPu*iQ2Pu;
        lambdaQ2Pu = MqPu*iqPu + MqPu*iQ1Pu + (MqPu + LQ2Pu)*iQ2Pu;
        if neglectTransformerTerms then
          udPu = raPu*idPu - omegaPu*lambdaqPu;
          uqPu = raPu*iqPu + omegaPu*lambdadPu;
        else
          udPu = raPu*idPu - omegaPu*lambdaqPu + der(lambdadPu)/omegaBase;
          uqPu = raPu*iqPu + omegaPu*lambdadPu + der(lambdaqPu)/omegaBase;
        end if;
        ufPu = rfPu*ifPu + der(lambdafPu)/omegaBase;
        0 = rDPu*iDPu + der(lambdaDPu)/omegaBase;
        0 = rQ1Pu*iQ1Pu + der(lambdaQ1Pu)/omegaBase;
        0 = rQ2Pu*iQ2Pu + der(lambdaQ2Pu)/omegaBase;
        der(theta) = (omegaPu - omegaRefPu)*omegaBase;
        2*H*der(omegaPu) = (CmPu*PNom/SNom - CePu) - DPu*(omegaPu - omegaRefPu);
        CePu = lambdaqPu*idPu - lambdadPu*iqPu;
        PePu = CePu*omegaPu;
        PmPu = CmPu*omegaPu;
        omega = omegaPu*omegaBase;
        ufPu = ufPuIn*kuf;
        VPu = port.VPu;
        PPu = -port.P/PNom;
      end SynchronousMachine4WindingsInternalParameters;
    end Machines;

    package Controls "Power systems controllers"
      extends Modelica.Icons.Package;

      package ExcitationSystems
        extends Modelica.Icons.Package;

        block VRProportional
          extends Controls.BaseClasses.BaseControllerFramework;
          parameter SI.PerUnit Ka(min = 0) "Overall equivalent gain";
          parameter SI.PerUnit VrMax "Output voltage max limit in p.u.";
          parameter SI.PerUnit VrMin "Output voltage min limit in p.u.";
          parameter Types.Time LagMax = 0 "Time lag before taking action when u going above uMax";
          parameter Types.Time LagMin = 0 "Time lag before taking action when u going below uMin";
          parameter PowerGrids.Controls.LimiterWithLag.State stateStart = PowerGrids.Controls.LimiterWithLag.State.notSat "Saturation initial state";
          parameter SI.PerUnit VcPuStart = 1 "Required start value of VcPu when fixInitialControlledVariable = true";
          parameter SI.PerUnit oversaturationPu = 0.1 "abs(u-usat)/(Vmax-Vmin) in case of saturated initial condition";
          final parameter Real delta = (limiterWithLag.uMax - limiterWithLag.uMin)*oversaturationPu "Actuator saturation margin";
          outer PowerGrids.Electrical.System systemPowerGrids "Reference to system object";
          Modelica.Blocks.Interfaces.RealInput VcPu "Machine terminal voltage p.u.";
          Modelica.Blocks.Interfaces.RealInput VrefPu "Voltage reference p.u.";
          Modelica.Blocks.Interfaces.RealOutput efdPu "Exciter output voltage p.u.";
          Modelica.Blocks.Math.Feedback Verr;
          PowerGrids.Controls.LimiterWithLag limiterWithLag(LagMax = LagMax, LagMin = LagMin, stateStart = stateStart, uMax = VrMax, uMin = VrMin);
          Modelica.Blocks.Math.Gain gain(k = Ka);
        initial equation
          if fixInitialControlledVariable then
            0 = homotopy(actual = if limiterWithLag.u > limiterWithLag.uMax then limiterWithLag.u - (limiterWithLag.uMax + delta) else if limiterWithLag.u < limiterWithLag.uMin then limiterWithLag.u - (limiterWithLag.uMin - delta) else VcPu - VcPuStart, simplified = VcPu - VcPuStart);
          end if;
        equation
          connect(VrefPu, Verr.u1);
          connect(VcPu, Verr.u2);
          connect(limiterWithLag.y, efdPu);
          connect(Verr.y, gain.u);
          connect(gain.y, limiterWithLag.u);
        end VRProportional;
      end ExcitationSystems;

      package TurbineGovernors
        extends Modelica.Icons.Package;

        block GoverProportional "Simple proportional governor"
          extends Controls.BaseClasses.BaseControllerFramework;
          parameter SI.PerUnit KGover "Mechanical power sensitivity to frequency";
          parameter SI.PerUnit PMaxPu = 1 "Maximum mechanical power p.u.";
          parameter SI.PerUnit PMinPu = 0 "Minimum mechanical power p.u.";
          parameter SI.PerUnit PPuStart = 1 "Required start value of PPu when fixInitialControlledVariable = true";
          parameter SI.PerUnit oversaturationPu = 0.1 "abs(u-usat)/(Vmax-Vmin) in case of saturated initial condition";
          final parameter Real delta = (limiter.uMax - limiter.uMin)*oversaturationPu "Actuator saturation margin";
          outer PowerGrids.Electrical.System systemPowerGrids "Reference to system object";
          Modelica.Blocks.Interfaces.RealInput PmRefPu "Reference frequency/load input [pu]";
          Modelica.Blocks.Interfaces.RealInput omegaPu "Frequency [pu]";
          Modelica.Blocks.Interfaces.RealOutput PMechPu "Mechanical turbine power [pu]";
          Modelica.Blocks.Math.Feedback errPu;
          Modelica.Blocks.Math.Feedback deltaOmegaPu;
          Modelica.Blocks.Sources.Constant omegaRefPu(k = 1);
          Modelica.Blocks.Math.Gain gain(k = KGover);
          Modelica.Blocks.Nonlinear.Limiter limiter(limitsAtInit = true, uMax = PMaxPu, uMin = PMinPu);
          Modelica.Blocks.Interfaces.RealInput PPu "Generator Active Power p.u.";
        initial equation
          if fixInitialControlledVariable then
            0 = homotopy(actual = if limiter.u > limiter.uMax then limiter.u - (limiter.uMax + delta) else if limiter.u < limiter.uMin then limiter.u - (limiter.uMin - delta) else PPu - PPuStart, simplified = PPu - PPuStart);
          end if;
        equation
          connect(omegaRefPu.y, deltaOmegaPu.u2);
          connect(PmRefPu, errPu.u1);
          connect(omegaPu, deltaOmegaPu.u1);
          connect(deltaOmegaPu.y, gain.u);
          connect(gain.y, errPu.u2);
          connect(errPu.y, limiter.u);
          connect(limiter.y, PMechPu);
        end GoverProportional;
      end TurbineGovernors;

      package BaseClasses "Base classes for controllers"
        extends Modelica.Icons.BasesPackage;

        block BaseControllerFramework "Base framework for all controllers such as AVR, PSS, etc."
          final parameter Boolean fixInitialControlledVariableDefault = if (systemPowerGrids.initOpt == Types.Choices.InitializationOption.globalSteadyStateFixedPowerFlow or systemPowerGrids.initOpt == Types.Choices.InitializationOption.localSteadyStateFixedPowerFlow) then true else false "= true adds extra initial equation to fix controlled variable";
          parameter Boolean fixInitialControlledVariable = fixInitialControlledVariableDefault "= true adds extra initial equation to fix controlled variable";
          outer System systemPowerGrids "Reference to system object for system-level defaults";
        end BaseControllerFramework;
      end BaseClasses;
    end Controls;

    package BaseClasses "Base classes package"
      extends Modelica.Icons.BasesPackage;

      model PortAC "AC port computing auxiliary quantities"
        parameter Types.Power SNom(start = 100e6) "Nominal or rated power";
        parameter Types.Voltage UNom(start = 400e3) "Nominal or rated phase-to-phase voltage";
        parameter Types.Power SBase = SNom "Base power";
        parameter Types.Voltage UBase = UNom "Base phase-to-phase voltage";
        parameter Types.Power PStart "Start value of active power flowing into port";
        parameter Types.Power QStart "Start value of reactive power flowing into port";
        parameter Types.Voltage UStart = UNom "Start value of phase-to-phase voltage modulus";
        parameter Types.Angle UPhaseStart = 0 "Start value of voltage phase";
        parameter Boolean portVariablesPhases = false "Compute voltage and current phases for monitoring purposes only" annotation(Evaluate = true);
        constant Boolean portVariablesPu = true "Add per-unit variables to model";
        constant Boolean generatorConvention = false "Add currents with generator convention (i > 0 when exiting the device) to model";
        final parameter Types.Voltage VBase = UBase/sqrt(3) "Base phase-to-ground voltage";
        final parameter Types.Current IBase = SBase/(3*VBase) "Base current";
        final parameter Types.Voltage VStart = UStart/sqrt(3) "Start value of phase-to ground voltage modulus";
        final parameter Types.Current IStart = sqrt(PStart^2 + QStart^2)/(3*VStart) "Start value of current modulus";
        final parameter Types.ComplexVoltage vStart = CM.fromPolar(UStart/sqrt(3), UPhaseStart) "Start value of phase-to-ground voltage phasor";
        final parameter Types.ComplexCurrent iStart = CM.conj(Complex(PStart, QStart)/(Complex(3)*vStart)) "Start value of current phasor flowing into the port";
        connector InputComplexVoltage = input Types.ComplexVoltage "Marks potential input for balancedness check without requiring binding equation";
        connector InputComplexCurrent = input Types.ComplexCurrent "Marks potential input for balancedness check without requiring binding equation";
        InputComplexVoltage v(re(nominal = VBase, start = vStart.re), im(nominal = VBase, start = vStart.im)) "Port voltage (line-to-neutral)";
        InputComplexCurrent i(re(nominal = IBase, start = iStart.re), im(nominal = IBase, start = iStart.im)) "Port current";
        Types.ComplexVoltage u(re(nominal = UBase, start = vStart.re*sqrt(3)), im(nominal = UBase, start = vStart.im*sqrt(3))) = sqrt(3)*v "Complex phase-to-phase voltage";
        Types.ComplexPower S(re(nominal = SBase), im(nominal = SBase)) = 3*v*CM.conj(i) "Complex power flowing into the port";
        Types.ActivePower P(nominal = SBase, start = PStart) = S.re "Active power flowing into the port";
        Types.ReactivePower Q(nominal = SBase, start = QStart) = S.im "Reactive power flowing into the port";
        Types.Voltage U(nominal = UBase, start = UStart) = CM.'abs'(u) "Port voltage absolute value (phase-to-phase)";
        Types.Current I(nominal = IBase, start = IStart) = CM.'abs'(i) "Port current (positive entering)";
        Types.PerUnit PPu(start = PStart/SBase) = if portVariablesPu then S.re/SBase else 0 "Active power flowing into the port in p.u. (base SBase)" annotation(HideResult = portVariablesPu);
        Types.PerUnit QPu(start = QStart/SBase) = if portVariablesPu then S.im/SBase else 0 "Reactive power flowing into the port in p.u. (base SBase)" annotation(HideResult = portVariablesPu);
        Types.ComplexPerUnit vPu(re(start = vStart.re/VBase), im(start = vStart.im/VBase)) = if portVariablesPu then u*(1/UBase) else Complex(0) "Complex voltage across the port in p.u. (base VBase)" annotation(HideResult = portVariablesPu);
        SI.PerUnit VPu(start = VStart/VBase) = if portVariablesPu then U/UBase else 0 "Absolute value of voltage across the port in p.u. (base VBase)" annotation(HideResult = portVariablesPu);
        Types.ComplexPerUnit iPu(re(start = iStart.re/IBase), im(start = iStart.im/IBase)) = if portVariablesPu then i*(1/IBase) else Complex(0) "Complex current flowing into the port in p.u. (base IBase)" annotation(HideResult = portVariablesPu);
        SI.PerUnit IPu(start = IStart/IBase) = if portVariablesPu then I/IBase else 0 "Absolute value of complex current flowing into the port in p.u. (base IBase)" annotation(HideResult = portVariablesPu);
        Types.Angle UPhase(start = UPhaseStart) = if portVariablesPhases then atan2(v.im, v.re) else 0 "Phase of voltage across the port" annotation(HideResult = portVariablesPhases);
        Types.Angle IPhase(start = CM.arg(iStart)) = if portVariablesPhases then atan2(i.im, i.re) else 0 "Phase of current into the port" annotation(HideResult = portVariablesPhases);
        Types.ComplexCurrent iGen(re(nominal = IBase, start = -iStart.re), im(nominal = IBase, start = -iStart.im)) = -i "Port current, generator convention";
        Types.ActivePower PGen(nominal = SBase, start = -PStart) = -S.re "Active power flowing out of the port";
        Types.ReactivePower QGen(nominal = SBase, start = -QStart) = -S.im "Reactive power flowing out of the port";
        Types.PerUnit PGenPu(start = -PStart/SBase) = -PPu "Active power flowing out of the port in p.u. (base SBase)";
        Types.PerUnit QGenPu(start = -QStart/SBase) = -QPu "Reactive power flowing out of the port in p.u. (base SBase)";
        Types.ComplexPerUnit iGenPu(re(start = -iStart.re/IBase), im(start = -iStart.im/IBase)) = -iPu "Complex current flowing out of the port in p.u. (base IBase)";
        SI.PerUnit IGenPu(start = IStart/IBase) = if portVariablesPu and generatorConvention then I/IBase else 0 "Absolute value of current flowing out of the port in p.u. (base IBase)" annotation(HideResult = portVariablesPu and generatorConvention);
      end PortAC;

      partial model OnePortAC "Base class for AC components with one port"
        import PowerGrids.Types.Choices.LocalInitializationOption;
        parameter Types.Voltage UNom(start = 400e3) "Nominal/rated line-to-line voltage" annotation(Evaluate = true);
        parameter Types.ApparentPower SNom(start = 100e6) "Nominal/rated apparent power" annotation(Evaluate = true);
        parameter Boolean portVariablesPhases = false "Compute voltage and current phases for monitoring purposes only" annotation(Evaluate = true);
        constant Boolean portVariablesPu = true "Add per-unit variables to model";
        constant Boolean generatorConvention = false "Add currents with generator convention (i > 0 when exiting the device) to model";
        parameter LocalInitializationOption localInit = LocalInitializationOption.none "Initialize the component locally in steady state from port start values" annotation(Evaluate = true);
        parameter Types.Voltage UStart = UNom "Start value of phase-to-phase voltage phasor, absolute value";
        parameter Types.Angle UPhaseStart = 0 "Start value of phase-to-phase voltage phasor, phase angle";
        parameter Types.ActivePower PStart = SNom "Start value of active power flowing into the port";
        parameter Types.ReactivePower QStart = 0 "Start value of reactive power flowing into the port";
        PowerGrids.Interfaces.TerminalAC terminal(v(re(start = port.vStart.re), im(start = port.vStart.im)), i(re(start = port.iStart.re), im(start = port.iStart.im)));
        PortAC port(final UNom = UNom, final SNom = SNom, final portVariablesPu = portVariablesPu, final portVariablesPhases = portVariablesPhases, final generatorConvention = generatorConvention, final UStart = UStart, final UPhaseStart = UPhaseStart, final PStart = PStart, final QStart = QStart) "AC port of node";
        outer Electrical.System systemPowerGrids "Reference to system object";
      equation
        if initial() and localInit == LocalInitializationOption.PV then
          CM.real(terminal.v*CM.conj(terminal.i)) = port.PStart;
          CM.'abs'(terminal.v) = port.VStart;
          port.Q = port.QStart;
          port.v.re*port.vStart.im = port.v.im*port.vStart.re;
        elseif initial() and localInit == LocalInitializationOption.PQ then
          terminal.v*CM.conj(terminal.i) = Complex(port.PStart, port.QStart);
          port.v.re*port.vStart.im = port.v.im*port.vStart.re;
          port.i.re*port.iStart.im = port.i.im*port.iStart.re;
        else
          port.v = terminal.v;
          port.i = terminal.i;
        end if;
      end OnePortAC;

      partial model OnePortACdqPU "Base class for one-port AC components with p.u. Park's transformation"
        extends OnePortAC(final portVariablesPu = true);
        parameter SI.Angle thetaStart = UPhaseStart "Start value of rotation between machine rotor frame and port phasor frame";
        final parameter Types.PerUnit udPuStart(fixed = false) "Start value of udPu";
        final parameter Types.PerUnit uqPuStart(fixed = false) "Start value of uqPu";
        final parameter Types.PerUnit idPuStart(fixed = false) "Start value of idPu";
        final parameter Types.PerUnit iqPuStart(fixed = false) "Start value of iqPu";
        Types.PerUnit udPu(start = udPuStart) "Voltage of direct axis in p.u.";
        Types.PerUnit uqPu(start = uqPuStart) "Voltage of quadrature axis in p.u.";
        Types.PerUnit idPu(start = idPuStart) "Current of direct axis in p.u.";
        Types.PerUnit iqPu(start = iqPuStart) "Current of quadrature axis in p.u.";
        Types.Angle theta(start = thetaStart) "Rotation between machine rotor frame and port phasor frame";
      initial equation
        port.vStart.re/port.VBase = sin(thetaStart)*udPuStart + cos(thetaStart)*uqPuStart;
        port.vStart.im/port.VBase = -cos(thetaStart)*udPuStart + sin(thetaStart)*uqPuStart;
        port.iStart.re/port.IBase = sin(thetaStart)*idPuStart + cos(thetaStart)*iqPuStart;
        port.iStart.im/port.IBase = -cos(thetaStart)*idPuStart + sin(thetaStart)*iqPuStart;
      equation
        port.vPu.re = sin(theta)*udPu + cos(theta)*uqPu;
        port.vPu.im = -cos(theta)*udPu + sin(theta)*uqPu;
        port.iPu.re = sin(theta)*idPu + cos(theta)*iqPu;
        port.iPu.im = -cos(theta)*idPu + sin(theta)*iqPu;
      end OnePortACdqPU;

      partial model TwoPortAC "Base class for two-port AC components"
        parameter Types.Voltage UNomA(start = 400e3) "Nominal/rated voltage, port A" annotation(Evaluate = true);
        parameter Types.Voltage UNomB = UNomA "Nominal/rated voltage, port B" annotation(Evaluate = true);
        parameter Types.Power SNom(start = 100e6) "Nominal/rated power" annotation(Evaluate = true);
        parameter Boolean portVariablesPhases = false "Compute voltage and current phases for monitoring purposes only" annotation(Evaluate = true);
        constant Boolean portVariablesPu = true "Add per-unit variables to model";
        parameter Boolean computePowerBalance = true "Compute net balance of complex power entering the component";
        parameter Types.Voltage UStartA = UNomA "Start value of phase-to-phase voltage phasor at port A, absolute value";
        parameter Types.Angle UPhaseStartA = 0 "Start value of phase-to-phase voltage phasor at port A, phase angle";
        parameter Types.ActivePower PStartA = SNom "Start value of active power flowing into port A";
        parameter Types.ReactivePower QStartA = 0 "Start value of reactive power flowing into port A";
        parameter Types.Voltage UStartB = UNomB "Start value of phase-to-phase voltage phasor at port B, absolute value";
        parameter Types.Angle UPhaseStartB = 0 "Start value of phase-to-phase voltage phasor at port B, phase angle";
        parameter Types.ActivePower PStartB = -SNom "Start value of active power flowing into port B";
        parameter Types.ReactivePower QStartB = 0 "Start value of reactive power flowing into port B";
        PowerGrids.Interfaces.TerminalAC terminalA;
        PowerGrids.Interfaces.TerminalAC terminalB;
        PortAC portA(final v = terminalA.v, final i = terminalA.i, final UNom = UNomA, final SNom = SNom, final portVariablesPu = portVariablesPu, final portVariablesPhases = portVariablesPhases, final generatorConvention = false, final UStart = UStartA, final UPhaseStart = UPhaseStartA, final PStart = PStartA, final QStart = QStartA) "AC port - terminalA";
        PortAC portB(final v = terminalB.v, final i = terminalB.i, final UNom = UNomB, final SNom = SNom, final portVariablesPu = portVariablesPu, final portVariablesPhases = portVariablesPhases, final generatorConvention = false, final UStart = UStartB, final UPhaseStart = UPhaseStartB, final PStart = PStartB, final QStart = QStartB) "AC port - terminalB";
        Types.ComplexPower Sbal = portA.S + portB.S if computePowerBalance "Complex power balance";
        outer Electrical.System systemPowerGrids "Reference to system object";
      end TwoPortAC;

      model ShuntConductance "Connects the port to ground via a conductor"
        extends OnePortAC;
        input Types.ComplexAdmittance Y "Shunt admittance";
        Types.ComplexVoltage v(re(nominal = port.VBase), im(nominal = port.VBase)) = port.v;
        Types.ComplexCurrent i(re(nominal = port.IBase), im(nominal = port.IBase)) = port.i;
      equation
        i = Y*v;
      end ShuntConductance;
    end BaseClasses;
  end Electrical;

  package Controls "Control blocks"
    extends Modelica.Icons.Package;

    model FreeOffset
      extends Modelica.Blocks.Interfaces.SO;
      import PowerGrids.Types.Choices.InitializationOption;
      parameter Boolean use_u = false "= true if time varying output is required";
      final parameter Boolean fixedOffsetDefault = if systemPowerGrids.initOpt == InitializationOption.globalSteadyStateFixedPowerFlow or systemPowerGrids.initOpt == InitializationOption.localSteadyStateFixedPowerFlow then false else true "Default choice of fixedOffsetDefault from system object";
      parameter Boolean fixedOffset = fixedOffsetDefault "= true if offset is fixed to zero, = false if offset is left free";
      final parameter Real offset(fixed = false) "Free offset of output y";
      outer PowerGrids.Electrical.System systemPowerGrids "Reference to system object";
      Modelica.Blocks.Interfaces.RealInput u if use_u;
    protected
      Modelica.Blocks.Interfaces.RealInput u_internal "Protected connector to be used in equations in place of conditional u";
    initial equation
      if fixedOffset then
        offset = 0;
      end if;
    equation
      y = u_internal + offset;
      connect(u, u_internal) "Automatically removed if u is disabled";
      if not use_u then
        u_internal = 0 "Provide a default zero value if u is disabled";
      end if;
    end FreeOffset;

    block LimiterWithLag
      extends Modelica.Blocks.Interfaces.SISO;
      encapsulated type State = enumeration(upperSat "Upper limit reached", lowerSat "Lower limit reached", notSat "u is in range");
      parameter Real uMax "Upper limit";
      parameter Real uMin "Lower limit";
      parameter Types.Time LagMax "Time lag before taking action when u going above uMax";
      parameter Types.Time LagMin "Time lag before taking action when u going below uMin";
      parameter State stateStart = State.notSat "saturation initial state";
      final parameter Boolean useLag = (LagMax > 0) or (LagMin > 0) "Lags are used only if at least one is not null";
      State state(start = stateStart, fixed = true) "saturation state";
      discrete SI.Time saturationLimitReached(start = 0, fixed = true) "Time in which the saturation limit is reached";
      Boolean satON "Saturation is active";
    equation
      y = homotopy(actual = if state == State.upperSat and satON then uMax elseif state == State.lowerSat and satON then uMin else u, simplified = u);
    algorithm
      when u > uMax then
        state := State.upperSat;
        saturationLimitReached := time;
      end when;
      when u < uMin then
        state := State.lowerSat;
        saturationLimitReached := time;
      end when;
      when u < uMax and u > uMin then
        state := State.notSat;
      end when;
      when useLag and state == State.notSat then
        satON := false;
      elsewhen useLag and state == State.upperSat and (time - saturationLimitReached) > LagMax then
        satON := true;
      elsewhen useLag and state == State.lowerSat and (time - saturationLimitReached) > LagMin then
        satON := true;
      end when;
      if not useLag then
        satON := true;
      else
      end if;
    end LimiterWithLag;
  end Controls;

  package Interfaces "Interfaces package"
    extends Modelica.Icons.InterfacesPackage;

    connector TerminalAC "Terminal for phasor-based AC connections"
      Types.ComplexVoltage v "Phase-to-ground voltage phasor";
      flow Types.ComplexCurrent i "Line current phasor";
    end TerminalAC;
  end Interfaces;

  package Types "Domain-specific type definitions"
    extends Modelica.Icons.TypesPackage;
    type Voltage = SI.Voltage(nominal = 1e4, displayUnit = "kV");
    type Current = SI.Current(nominal = 1e4, displayUnit = "kA");
    type ActivePower = SI.ActivePower(nominal = 1e8, displayUnit = "MW");
    type ReactivePower = SI.ReactivePower(nominal = 1e8, displayUnit = "MVA");
    type Power = SI.Power(nominal = 1e8, displayUnit = "MW");
    type ApparentPower = SI.ApparentPower(nominal = 1e8, displayUnit = "MVA");
    type Angle = SI.Angle;
    type AngularVelocity = SI.AngularVelocity;
    type Frequency = SI.Frequency;
    type Resistance = SI.Resistance;
    type Reactance = SI.Reactance;
    type Conductance = SI.Conductance;
    type Susceptance = SI.Susceptance;
    type PerUnit = SI.PerUnit;
    type Time = SI.Time;
    operator record ComplexVoltage = SI.ComplexVoltage(re(nominal = 1e4, displayUnit = "kV"), im(nominal = 1e4, displayUnit = "kV"));
    operator record ComplexCurrent = SI.ComplexCurrent(re(nominal = 1e4, displayUnit = "kA"), im(nominal = 1e4, displayUnit = "kA"));
    operator record ComplexAdmittance = SI.ComplexAdmittance;
    operator record ComplexPower = SI.ComplexPower(re(nominal = 1e8, displayUnit = "MW"), im(nominal = 1e8, displayUnit = "MVA"));
    operator record ComplexPerUnit = Complex(re(unit = "1"), im(unit = "1"));

    package Choices
      extends Modelica.Icons.TypesPackage;
      type ReferenceFrequency = enumeration(nominalFrequency "Nominal frequency", fixedReferenceGenerator "Fixed reference generator frequency", adaptiveReferenceGenerators "One reference generator for each synchronous island");
      type ExcitationPuType = enumeration(nominalStatorVoltageNoLoad "1 p.u. gives nominal air-gap stator voltage at no load", Kundur "Base voltage as per Kundur, Power System Stability and Control");
      type TimeConstantsApproximation = enumeration(classicalDefinition "Tpd0 = T1, Tppd0 = T3", accurateEstimation "Tpd0 = T1+T2, Tppd0 = T1T3/(T1+T2)", exactComputation "Exact polynomial roots");
      type InitializationOption = enumeration(globalSteadyStateFixedSetPoints "Global steady state, fixed set points", globalSteadyStateFixedPowerFlow "Global steady state, fixed power flow", localSteadyStateFixedPowerFlow "Local steady state, fixed power flow", noInit "No initial equations");
      type LocalInitializationOption = enumeration(none "Global initialization", PV "Try to match PV", PQ "Try to match PQ");
    end Choices;
  end Types;

  package Functions "Custom functions"
    extends Modelica.Icons.UtilitiesPackage;

    function largerTimeConstant
      extends Modelica.Icons.Function;
      input Real a;
      input Real b;
      output Real T;
    algorithm
      T := (a + sqrt(abs(a^2 - 4*b)))/2;
      annotation(Inline = true);
    end largerTimeConstant;

    function smallerTimeConstant
      extends Modelica.Icons.Function;
      input Real a;
      input Real b;
      output Real T;
    algorithm
      T := 2*b/(a + sqrt(abs(a^2 - 4*b)));
      annotation(Inline = true);
    end smallerTimeConstant;
  end Functions;

  package Icons "Icons for the PowerGrids library"
    extends Modelica.Icons.IconsPackage;

    model Bus end Bus;

    model Line end Line;

    model Transformer end Transformer;

    model Load end Load;

    model Machine end Machine;

    model CapacitorBank end CapacitorBank;
  end Icons;
  annotation(version = "1.0.3");
end PowerGrids;

model IEEE14busGen2Disconnection_total  "Simulation of the disconnection of generator 2 at t = 1 s"
  extends PowerGrids.Examples.IEEE14bus.IEEE14busGen2Disconnection;
 annotation(experiment(StartTime = 0, StopTime = 40, Tolerance = 1e-6, Interval = 0.04));
end IEEE14busGen2Disconnection_total;
