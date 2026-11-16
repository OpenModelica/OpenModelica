within;

impure function spatialHistoryBehavior
  output Boolean ok;
  external "C" ok = spatialHistoryBehavior()
    annotation(Include = "#include \"historyBehavior.c\"");
end spatialHistoryBehavior;

model SpatialHistoryBehavior
initial algorithm
  assert(spatialHistoryBehavior(), "Transport history check failed");
end SpatialHistoryBehavior;

function spatialCausalInlet
  input Real u;
  output Real y;
algorithm
  y := u;
  annotation(Inline = false);
end spatialCausalInlet;

model SpatialDistributionCausal
  parameter Real direction = 1;
  parameter Real velocity = 10;
  Real position(start = 3, fixed = true);
  Real filtered(start = 0, fixed = true);
  Real inlet;
  Real outlet;
  Real left;
  Real right;
equation
  der(position) = velocity * direction;
  inlet = spatialCausalInlet(direction * (position - 3) / velocity) + 0.1 * outlet;
  (left, right) = spatialDistribution(if direction > 0 then inlet else 0, if direction > 0 then 0 else inlet,
    position, direction > 0, {0, 1}, {0, 0});
  outlet = if direction > 0 then right else left;
  der(filtered) = outlet - filtered;
end SpatialDistributionCausal;

model SpatialCoarseEvents
  parameter Real direction = 1;
  Real position(start = 0, fixed = true);
  Real integral(start = 0, fixed = true);
  Real left;
  Real right;
  Real outlet;
equation
  der(position) = direction;
  (left, right) = spatialDistribution(0, 0, position, direction > 0, {0, 0.2, 0.2, 0.4, 0.4, 1}, {0, 0, 1, 1, 0, 0});
  outlet = if direction > 0 then right else left;
  der(integral) = outlet;
end SpatialCoarseEvents;

model SpatialHistoryEvents
  Real position(start = 0, fixed = true);
  Real unused;
  Real outlet;
  Boolean crossed = outlet > 0.5;
equation
  der(position) = 10;
  (unused, outlet) = spatialDistribution(time, 0, position, true, {0, 1}, {0, 0});
end SpatialHistoryEvents;

model SpatialInitialProfile
  Real position(start = 4);
  Real unused;
  Real outlet;
initial equation
  position = 4 + outlet;
equation
  der(position) = 1;
  (unused, outlet) = spatialDistribution(0, 0, position, true, {0, 1}, {0, 1});
end SpatialInitialProfile;
