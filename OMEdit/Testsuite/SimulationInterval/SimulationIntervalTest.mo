model SimulationIntervalTest
  Real x(start = 1, fixed = true);
equation
  der(x) = -x;
  annotation(experiment(StartTime = 0, StopTime = 1.2, Interval = 0.3));
end SimulationIntervalTest;
