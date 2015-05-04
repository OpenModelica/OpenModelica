// Van der Pol model

model VanDerPol  "Van der Pol oscillator model"
  Real x(start = 1);
  Real y(start = 2);
  parameter Real lambda = 0.3;
equation
  der(x) = y;
  der(y) = - x + lambda*(1 - x*x)*y;
end VanDerPol;
