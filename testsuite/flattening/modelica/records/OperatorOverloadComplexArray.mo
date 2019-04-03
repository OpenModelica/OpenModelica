// name: OperatorOverloadComplexArray.mo
// keywords: operator overload array
// status: correct
//
// Tests operator overloading on arrays of Complex numbers, This 'Complex' is a slightly modified version of the MSL to test more stuff.
// and also (NOT RELATED to overloading) encapsulated was creating lookup problem in ##Complex.'*'.scalarProduct##
// because it was lookin for ##Complex.'*'.multiply## and ##'*'## is encapsulated. BUG??
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
      // annotation(__OpenModelica_EarlyInline = true);
    end subtract;
  end '-';

  operator '*'  " Multiplication"

    encapsulated function multiply "Multiply two complex numbers"
      import Complex;
      input Complex c1 "Complex number 1";
      input Complex c2 "Complex number 2";
      output Complex c3 "= c1*c2";
    algorithm
      c3:=Complex(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
      // annotation(__OpenModelica_EarlyInline = true);
    end multiply;

  // This function is modified (Modelica.Complex) to return an array instead
  // of a scalar. Just to check that even when the above function 'multiply'
  // can vectorize an '*' operation, this is given priority. (See the test model)
    function scalarProduct "Scalar product c1*c2 of two complex vectors"
      import Complex;
      input Complex c1[:] "Vector of Complex numbers 1";
      input Complex c2[size(c1, 1)] "Vector of Complex numbers 2";
      output Complex c3[size(c1, 1)] "= c1*c2";
    algorithm
      c3:=c2;
      // annotation(__OpenModelica_EarlyInline = true);
    end scalarProduct;

  end '*';

  encapsulated operator function '+' "Add two complex numbers"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1 + c2";
  algorithm
    c3:=Complex(c1.re + c2.re, c1.im + c2.im);
    // annotation(__OpenModelica_EarlyInline = true);
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

    else     s:=s + " - ";

    end if;
    s:=s + String(abs(c.im), significantDigits = significantDigits) + "*" + name;

    else
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

model Test
  Complex c_s1, c_s2;
  Complex[3] c1, c2;
  Boolean b[3], b2[3];
  String s[3];
  Integer a[3] = {1,2,3};
equation
  // overloaded constructor expansion
   c1 = Complex(a);

   // Elemntwise vectorization
   c2 = c1 .+ c1;
   c2 = c2 .* c1;
   c2 = c1 .^ c1;
   c1 = c1 ./ c2;



   //Make sure that exact matchs for non-elemntwise operators have priority over vectorization
   c2 = c1 * c1;   // This should call Complex.'*'.scalarProduct  (We have a match for an array op -> priority)
   c2 = c1 + c1;    // This should be vectorized (no match for an array op. )  (!!WITH a WARNING!!)

   // implicit construction and then operation
   // This is tricky!
   c1 = c1 * c2; // This should call Complex.'*'.scalarProduct
   c1 = c1 .* {1,2,3}; // This should be vectorized and then each one constructed
   c1 = c1 + {1,2,3}; // This should be vectorized (no match for an array op. )  (!!WITH a WARNING!!) then each one constructed

   c1 = c1 .+ 3; // This should be vectorized and the scalar one constructed for each

   // negate an array -> vectorize
   c1 = -c2;
   // logical not
   c2 = not(c1);

   // logical 'and' on arrays.
   b = c1 and c2;  // This should be vectorized

   // String() operator on arrays
   s = String(c1,"j",5);

   // Mix
   // === ((c6 ./ c5 ) * c4) .+ (c3 .* 1) .- (c2 .* c1)
   c1 = c1 ./ c2 .* c1 .+ c2 .* 1 .- c2 .* c1;
end Test;

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
//   c3 := Complex(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
// end Complex.'*'.multiply;
//
// function Complex.'*'.scalarProduct "Scalar product c1*c2 of two complex vectors"
//   input Complex[:] c1 "Vector of Complex numbers 1";
//   input Complex[size(c1, 1)] c2 "Vector of Complex numbers 2";
//   output Complex[size(c1, 1)] c3 "= c1*c2";
// algorithm
//   c3 := c2;
// end Complex.'*'.scalarProduct;
//
// function Complex.'+' "Add two complex numbers"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Complex c3 "= c1 + c2";
// algorithm
//   c3 := Complex(c1.re + c2.re, c1.im + c2.im);
// end Complex.'+';
//
// function Complex.'-'.negate "Unary minus (multiply complex number by -1)"
//   input Complex c1 "Complex number";
//   output Complex c2 "= -c1";
// algorithm
//   c2 := Complex(-c1.re, -c1.im);
// end Complex.'-'.negate;
//
// function Complex.'-'.negateArr "Unary minus (multiply complex number by -1)"
//   input Complex[:] c1 "Complex number";
//   output Complex[size(c1, 1)] c2 "= -c1";
// algorithm
//   c2[1] := Complex(-c1[1].re, -c1[1].im);
// end Complex.'-'.negateArr;
//
// function Complex.'-'.subtract "Subtract two complex numbers"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Complex c3 "= c1 - c2";
// algorithm
//   c3 := Complex(c1.re - c2.re, c1.im - c2.im);
// end Complex.'-'.subtract;
//
// function Complex.'/' "Divide two complex numbers"
//   input Complex c1 "Complex number 1";
//   input Complex c2 "Complex number 2";
//   output Complex c3 "= c1/c2";
// algorithm
//   c3 := Complex((c1.re * c2.re + c1.im * c2.im) / (c2.re ^ 2.0 + c2.im ^ 2.0), (c1.im * c2.re - c1.re * c2.im) / (c2.re ^ 2.0 + c2.im ^ 2.0));
// end Complex.'/';
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
//   protected Real lnz = 0.5 * log(c1.re ^ 2.0 + c1.im ^ 2.0);
//   protected Real phi = atan2(c1.im, c1.re);
//   protected Real re = lnz * c2.re - phi * c2.im;
//   protected Real im = lnz * c2.im + phi * c2.re;
// algorithm
//   c3 := Complex(exp(re) * cos(im), exp(re) * sin(im));
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
//   output Complex result = Complex(re, im) "Complex number";
// end Complex.'constructor'.fromReal;
//
// function Complex.'not' "not (multiply complex number by -1)"
//   input Complex c1 "Complex number";
//   output Complex c2 "= -c1";
// algorithm
//   c2 := Complex(-c1.re, -c1.im);
// end Complex.'not';
//
// class Test
//   Real c_s1.re "Real part of complex number";
//   Real c_s1.im "Imaginary part of complex number";
//   Real c_s2.re "Real part of complex number";
//   Real c_s2.im "Imaginary part of complex number";
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
//   Boolean b[1];
//   Boolean b[2];
//   Boolean b[3];
//   Boolean b2[1];
//   Boolean b2[2];
//   Boolean b2[3];
//   String s[1];
//   String s[2];
//   String s[3];
//   Integer a[1];
//   Integer a[2];
//   Integer a[3];
// equation
//   a = {1, 2, 3};
//   c1[1] = Complex.'constructor'.fromReal(/*Real*/(a[1]), 0.0);
//   c1[2] = Complex.'constructor'.fromReal(/*Real*/(a[2]), 0.0);
//   c1[3] = Complex.'constructor'.fromReal(/*Real*/(a[3]), 0.0);
//   c2[1] = Complex.'+'(c1[1], c1[1]);
//   c2[2] = Complex.'+'(c1[2], c1[2]);
//   c2[3] = Complex.'+'(c1[3], c1[3]);
//   c2[1] = Complex.'*'.multiply(c2[1], c1[1]);
//   c2[2] = Complex.'*'.multiply(c2[2], c1[2]);
//   c2[3] = Complex.'*'.multiply(c2[3], c1[3]);
//   c2[1] = Complex.'^'(c1[1], c1[1]);
//   c2[2] = Complex.'^'(c1[2], c1[2]);
//   c2[3] = Complex.'^'(c1[3], c1[3]);
//   c1[1] = Complex.'/'(c1[1], c2[1]);
//   c1[2] = Complex.'/'(c1[2], c2[2]);
//   c1[3] = Complex.'/'(c1[3], c2[3]);
//   c2 = Complex.'*'.scalarProduct(c1, c1);
//   c2[1] = Complex.'+'(c1[1], c1[1]);
//   c2[2] = Complex.'+'(c1[2], c1[2]);
//   c2[3] = Complex.'+'(c1[3], c1[3]);
//   c1 = Complex.'*'.scalarProduct(c1, c2);
//   c1[1] = Complex.'*'.multiply(c1[1], Complex.'constructor'.fromReal(1.0, 0.0));
//   c1[2] = Complex.'*'.multiply(c1[2], Complex.'constructor'.fromReal(2.0, 0.0));
//   c1[3] = Complex.'*'.multiply(c1[3], Complex.'constructor'.fromReal(3.0, 0.0));
//   c1[1] = Complex.'+'(c1[1], Complex.'constructor'.fromReal(1.0, 0.0));
//   c1[2] = Complex.'+'(c1[2], Complex.'constructor'.fromReal(2.0, 0.0));
//   c1[3] = Complex.'+'(c1[3], Complex.'constructor'.fromReal(3.0, 0.0));
//   c1[1] = Complex.'+'(c1[1], Complex.'constructor'.fromReal(3.0, 0.0));
//   c1[2] = Complex.'+'(c1[2], Complex.'constructor'.fromReal(3.0, 0.0));
//   c1[3] = Complex.'+'(c1[3], Complex.'constructor'.fromReal(3.0, 0.0));
//   c1[1] = Complex.'-'.negate(c2[1]);
//   c1[2] = Complex.'-'.negate(c2[2]);
//   c1[3] = Complex.'-'.negate(c2[3]);
//   c2[1] = Complex.'not'(c1[1]);
//   c2[2] = Complex.'not'(c1[2]);
//   c2[3] = Complex.'not'(c1[3]);
//   b[1] = Complex.'and'(c1[1], c2[1]);
//   b[2] = Complex.'and'(c1[2], c2[2]);
//   b[3] = Complex.'and'(c1[3], c2[3]);
//   s[1] = Complex.'String'(c1[1], "j", 5);
//   s[2] = Complex.'String'(c1[2], "j", 5);
//   s[3] = Complex.'String'(c1[3], "j", 5);
//   c1[1] = Complex.'-'.subtract(Complex.'+'(Complex.'*'.multiply(Complex.'/'(c1[1], c2[1]), c1[1]), Complex.'*'.multiply(c2[1], Complex.'constructor'.fromReal(1.0, 0.0))), Complex.'*'.multiply(c2[1], c1[1]));
//   c1[2] = Complex.'-'.subtract(Complex.'+'(Complex.'*'.multiply(Complex.'/'(c1[2], c2[2]), c1[2]), Complex.'*'.multiply(c2[2], Complex.'constructor'.fromReal(1.0, 0.0))), Complex.'*'.multiply(c2[2], c1[2]));
//   c1[3] = Complex.'-'.subtract(Complex.'+'(Complex.'*'.multiply(Complex.'/'(c1[3], c2[3]), c1[3]), Complex.'*'.multiply(c2[3], Complex.'constructor'.fromReal(1.0, 0.0))), Complex.'*'.multiply(c2[3], c1[3]));
// end Test;
// endResult
