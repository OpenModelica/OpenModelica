model DaeModeMeEvent "A when condition on an algebraic variable that the event changes"
  Real x(start = 0, fixed = true);
  Real y(start = 0);
  discrete Real d(start = 0, fixed = true);
  discrete Real cnt(start = 0, fixed = true);
equation
  der(x) = 1;
  y = 0.5*sin(y) + x - d;
  when x > 0.5 then
    d = 0.6;
  end when;
  when y < 0.1 then
    cnt = pre(cnt) + 1;
  end when;
  annotation(
    __OpenModelica_commandLineOptions = "--daeMode",
    experiment(StopTime = 1, Tolerance = 1e-6));
end DaeModeMeEvent;
