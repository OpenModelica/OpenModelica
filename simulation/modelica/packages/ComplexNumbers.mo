// name:     ComplexNumbers
// keywords: package, functions
// status:   correct
//
// defines and uses a package
// Drmodelica: 10.1 Abstract Data Type (p. 333)
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
  ComplexNumbers.Complex z,w;
  equation
    z = ComplexNumbers.Multiply(a, b);
    w = ComplexNumbers.Add(a, b);
end ComplexUser;

// class ComplexUser
// Real a.re;
// Real a.im;
// Real b.re;
// Real b.im;
// Real z.re;
// Real z.im;
// Real w.re;
// Real w.im;
// equation
//   a.re = 1.0;
//   a.im = 2.0;
//   b.re = 1.0;
//   b.im = 2.0;
//   __TMP__0 = ComplexNumbers.Multiply(a,b);
//   z.re = __TMP__0.re;
//   z.im = __TMP__0.im;
//   __TMP__1 = ComplexNumbers.Add(a,b);
//   z.re = __TMP__1.re;
//   z.im = __TMP__1.im;
// end ComplexUser;
