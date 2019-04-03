// name:     VanDerPol
// keywords: equation
// status:   correct
//
// Drmodelica: 2.1 Van der Pol (p. 22)
//
model VanDerPol  "Van der Pol oscillator model"
  Real x(start = 1);
  Real y(start = 1);
  parameter Real lambda = 0.3;
equation
  der(x) = y;
  der(y) = - x + lambda*(1 - x*x)*y;
end VanDerPol;

// Result:
// class VanDerPol "Van der Pol oscillator model"
//   Real x(start = 1.0);
//   Real y(start = 1.0);
//   parameter Real lambda = 0.3;
// equation
//   der(x) = y;
//   der(y) = lambda * (1.0 - x ^ 2.0) * y - x;
// end VanDerPol;
// endResult
