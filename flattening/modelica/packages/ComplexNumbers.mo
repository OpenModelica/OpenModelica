// name:     ComplexNumbers
// keywords: package, functions
// status:   correct
//
// defines and uses a package
//

encapsulated package ComplexNumbers
  record Complex
    Real re;
    Real im;
  end Complex;

  function Add
    input Complex x;
    input Complex y;
    output Complex z;
  algorithm
    z.re := x.re + y.re;
    z.im := x.im + y.im;
  end Add;

  function Multiply
    input Complex x;
    input Complex y;
    output Complex z;
  algorithm
    z.re := x.re*y.re - x.im*y.im;
    z.im := x.re*y.im + x.im*y.re;
  end Multiply;

  function MakeComplex
    input Real x;
    input Real y;
    output Complex z;
    algorithm
      z.re := x;
      z.im := y;
  end MakeComplex;
end ComplexNumbers;


class ComplexUser
  ComplexNumbers.Complex a(re=1.0, im=2.0);
  ComplexNumbers.Complex b(re=1.0, im=2.0);
  ComplexNumbers.Complex z, w;
  equation
    z = ComplexNumbers.Multiply(a, b);
    z = ComplexNumbers.Add(a, b);
end ComplexUser;

// Result:
// function ComplexNumbers.Add
//   input ComplexNumbers.Complex x;
//   input ComplexNumbers.Complex y;
//   output ComplexNumbers.Complex z;
// algorithm
//   z.re := x.re + y.re;
//   z.im := x.im + y.im;
// end ComplexNumbers.Add;
//
// function ComplexNumbers.Complex "Automatically generated record constructor for ComplexNumbers.Complex"
//   input Real re;
//   input Real im;
//   output Complex res;
// end ComplexNumbers.Complex;
//
// function ComplexNumbers.Complex$a "Automatically generated record constructor for ComplexNumbers.Complex$a"
//   input Real re;
//   input Real im;
//   output Complex$a res;
// end ComplexNumbers.Complex$a;
//
// function ComplexNumbers.Complex$b "Automatically generated record constructor for ComplexNumbers.Complex$b"
//   input Real re;
//   input Real im;
//   output Complex$b res;
// end ComplexNumbers.Complex$b;
//
// function ComplexNumbers.Multiply
//   input ComplexNumbers.Complex x;
//   input ComplexNumbers.Complex y;
//   output ComplexNumbers.Complex z;
// algorithm
//   z.re := x.re * y.re - x.im * y.im;
//   z.im := x.re * y.im + x.im * y.re;
// end ComplexNumbers.Multiply;
//
// class ComplexUser
//   Real a.re = 1.0;
//   Real a.im = 2.0;
//   Real b.re = 1.0;
//   Real b.im = 2.0;
//   Real z.re;
//   Real z.im;
//   Real w.re;
//   Real w.im;
// equation
//   z = ComplexNumbers.Multiply(/*.ComplexNumbers.Complex*/(a), /*.ComplexNumbers.Complex*/(b));
//   z = ComplexNumbers.Add(/*.ComplexNumbers.Complex*/(a), /*.ComplexNumbers.Complex*/(b));
// end ComplexUser;
// endResult
