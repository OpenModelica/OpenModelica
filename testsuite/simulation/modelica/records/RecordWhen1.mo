operator record Complex
  replaceable Real re;
  replaceable Real im;

  encapsulated operator 'constructor'
    function fromReal
      import Complex;
      input Real re;
      input Real im = 0;
      output Complex result(re = re, im = im);
    algorithm
      annotation(Inline = true);
    end fromReal;
  end 'constructor';

  encapsulated operator function '0'
    import Complex;
    output Complex result;
  algorithm
    result := Complex(0);
    annotation(Inline = true);
  end '0';

  encapsulated operator '-'
    function negate
      import Complex;
      input Complex c1;
      output Complex c2;
    algorithm
      c2 := Complex(-c1.re, -c1.im);
      annotation(Inline = true, smoothOrder = 100);
    end negate;

    function subtract
      import Complex;
      input Complex c1;
      input Complex c2;
      output Complex c3;
    algorithm
      c3 := Complex(c1.re - c2.re, c1.im - c2.im);
      annotation(Inline = true, smoothOrder = 100);
    end subtract;
  end '-';

  encapsulated operator '*'
    function multiply
      import Complex;
      input Complex c1;
      input Complex c2;
      output Complex c3;
    algorithm
      c3 := Complex(c1.re*c2.re - c1.im*c2.im, c1.re*c2.im + c1.im*c2.re);
      annotation(Inline = true, smoothOrder = 100);
    end multiply;

    function scalarProduct
      import Complex;
      input Complex c1[:];
      input Complex c2[size(c1, 1)];
      output Complex c3;
    algorithm
      c3 := Complex(0);
      for i in 1:size(c1, 1) loop
        c3 := Complex(c3.re + c1[i].re*c2[i].re + c1[i].im*c2[i].im, c3.im + c1[i].re*c2[i].im - c1[i].im*c2[i].re);
      end for;
      annotation(Inline = true, smoothOrder = 100);
    end scalarProduct;
  end '*';

  encapsulated operator function '+'
    import Complex;
    input Complex c1;
    input Complex c2;
    output Complex c3;
  algorithm
    c3 := Complex(c1.re + c2.re, c1.im + c2.im);
    annotation(Inline = true, smoothOrder = 100);
  end '+';

  encapsulated operator function '/'
    import Complex;
    input Complex c1;
    input Complex c2;
    output Complex c3;
  algorithm
    c3 := Complex((+c1.re*c2.re + c1.im*c2.im)/(c2.re*c2.re + c2.im*c2.im), (-c1.re*c2.im + c1.im*c2.re)/(c2.re*c2.re + c2.im*c2.im));
    annotation(Inline = true, smoothOrder = 100);
  end '/';

  encapsulated operator '^'
    function complexPower
      import Complex;
      input Complex c1;
      input Complex c2;
      output Complex c3;
    protected
      Real lnz = 0.5*log(c1.re*c1.re + c1.im*c1.im);
      Real phi = atan2(c1.im, c1.re);
      Real re = lnz*c2.re - phi*c2.im;
      Real im = lnz*c2.im + phi*c2.re;
    algorithm
      c3 := Complex(exp(re)*cos(im), exp(re)*sin(im));
      annotation(Inline = true, smoothOrder = 100);
    end complexPower;

    function integerPower
      import Complex;
      input Complex c1;
      input Integer c2;
      output Complex c3;
    algorithm
      c3 := if c2 == 0 then Complex(1) else Complex.'^'.complexPower(c1, Complex(c2));
      annotation(Inline = true, smoothOrder = 100);
    end integerPower;
  end '^';

  encapsulated operator function '=='
    import Complex;
    input Complex c1;
    input Complex c2;
    output Boolean result;
  algorithm
    result := c1.re == c2.re and c1.im == c2.im;
    annotation(Inline = true);
  end '==';

  encapsulated operator function '<>'
    import Complex;
    input Complex c1;
    input Complex c2;
    output Boolean result;
  algorithm
    result := c1.re <> c2.re or c1.im <> c2.im;
    annotation(Inline = true);
  end '<>';

  encapsulated operator function 'String'
    import Complex;
    input Complex c;
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
    annotation(Inline = true);
  end 'String';
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end Complex;

package Modelica
  package Blocks
    import Modelica.Units.SI;

    package Interfaces
      connector IntegerInput = input Integer;
      connector IntegerOutput = output Integer;

      partial block IntegerSO
        IntegerOutput y;
      end IntegerSO;

      partial block IntegerSignalSource
        extends IntegerSO;
        parameter Integer offset = 0;
        parameter SI.Time startTime = 0;
      end IntegerSignalSource;
    end Interfaces;

    package Sources
      import Modelica.Blocks.Interfaces;

      block IntegerStep
        parameter Integer height = 1;
        extends Interfaces.IntegerSignalSource;
      equation
        y = offset + (if time < startTime then 0 else height);
      end IntegerStep;
    end Sources;
  end Blocks;

  package ComplexBlocks
    package Interfaces
      connector ComplexInput = input Complex annotation(IconMap(primitivesVisible = false));
      connector ComplexOutput = output Complex annotation(IconMap(primitivesVisible = false));

      partial block ComplexSO
        ComplexOutput y;
      end ComplexSO;

      partial block ComplexMISO
        parameter Integer nin = 1;
        ComplexInput u[nin];
        ComplexOutput y;
        parameter Boolean useConjugateInput[nin] = fill(false, nin);
      protected
        Complex uInternal[nin] = {if useConjugateInput[k] then Modelica.ComplexMath.conj(u[k]) else u[k] for k in 1:nin};
      end ComplexMISO;
    end Interfaces;

    package Routing
      block Extractor
        extends Modelica.ComplexBlocks.Interfaces.ComplexMISO;
        parameter Boolean allowOutOfRange = false;
        parameter Complex outOfRangeValue = Complex(1e10, 0);
        Modelica.Blocks.Interfaces.IntegerInput index;
      protected
        Complex k[nin];
      equation
        when {initial(), change(index)} then
          for i in 1:nin loop
            k[i] = if index == i then Complex(1, 0) else Complex(0, 0);
          end for;
        end when;
        y = if not allowOutOfRange or index > 0 and index <= nin then k*u else outOfRangeValue;
      end Extractor;
    end Routing;

    package Sources
      block ComplexConstant
        parameter Complex k(re(start = 1), im(start = 0));
        extends Modelica.ComplexBlocks.Interfaces.ComplexSO;
      equation
        y = k;
      end ComplexConstant;
    end Sources;
  end ComplexBlocks;

  package ComplexMath
    function conj
      input Complex c1;
      output Complex c2;
    algorithm
      c2 := Complex(c1.re, -c1.im);
      annotation(Inline = true);
    end conj;
  end ComplexMath;

  package Units
    package SI
      type Time = Real(final quantity = "Time", final unit = "s");
    end SI;
  end Units;
end Modelica;

package RecordWhen1
  model Test
    Modelica.ComplexBlocks.Sources.ComplexConstant complexConst[3](k = {Complex(1, 0), Complex(1, 1), Complex(0, 1)});
    Modelica.ComplexBlocks.Routing.Extractor extractor(nin = 3);
    Modelica.Blocks.Sources.IntegerStep integerStep(offset = 1, startTime = 0.5, height = 2);
  equation
    connect(complexConst.y, extractor.u);
    connect(integerStep.y, extractor.index);
    annotation(experiment(StopTime = 1, Interval = 0.1));
  end Test;
end RecordWhen1;
