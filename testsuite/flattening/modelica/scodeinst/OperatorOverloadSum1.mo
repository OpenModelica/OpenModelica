// name: OperatorOverloadSum1
// keywords: operator overload complex
// status: correct
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

  encapsulated operator function '+' "Add two complex numbers"
    import Complex;
    input Complex c1 "Complex number 1";
    input Complex c2 "Complex number 2";
    output Complex c3 "= c1 + c2";
  algorithm
    c3:=Complex(c1.re + c2.re, c1.im + c2.im);
  end '+';

  encapsulated operator function '0'
    import Complex;
    output Complex c;
  algorithm
    c := Complex(0,0);
    annotation(Inline=true);
  end '0';
end Complex;

model OperatorOverloadSum1
  Complex c1[3] = {Complex(time), Complex(time), Complex(time)};
  Complex c2;
equation
  c2 = sum(c1[i] for i in 1:size(c1, 1));
end OperatorOverloadSum1;

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
// function Complex.'constructor'.fromReal "Construct Complex from Real"
//   input Real re "Real part of complex number";
//   input Real im = 0.0 "Imaginary part of complex number";
//   output Complex result = Complex.'constructor'.fromReal(re, im) "Complex number";
// algorithm
// end Complex.'constructor'.fromReal;
//
// class OperatorOverloadSum1
//   Real c1[1].re "Real part of complex number";
//   Real c1[1].im "Imaginary part of complex number";
//   Real c1[2].re "Real part of complex number";
//   Real c1[2].im "Imaginary part of complex number";
//   Real c1[3].re "Real part of complex number";
//   Real c1[3].im "Imaginary part of complex number";
//   Real c2.re "Real part of complex number";
//   Real c2.im "Imaginary part of complex number";
// equation
//   c1[1] = Complex.'constructor'.fromReal(time, 0.0);
//   c1[2] = Complex.'constructor'.fromReal(time, 0.0);
//   c1[3] = Complex.'constructor'.fromReal(time, 0.0);
//   c2 = sum(c1[i] for i in 1:3);
// end OperatorOverloadSum1;
// endResult
