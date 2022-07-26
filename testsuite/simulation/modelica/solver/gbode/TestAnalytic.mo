model TestAnalytic
  Real x(start = 0, fixed = true);
  Real v(start = 1, fixed = true);
  Real x_exact = sin(time);
  Real v_exact = cos(time);
  Real err = sqrt((x - x_exact) ^ 2 + (v - v_exact) ^ 2);
equation
  der(x) = v;
  der(v) = -x;
  annotation(
    experiment(StartTime = 0, StopTime = 10, Tolerance = 1e-06, Interval = 0.02));
end TestAnalytic;
