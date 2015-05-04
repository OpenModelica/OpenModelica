block SyncFilter
  parameter Real UpdateRate = 25000.0;
  parameter Integer n = 5;
  extends Modelica.Blocks.Interfaces.DiscreteSISO(samplePeriod = 1.0 / (n * UpdateRate));
  output Real x[n - 1] "State of transfer function from controller canonical form";

  Real b[n] = ones(n) / (1.0 * n);
  Real xext[n];
  Real x1;

equation
  when sampleTrigger then
      x1 = u;
    xext = vector([x1;x]);
    x = xext[1:size(x, 1)];
    y = vector([b]) * xext;

  end when;
end SyncFilter;

model SyncFilterTest
  SyncFilter syncFilter;
  Modelica.Blocks.Sources.Clock clock;
equation
  connect(clock.y, syncFilter.u);
end SyncFilterTest;
