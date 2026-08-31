model Issue13292
  "Regression test for #13292: resolveLoops must not combine equations with non +/-1 coefficients"
  parameter Integer n_comp = 2;
  Real n_dot;
  Real n[n_comp], n_total;
  Real m[n_comp], m_total;
  Real x[n_comp];
equation
  der(n) = - n_dot*x;
  x*sum(n) = n;
  n_total = sum(n);
  m[1] = 2*n[1];
  m[2] = 2*n[2];
  m_total = sum(m);
  n_dot = 10;
initial equation
  n = {1.0, 2.0};
end Issue13292;
