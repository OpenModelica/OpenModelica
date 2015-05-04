model OilShalePyrolysis
  // see: Dynamic Optimization of Batch Reactors Using Adaptive Stochastic Algorithms 1997,
  // Eugenio F. Carrasco, Julio R. Banga
  Real x1(start = 1, fixed = true);
  Real x2(start = 0, fixed = true);
  Real x3(start = 0, fixed = true);
  Real x4(start = 0, fixed = true);
  Real k1;
  Real k2;
  Real k3;
  Real k4;
  Real k5;
  input Real T(start = 700, min = 698.15, max = 748.15);
equation
  k1 = exp(8.86 - (20300/1.9872)/T);
  k2 = exp(24.25 - (37400/1.9872)/T);
  k3 = exp(23.67 - (33800/1.9872)/T);
  k4 = exp(18.75 - (28200/1.9872)/T);
  k5 = exp(20.70 - (31000/1.9872)/T);
  der(x1) = -k1*x1 - (k3+k4+k5)*x1*x2;
  der(x2) = k1*x1 - k2*x2 + k3*x1*x2;
  der(x3) = k2*x2 + k4*x1*x2;
  der(x4) = k5*x1*x2;
end OilShalePyrolysis;

optimization nmpcOilShalePyrolysis(objective = -x2)
  extends OilShalePyrolysis;
end nmpcOilShalePyrolysis;

