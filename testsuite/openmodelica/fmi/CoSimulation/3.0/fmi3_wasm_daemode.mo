model DaeModeWhenLoop "Nonlinear algebraic loop that a when-equation is part of"
  Real x(start = 0, fixed = true);
  Real y(start = 0) "solved from a nonlinear equation that reads the timer";
  discrete Real tSwitch(start = 1e60, fixed = true) "when y last rose past the threshold";
equation
  der(x) = 1 - x;
  y = 0.5 * sin(y) + x + (if tSwitch < 1e59 then 0.2 else 0.0);
  when y > 0.5 then
    tSwitch = time;
  elsewhen y < 0.5 then
    tSwitch = 1e60;
  end when;
  annotation(
    __OpenModelica_commandLineOptions = "--daeMode",
    experiment(StopTime = 5, Tolerance = 1e-6));
end DaeModeWhenLoop;
