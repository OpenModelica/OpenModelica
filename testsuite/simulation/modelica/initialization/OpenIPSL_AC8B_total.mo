package ModelicaServices "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine "Machine dependent constants"
    extends Modelica.Icons.Package;
    final constant Real eps = 2.2204460492503131e-016 "The difference between 1 and the least value greater than 1 that is representable in the given floating point type";
    final constant Real small = 2.2250738585072014e-308 "Minimum normalized positive floating-point number";
    final constant Real inf = 1e60 "Maximum representable finite floating-point number";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end ModelicaServices;

package Modelica "Modelica Standard Library"
  extends Modelica.Icons.Package;

  package Blocks "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;

    package Continuous "Library of continuous control blocks with internal states"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

      block Integrator "Output the integral of the input signal with optional reset"
        import Modelica.Blocks.Types.Init;
        parameter Real k = 1 "Integrator gain";
        parameter Boolean use_reset = false "= true, if reset port enabled" annotation(Evaluate = true, HideResult = true);
        parameter Boolean use_set = false "= true, if set port enabled and used as reinitialization value when reset" annotation(Evaluate = true, HideResult = true);
        parameter Init initType = Init.InitialState "Type of initialization (1: no init, 2: steady state, 3,4: initial output)" annotation(Evaluate = true);
        parameter Real y_start = 0 "Initial or guess value of output (= state)";
        extends Interfaces.SISO;
        Modelica.Blocks.Interfaces.BooleanInput reset if use_reset "Optional connector of reset signal";
        Modelica.Blocks.Interfaces.RealInput set if use_reset and use_set "Optional connector of set signal";
      protected
        Modelica.Blocks.Interfaces.BooleanOutput local_reset annotation(HideResult = true);
        Modelica.Blocks.Interfaces.RealOutput local_set annotation(HideResult = true);
      initial equation
        if initType == Init.SteadyState then
          der(y) = 0;
        elseif initType == Init.InitialState or initType == Init.InitialOutput then
          y = y_start;
        end if;
      equation
        if use_reset then
          connect(reset, local_reset);
          if use_set then
            connect(set, local_set);
          else
            local_set = y_start;
          end if;
          when local_reset then
            reinit(y, local_set);
          end when;
        else
          local_reset = false;
          local_set = 0;
        end if;
        der(y) = k*u;
      end Integrator;
    end Continuous;

    package Interfaces "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector";
      connector RealOutput = output Real "'output Real' as connector";
      connector BooleanInput = input Boolean "'input Boolean' as connector";
      connector BooleanOutput = output Boolean "'output Boolean' as connector";
      connector RealVectorInput = input Real "Real input connector used for vector of connectors";

      partial block SO "Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealOutput y "Connector of Real output signal";
      end SO;

      partial block SISO "Single Input Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealInput u "Connector of Real input signal";
        RealOutput y "Connector of Real output signal";
      end SISO;

      partial block SI2SO "2 Single Input / 1 Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealInput u1 "Connector of Real input signal 1";
        RealInput u2 "Connector of Real input signal 2";
        RealOutput y "Connector of Real output signal";
      end SI2SO;

      partial block PartialRealMISO "Partial block with a RealVectorInput and a RealOutput signal"
        parameter Integer significantDigits(min = 1) = 3 "Number of significant digits to be shown in dynamic diagram layer for y";
        parameter Integer nu(min = 0) = 0 "Number of input connections" annotation(HideResult = true);
        Modelica.Blocks.Interfaces.RealVectorInput u[nu];
        Modelica.Blocks.Interfaces.RealOutput y;
      end PartialRealMISO;
    end Interfaces;

    package Logical "Library of components with Boolean input and output signals"
      extends Modelica.Icons.Package;

      block Switch "Switch between two Real signals"
        extends Modelica.Blocks.Icons.PartialBooleanBlock;
        Blocks.Interfaces.RealInput u1 "Connector of first Real input signal";
        Blocks.Interfaces.BooleanInput u2 "Connector of Boolean input signal";
        Blocks.Interfaces.RealInput u3 "Connector of second Real input signal";
        Blocks.Interfaces.RealOutput y "Connector of Real output signal";
      equation
        y = if u2 then u1 else u3;
      end Switch;
    end Logical;

    package Math "Library of Real mathematical functions as input/output blocks"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

      block Gain "Output the product of a gain value with the input signal"
        parameter Real k(start = 1) "Gain value multiplied with input signal";
        Interfaces.RealInput u "Input signal connector";
        Interfaces.RealOutput y "Output signal connector";
      equation
        y = k*u;
      end Gain;

      block MultiSum "Sum of Reals: y = k[1]*u[1] + k[2]*u[2] + ... + k[n]*u[n]"
        extends Modelica.Blocks.Interfaces.PartialRealMISO;
        parameter Real k[nu] = fill(1, nu) "Input gains";
      equation
        if size(u, 1) > 0 then
          y = k*u;
        else
          y = 0;
        end if;
      end MultiSum;

      block Feedback "Output difference between commanded and feedback input"
        Interfaces.RealInput u1 "Commanded input";
        Interfaces.RealInput u2 "Feedback input";
        Interfaces.RealOutput y;
      equation
        y = u1 - u2;
      end Feedback;

      block Add "Output the sum of the two inputs"
        extends Interfaces.SI2SO;
        parameter Real k1 = +1 "Gain of input signal 1";
        parameter Real k2 = +1 "Gain of input signal 2";
      equation
        y = k1*u1 + k2*u2;
      end Add;

      block Add3 "Output the sum of the three inputs"
        extends Modelica.Blocks.Icons.Block;
        parameter Real k1 = +1 "Gain of input signal 1";
        parameter Real k2 = +1 "Gain of input signal 2";
        parameter Real k3 = +1 "Gain of input signal 3";
        Interfaces.RealInput u1 "Connector of Real input signal 1";
        Interfaces.RealInput u2 "Connector of Real input signal 2";
        Interfaces.RealInput u3 "Connector of Real input signal 3";
        Interfaces.RealOutput y "Connector of Real output signal";
      equation
        y = k1*u1 + k2*u2 + k3*u3;
      end Add3;

      block Product "Output product of the two inputs"
        extends Interfaces.SI2SO;
      equation
        y = u1*u2;
      end Product;

      block Division "Output first input divided by second input"
        extends Interfaces.SI2SO;
      equation
        y = u1/u2;
      end Division;
    end Math;

    package Nonlinear "Library of discontinuous or non-differentiable algebraic control blocks"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

      block Limiter "Limit the range of a signal"
        parameter Real uMax(start = 1) "Upper limits of input signals";
        parameter Real uMin = -uMax "Lower limits of input signals";
        parameter Boolean strict = false "= true, if strict limits with noEvent(..)" annotation(Evaluate = true);
        parameter Types.LimiterHomotopy homotopyType = Modelica.Blocks.Types.LimiterHomotopy.Linear "Simplified model for homotopy-based initialization" annotation(Evaluate = true);
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
      extends Modelica.Icons.SourcesPackage;

      block RealExpression "Set output signal to a time varying Real expression"
        Modelica.Blocks.Interfaces.RealOutput y = 0.0 "Value of Real output";
      end RealExpression;

      block Constant "Generate constant signal of type Real"
        parameter Real k(start = 1) "Constant output value";
        extends Interfaces.SO;
      equation
        y = k;
      end Constant;
    end Sources;

    package Types "Library of constants, external objects and types with choices, especially to build menus"
      extends Modelica.Icons.TypesPackage;
      type Init = enumeration(NoInit "No initialization (start values are used as guess values with fixed=false)", SteadyState "Steady state initialization (derivatives of states are zero)", InitialState "Initialization with initial states", InitialOutput "Initialization with initial outputs (and steady state of the states if possible)") "Enumeration defining initialization of a block" annotation(Evaluate = true);
      type LimiterHomotopy = enumeration(NoHomotopy "Homotopy is not used", Linear "Simplified model without limits", UpperLimit "Simplified model fixed at upper limit", LowerLimit "Simplified model fixed at lower limit") "Enumeration defining use of homotopy in limiter components" annotation(Evaluate = true);
    end Types;

    package Icons "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block "Basic graphical layout of input/output block" end Block;

      partial block PartialBooleanBlock "Basic graphical layout of logical block" end PartialBooleanBlock;
    end Icons;
  end Blocks;

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
    algorithm
      y := .asin(u);
      annotation(Inline = true);
    end asin;

    function atan2 "Four quadrant inverse tangent"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1 "First independent variable";
      input Real u2 "Second independent variable";
      output Modelica.Units.SI.Angle y "Dependent variable y=atan2(u1, u2)=atan(u1/u2)";
    algorithm
      y := .atan2(u1, u2);
      annotation(Inline = true);
    end atan2;

    function atan3 "Four quadrant inverse tangent (select solution that is closest to given angle y0)"
      import Modelica.Constants.pi;
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1 "First independent variable";
      input Real u2 "Second independent variable";
      input Modelica.Units.SI.Angle y0 = 0 "y shall be in the range: -pi < y-y0 <= pi";
      output Modelica.Units.SI.Angle y "Dependent variable y=atan3(u1, u2, y0)=atan(u1/u2)";
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
      input Real u "Independent variable";
      output Real y "Dependent variable y=exp(u)";
    algorithm
      y := .exp(u);
      annotation(Inline = true);
    end exp;
  end Math;

  package ComplexMath "Library of complex mathematical functions (e.g., sin, cos) and of functions operating on complex vectors and matrices"
    extends Modelica.Icons.Package;
    final constant Complex j = Complex(0, 1) "Imaginary unit";

    function abs "Absolute value of complex number"
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      output Real result "= abs(c)";
    algorithm
      result := .sqrt(c.re^2 + c.im^2);
      annotation(Inline = true);
    end abs;

    function arg "Phase angle of complex number"
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      input Modelica.Units.SI.Angle phi0 = 0 "Phase angle phi shall be in the range: -pi < phi-phi0 < pi";
      output Modelica.Units.SI.Angle phi "= phase angle of c";
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

    function imag "Imaginary part of complex number"
      extends Modelica.Icons.Function;
      input Complex c "Complex number";
      output Real r "= c.im";
    algorithm
      r := c.im;
      annotation(Inline = true);
    end imag;
  end ComplexMath;

  package Constants "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;
    import Modelica.Units.NonSI;
    final constant Real pi = 2*Modelica.Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "The difference between 1 and the least value greater than 1 that is representable in the given floating point type";
    final constant Real small = ModelicaServices.Machine.small "Minimum normalized positive floating-point number";
    final constant Real inf = ModelicaServices.Machine.inf "Maximum representable finite floating-point number";
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant SI.ElectricCharge q = 1.602176634e-19 "Elementary charge";
    final constant Real h(final unit = "J.s") = 6.62607015e-34 "Planck constant";
    final constant Real k(final unit = "J/K") = 1.380649e-23 "Boltzmann constant";
    final constant Real N_A(final unit = "1/mol") = 6.02214076e23 "Avogadro constant";
    final constant SI.Permeability mu_0 = 1.25663706212e-6 "Magnetic constant";
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

    partial package TypesPackage "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package FunctionsPackage "Icon for packages containing functions"
      extends Modelica.Icons.Package;
    end FunctionsPackage;

    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package InternalPackage "Icon for an internal package (indicating that the package should not be directly utilized by user)" end InternalPackage;

    partial function Function "Icon for functions" end Function;
  end Icons;

  package Units "Library of type and unit definitions"
    extends Modelica.Icons.Package;

    package SI "Library of SI unit definitions"
      extends Modelica.Icons.Package;
      type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
      type Time = Real(final quantity = "Time", final unit = "s");
      type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
      type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
      type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
      type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
      type ElectricCharge = Real(final quantity = "ElectricCharge", final unit = "C");
      type ElectricPotential = Real(final quantity = "ElectricPotential", final unit = "V");
      type Voltage = ElectricPotential;
      type Permeability = Real(final quantity = "Permeability", final unit = "V.s/(A.m)");
      type ActivePower = Real(final quantity = "Power", final unit = "W");
      type ApparentPower = Real(final quantity = "Power", final unit = "V.A");
      type ReactivePower = Real(final quantity = "Power", final unit = "var");
      type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
      type PerUnit = Real(unit = "1");
      operator record ComplexPower = Complex(redeclare ActivePower re "Real part of complex apparent power (active power)", redeclare ReactivePower im "Imaginary part of complex apparent power (reactive power)") "Complex apparent power";
    end SI;

    package NonSI "Type definitions of non SI and other units"
      extends Modelica.Icons.Package;
      type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use Modelica.Units.SI.TemperatureDifference)" annotation(absoluteValue = true);
      type Angle_deg = Real(final quantity = "Angle", final unit = "deg") "Angle in degree";
    end NonSI;

    package Conversions "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      function to_deg "Convert from radian to degree"
        extends Modelica.Units.Icons.Conversion;
        input SI.Angle radian "Value in radian";
        output Modelica.Units.NonSI.Angle_deg degree "Value in degree";
      algorithm
        degree := (180.0/Modelica.Constants.pi)*radian;
        annotation(Inline = true);
      end to_deg;
    end Conversions;

    package Icons "Icons for Units"
      extends Modelica.Icons.IconsPackage;

      partial function Conversion "Base icon for conversion functions" end Conversion;
    end Icons;
  end Units;
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end Modelica;

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
      annotation(Inline = true, smoothOrder = 100);
    end negate;

    function subtract "Subtract two complex numbers"
      import Complex;
      input Complex c1 "Complex number 1";
      input Complex c2 "Complex number 2";
      output Complex c3 "= c1 - c2";
    algorithm
      c3 := Complex(c1.re - c2.re, c1.im - c2.im);
      annotation(Inline = true, smoothOrder = 100);
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
      annotation(Inline = true, smoothOrder = 100);
    end multiply;

    function scalarProduct "Scalar product of two complex vectors c1 and c2"
      import Complex;
      input Complex c1[:] "Vector of Complex numbers 1";
      input Complex c2[size(c1, 1)] "Vector of Complex numbers 2";
      output Complex c3 "Scalar product of c1 and c2";
    algorithm
      c3 := Complex(0);
      for i in 1:size(c1, 1) loop
        c3 := Complex(c3.re + c1[i].re*c2[i].re + c1[i].im*c2[i].im, c3.im + c1[i].re*c2[i].im - c1[i].im*c2[i].re);
      end for;
      annotation(Inline = true, smoothOrder = 100);
    end scalarProduct;
  end '*';

  encapsulated operator function '+' "Add two complex numbers"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1 + c2";
  algorithm
    c3 := Complex(c1.re + c2.re, c1.im + c2.im);
    annotation(Inline = true, smoothOrder = 100);
  end '+';

  encapsulated operator function '/' "Divide two complex numbers"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1/c2";
  algorithm
    c3 := Complex((+c1.re*c2.re + c1.im*c2.im)/(c2.re*c2.re + c2.im*c2.im), (-c1.re*c2.im + c1.im*c2.re)/(c2.re*c2.re + c2.im*c2.im));
    annotation(Inline = true, smoothOrder = 100);
  end '/';

  encapsulated operator '^' "Power"
    function complexPower "Complex power of complex number"
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
      annotation(Inline = true, smoothOrder = 100);
    end complexPower;

    function integerPower "Integer power of complex number"
      import Complex;
      input Complex c1 "Complex number";
      input Integer c2 "Integer exponent";
      output Complex c3 "= c1^c2";
    algorithm
      c3 := if c2 == 0 then Complex(1) else Complex.'^'.complexPower(c1, Complex(c2));
      annotation(Inline = true, smoothOrder = 100);
    end integerPower;
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
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end Complex;

