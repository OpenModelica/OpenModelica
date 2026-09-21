model DaeModeMe "Index-1 DAE: an algebraic loop, a nonlinear algebraic variable, a state event"
  Real x(start = 1, fixed = true);
  Real y "in a linear loop with z";
  Real z(nominal = 0.1);
  Real w "nonlinear in z";
  discrete Real bump(start = 0, fixed = true);
equation
  der(x) = y - bump;
  y + 2*z = x;
  y - 3*z = 2*x;
  w = x*z + z^2;
  when x > 1.5 then
    bump = 0.5;
  end when;
  annotation(
    __OpenModelica_commandLineOptions = "--daeMode",
    experiment(StopTime = 1, Tolerance = 1e-6));
end DaeModeMe;
