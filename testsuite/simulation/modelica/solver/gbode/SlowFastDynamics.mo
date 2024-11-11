model SlowFastDynamics
  parameter Real epsilon = 3;
  parameter Real corr = 0.01;
  parameter Real fast = 7;
  parameter Real slow = 0.1;
  Real y[2](start = {1,1}, each fixed=true);
equation
  der(y) = {-y[1] - corr*y[2] + fast*sin(fast*time), corr*y[1] - epsilon*y[2] - cos(slow*time)};
annotation(
    experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-6, Interval = 0.002),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian --generateDynamicJacobian=symbolic",
    __OpenModelica_simulationFlags(gbm = "gauss6", lv = "LOG_STATS", s = "gbode"));
end SlowFastDynamics;