package OpenIPSL "Open-Instance Power System Library"
  import Modelica.Units.SI;
  import C = Modelica.Constants;

  package Electrical "Package for electrical models used in this library"
    extends Modelica.Icons.Package;

    record SystemBase "System Base Definition"
      parameter Types.ApparentPower S_b = 100e6 "System base";
      parameter Types.Frequency fn = 50 "System frequency";
      annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "
        No 'System Data' component is defined.
        A default component will be used, and generate a system base of 100 MVA,
        and a frequency of 50 Hz");
    end SystemBase;

    package Controls "Models that represent controllers used in machines such as exciters, stabilizers and governors, for example"
      extends Modelica.Icons.Package;

      package PSSE "Controller models from PSSE"
        extends Modelica.Icons.Package;

        package ES "Excitation system models from PSSE"
          extends Modelica.Icons.Package;

          model AC8B "AC8B Excitation System [IEEE2005]"
            import OpenIPSL.NonElectrical.Functions.SE;
            import OpenIPSL.Electrical.Controls.PSSE.ES.BaseClasses.invFEX;
            extends OpenIPSL.Electrical.Controls.PSSE.ES.BaseClasses.BaseExciter;
            parameter Types.Time T_R "Filter time constant ";
            parameter Types.PerUnit K_PR "Voltage regulator proportional gain";
            parameter Types.PerUnit K_IR "Voltage regulator integral gain";
            parameter Types.PerUnit K_DR "Voltage regulator derivative gain";
            parameter Types.Time T_DR "Regulator derivative block time constant ";
            parameter Types.PerUnit VPID_MAX "PID maximum limit";
            parameter Types.PerUnit VPID_MIN "PID minimum limit";
            parameter Types.PerUnit K_A "Voltage regulator gain";
            parameter Types.Time T_A "Voltage regulator time constant ";
            parameter Types.PerUnit V_RMAX "Maximum voltage regulator output";
            parameter Types.PerUnit V_RMIN "Minimum voltage regulator output";
            parameter Types.Time T_E "Exciter time constant, integration rate associated with exciter
              control ";
            parameter Types.PerUnit K_C "Rectifier loading factor proportional to commutating reactance";
            parameter Types.PerUnit K_D "Demagnetizing factor, a function of exciter alternator
              reactances";
            parameter Types.PerUnit K_E "Exciter constant related to self-excited field";
            parameter Types.PerUnit E_1 "Exciter alternator output voltages back of commutating reactance
              at which saturation is defined";
            parameter Types.PerUnit S_EE_1 "Exciter saturation function value at the corresponding exciter
              voltage, E1, back of commutating reactance";
            parameter Types.PerUnit E_2 "Exciter alternator output voltages back of commutating
              reactance at which saturation is defined";
            parameter Types.PerUnit S_EE_2 "Exciter saturation function value at the correspponding exciter
              voltage, E2, back of commutating reactance";
            parameter Types.PerUnit VFE_MAX "Exciter field current limit reference";
            parameter Types.PerUnit VE_MIN "Minimum exciter voltage output";
            OpenIPSL.Electrical.Controls.PSSE.ES.BaseClasses.RotatingExciterWithDemagnetizationVarLim rotatingExciterWithDemagnetizationVarLim(T_E = T_E, K_E = K_E, E_1 = E_1, E_2 = E_2, S_EE_1 = S_EE_1, S_EE_2 = S_EE_2, Efd0 = VE0, K_D = K_D);
            Modelica.Blocks.Sources.Constant lowLim(k = VE_MIN);
            Modelica.Blocks.Sources.Constant FEMAX(k = VFE_MAX);
            Modelica.Blocks.Math.Add DiffV2(k2 = -K_D);
            OpenIPSL.NonElectrical.Functions.ImSE se1(SE1 = S_EE_1, SE2 = S_EE_2, E1 = E_1, E2 = E_2);
            Modelica.Blocks.Sources.Constant const(k = K_E);
            Modelica.Blocks.Math.Add DiffV3;
            NonElectrical.Nonlinear.Div0block div0block;
            Modelica.Blocks.Interfaces.RealInput XADIFD "Field current";
            NonElectrical.Continuous.PID_No_Windup pID_No_Windup(K_P = K_PR, K_I = K_IR, K_D = K_DR, T_D = T_DR, V_RMAX = VPID_MAX, V_RMIN = VPID_MIN, y_start_int = y_start_int);
            OpenIPSL.NonElectrical.Continuous.SimpleLag TransducerDelay(K = 1, T = T_R, y_start = ECOMP0);
            Modelica.Blocks.Math.Add3 VS;
            Modelica.Blocks.Math.Add DiffV1(k2 = +1);
            OpenIPSL.NonElectrical.Continuous.SimpleLagLim simpleLagLim(K = K_A, T = T_A, y_start = VR0, outMax = V_RMAX, outMin = V_RMIN);
            OpenIPSL.Electrical.Controls.PSSE.ES.BaseClasses.RectifierCommutationVoltageDrop rectifierCommutationVoltageDrop(K_C = K_C);
          protected
            parameter Real VR0(fixed = false);
            parameter Real Ifd0(fixed = false);
            parameter Real VE0(fixed = false);
            parameter Real VFE0(fixed = false);
            parameter Real Efd0(fixed = false);
            parameter Real y_start_int(fixed = false);
          initial equation
            VE0 = invFEX(K_C = K_C, Efd0 = Efd0, Ifd0 = Ifd0);
            VFE0 = VE0*(SE(VE0, S_EE_1, S_EE_2, E_1, E_2) + K_E) + Ifd0*K_D;
            VR0 = VFE0;
            V_REF = ECOMP;
            y_start_int = VR0/K_A;
            Ifd0 = XADIFD;
          equation
            connect(TransducerDelay.u, ECOMP);
            connect(DiffV.u2, TransducerDelay.y);
            connect(VOTHSG, VS.u1);
            connect(rectifierCommutationVoltageDrop.EFD, EFD);
            connect(rectifierCommutationVoltageDrop.V_EX, rotatingExciterWithDemagnetizationVarLim.EFD);
            connect(FEMAX.y, DiffV2.u1);
            connect(DiffV3.u1, const.y);
            connect(DiffV3.u2, se1.VE_OUT);
            connect(rotatingExciterWithDemagnetizationVarLim.I_C, simpleLagLim.y);
            connect(VUEL, VS.u2);
            connect(VOEL, VS.u3);
            connect(DiffV.y, DiffV1.u1);
            connect(VS.y, DiffV1.u2);
            connect(div0block.y, rotatingExciterWithDemagnetizationVarLim.outMax);
            connect(rotatingExciterWithDemagnetizationVarLim.outMin, lowLim.y);
            connect(XADIFD, DiffV2.u2);
            connect(rotatingExciterWithDemagnetizationVarLim.XADIFD, DiffV2.u2);
            connect(rectifierCommutationVoltageDrop.XADIFD, DiffV2.u2);
            connect(se1.VE_IN, rotatingExciterWithDemagnetizationVarLim.EFD);
            connect(DiffV1.y, pID_No_Windup.u);
            connect(pID_No_Windup.y, simpleLagLim.u);
            connect(DiffV2.y, div0block.u1);
            connect(DiffV3.y, div0block.u2);
          end AC8B;

          package BaseClasses "Base classes used in excitation systems from PSSE"
            extends Modelica.Icons.BasesPackage;

            partial model BaseExciter "Base exciter model for PSSE excitation systems"
              Modelica.Blocks.Interfaces.RealInput VUEL;
              Modelica.Blocks.Interfaces.RealInput VOEL;
              Modelica.Blocks.Interfaces.RealOutput EFD "Excitation Voltage [pu]";
              Modelica.Blocks.Interfaces.RealInput EFD0;
              Modelica.Blocks.Interfaces.RealInput VOTHSG;
              Modelica.Blocks.Interfaces.RealInput ECOMP;
              Modelica.Blocks.Sources.Constant VoltageReference(k = V_REF);
              Modelica.Blocks.Math.Add DiffV(k2 = -1);
            protected
              parameter Real Efd0(fixed = false);
              parameter Real V_REF(fixed = false);
              parameter Real ECOMP0(fixed = false);
            public
              Modelica.Blocks.Interfaces.RealInput XADIFD;
            initial equation
              Efd0 = EFD0;
              ECOMP0 = ECOMP;
            equation
              connect(VoltageReference.y, DiffV.u1);
            end BaseExciter;

            model RotatingExciterWithDemagnetization "Base model for a rotating exciter system with demagnetization effect"
              extends OpenIPSL.Electrical.Controls.PSSE.ES.BaseClasses.RotatingExciterBase(redeclare Modelica.Blocks.Math.Add3 Sum(k3 = K_D), redeclare replaceable Modelica.Blocks.Continuous.Integrator sISO(k = 1/T_E, initType = Modelica.Blocks.Types.Init.InitialOutput, y_start = Efd0));
              parameter Types.PerUnit K_D "Exciter demagnetizing factor";
              Modelica.Blocks.Interfaces.RealInput XADIFD;
              Modelica.Blocks.Interfaces.RealOutput V_FE;
            equation
              connect(XADIFD, Sum.u3);
              connect(V_FE, feedback.u2);
            end RotatingExciterWithDemagnetization;

            model RotatingExciterWithDemagnetizationVarLim "Base model for a rotating exciter system with demagnetization effect and variable limits in output"
              extends RotatingExciterWithDemagnetization(redeclare replaceable OpenIPSL.NonElectrical.Continuous.IntegratorLimVar sISO(K = 1/T_E, y_start = Efd0), redeclare Modelica.Blocks.Math.Add3 Sum(k3 = K_D));
              parameter Types.PerUnit K_D "Exciter demagnetizing factor";
              Modelica.Blocks.Interfaces.RealInput outMin;
              Modelica.Blocks.Interfaces.RealInput outMax;
            equation
              connect(outMax, sISO.outMax);
              connect(outMin, sISO.outMin);
            end RotatingExciterWithDemagnetizationVarLim;

            model RectifierCommutationVoltageDrop "Base model for excitation system with commutation voltage drop on rectifier"
              parameter Types.PerUnit K_C "Rectifier load factor";
              Modelica.Blocks.Interfaces.RealInput V_EX;
              Modelica.Blocks.Interfaces.RealInput XADIFD;
              Modelica.Blocks.Interfaces.RealOutput EFD;
              Modelica.Blocks.Math.Gain gain2(k = K_C);
              NonElectrical.Nonlinear.FEX fEX;
              Modelica.Blocks.Math.Product product1;
              Modelica.Blocks.Math.Division division;
            equation
              connect(V_EX, division.u2);
              connect(XADIFD, gain2.u);
              connect(gain2.y, division.u1);
              connect(division.y, fEX.u);
              connect(product1.y, EFD);
              connect(fEX.y, product1.u2);
              connect(product1.u1, division.u2);
            end RectifierCommutationVoltageDrop;

            model RotatingExciterBase "Base model for a rotating exciter"
              parameter Types.Time T_E "Exciter time constant";
              parameter Real K_E "Exciter field gain";
              parameter Types.PerUnit E_1 "Exciter saturation point 1";
              parameter Types.PerUnit E_2 "Exciter saturation point 2";
              parameter Types.PerUnit S_EE_1 "Saturation at E_1";
              parameter Types.PerUnit S_EE_2 "Saturation at E_2";
              parameter Types.PerUnit Efd0;
              Modelica.Blocks.Interfaces.RealInput I_C;
              Modelica.Blocks.Interfaces.RealOutput EFD;
              Modelica.Blocks.Math.Gain gain(k = K_E);
              replaceable Modelica.Blocks.Math.Add Sum;
              Modelica.Blocks.Math.Product VE;
              NonElectrical.Functions.ImSE se1(SE1 = S_EE_1, SE2 = S_EE_2, E1 = E_1, E2 = E_2);
              Modelica.Blocks.Math.Feedback feedback;
              replaceable Modelica.Blocks.Interfaces.SISO sISO;
            equation
              connect(Sum.y, feedback.u2);
              connect(se1.VE_OUT, VE.u2);
              connect(se1.VE_IN, EFD);
              connect(VE.u1, EFD);
              connect(gain.u, EFD);
              connect(gain.y, Sum.u2);
              connect(VE.y, Sum.u1);
              connect(I_C, feedback.u1);
              connect(feedback.y, sISO.u);
              connect(sISO.y, EFD);
            end RotatingExciterBase;

            function invFEX "Inverse F_EX function for initialization"
              input Real K_C;
              input Real Efd0;
              input Real Ifd0;
              output Real VE0;
            algorithm
              if Ifd0 <= 0 then
                VE0 := Efd0;
              elseif K_C*Ifd0/(Efd0 + 0.577*K_C*Ifd0) <= 0.433 then
                VE0 := Efd0 + 0.577*K_C*Ifd0;
              elseif K_C*Ifd0/sqrt((Efd0^2 + (K_C*Ifd0)^2)/0.75) > 0.433 and K_C*Ifd0/sqrt((Efd0^2 + (K_C*Ifd0)^2)/0.75) < 0.75 then
                VE0 := sqrt((Efd0^2 + (K_C*Ifd0)^2)/0.75);
              else
                VE0 := (Efd0 + 1.732*K_C*Ifd0)/1.732;
              end if;
            end invFEX;
          end BaseClasses;
        end ES;
      end PSSE;
    end Controls;

    package Branches "Models that represent devices that connect two or more buses such as transformers and power lines"
      extends Modelica.Icons.Package;

      model PwLine "Model for a transmission Line based on the pi-equivalent circuit"
        outer OpenIPSL.Electrical.SystemBase SysData;
        import Modelica.ComplexMath.conj;
        import Modelica.ComplexMath.real;
        import Modelica.ComplexMath.imag;
        import Modelica.ComplexMath.j;
        OpenIPSL.Interfaces.PwPin_p p;
        OpenIPSL.Interfaces.PwPin_n n;
        parameter Types.PerUnit R "Resistance";
        parameter Types.PerUnit X "Reactance";
        parameter Types.PerUnit G "Shunt half conductance";
        parameter Types.PerUnit B "Shunt half susceptance";
        parameter Types.ApparentPower S_b = SysData.S_b "System base power";
        parameter Types.Time t1 = Modelica.Constants.inf;
        parameter Types.Time t2 = Modelica.Constants.inf;
        parameter Integer opening = 1;
        parameter Boolean displayPF = false "Display power flow results:";
        Types.ActivePower P12;
        Types.ActivePower P21;
        Types.ReactivePower Q12;
        Types.ReactivePower Q21;
        Complex vs(re = p.vr, im = p.vi);
        Complex is(re = p.ir, im = p.ii);
        Complex vr(re = n.vr, im = n.vi);
        Complex ir(re = n.ir, im = n.ii);
      protected
        parameter Complex Y(re = G, im = B);
        parameter Complex Z(re = R, im = X);
      equation
        P12 = real(vs*conj(is))*S_b;
        P21 = -real(vr*conj(ir))*S_b;
        Q12 = imag(vs*conj(is))*S_b;
        Q21 = -imag(vr*conj(ir))*S_b;
        if time >= t1 and time < t2 then
          if opening == 1 then
            is = Complex(0);
            ir = Complex(0);
          elseif opening == 2 then
            is = Complex(0);
            ir = (vr - ir*Z)*Y;
          else
            ir = Complex(0);
            is = (vs - is*Z)*Y;
          end if;
        else
          vs - vr = Z*(is - vs*Y);
          vr - vs = Z*(ir - vr*Y);
        end if;
      end PwLine;
    end Branches;

    package Buses "Models that represent electrical nodes of a circuit"
      extends Modelica.Icons.Package;

      model Bus "Bus model (2014/03/10)"
        extends OpenIPSL.Electrical.Essentials.pfComponent(final enableQ_0 = false, final enableP_0 = false, final enablefn = false, final enableV_b = false, final enableS_b = false, final enabledisplayPF = true, final enableangle_0 = true, final enablev_0 = true);
        OpenIPSL.Interfaces.PwPin p(vr(start = v_0*cos(angle_0)), vi(start = v_0*sin(angle_0)));
        Types.PerUnit v(start = v_0) "Bus voltage magnitude";
        Types.Angle angle(start = angle_0) "Bus voltage angle";
        Modelica.Units.NonSI.Angle_deg angleDisplay = Modelica.Units.Conversions.to_deg(angle) "Angle in degrees for display purposes";
      equation
        v = sqrt(p.vr^2 + p.vi^2);
        angle = atan2(p.vi, p.vr);
        p.ir = 0;
        p.ii = 0;
      end Bus;
    end Buses;

    package Events "Models that can be used for the representation of events in a power system such as three-phase faults"
      extends Modelica.Icons.Package;

      model PwFault "Transitory short-circuit on a node. Shunt impedance connected only during a specified interval of time.
                    Developed by AIA. 2014/12/16"
        OpenIPSL.Interfaces.PwPin p;
        parameter Types.PerUnit R "Resistance";
        parameter Types.PerUnit X "Reactance";
        parameter Types.Time t1 "Start time of the fault";
        parameter Types.Time t2 "End time of the fault";
        import Modelica.Constants.eps;
      protected
        parameter Boolean ground = abs(R) < eps and abs(X) < eps;
      equation
        if time < t1 then
          p.ii = 0;
          p.ir = 0;
        elseif time < t2 and ground then
          p.vr = 1E-10;
          p.vi = 0;
        elseif time < t2 then
          p.ii = (R*p.vi - X*p.vr)/(X*X + R*R);
          p.ir = (R*p.vr + X*p.vi)/(R*R + X*X);
        else
          p.ii = 0;
          p.ir = 0;
        end if;
      end PwFault;
    end Events;

    package Loads "Models that represent various types of loads in a power system"
      extends Modelica.Icons.Package;

      package PSSE "Load models from PSSE components"
        extends Modelica.Icons.Package;

        model Load_variation "PSS/E Load with variation"
          extends BaseClasses.baseLoad;
          parameter Types.PerUnit d_P "Active Load Variation";
          parameter Types.Time t1 "Time of Load Variation";
          parameter Types.Time d_t "Time duration of load variation";
        protected
          parameter Real PF = if q0 <= C.eps then 1 else p0/q0 "Ration between active and reactive power; Not Power Factor";
          parameter Types.PerUnit d_Q = (p0 + d_P)/PF - q0;
        equation
          if time >= t1 and time < t1 + d_t then
            kI*S_I.re*v + S_Y.re*v^2 + kP*(S_P.re + d_P) = p.vr*p.ir + p.vi*p.ii;
            kI*S_I.im*v + S_Y.im*v^2 + kP*(S_P.im + d_Q) = (-p.vr*p.ii) + p.vi*p.ir;
          else
            kI*S_I.re*v + S_Y.re*v^2 + kP*S_P.re = p.vr*p.ir + p.vi*p.ii;
            kI*S_I.im*v + S_Y.im*v^2 + kP*S_P.im = (-p.vr*p.ii) + p.vi*p.ir;
          end if;
        end Load_variation;

        package BaseClasses "Base load models from PSSE"
          extends Modelica.Icons.BasesPackage;

          partial model baseLoad "Base load for PSSE models"
            extends OpenIPSL.Electrical.Essentials.pfComponent(final enabledisplayPF = false, final enablefn = false, final enableV_b = false, final enableS_b = true, final enableangle_0 = true, final enablev_0 = true, final enableQ_0 = true, final enableP_0 = true);
            import Modelica.ComplexMath.j;
            parameter Types.ComplexPower S_p = Complex(P_0, Q_0) "Consumption of original constant power load";
            parameter Types.ComplexPower S_i = Complex(0.0, 0.0) "Consumption of original constant current load";
            parameter Types.ComplexPower S_y = Complex(0.0, 0.0) "Consumption of original constant shunt admittance load";
            parameter Complex a = Complex(1.0, 0.0) "Load transfer fraction for constant current load";
            parameter Complex b = Complex(0.0, 1.0) "Load transfer fraction for constant shunt admittance load";
            parameter Types.PerUnit PQBRAK = 0.7 "Constant power characteristic threshold";
            parameter Integer characteristic = 1;
            OpenIPSL.Interfaces.PwPin p(vr(start = vr0), vi(start = vi0), ir(start = ir0), ii(start = ii0));
            Types.Angle angle(start = angle_0) "Bus voltage angle";
            Types.PerUnit v(start = v_0) "Bus voltage magnitude";
            Types.PerUnit P "Active power consumption";
            Types.PerUnit Q "Reactive power consumption";
          protected
            parameter Types.PerUnit p0 = (S_i.re*v_0 + S_y.re*v_0^2 + S_p.re)/S_b "Initial active power";
            parameter Types.PerUnit q0 = (S_i.im*v_0 + S_y.im*v_0^2 + S_p.im)/S_b "Initial reactive power";
            parameter Types.PerUnit vr0 = v_0*cos(angle_0) "Initial real voltage";
            parameter Types.PerUnit vi0 = v_0*sin(angle_0) "Initial imaginary voltage";
            parameter Types.PerUnit ir0 = (p0*vr0 + q0*vi0)/(vr0^2 + vi0^2) "Initial real current";
            parameter Types.PerUnit ii0 = (p0*vi0 - q0*vr0)/(vr0^2 + vi0^2) "Initial imaginary current";
            parameter Complex S_P = Complex((1 - a.re - b.re)*S_p.re, (1 - a.im - b.im)*S_p.im)/S_b "[pu]";
            parameter Complex S_I = (S_i + Complex(a.re*S_p.re/v_0, a.im*S_p.im/v_0))/S_b "[pu]";
            parameter Complex S_Y = (S_y + Complex(b.re*S_p.re/v_0^2, b.im*S_p.im/v_0^2))/S_b "[pu]";
            parameter Real a2 = 1.502;
            parameter Real b2 = 1.769;
            parameter Real a0 = 0.4881;
            parameter Real a1 = -0.4999;
            parameter Real b1 = 0.1389;
            parameter Real wp = 3.964;
            Real kP(start = 1);
            Real kI(start = 1);
          equation
            P = p.vr*p.ir + p.vi*p.ii;
            Q = (-p.vr*p.ii) + p.vi*p.ir;
            angle = atan2(p.vi, p.vr);
            v = sqrt(p.vr^2 + p.vi^2);
            if characteristic == 1 then
              if v < PQBRAK/2 and v > 0 then
                kP = 2*(v/PQBRAK)^2;
                kI = 1;
              elseif v > PQBRAK/2 and v < PQBRAK then
                kP = 1 - 2*((v - PQBRAK)/PQBRAK)^2;
                kI = 1;
              else
                kP = 1;
                kI = 1;
              end if;
            else
              if v < PQBRAK then
                kP = a0 + a1*cos(v*wp) + b1*sin(v*wp);
              else
                kP = 1;
              end if;
              if v < 0.5 then
                kI = a2*b2*v^(b2 - 1)*exp(-a2*v^b2);
              else
                kI = 1;
              end if;
            end if;
          end baseLoad;
        end BaseClasses;
      end PSSE;
    end Loads;

    package Machines "Models that represent the rotating electrical machines connected to a power system such as generators and motors"
      extends Modelica.Icons.Package;

      package PSSE "Machine models from PSSE"
        extends Modelica.Icons.Package;

        model GENCLS "Classic generator model that can also represent an infinite bus"
          extends Icons.VerifiedModel;
          extends OpenIPSL.Electrical.Essentials.pfComponent(final enabledisplayPF = false, final enableangle_0 = true, final enablev_0 = true, final enableQ_0 = true, final enableP_0 = true, final enablefn = false, final enableV_b = false, final enableS_b = false);
          OpenIPSL.Interfaces.PwPin p(vr(start = vr0), vi(start = vi0), ir(start = ir0), ii(start = ii0));
          parameter Types.ApparentPower M_b = 100e6 "Machine base power rating";
          parameter Types.Time H = 0 "Inertia constant";
          parameter Real D = 0 "Damping coefficient";
          parameter Types.PerUnit R_a = 0 "Armature resistance";
          parameter Types.PerUnit X_d = 0.2 "d-axis transient reactance";
          Types.Angle delta(start = delta0, fixed = true) "Rotor angle";
          Types.PerUnit omega(start = 0, fixed = true) "Rotor speed";
          Types.PerUnit V(start = v_0) "Bus voltage magnitude";
          Types.Angle anglev(start = angle_0) "Bus voltage angle";
          Types.PerUnit eq(start = vf0, fixed = true) "Constant emf behind transient reactance";
          Types.PerUnit vd(start = vd0) "d-axis voltage";
          Types.PerUnit vq(start = vq0) "q-axis voltage";
          Types.PerUnit id(start = id0) "d-axis current";
          Types.PerUnit iq(start = iq0) "q-axis current";
          Types.PerUnit P(start = P_0/S_b) "Active power (system base)";
          Types.PerUnit Q(start = Q_0/S_b) "Reactive power (system base)";
        protected
          parameter Real CoB = M_b/S_b "Change from system to machine base";
          parameter Types.PerUnit p0 = P_0/M_b "Initial active power (machine base)";
          parameter Types.PerUnit q0 = Q_0/M_b "Initial reactive power (machine base)";
          parameter Types.PerUnit vr0 = v_0*cos(angle_0);
          parameter Types.PerUnit vi0 = v_0*sin(angle_0);
          parameter Types.PerUnit ir0 = (p0*vr0 + q0*vi0)/(vr0^2 + vi0^2);
          parameter Types.PerUnit ii0 = (p0*vi0 - q0*vr0)/(vr0^2 + vi0^2);
          parameter Types.Angle delta0 = atan2(vi0 + R_a*ii0 + X_d*ir0, vr0 + R_a*ir0 - X_d*ii0);
          parameter Types.PerUnit vd0 = vr0*cos(C.pi/2 - delta0) - vi0*sin(C.pi/2 - delta0);
          parameter Types.PerUnit vq0 = vr0*sin(C.pi/2 - delta0) + vi0*cos(C.pi/2 - delta0);
          parameter Types.PerUnit id0 = ir0*cos(C.pi/2 - delta0) - ii0*sin(C.pi/2 - delta0);
          parameter Types.PerUnit iq0 = ir0*sin(C.pi/2 - delta0) + ii0*cos(C.pi/2 - delta0);
          parameter Types.PerUnit vf0 = vq0 + R_a*iq0 + X_d*id0;
        equation
          if abs(H) > C.eps then
            der(delta) = omega*2*C.pi*fn;
            der(omega) = (P_0/S_b - P - D*omega)/(2*H);
          else
            der(delta) = 0;
            der(omega) = 0;
          end if;
          der(eq) = 0 "Classical model assumes constant emf";
          vq = eq - R_a*iq - X_d*id "q-axis voltage equation";
          vd = X_d*iq - R_a*id "d-axis voltage equation";
          [p.ir; p.ii] = -CoB*[sin(delta), cos(delta); -cos(delta), sin(delta)]*[id; iq];
          [p.vr; p.vi] = [sin(delta), cos(delta); -cos(delta), sin(delta)]*[vd; vq];
          -P = p.vr*p.ir + p.vi*p.ii;
          -Q = p.vi*p.ir - p.vr*p.ii;
          V = sqrt(p.vr^2 + p.vi^2);
          anglev = atan2(p.vi, p.vr);
        end GENCLS;

        model GENROU "ROUND ROTOR GENERATOR MODEL (QUADRATIC SATURATION)"
          extends Icons.VerifiedModel;
          import Complex;
          import Modelica.ComplexMath.arg;
          import Modelica.ComplexMath.real;
          import Modelica.ComplexMath.imag;
          import Modelica.ComplexMath.abs;
          import Modelica.ComplexMath.conj;
          import Modelica.ComplexMath.fromPolar;
          import Modelica.ComplexMath.j;
          import OpenIPSL.NonElectrical.Functions.SE;
          extends BaseClasses.baseMachine(XADIFD(start = efd0), delta(start = delta0, fixed = true), id(start = id0), iq(start = iq0), ud(start = ud0), uq(start = uq0), Te(start = pm0));
          parameter Types.PerUnit Xpq "q-axis transient reactance ";
          parameter Types.Time Tpq0 "q-axis transient open-circuit time constant";
          parameter Types.PerUnit Xpp = Xppd "Sub-transient reactance ";
          Types.PerUnit Epd(start = Epd0) "d-axis voltage behind transient reactance ";
          Types.PerUnit Epq(start = Epq0) "q-axis voltage behind transient reactance ";
          Types.PerUnit PSIkd(start = PSIkd0) "d-axis rotor flux linkage ";
          Types.PerUnit PSIkq(start = PSIkq0) "q-axis rotor flux linkage ";
          Types.PerUnit PSId(start = PSId0) "d-axis flux linkage ";
          Types.PerUnit PSIq(start = PSIq0) "q-axis flux linkage ";
          Types.PerUnit PSIppd(start = PSIppd0) "d-axis subtransient flux linkage ";
          Types.PerUnit PSIppq(start = PSIppq0) "q-axis subtransient flux linkage ";
          Types.PerUnit PSIpp "Air-gap flux ";
          Types.PerUnit XadIfd(start = efd0) "d-axis machine field current ";
          Types.PerUnit XaqIlq(start = 0) "q-axis Machine field current ";
        protected
          parameter Complex Zs = Complex(R_a, Xpp) "Equivalent impedance";
          parameter Complex VT = Complex(v_0*cos(angle_0), v_0*sin(angle_0)) "Complex terminal voltage";
          parameter Complex S = Complex(p0, q0) "Complex power on machine base";
          parameter Complex It = Complex(real(S/VT), -imag(S/VT)) "Complex current, machine base";
          parameter Complex Is = Complex(real(It + VT/Zs), imag(It + VT/Zs)) "Equivalent internal current source";
          parameter Complex PSIpp0 = Complex(real(Zs*Is), imag(Zs*Is)) "Sub-transient flux linkage in stator reference frame";
          parameter Types.Angle ang_PSIpp0 = arg(PSIpp0) "flux angle";
          parameter Types.Angle ang_It = arg(It) "current angle";
          parameter Types.Angle ang_PSIpp0andIt = ang_PSIpp0 - ang_It "angle difference";
          parameter Types.PerUnit abs_PSIpp0 = abs(PSIpp0) "magnitude of sub-transient flux linkage";
          parameter Real dsat = SE(abs_PSIpp0, S10, S12, 1, 1.2) "To include saturation of during initialization";
          parameter Real a = abs_PSIpp0 + abs_PSIpp0*dsat*(Xq - Xl)/(Xd - Xl);
          parameter Real b = (It.re^2 + It.im^2)^0.5*(Xpp - Xq);
          parameter Types.Angle delta0 = atan(b*cos(ang_PSIpp0andIt)/(b*sin(ang_PSIpp0andIt) - a)) + ang_PSIpp0 "initial rotor angle in radians";
          parameter Complex DQ_dq = cos(delta0) - j*sin(delta0) "Parks transformation, from stator to rotor reference frame";
          parameter Complex PSIpp0_dq = PSIpp0*DQ_dq "Flux linkage in rotor reference frame";
          parameter Complex I_dq = conj(It*DQ_dq);
          parameter Types.PerUnit PSIppq0 = imag(PSIpp0_dq) "q-axis component of the sub-transient flux linkage";
          parameter Types.PerUnit PSIppd0 = real(PSIpp0_dq) "d-axis component of the sub-transient flux linkage";
          parameter Types.PerUnit iq0 = real(I_dq) "q-axis component of initial current";
          parameter Types.PerUnit id0 = imag(I_dq) "d-axis component of initial current";
          parameter Types.PerUnit ud0 = (-(PSIppq0 - Xppq*iq0)) - R_a*id0 "d-axis component of initial voltage";
          parameter Types.PerUnit uq0 = PSIppd0 - Xppd*id0 - R_a*iq0 "q-axis component of initial voltage";
          parameter Types.PerUnit vr0 = v_0*cos(angle_0) "Real component of initial terminal voltage";
          parameter Types.PerUnit vi0 = v_0*sin(angle_0) "Imaginary component of initial terminal voltage";
          parameter Types.PerUnit ir0 = -CoB*(p0*vr0 + q0*vi0)/(vr0^2 + vi0^2) "Real component of initial armature current (system base)";
          parameter Types.PerUnit ii0 = -CoB*(p0*vi0 - q0*vr0)/(vr0^2 + vi0^2) "Imaginary component of initial armature current (system base)";
          parameter Types.PerUnit pm0 = p0 + R_a*iq0*iq0 + R_a*id0*id0 "Initial mechanical power (machine base)";
          parameter Types.PerUnit efd0 = dsat*PSIppd0 + PSIppd0 + (Xpd - Xpp)*id0 + (Xd - Xpd)*id0 "Initial field voltage magnitude";
          parameter Types.PerUnit Epq0 = PSIkd0 + (Xpd - Xl)*id0;
          parameter Types.PerUnit Epd0 = PSIkq0 - (Xpq - Xl)*iq0;
          parameter Types.PerUnit PSIkd0 = (PSIppd0 - (Xpd - Xl)*K3d*id0)/(K3d + K4d) "d-axis initial rotor flux linkage";
          parameter Types.PerUnit PSIkq0 = ((-PSIppq0) + (Xpq - Xl)*K3q*iq0)/(K3q + K4q) "q-axis initial rotor flux linkage";
          parameter Types.PerUnit PSId0 = PSIppd0 - Xppd*id0;
          parameter Types.PerUnit PSIq0 = (-PSIppq0) - Xppq*iq0;
          parameter Real K1d = (Xpd - Xppd)*(Xd - Xpd)/(Xpd - Xl)^2;
          parameter Real K2d = (Xpd - Xl)*(Xppd - Xl)/(Xpd - Xppd);
          parameter Real K1q = (Xpq - Xppq)*(Xq - Xpq)/(Xpq - Xl)^2;
          parameter Real K2q = (Xpq - Xl)*(Xppq - Xl)/(Xpq - Xppq);
          parameter Real K3d = (Xppd - Xl)/(Xpd - Xl);
          parameter Real K4d = (Xpd - Xppd)/(Xpd - Xl);
          parameter Real K3q = (Xppq - Xl)/(Xpq - Xl);
          parameter Real K4q = (Xpq - Xppq)/(Xpq - Xl);
          parameter Real CoB = M_b/S_b "Constant to change from system base to machine base";
        initial equation
          der(Epd) = 0;
          der(Epq) = 0;
          der(PSIkd) = 0;
          der(PSIkq) = 0;
        equation
          XADIFD = XadIfd;
          ISORCE = XadIfd;
          EFD0 = efd0;
          PMECH0 = pm0;
          der(Epq) = 1/Tpd0*(EFD - XadIfd);
          der(Epd) = 1/Tpq0*(-1)*XaqIlq;
          der(PSIkd) = 1/Tppd0*(Epq - PSIkd - (Xpd - Xl)*id);
          der(PSIkq) = 1/Tppq0*(Epd - PSIkq + (Xpq - Xl)*iq);
          Te = PSId*iq - PSIq*id;
          PSId = PSIppd - Xppd*id;
          PSIq = (-PSIppq) - Xppq*iq;
          PSIppd = Epq*K3d + PSIkd*K4d;
          -PSIppq = (-Epd*K3q) - PSIkq*K4q;
          PSIpp = sqrt(PSIppd*PSIppd + PSIppq*PSIppq);
          XadIfd = K1d*(Epq - PSIkd - (Xpd - Xl)*id) + Epq + id*(Xd - Xpd) + SE(PSIpp, S10, S12, 1, 1.2)*PSIppd;
          XaqIlq = K1q*(Epd - PSIkq + (Xpq - Xl)*iq) + Epd - iq*(Xq - Xpq) - SE(PSIpp, S10, S12, 1, 1.2)*(-1)*PSIppq*(Xq - Xl)/(Xd - Xl);
          ud = (-PSIq) - R_a*id;
          uq = PSId - R_a*iq;
        end GENROU;

        package BaseClasses "Base classes for base machines from PSSE"
          extends Modelica.Icons.BasesPackage;

          partial model baseMachine "Base machine for PSSE models"
            import Complex;
            import Modelica.ComplexMath.arg;
            import Modelica.ComplexMath.real;
            import Modelica.ComplexMath.imag;
            import Modelica.ComplexMath.conj;
            import Modelica.Blocks.Interfaces.*;
            extends OpenIPSL.Electrical.Essentials.pfComponent(final enabledisplayPF = false, final enablefn = false, final enableV_b = false, final enableangle_0 = true, final enablev_0 = true, final enableQ_0 = true, final enableP_0 = true, final enableS_b = true);
            parameter Types.ApparentPower M_b "Machine base power";
            parameter Types.Time Tpd0 "d-axis transient open-circuit time constant";
            parameter Types.Time Tppd0 "d-axis sub-transient open-circuit time constant";
            parameter Types.Time Tppq0 "q-axis sub-transient open-circuit time constant";
            parameter Types.Time H "Inertia constant";
            parameter Real D "Speed damping";
            parameter Types.PerUnit Xd "d-axis reactance";
            parameter Types.PerUnit Xq "q-axis reactance";
            parameter Types.PerUnit Xpd "d-axis transient reactance";
            parameter Types.PerUnit Xppd "d-axis sub-transient reactance";
            parameter Types.PerUnit Xppq "q-axis sub-transient reactance";
            parameter Types.PerUnit Xl "leakage reactance";
            parameter Types.PerUnit S10 "Saturation factor at 1.0 pu";
            parameter Types.PerUnit S12 "Saturation factor at 1.2 pu";
            parameter Types.PerUnit R_a = 0 "Armature resistance";
            parameter Types.PerUnit w0(min = -1 + C.eps) = 0 "Initial speed deviation from nominal";
            OpenIPSL.Interfaces.PwPin p(vr(start = vr0), vi(start = vi0), ir(start = ir0), ii(start = ii0));
            RealOutput SPEED "Machine speed deviation from nominal [pu]";
            RealInput PMECH "Turbine mechanical power (machine base)";
            RealOutput PMECH0 "Initial value of machine electrical power (machine base)";
            RealOutput ETERM(start = v_0) "Machine terminal voltage [pu]";
            RealInput EFD "Generator main field voltage [pu]";
            RealOutput EFD0 "Initial generator main field voltage [pu]";
            RealOutput PELEC(start = p0) "Machine electrical power (machine base)";
            RealOutput ISORCE "Machine source current [pu]";
            RealOutput ANGLE "Machine relative rotor angle";
            RealOutput XADIFD "Machine field current [pu]";
            Types.PerUnit w(start = w0, fixed = true) "Machine speed deviation";
            Types.Angle delta "Rotor angle";
            Types.PerUnit Vt(start = v_0) "Bus voltage magnitude";
            Types.Angle anglev(start = angle_0) "Bus voltage angle";
            Types.PerUnit I(start = sqrt(ir0^2 + ii0^2)) "Terminal current magnitude";
            Types.Angle anglei(start = atan2(ii0, ir0)) "Terminal current angle";
            Types.PerUnit P(start = P_0/S_b) "Active power (system base)";
            Types.PerUnit Q(start = Q_0/S_b) "Reactive power (system base)";
            Types.PerUnit Te "Electrical torque [pu]";
            Types.PerUnit id "d-axis armature current [pu]";
            Types.PerUnit iq "q-axis armature current [pu]";
            Types.PerUnit ud "d-axis terminal voltage [pu]";
            Types.PerUnit uq "q-axis terminal voltage [pu]";
            Modelica.Blocks.Interfaces.RealOutput QELEC(start = p0) "Machine electrical power (machine base)";
          protected
            parameter Types.AngularVelocity w_b = 2*C.pi*fn "System base speed";
            parameter Real CoB = M_b/S_b;
            parameter Types.PerUnit vr0 = v_0*cos(angle_0) "Real component of initial terminal voltage";
            parameter Types.PerUnit vi0 = v_0*sin(angle_0) "Imaginary component of initial terminal voltage";
            parameter Types.PerUnit ir0 = -CoB*(p0*vr0 + q0*vi0)/(vr0^2 + vi0^2) "Real component of initial armature current (system base)";
            parameter Types.PerUnit ii0 = -CoB*(p0*vi0 - q0*vr0)/(vr0^2 + vi0^2) "Imaginary component of initial armature current (system base)";
            parameter Types.PerUnit p0 = P_0/M_b "Initial active power generation (machine base)";
            parameter Types.PerUnit q0 = Q_0/M_b "Initial reactive power generation (machine base)";
          equation
            ANGLE = delta;
            SPEED = w;
            ETERM = Vt;
            PELEC = P/CoB;
            QELEC = Q/CoB;
            [p.ir; p.ii] = -CoB*[sin(delta), cos(delta); -cos(delta), sin(delta)]*[id; iq];
            [p.vr; p.vi] = [sin(delta), cos(delta); -cos(delta), sin(delta)]*[ud; uq];
            -P = p.vr*p.ir + p.vi*p.ii;
            -Q = p.vi*p.ir - p.vr*p.ii;
            Vt = sqrt(p.vr^2 + p.vi^2);
            anglev = atan2(p.vi, p.vr);
            I = sqrt(p.ii^2 + p.ir^2);
            anglei = atan2(p.ii, p.ir);
            der(w) = ((PMECH - D*w)/(w + 1) - Te)/(2*H);
            der(delta) = w_b*w;
          end baseMachine;
        end BaseClasses;
      end PSSE;
    end Machines;

    package Essentials "Contains models that can be extended for purposes of initialization with power flow results"
      extends Modelica.Icons.InternalPackage;

      partial model pfComponent "Partial model containing all the parameters for entering power flow data"
        outer OpenIPSL.Electrical.SystemBase SysData "Must add this line in all models";
        parameter Types.ApparentPower S_b = SysData.S_b "System base power";
        parameter Boolean enableS_b = false "Enable S_b in parameter list";
        parameter Types.Voltage V_b = 400e3 "Base voltage of the bus";
        parameter Boolean enableV_b = false "Enable V_b in parameter list";
        parameter Types.Frequency fn = SysData.fn "System frequency";
        parameter Boolean enablefn = false "Enable fn in parameter list";
        parameter Types.ActivePower P_0 = 1e6 "Initial active power";
        parameter Boolean enableP_0 = false "Enable P_0 in parameter list";
        parameter Types.ReactivePower Q_0 = 0 "Initial reactive power";
        parameter Boolean enableQ_0 = false "Enable Q_0 in parameter list";
        parameter Types.PerUnit v_0 = 1 "Initial voltage magnitude";
        parameter Boolean enablev_0 = false "Enable v_0 in parameter list";
        parameter Types.Angle angle_0 = 0 "Initial voltage angle";
        parameter Boolean enableangle_0 = false "Enable angle_0 in parameter list";
        parameter Boolean displayPF = false "Display power flow:";
        parameter Boolean enabledisplayPF = false "Enable displayPF in parameter list";
      end pfComponent;
    end Essentials;
  end Electrical;

  package NonElectrical "Package for non-electrical models used in this library"
    extends Modelica.Icons.Package;

    package Continuous "Blocks that are described with continuous equations"
      extends Modelica.Icons.Package;

      block IntegratorLimVar "Integrator with a non windup limiter and variable limits"
        extends Modelica.Blocks.Interfaces.SISO;
        parameter Real K "Gain" annotation(Evaluate = false);
        parameter Real y_start "Output start value";
        Modelica.Blocks.Interfaces.RealInput outMax;
        Modelica.Blocks.Interfaces.RealInput outMin;
      protected
        Real x "Dummy variable for input";
        Real w "Dummy variable for output";
        Real initVar "Dummy variable to be used as setting quantity";
        Boolean ReachUpper "Flag for reaching upper limit";
        Boolean ReachLower "Flag for reaching lower limit";
        Boolean Rising "Flag to know if input is positive";
        Boolean Falling "Flag to know if input is negative";
        Boolean Reinit "Flag to reset state variable";
      initial equation
        if y_start >= outMax then
          w = outMax;
        elseif y_start <= outMin then
          w = outMin;
        else
          w = y_start;
        end if;
      equation
        assert(outMax > outMin, "Upper limit must be greater than lower limit");
        if ReachUpper then
          x = 0;
          y = outMax;
        elseif ReachLower then
          x = 0;
          y = outMin;
        else
          x = u;
          y = w;
        end if;
        der(w) = K*x;
        when Reinit then
          reinit(w, initVar);
        end when;
      algorithm
        if u > Modelica.Constants.eps then
          Rising := true;
          Falling := false;
        elseif u < -Modelica.Constants.eps then
          Rising := false;
          Falling := true;
        else
          Rising := false;
          Falling := false;
        end if;
        if w > outMax then
          ReachUpper := true;
          ReachLower := false;
        elseif w < outMin then
          ReachLower := true;
          ReachUpper := false;
        else
          ReachUpper := false;
          ReachLower := false;
        end if;
        if ReachUpper and Falling then
          Reinit := true;
          initVar := outMax;
        elseif ReachLower and Rising then
          Reinit := true;
          initVar := outMin;
        else
        end if;
      end IntegratorLimVar;

      model PI_No_Windup "PI controller with no wind-up"
        extends Modelica.Blocks.Interfaces.SISO;
        parameter Types.PerUnit K_P "Voltage regulator proportional gain";
        parameter Types.PerUnit K_I "Voltage regulator integral gain";
        parameter Types.PerUnit V_RMAX "Maximum regulator output";
        parameter Types.PerUnit V_RMIN "Minimum regulator output";
        parameter Types.PerUnit y_start_int "Initial output value";
        Modelica.Blocks.Continuous.Integrator integral(k = K_I, use_reset = false, initType = Modelica.Blocks.Types.Init.InitialOutput, y_start = y_start_int);
        Modelica.Blocks.Math.Gain proportional(k = K_P);
        Modelica.Blocks.Math.MultiSum add(nu = 2);
        Modelica.Blocks.Nonlinear.Limiter limiter(uMax = V_RMAX, uMin = V_RMIN);
        Modelica.Blocks.Logical.Switch reset_switch;
        Modelica.Blocks.Sources.RealExpression zero;
      equation
        reset_switch.u2 = if (abs(V_RMAX - y) <= Modelica.Constants.eps and der(integral.y) > 0) then true else if (abs(V_RMIN - y) <= Modelica.Constants.eps and der(integral.y) < 0) then true else false;
        connect(add.y, limiter.u);
        connect(reset_switch.u1, zero.y);
        connect(reset_switch.y, integral.u);
        connect(u, reset_switch.u3);
        connect(proportional.u, u);
        connect(limiter.y, y);
        connect(integral.y, add.u[1]);
        connect(proportional.y, add.u[2]);
      end PI_No_Windup;

      model PID_No_Windup "PID controller with no wind-up"
        extends PI_No_Windup(add(nu = 3));
        parameter Types.PerUnit K_D "Voltage regulator derivative gain";
        parameter Types.Time T_D "Voltage regulator derivative channel time constant";
        Modelica.Blocks.Math.Gain gain1(k = K_D*kd);
        Modelica.Blocks.Math.Add derivative_add(k2 = -1);
        Modelica.Blocks.Continuous.Integrator derivative(initType = Modelica.Blocks.Types.Init.InitialOutput, y_start = 0);
        Modelica.Blocks.Math.Gain gain2(k = kd);
      protected
        parameter Real kd = if T_D <= Modelica.Constants.eps then 1 else 1/T_D;
      equation
        connect(gain1.y, derivative_add.u1);
        connect(derivative.y, derivative_add.u2);
        connect(gain2.y, derivative.u);
        connect(u, gain1.u);
        connect(gain2.u, derivative_add.y);
        connect(derivative_add.y, add.u[3]);
      end PID_No_Windup;

      block SimpleLag "First order lag transfer function block"
        extends Modelica.Blocks.Interfaces.SISO(y(start = y_start));
        Modelica.Blocks.Sources.RealExpression const(y = T);
        Real state(start = y_start);
        parameter Real K "Gain";
        parameter Types.Time T "Lag time constant" annotation(Evaluate = true);
        parameter Real y_start "Output start value";
      protected
        parameter Real T_mod = if T < Modelica.Constants.eps then 1000 else T;
      initial equation
        state = y_start;
      equation
        T_mod*der(state) = K*u - state;
        if abs(const.y) <= Modelica.Constants.eps then
          y = u*K;
        else
          y = state;
        end if;
      end SimpleLag;

      block SimpleLagLim "First order lag transfer function block with a non windup limiter"
        extends Modelica.Blocks.Interfaces.SISO(y(start = y_start));
        Modelica.Blocks.Sources.RealExpression const(y = T);
        Real state;
        parameter Real K "Gain";
        parameter Types.Time T "Lag time constant";
        parameter Real y_start "Output start value";
        parameter Real outMax "Maximum output value";
        parameter Real outMin "Minimum output value";
      protected
        parameter Real T_mod = if T < Modelica.Constants.eps then 1000 else T;
      initial equation
        state = y_start;
      equation
        T_mod*der(state) = K*u - state;
        when state > outMax and K*u - state < 0 then
          reinit(state, outMax);
        elsewhen state < outMin and K*u - state > 0 then
          reinit(state, outMin);
        end when;
        if abs(const.y) <= Modelica.Constants.eps then
          y = max(min(u*K, outMax), outMin);
        else
          y = max(min(state, outMax), outMin);
        end if;
      end SimpleLagLim;
    end Continuous;

    package Functions "Package with functions used in the models from the library"
      extends Modelica.Icons.FunctionsPackage;

      function div0protect "Division avoiding 0 by replacing b with eps if requried"
        extends Modelica.Icons.Function;
        import eps = Modelica.Constants.small;
        input Real a "Dividend";
        input Real b "Divisor";
        output Real c "Quotient";
      algorithm
        c := a/(max(b, eps));
      end div0protect;

      block ImSE "Block for Saturation function of Exc "
        input Modelica.Blocks.Interfaces.RealInput VE_IN "Unsaturated Input";
        output Modelica.Blocks.Interfaces.RealOutput VE_OUT "Saturated Output";
        parameter Real SE1 "Saturation at E1";
        parameter Real SE2 "Saturation at E2";
        parameter Real E1;
        parameter Real E2;
      equation
        VE_OUT = OpenIPSL.NonElectrical.Functions.SE(VE_IN, SE1, SE2, E1, E2);
      end ImSE;

      function SE "Scaled Quadratic Saturation Function (PTI PSS/E) "
        extends Modelica.Icons.Function;
        input Real u "Unsaturated Input";
        input Real SE1;
        input Real SE2;
        input Real E1;
        input Real E2;
        output Real sys "Saturated Output";
      protected
        Real a = if SE2 <> 0 then sqrt(SE1*E1/(SE2*E2)) else 0;
        Real A = E2 - (E1 - E2)/(a - 1);
        Real B = if abs(E1 - E2) < Modelica.Constants.eps then 0 else SE2*E2*(a - 1)^2/(E1 - E2)^2;
      algorithm
        if SE1 == 0.0 or u <= 0.0 then
          sys := 0.0;
        else
          if u <= A then
            sys := 0.0;
          else
            sys := B*(u - A)^2/u;
          end if;
        end if;
      end SE;
    end Functions;

    package Nonlinear "Blocks that are described with nonlinear equations"
      extends Modelica.Icons.Package;

      block Div0block "Block that implements division by zero protection"
        extends Modelica.Blocks.Interfaces.SI2SO;
      equation
        y = OpenIPSL.NonElectrical.Functions.div0protect(u1, u2);
      end Div0block;

      model FEX "FEX=f(IN)"
        Modelica.Blocks.Interfaces.RealInput u;
        Modelica.Blocks.Interfaces.RealOutput y;
      equation
        if u <= 0 then
          y = 1;
        elseif u > 0 and u <= 0.433 then
          y = 1 - 0.577*u;
        elseif u > 0.433 and u < 0.75 then
          y = sqrt(0.75 - u^2);
        elseif u >= 0.75 and u <= 1 then
          y = 1.732*(1 - u);
        else
          y = 0;
        end if;
      end FEX;
    end Nonlinear;
  end NonElectrical;

  package Interfaces "Package for interface models used in this library. "
    extends Modelica.Icons.InterfacesPackage;

    connector PwPin "Connector for electrical blocks treating voltage and current as complex variables"
      Types.PerUnit vr "Real part of the voltage";
      Types.PerUnit vi "Imaginary part of the voltage";
      flow Types.PerUnit ir(start = Modelica.Constants.eps) "Real part of the current";
      flow Types.PerUnit ii(start = Modelica.Constants.eps) "Imaginary part of the current";
    end PwPin;

    connector PwPin_p "Positive connector for electrical blocks treating voltage and current as complex variables"
      extends PwPin;
    end PwPin_p;

    connector PwPin_n "Negative connector for electrical blocks treating voltage and current as complex variables"
      extends PwPin;
    end PwPin_n;
  end Interfaces;

  package Icons "Place for OpenIPSL specific icons"
    extends Modelica.Icons.IconsPackage;

    partial class VerifiedModel "Icon for classes that were verified" end VerifiedModel;
  end Icons;

  package Types "Library specific type definitions"
    extends Modelica.Icons.TypesPackage;
    type Voltage = SI.Voltage(nominal = 1e4, displayUnit = "kV");
    type ActivePower = SI.ActivePower(nominal = 1e8, displayUnit = "MW");
    type ReactivePower = SI.ReactivePower(nominal = 1e8, displayUnit = "Mvar");
    type ApparentPower = SI.ApparentPower(nominal = 1e8, displayUnit = "MV.A");
    type Angle = SI.Angle(displayUnit = "deg");
    type AngularVelocity = SI.AngularVelocity;
    type Frequency = SI.Frequency;
    type PerUnit = SI.PerUnit;
    type Time = SI.Time;
    operator record ComplexPower = SI.ComplexPower(re(nominal = 1e8, displayUnit = "MW"), im(nominal = 1e8, displayUnit = "MV.A")) "Active and Reactive powers in cartesian representation";
  end Types;

  package Tests "Package with set of basic systems designed for testing the various models from the library"
    extends Modelica.Icons.ExamplesPackage;

    package Controls "Set of simple systems to test the functionality of models representing exciters, turbine governors and stabilizers"
      extends Modelica.Icons.ExamplesPackage;

      package PSSE "Set of simple systems to test the functionality of exciter, stabilizers, and turbine governor models from PSSE"
        extends Modelica.Icons.ExamplesPackage;

        package ES "Set of simple systems to test the functionality of exciter models from PSAT"
          extends Modelica.Icons.ExamplesPackage;

          model AC8B "SMIB system to test functionality of exciter AC8B"
            extends OpenIPSL.Tests.BaseClasses.SMIB;
            OpenIPSL.Electrical.Machines.PSSE.GENROU gENROU(Xppd = 0.2059, Xppq = 0.2059, Xpp = 0.2059, Xl = 0.129, angle_0 = 0.070620673811798, Tpd0 = 6.27, Tppd0 = 0.059, Tppq0 = 0.096, H = 4.4710, D = 0, Xd = 2.014, Xq = 1.96, Xpd = 0.331, S10 = 0.14, S12 = 0.56, Xpq = 0.466, Tpq0 = 0.7, M_b = 100000000, P_0 = 39999952.912331, Q_0 = 5416571.3489056, v_0 = 1);
            Modelica.Blocks.Sources.Constant const5(k = 0);
            Electrical.Controls.PSSE.ES.AC8B aC8B(T_R = 0.02, K_PR = 160, K_IR = 6, K_DR = 8, T_DR = 0.08, VPID_MAX = Modelica.Constants.inf, VPID_MIN = -Modelica.Constants.inf, K_A = 1, T_A = 0.01, V_RMAX = 7.76, V_RMIN = -6.96, T_E = 1, K_C = 0.2, K_D = 0.2, K_E = 1, E_1 = 1, S_EE_1 = 0.05, E_2 = 2, S_EE_2 = 0.5, VFE_MAX = 8, VE_MIN = 0);
          equation
            connect(aC8B.EFD0, gENROU.EFD0);
            connect(gENROU.XADIFD, aC8B.XADIFD);
            connect(aC8B.ECOMP, gENROU.ETERM);
            connect(gENROU.PMECH0, gENROU.PMECH);
            connect(aC8B.EFD, gENROU.EFD);
            connect(gENROU.p, GEN1.p);
            connect(const5.y, aC8B.VOTHSG);
            connect(aC8B.VUEL, const5.y);
            connect(aC8B.VOEL, const5.y);
            annotation(experiment(StopTime = 10, Interval = 0.0001, Tolerance = 1e-06));
          end AC8B;
        end ES;
      end PSSE;
    end Controls;

    package BaseClasses "Set of base classes that are extended to create small systems for testing functionalities of the various models from the library"
      extends Modelica.Icons.BasesPackage;

      partial model SMIB "SMIB - Single Machine Infinite Base system with one load."
        extends Modelica.Icons.Example;
        OpenIPSL.Electrical.Branches.PwLine pwLine(R = 0.001, X = 0.2, G = 0, B = 0);
        OpenIPSL.Electrical.Branches.PwLine pwLine3(R = 0.0005, X = 0.1, G = 0, B = 0);
        OpenIPSL.Electrical.Branches.PwLine pwLine4(R = 0.0005, X = 0.1, G = 0, B = 0);
        OpenIPSL.Electrical.Machines.PSSE.GENCLS gENCLS(M_b = 100e6, D = 0, angle_0 = 0, X_d = 0.2, H = 0, P_0 = 10017110, Q_0 = 8006544, v_0 = 1);
        OpenIPSL.Electrical.Loads.PSSE.Load_variation constantLoad(PQBRAK = 0.7, d_t = 0, d_P = 0, angle_0 = -0.5762684, t1 = 0, characteristic = 2, P_0 = 50000000, Q_0 = 10000000, v_0 = 0.9919935);
        OpenIPSL.Electrical.Events.PwFault pwFault(t1 = 2, t2 = 2.15, R = C.eps, X = C.eps);
        OpenIPSL.Electrical.Buses.Bus GEN1;
        inner OpenIPSL.Electrical.SystemBase SysData(S_b = 100e6, fn = 50);
        OpenIPSL.Electrical.Buses.Bus LOAD(v_0 = constantLoad.v_0, angle_0 = constantLoad.angle_0);
        OpenIPSL.Electrical.Buses.Bus GEN2;
        OpenIPSL.Electrical.Buses.Bus FAULT;
        Electrical.Branches.PwLine pwLine1(R = 0.0005, G = 0, B = 0, X = 0.1);
        Electrical.Branches.PwLine pwLine2(R = 0.0005, G = 0, B = 0, X = 0.1);
        Electrical.Buses.Bus SHUNT;
      equation
        connect(GEN1.p, pwLine.p);
        connect(pwLine.n, LOAD.p);
        connect(pwLine3.p, LOAD.p);
        connect(constantLoad.p, LOAD.p);
        connect(GEN2.p, gENCLS.p);
        connect(pwLine4.n, GEN2.p);
        connect(FAULT.p, pwLine4.p);
        connect(FAULT.p, pwLine3.n);
        connect(pwFault.p, pwLine4.p);
        connect(pwLine1.p, LOAD.p);
        connect(pwLine1.n, SHUNT.p);
        connect(pwLine2.p, SHUNT.p);
        connect(pwLine2.n, GEN2.p);
      end SMIB;
    end BaseClasses;
  end Tests;
  annotation(Protection(access = Access.packageDuplicate), version = "3.1.0", versionDate = "2026-02-25");
end OpenIPSL;

model AC8B_total  "SMIB system to test functionality of exciter AC8B"
  extends OpenIPSL.Tests.Controls.PSSE.ES.AC8B;
 annotation(experiment(StopTime = 10, Interval = 0.0001, Tolerance = 1e-06));
end AC8B_total;
