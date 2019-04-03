// name: OperatorOverloadArrayOp1
// keywords: operator overload complex
// status: correct
// cflags: -d=newInst
//
//

operator record Complex "Complex number with overloaded operators"
  Real re "Real part of complex number";
  Real im "Imaginary part of complex number";

  encapsulated operator 'constructor'  " Constructor"
    function fromReal "Construct Complex from Real"
      import Complex;
      input Real re "Real part of complex number";
      input Real im = 0.0 "Imaginary part of complex number";
      output Complex result = Complex(re = re, im = im) "Complex number";
    algorithm
    end fromReal;
  end 'constructor';

  encapsulated operator '-' "Unary and binary minus"
    function negate "Unary minus (multiply complex number by -1)"
      import Complex;
      input Complex c1 "Complex number";
      output Complex c2 "= -c1";
    algorithm
      c2:=Complex(-c1.re, -c1.im);
    end negate;

    function negateArr "Unary minus (multiply complex number by -1)"
      import Complex;
      input Complex c1[:] "Complex number";
      output Complex[size(c1,1)] c2 "= -c1";
    algorithm
      c2[1]:=Complex(-c1[1].re, -c1[1].im);
    end negateArr;

    function subtract "Subtract two complex numbers"
      import Complex;
      input Complex c1 "Complex number 1";
      input Complex c2 "Complex number 2";
      output Complex c3 "= c1 - c2";
    algorithm
      c3:=Complex(c1.re - c2.re, c1.im - c2.im);
    end subtract;
  end '-';

  encapsulated operator '*'  " Multiplication"
    function multiply "Multiply two complex numbers"
      import Complex;
      input Complex c1 "Complex number 1";
      input Complex c2 "Complex number 2";
      output Complex c3 "= c1*c2";
    algorithm
      c3:=Complex(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
    end multiply;

    function scalarProduct "Scalar product c1*c2 of two complex vectors"
      import Complex;
      input Complex c1[:] "Vector of Complex numbers 1";
      input Complex c2[size(c1, 1)] "Vector of Complex numbers 2";
      output Complex c3 "= c1*c2";
    algorithm
      c3:=Complex(0);
      for i in 1:size(c1, 1) loop
              c3:=c3 + c1[i] * c2[i];

      end for;
    end scalarProduct;
  end '*';

  encapsulated operator function '+' "Add two complex numbers"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1 + c2";
  algorithm
    c3:=Complex(c1.re + c2.re, c1.im + c2.im);
  end '+';

  encapsulated operator function '/' "Divide two complex numbers"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1/c2";
  algorithm
    c3:=Complex((+c1.re * c2.re + c1.im * c2.im) / (c2.re * c2.re + c2.im * c2.im), (-c1.re * c2.im + c1.im * c2.re) / (c2.re * c2.re + c2.im * c2.im));
  end '/';

  encapsulated operator function '^' "Complex power of complex number"
    import Complex;
    input Complex c1 "Complex number";
    input Complex c2 "Complex exponent";
    output Complex c3 "= c1^c2";
  protected
    Real lnz = 0.5 * log(c1.re * c1.re + c1.im * c1.im);
    Real phi = atan2(c1.im, c1.re);
    Real re = lnz * c2.re - phi * c2.im;
    Real im = lnz * c2.im + phi * c2.re;
  algorithm
    c3:=Complex(exp(re) * cos(im), exp(re) * sin(im));
  end '^';

  encapsulated operator function '==' "Test whether two complex numbers are identical"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Boolean result "c1 == c2";
  algorithm
    result:=c1.re == c2.re and c1.im == c2.im;
  end '==';

  encapsulated operator function 'and' "Test whether two complex numbers are identical"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Boolean result "c1 == c2";
  algorithm
    result:=c1.re == c2.re and c1.im == c2.im;
  end 'and';

  encapsulated operator function 'not' "not (multiply complex number by -1)"
      import Complex;
      input Complex c1 "Complex number";
      output Complex c2 "= -c1";
    algorithm
      c2:=Complex(-c1.re, -c1.im);
  end 'not';

  encapsulated operator function 'String' "Transform Complex number into a String representation"
    import Complex;
    input Complex c "Complex number to be transformed in a String representation";
    input String name = "j" "Name of variable representing sqrt(-1) in the string";
    input Integer significantDigits = 6 "Number of significant digits that are shown";
    output String s =  " ";
  algorithm
    s:=String(c.re, significantDigits = significantDigits);

    if c.im <> 0 then
      if c.im > 0 then
        s:=s + " + ";
      else
        s:=s + " - ";
      end if;

      s:= s + String(abs(c.im), significantDigits = significantDigits) + "*" + name;
    end if;
  end 'String';

  encapsulated operator function '0'
    import Complex;
    output Complex c;
  algorithm
    c := Complex(0,0);
    annotation(Inline=true);
  end '0';
end Complex;

model OperatorOverloadArrayOp1
  Complex c1[3], c2[3], c3[3];
equation
  c1 = c2 - c3; 
  c1 = c2 + c3; 
end OperatorOverloadArrayOp1;

// Result:
// function Complex "Automatically generated record constructor for Complex"
//   input Real re;
//   input Real im;
//   output Complex res;
// end Complex;
//
// function Complex.'+' "Add two complex numbers"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Complex c3 "= c1 + c2";
// algorithm
//   c3 := Complex.'constructor'.fromReal(c1.re + c2.re, c1.im + c2.im);
// end Complex.'+';
//
// function Complex.'-'.subtract "Subtract two complex numbers"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Complex c3 "= c1 - c2";
// algorithm
//   c3 := Complex.'constructor'.fromReal(c1.re - c2.re, c1.im - c2.im);
// end Complex.'-'.subtract;
//
// function Complex.'constructor'.fromReal "Construct Complex from Real"
//   input Real re "Real part of complex number";
//   input Real im = 0.0 "Imaginary part of complex number";
//   output Complex result = Complex.'constructor'.fromReal(re, im) "Complex number";
// algorithm
// end Complex.'constructor'.fromReal;
//
// class OperatorOverloadArrayOp1
//   Real c1[1].re "Real part of complex number";
//   Real c1[1].im "Imaginary part of complex number";
//   Real c1[2].re "Real part of complex number";
//   Real c1[2].im "Imaginary part of complex number";
//   Real c1[3].re "Real part of complex number";
//   Real c1[3].im "Imaginary part of complex number";
//   Real c2[1].re "Real part of complex number";
//   Real c2[1].im "Imaginary part of complex number";
//   Real c2[2].re "Real part of complex number";
//   Real c2[2].im "Imaginary part of complex number";
//   Real c2[3].re "Real part of complex number";
//   Real c2[3].im "Imaginary part of complex number";
//   Real c3[1].re "Real part of complex number";
//   Real c3[1].im "Imaginary part of complex number";
//   Real c3[2].re "Real part of complex number";
//   Real c3[2].im "Imaginary part of complex number";
//   Real c3[3].re "Real part of complex number";
//   Real c3[3].im "Imaginary part of complex number";
// equation
//   c1[1] = Complex.'-'.subtract(c2[1], c3[1]);
//   c1[2] = Complex.'-'.subtract(c2[2], c3[2]);
//   c1[3] = Complex.'-'.subtract(c2[3], c3[3]);
//   c1[1] = Complex.'+'(c2[1], c3[1]);
//   c1[2] = Complex.'+'(c2[2], c3[2]);
//   c1[3] = Complex.'+'(c2[3], c3[3]);
// end OperatorOverloadArrayOp1;
// endResult
