encapsulated package TestPackage  "TestPackage models library" 

  import TestPackage.Types;

  package Types  "Standard types for electrical variables" 
    package AC  "types for AC variables" 
      record Voltage = .Complex "AC voltage as complex number";
      record Current = .Complex "AC current as complex number";
    end AC;
  end Types;

  package Connectors  "Connectors specific to TestPackage software" 
    connector ACPower  "connector for AC power (described using complex V and i variables)" 
      Types.AC.Voltage V "complex AC voltage";
      flow Types.AC.Current i "complex AC current (positive when entering the device)";
    end ACPower;
    annotation(version = "0.1"); 
  end Connectors;
  annotation(version = "0.1"); 
end TestPackage;

operator record Complex  "Complex number with overloaded operators" 
  replaceable Real re "Real part of complex number";
  replaceable Real im "Imaginary part of complex number";

  encapsulated operator 'constructor'  "Constructor" 
    function fromReal  "Construct Complex from Real" 
      input Real re "Real part of complex number";
      input Real im = 0 "Imaginary part of complex number";
      output .Complex result(re = re, im = im) "Complex number";
    algorithm
      annotation(Inline = true); 
    end fromReal;
  end 'constructor';

  encapsulated operator function '0'  "Zero-element of addition (= Complex(0))" 
    output .Complex result "Complex(0)";
  algorithm
    result := .Complex(0);
    annotation(Inline = true); 
  end '0';

  encapsulated operator '-'  "Unary and binary minus" 
    function negate  "Unary minus (multiply complex number by -1)" 
      input .Complex c1 "Complex number";
      output .Complex c2 "= -c1";
    algorithm
      c2 := .Complex(-c1.re, -c1.im);
      annotation(Inline = true); 
    end negate;

    function subtract  "Subtract two complex numbers" 
      input .Complex c1 "Complex number 1";
      input .Complex c2 "Complex number 2";
      output .Complex c3 "= c1 - c2";
    algorithm
      c3 := .Complex(c1.re - c2.re, c1.im - c2.im);
      annotation(Inline = true); 
    end subtract;
  end '-';

  encapsulated operator '*'  "Multiplication" 
    function multiply  "Multiply two complex numbers" 
      input .Complex c1 "Complex number 1";
      input .Complex c2 "Complex number 2";
      output .Complex c3 "= c1*c2";
    algorithm
      c3 := .Complex(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
      annotation(Inline = true); 
    end multiply;

    function scalarProduct  "Scalar product c1*c2 of two complex vectors" 
      input .Complex[:] c1 "Vector of Complex numbers 1";
      input .Complex[size(c1, 1)] c2 "Vector of Complex numbers 2";
      output .Complex c3 "= c1*c2";
    algorithm
      c3 := .Complex(0);
      for i in 1:size(c1, 1) loop
        c3 := c3 + c1[i] * c2[i];
      end for;
      annotation(Inline = true); 
    end scalarProduct;
  end '*';

  encapsulated operator function '+'  "Add two complex numbers" 
    input .Complex c1 "Complex number 1";
    input .Complex c2 "Complex number 2";
    output .Complex c3 "= c1 + c2";
  algorithm
    c3 := .Complex(c1.re + c2.re, c1.im + c2.im);
    annotation(Inline = true); 
  end '+';

  encapsulated operator function '/'  "Divide two complex numbers" 
    input .Complex c1 "Complex number 1";
    input .Complex c2 "Complex number 2";
    output .Complex c3 "= c1/c2";
  algorithm
    c3 := .Complex(((+c1.re * c2.re) + c1.im * c2.im) / (c2.re * c2.re + c2.im * c2.im), ((-c1.re * c2.im) + c1.im * c2.re) / (c2.re * c2.re + c2.im * c2.im));
    annotation(Inline = true); 
  end '/';

  encapsulated operator function '^'  "Complex power of complex number" 
    input .Complex c1 "Complex number";
    input .Complex c2 "Complex exponent";
    output .Complex c3 "= c1^c2";
  protected
    Real lnz = 0.5 * log(c1.re * c1.re + c1.im * c1.im);
    Real phi = atan2(c1.im, c1.re);
    Real re = lnz * c2.re - phi * c2.im;
    Real im = lnz * c2.im + phi * c2.re;
  algorithm
    c3 := .Complex(exp(re) * cos(im), exp(re) * sin(im));
    annotation(Inline = true); 
  end '^';

  encapsulated operator function '=='  "Test whether two complex numbers are identical" 
    input .Complex c1 "Complex number 1";
    input .Complex c2 "Complex number 2";
    output Boolean result "c1 == c2";
  algorithm
    result := c1.re == c2.re and c1.im == c2.im;
    annotation(Inline = true); 
  end '==';

  encapsulated operator function '<>'  "Test whether two complex numbers are not identical" 
    input .Complex c1 "Complex number 1";
    input .Complex c2 "Complex number 2";
    output Boolean result "c1 <> c2";
  algorithm
    result := c1.re <> c2.re or c1.im <> c2.im;
    annotation(Inline = true); 
  end '<>';

  encapsulated operator function 'String'  "Transform Complex number into a String representation" 
    input .Complex c "Complex number to be transformed in a String representation";
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
  annotation(Protection(access = Access.hide), version = "3.2.2", versionBuild = 0, versionDate = "2016-01-15", dateModified = "2016-01-15 08:44:41Z"); 
end Complex;

