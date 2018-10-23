// name: OperatorOverloadComplex
// keywords: operator overload complex
// status: correct
// cflags: -d=newInst
//
// Tests operator overloading on Complex numbers, operators can only contain function declarations
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

model OperatorOverloadComplex
  Complex c1;
  Complex c2,c3,c4,c5,c6,c7,c8;
  Complex ca1[3], ca2[3], ca3[3];
  Boolean b,b2;
  String s;
equation
  // overloaded constructor
  c1 = Complex(1.0);
  // implicit construction and then addition -> c1 + Complex(1.0)
  c2 = c1 + 1.0;
  // negate
  c3 = -c2;
  // power
  c4 = c1 ^ c2;
  // logical not
  c5 = not(c4);
  // logical and
  b = c1 and c2;
  // String() operator
  s = String(c1,"j",5);
  // implicit construction and then equality test -> c1 == Complex(0)
  b2 = c4 == 0;
  // multiplication
  c6 = c5 * c4;
  // Mix
  // ===((((c6 / c5 )* (c4 ^ c3)) * Complex(1.0)) + c2) - c1
  c7 = c6 / c5 * c4 ^ c3 * 1 + c2 - c1;
  c8 = Complex.'0'();

  ca1 = -ca2;
  c1 = ca2 * ca3;
end OperatorOverloadComplex;

