// name: Inline2
// keywords:
// status: correct
//

operator record Complex
  Real re, im;

  encapsulated operator 'constructor'
    function fromReal
      import Complex;
      input Real re;
      input Real im = 0.0;
      output Complex result(re = re, im = im);
    algorithm
    end fromReal;
  end 'constructor';
end Complex;

model Inline2
  parameter Real a = 1;
  parameter Real b = 2;
  final parameter Complex c = Complex(a, b);
end Inline2;

// Result:
// class Inline2
//   parameter Real a = 1.0;
//   parameter Real b = 2.0;
//   final parameter Real c.re = a;
//   final parameter Real c.im = b;
// end Inline2;
// endResult
