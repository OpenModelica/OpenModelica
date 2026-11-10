// name:     DAEexample2
// keywords: equation
// status:   correct
//
// Drmodelica: 2.1 Differential Algebraic Equation System (p. 19)
//

model DAEexample
  Real x(start = 0.9,fixed=true);
  Real y;
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
//    x - y = exp(-0.9 * x) * cos(y);
// end DAEexample;