// Result:
// function Complex "Automatically generated record constructor for Complex"
//   input Real re;
//   input Real im;
//   output Complex res;
// end Complex;
//
// function Complex.'*'.multiply "Multiply two complex numbers"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Complex c3 "= c1*c2";
// algorithm
//   c3 := Complex.'constructor'.fromReal(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
// end Complex.'*'.multiply;
//
// function Complex.'*'.scalarProduct "Scalar product c1*c2 of two complex vectors"
//   input Complex[:] c1 "Vector of Complex numbers 1";
//   input Complex[size(c1, 1)] c2 "Vector of Complex numbers 2";
//   output Complex c3 "= c1*c2";
// algorithm
//   c3 := Complex.'constructor'.fromReal(0.0, 0.0);
//   for i in 1:size(c1, 1) loop
//     c3 := Complex.'+'(c3, Complex.'*'.multiply(c1[i], c2[i]));
//   end for;
// end Complex.'*'.scalarProduct;
//
// function Complex.'+' "Add two complex numbers"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Complex c3 "= c1 + c2";
// algorithm
//   c3 := Complex.'constructor'.fromReal(c1.re + c2.re, c1.im + c2.im);
// end Complex.'+';
//
// function Complex.'-'.negate "Unary minus (multiply complex number by -1)"
//   input Complex c1 "Complex number";
//   output Complex c2 "= -c1";
// algorithm
//   c2 := Complex.'constructor'.fromReal(-c1.re, -c1.im);
// end Complex.'-'.negate;
//
// function Complex.'-'.negateArr "Unary minus (multiply complex number by -1)"
//   input Complex[:] c1 "Complex number";
//   output Complex[size(c1, 1)] c2 "= -c1";
// algorithm
//   c2[1] := Complex.'constructor'.fromReal(-c1[1].re, -c1[1].im);
// end Complex.'-'.negateArr;
//
// function Complex.'-'.subtract "Subtract two complex numbers"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Complex c3 "= c1 - c2";
// algorithm
//   c3 := Complex.'constructor'.fromReal(c1.re - c2.re, c1.im - c2.im);
// end Complex.'-'.subtract;
//
// function Complex.'/' "Divide two complex numbers"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Complex c3 "= c1/c2";
// algorithm
//   c3 := Complex.'constructor'.fromReal((c1.re * c2.re + c1.im * c2.im) / (c2.re * c2.re + c2.im * c2.im), ((-c1.re * c2.im) + c1.im * c2.re) / (c2.re * c2.re + c2.im * c2.im));
// end Complex.'/';
//
// function Complex.'0' "Inline before index reduction"
//   output Complex c;
// algorithm
//   c := Complex.'constructor'.fromReal(0.0, 0.0);
// end Complex.'0';
//
// function Complex.'==' "Test whether two complex numbers are identical"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Boolean result "c1 == c2";
// algorithm
//   result := c1.re == c2.re and c1.im == c2.im;
// end Complex.'==';
//
// function Complex.'String' "Transform Complex number into a String representation"
//   input Complex c "Complex number to be transformed in a String representation";
//   input String name = "j" "Name of variable representing sqrt(-1) in the string";
//   input Integer significantDigits = 6 "Number of significant digits that are shown";
//   output String s = " ";
// algorithm
//   s := String(c.re, significantDigits, 0, true);
//   if c.im <> 0.0 then
//     if c.im > 0.0 then
//       s := s + " + ";
//     else
//       s := s + " - ";
//     end if;
//     s := s + String(abs(c.im), significantDigits, 0, true) + "*" + name;
//   end if;
// end Complex.'String';
//
// function Complex.'^' "Complex power of complex number"
//   input Complex c1 "Complex number";
//   input Complex c2 "Complex exponent";
//   output Complex c3 "= c1^c2";
//   protected Real lnz = 0.5 * log(c1.re * c1.re + c1.im * c1.im);
//   protected Real phi = atan2(c1.im, c1.re);
//   protected Real re = lnz * c2.re - phi * c2.im;
//   protected Real im = lnz * c2.im + phi * c2.re;
// algorithm
//   c3 := Complex.'constructor'.fromReal(exp(re) * cos(im), exp(re) * sin(im));
// end Complex.'^';
//
// function Complex.'and' "Test whether two complex numbers are identical"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Boolean result "c1 == c2";
// algorithm
//   result := c1.re == c2.re and c1.im == c2.im;
// end Complex.'and';
//
// function Complex.'constructor'.fromReal "Construct Complex from Real"
//   input Real re "Real part of complex number";
//   input Real im = 0.0 "Imaginary part of complex number";
//   output Complex result = Complex.'constructor'.fromReal(re, im) "Complex number";
// algorithm
// end Complex.'constructor'.fromReal;
//
// function Complex.'not' "not (multiply complex number by -1)"
//   input Complex c1 "Complex number";
//   output Complex c2 "= -c1";
// algorithm
//   c2 := Complex.'constructor'.fromReal(-c1.re, -c1.im);
// end Complex.'not';
//
// class OperatorOverloadComplex
//   Real c1.re "Real part of complex number";
//   Real c1.im "Imaginary part of complex number";
//   Real c2.re "Real part of complex number";
//   Real c2.im "Imaginary part of complex number";
//   Real c3.re "Real part of complex number";
//   Real c3.im "Imaginary part of complex number";
//   Real c4.re "Real part of complex number";
//   Real c4.im "Imaginary part of complex number";
//   Real c5.re "Real part of complex number";
//   Real c5.im "Imaginary part of complex number";
//   Real c6.re "Real part of complex number";
//   Real c6.im "Imaginary part of complex number";
//   Real c7.re "Real part of complex number";
//   Real c7.im "Imaginary part of complex number";
//   Real c8.re "Real part of complex number";
//   Real c8.im "Imaginary part of complex number";
//   Real ca1[1].re "Real part of complex number";
//   Real ca1[1].im "Imaginary part of complex number";
//   Real ca1[2].re "Real part of complex number";
//   Real ca1[2].im "Imaginary part of complex number";
//   Real ca1[3].re "Real part of complex number";
//   Real ca1[3].im "Imaginary part of complex number";
//   Real ca2[1].re "Real part of complex number";
//   Real ca2[1].im "Imaginary part of complex number";
//   Real ca2[2].re "Real part of complex number";
//   Real ca2[2].im "Imaginary part of complex number";
//   Real ca2[3].re "Real part of complex number";
//   Real ca2[3].im "Imaginary part of complex number";
//   Real ca3[1].re "Real part of complex number";
//   Real ca3[1].im "Imaginary part of complex number";
//   Real ca3[2].re "Real part of complex number";
//   Real ca3[2].im "Imaginary part of complex number";
//   Real ca3[3].re "Real part of complex number";
//   Real ca3[3].im "Imaginary part of complex number";
//   Boolean b;
//   Boolean b2;
//   String s;
// equation
//   c1 = Complex.'constructor'.fromReal(1.0, 0.0);
//   c2 = Complex.'+'(c1, Complex.'constructor'.fromReal(1.0, 0.0));
//   c3 = Complex.'-'.negate(c2);
//   c4 = Complex.'^'(c1, c2);
//   c5 = Complex.'not'(c4);
//   b = Complex.'and'(c1, c2);
//   s = Complex.'String'(c1, "j", 5);
//   b2 = Complex.'=='(c4, Complex.'constructor'.fromReal(0.0, 0.0));
//   c6 = Complex.'*'.multiply(c5, c4);
//   c7 = Complex.'-'.subtract(Complex.'+'(Complex.'*'.multiply(Complex.'*'.multiply(Complex.'/'(c6, c5), Complex.'^'(c4, c3)), Complex.'constructor'.fromReal(1.0, 0.0)), c2), c1);
//   c8 = Complex.'0'();
//   ca1 = Complex.'-'.negateArr(ca2);
//   c1 = Complex.'*'.scalarProduct(ca2, ca3);
// end OperatorOverloadComplex;
// endResult
