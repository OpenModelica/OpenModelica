model ClockedSource
  parameter Real dt = 0.1;
  Real u = 1;
  Modelica.Blocks.Interfaces.RealOutput ud;
equation
  ud = sample(time*u, Clock(dt));
end ClockedSource;
