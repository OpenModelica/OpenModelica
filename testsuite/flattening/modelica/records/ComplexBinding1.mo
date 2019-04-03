// name:     ComplexBinding1
// keywords: #4606 
// status:   correct
//

operator record Complex 
  replaceable Real re;
  replaceable Real im;

  encapsulated operator 'constructor' 
    function fromReal 
      input Real re;
      input Real im = 0;
      output .Complex result(re = re, im = im);
    end fromReal;
  end 'constructor';

  encapsulated operator function '+'
    input .Complex c1;
    input .Complex c2;
    output .Complex c3;
  algorithm
    c3 := .Complex(c1.re + c2.re, c1.im + c2.im);
  end '+';

end Complex;

function F  
  input Complex Z1;
  input Complex Z2;
  output Complex Z3;
algorithm
  Z3 := Z1 + Z2;
end F;

model ComplexBinding1
  parameter Complex Z1 = Complex(1, 1);
  parameter Complex Z2 = Z1;
  Complex Z3 = F(Z1, Z2);
end ComplexBinding1;

// Result:
// function Complex "Automatically generated record constructor for Complex"
//   input Real re;
//   input Real im;
//   output Complex res;
// end Complex;
//
// function Complex.'+'
//   input Complex c1;
//   input Complex c2;
//   output Complex c3;
// algorithm
//   c3 := Complex(c1.re + c2.re, c1.im + c2.im);
// end Complex.'+';
//
// function F
//   input Complex Z1;
//   input Complex Z2;
//   output Complex Z3;
// algorithm
//   Z3 := Complex.'+'(Z1, Z2);
// end F;
//
// class ComplexBinding1
//   parameter Real Z1.re = 1.0;
//   parameter Real Z1.im = 1.0;
//   parameter Real Z2.re = Z1.re;
//   parameter Real Z2.im = Z1.im;
//   Real Z3.re;
//   Real Z3.im;
// equation
//   Z3 = F(Z1, Z2);
// end ComplexBinding1;
// endResult
