package RestrictedVariabilityParamDialog
    model Volume
    Real V;
    Real X;
  end Volume;

  model TestVolume
  Volume volume annotation(
      Placement(transformation(origin = {-6, 14}, extent = {{-10, -10}, {10, 10}})));
  end TestVolume;

  model RestrictByRedeclare
    extends RestrictedVariabilityParamDialog.Volume(redeclare parameter Real V=0);
  end RestrictByRedeclare;

  model InputByRedeclare
    extends RestrictedVariabilityParamDialog.Volume(redeclare input Real X=0);
  end InputByRedeclare;

  model TestRestrictByRedeclare
  RestrictByRedeclare restrictByRedeclare(V=1) annotation(
      Placement(transformation(origin = {2, -2}, extent = {{-10, -10}, {10, 10}})));
  annotation(
      experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-06, Interval = 0.002));
end TestRestrictByRedeclare;
end RestrictedVariabilityParamDialog;
