// name: OperatorSimple
// keywords: operator
// status: correct
//
// Tests simple operator overloading
//

operator record Complex
  Real re;
  Real im;

  operator '*'
    function mul
      input Complex c1;
      input Complex c2;
      output Complex result;
    algorithm
      result := Complex(re=c1.re*c2.re - c1.im*c2.im,
                        im=c1.re*c2.im + c1.im*c2.re);
    end mul;
  end '*';
end Complex;

model OperatorSimple
  Complex c1,c2,c3;
equation
  c1 = Complex(re=2.0,im=3.0);
  c2 = Complex(re=7.0,im=3.14);
  c3 = c1 * c2;
end OperatorSimple;

// Result:
// function Complex "Automatically generated record constructor for Complex"
//   input Real re;
//   input Real im;
//   output Complex res;
// end Complex;
//
// function Complex.'*'.mul
//   input Complex c1;
//   input Complex c2;
//   output Complex result;
// algorithm
//   result := Complex(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
// end Complex.'*'.mul;
//
// class OperatorSimple
//   Real c1.re;
//   Real c1.im;
//   Real c2.re;
//   Real c2.im;
//   Real c3.re;
//   Real c3.im;
// equation
//   c1.re = 2.0;
//   c1.im = 3.0;
//   c2.re = 7.0;
//   c2.im = 3.14;
//   c3 = Complex.'*'.mul(c1, c2);
// end OperatorSimple;
// endResult
