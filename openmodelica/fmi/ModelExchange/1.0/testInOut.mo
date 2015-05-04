model testInOut
  InOutTest inOutTest
    annotation (Placement(transformation(extent={{-22,60},{-2,80}})));
  Modelica.Blocks.Sources.Sine sine
    annotation (Placement(transformation(extent={{-92,66},{-72,86}})));
  Modelica.Blocks.Math.Add add(k2=-1)
    annotation (Placement(transformation(extent={{62,60},{82,80}})));
  InOutTest_me_FMU inOutTest_fmu
    annotation (Placement(transformation(extent={{-20,26},{0,46}})));
equation
  connect(sine.y, inOutTest.u) annotation (Line(
      points={{-71,76},{-42,76},{-42,77},{-20,77}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(inOutTest.y, add.u1) annotation (Line(
      points={{-3,77},{12.1,77},{12.1,76},{60,76}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(sine.y, inOutTest_fmu.u) annotation (Line(
      points={{-71,76},{-56,76},{-56,41},{-20.4,41}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(inOutTest_fmu.y, add.u2) annotation (Line(
      points={{0.4,41},{34,41},{34,64},{60,64}},
      color={0,0,127},
      smooth=Smooth.None));
end testInOut;
