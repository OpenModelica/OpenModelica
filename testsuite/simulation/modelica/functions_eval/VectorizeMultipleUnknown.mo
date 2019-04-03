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

operator record Complex
  replaceable Real re;
  replaceable Real im;

  encapsulated operator 'constructor'
    function fromReal
      input Real re;
      input Real im = 0;
      output .Complex result(re = re, im = im);
    algorithm
    end fromReal;
  end 'constructor';

  encapsulated operator function '0'
    output .Complex result;
  algorithm
    result := .Complex(0);
  end '0';

  encapsulated operator '-'
    function negate
      input .Complex c1;
      output .Complex c2;
    algorithm
      c2 := .Complex(-c1.re, -c1.im);
    end negate;

    function subtract
      input .Complex c1;
      input .Complex c2;
      output .Complex c3;
    algorithm
      c3 := .Complex(c1.re - c2.re, c1.im - c2.im);
    end subtract;
  end '-';

  encapsulated operator '*'
    function multiply
      input .Complex c1;
      input .Complex c2;
      output .Complex c3;
    algorithm
      c3 := .Complex(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
    end multiply;

    function scalarProduct
      input .Complex[:] c1;
      input .Complex[size(c1, 1)] c2;
      output .Complex c3;
    algorithm
      c3 := .Complex(0);
      for i in 1:size(c1, 1) loop
        c3 := c3 + c1[i] * c2[i];
      end for;
    end scalarProduct;
  end '*';

  encapsulated operator function '+'
    input .Complex c1;
    input .Complex c2;
    output .Complex c3;
  algorithm
    c3 := .Complex(c1.re + c2.re, c1.im + c2.im);
  end '+';

  encapsulated operator function '/'
    input .Complex c1;
    input .Complex c2;
    output .Complex c3;
  algorithm
    c3 := .Complex(((+c1.re * c2.re) + c1.im * c2.im) / (c2.re * c2.re + c2.im * c2.im), ((-c1.re * c2.im) + c1.im * c2.re) / (c2.re * c2.re + c2.im * c2.im));
  end '/';

  encapsulated operator function '^'
    input .Complex c1;
    input .Complex c2;
    output .Complex c3;
  protected
    Real lnz = 0.5 * log(c1.re * c1.re + c1.im * c1.im);
    Real phi = atan2(c1.im, c1.re);
    Real re = lnz * c2.re - phi * c2.im;
    Real im = lnz * c2.im + phi * c2.re;
  algorithm
    c3 := .Complex(exp(re) * cos(im), exp(re) * sin(im));
  end '^';

  encapsulated operator function '=='
    input .Complex c1;
    input .Complex c2;
    output Boolean result;
  algorithm
    result := c1.re == c2.re and c1.im == c2.im;
  end '==';

  encapsulated operator function 'String'
    input .Complex c;
    input String name = "j";
    input Integer significantDigits = 6;
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
  end 'String';
end Complex;

package Modelica
  extends Modelica.Icons.Package;

  package Electrical
    extends Modelica.Icons.Package;

    package MultiPhase
      extends Modelica.Icons.Package;

      package Functions
        extends Modelica.Icons.Package;

        function symmetricOrientation
          extends Modelica.Icons.Function;
          input Integer m;
          output Modelica.SIunits.Angle[m] orientation;
        algorithm
          if mod(m, 2) == 0 then
            if m == 2 then
              orientation[1] := 0;
              orientation[2] := +.Modelica.Constants.pi / 2;
            else
              orientation[1:integer(m / 2)] := symmetricOrientation(integer(m / 2));
              orientation[integer(m / 2) + 1:m] := symmetricOrientation(integer(m / 2)) - fill(.Modelica.Constants.pi / m, integer(m / 2));
            end if;
          else
            orientation := array((k - 1) * 2 * .Modelica.Constants.pi / m for k in 1:m);
          end if;
        end symmetricOrientation;

        function symmetricOrientationMatrix
          extends Modelica.Icons.Function;
          input Integer m;
          output Modelica.SIunits.Angle[m, m] orientation;
        algorithm
          orientation := zeros(m, m);
          if mod(m, 2) == 0 then
            if m == 2 then
              orientation := {{0, +.Modelica.Constants.pi / 2}, {0, -.Modelica.Constants.pi / 2}};
            else
              orientation[1:integer(m / 2), 1:integer(m / 2)] := symmetricOrientationMatrix(integer(m / 2));
              orientation[1 + integer(m / 2):m, 1 + integer(m / 2):m] := symmetricOrientationMatrix(integer(m / 2)) - fill(.Modelica.Constants.pi / m, integer(m / 2), integer(m / 2));
            end if;
          else
            for k in 1:m loop
              orientation[k, :] := Modelica.Electrical.MultiPhase.Functions.symmetricOrientation(m) * k;
            end for;
          end if;
        end symmetricOrientationMatrix;

        function symmetricTransformationMatrix
          extends Modelica.Icons.Function;
          input Integer m;
          output Complex[m, m] transformation;
        algorithm
          transformation := Modelica.ComplexMath.fromPolar(fill(numberOfSymmetricBaseSystems(m) / m, m, m), Electrical.MultiPhase.Functions.symmetricOrientationMatrix(m));
        end symmetricTransformationMatrix;

        function numberOfSymmetricBaseSystems
          extends Modelica.Icons.Function;
          input Integer m = 3;
          output Integer n;
        algorithm
          n := 1;
          if mod(m, 2) == 0 then
            if m == 2 then
              n := 1;
            else
              n := n * 2 * numberOfSymmetricBaseSystems(integer(m / 2));
            end if;
          else
            n := 1;
          end if;
        end numberOfSymmetricBaseSystems;
      end Functions;
    end MultiPhase;
  end Electrical;

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

    function cos
      extends Modelica.Math.Icons.AxisLeft;
      input .Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = cos(u);
    end cos;

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

  package ComplexMath
    extends Modelica.Icons.Package;

    function fromPolar
      extends Modelica.Icons.Function;
      input Real len;
      input Modelica.SIunits.Angle phi;
      output Complex c;
    algorithm
      c := Complex(len * Modelica.Math.cos(phi), len * Modelica.Math.sin(phi));
    end fromPolar;
  end ComplexMath;

  package Constants
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant .Modelica.SIunits.Velocity c = 299792458;
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7;
  end Constants;

  package Icons
    extends Icons.Package;

    partial package Package  end Package;

    partial package IconsPackage
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial function Function  end Function;
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
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
end Modelica;

function VectorizeMultipleUnknown
  extends Modelica.Electrical.MultiPhase.Functions.symmetricTransformationMatrix;
end VectorizeMultipleUnknown;
