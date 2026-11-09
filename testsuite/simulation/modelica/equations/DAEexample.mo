// name:     DAEexample
// keywords: equation
// status:   correct
//
// Equation handling
//

model DAEexample
  Real x(start = 0.9,fixed=true);
  Real y(fixed=false);
  parameter Real a=2;
equation
  (1 + 0.5*sin(y))*der(x) + der(y) = a*sin(time);
  x-y = exp(-0.9*x)*cos(y);
end DAEexample;

// class DAEexample
// Real x(start=0.9);
// Real y;
// parameter Real a = 2;
// equation
//   (1.0 + 0.5 * sin(y)) * der(x) + der(y) = a * sin(time);
//   x - y = exp(-(0.9 * x)) * cos(y);
// end DAEexample;
