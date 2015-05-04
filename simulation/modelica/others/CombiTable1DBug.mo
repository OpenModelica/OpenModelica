
model CombiTable1DBug
  parameter Real[:, 2] efficiency_characteristic = [0, 0.7];
  Modelica.Blocks.Tables.CombiTable1D eff_vs_flow(table = efficiency_characteristic, smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments);
  Real y;
equation
  eff_vs_flow.u[1] = 0;
  y = eff_vs_flow.y[1];
end CombiTable1DBug;

