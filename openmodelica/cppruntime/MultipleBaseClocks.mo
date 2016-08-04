within ;
model MultipleBaseClocks
    discrete Real x( start=0);
  Modelica_Synchronous.ClockSignals.Clocks.PeriodicExactClock clock1(resolution=
       Modelica_Synchronous.Types.Resolution.ms, factor=10) annotation (
      Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=90,
        origin={64,-20})));
Modelica_Synchronous.ClockSignals.Sampler.SubSample subSample(factor=4)
  annotation (Placement(transformation(extent={{-6,-6},{6,6}},
        rotation=90,
        origin={64,6})));
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample1
    annotation (Placement(transformation(extent={{58,22},{70,34}})));
  Modelica.Blocks.Sources.Sine sine(freqHz=2,
    offset=0.1,
    startTime=0)
    annotation (Placement(transformation(extent={{-80,60},{-60,80}})));
  Modelica_Synchronous.ClockSignals.Clocks.PeriodicExactClock clock2(resolution=
       Modelica_Synchronous.Types.Resolution.ms, factor=20) annotation (
      Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=90,
        origin={102,-20})));
Modelica_Synchronous.ClockSignals.Sampler.SuperSample superSample(factor=2)
    annotation (Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=90,
        origin={102,6})));
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample2
    annotation (Placement(transformation(extent={{96,20},{108,32}})));
  Modelica_Synchronous.ClockSignals.Clocks.PeriodicExactClock clock3(resolution=
       Modelica_Synchronous.Types.Resolution.ms, factor=15) annotation (
      Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=90,
        origin={136,-20})));
  Modelica_Synchronous.RealSignals.Sampler.ShiftSample shiftSample1(
      shiftCounter=1, resolution=2) annotation (Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=0,
        origin={158,26})));
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample3
    annotation (Placement(transformation(extent={{130,20},{142,32}})));

  Modelica_Synchronous.ClockSignals.Clocks.EventClock eventClock annotation (
      Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=270,
        origin={-54,-18})));
  Modelica.Blocks.Math.RealToBoolean realToBoolean(threshold=0.5) annotation (
      Placement(transformation(
        extent={{-5,-6},{5,6}},
        rotation=270,
        origin={-54,23})));
  Modelica_Synchronous.ClockSignals.Clocks.EventClock eventClock1 annotation (
      Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=270,
        origin={-4,-18})));
  Modelica.Blocks.Math.RealToBoolean realToBoolean1(threshold=0.2) annotation (
      Placement(transformation(
        extent={{-5,-6},{5,6}},
        rotation=270,
        origin={-4,23})));
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample4(y(start=0))
                                                                 annotation (
      Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=0,
        origin={-30,22})));
  Modelica_Synchronous.RealSignals.Sampler.SampleClocked sample5 annotation (
      Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=0,
        origin={26,20})));
  Modelica_Synchronous.ClockSignals.Clocks.PeriodicExactClock clock4(resolution=
       Modelica_Synchronous.Types.Resolution.ms, factor=8)  annotation (
      Placement(transformation(
        extent={{-6,-6},{6,6}},
        rotation=90,
        origin={24,-56})));
equation

  when Clock(3,10) then
    x = previous(x)+2;
  end when;

  connect(clock1.y, subSample.u) annotation (Line(
      points={{64,-13.4},{64,-1.2}},
      color={175,175,175},
      pattern=LinePattern.Dot,
      thickness=0.5,
      smooth=Smooth.None));
  connect(subSample.y,sample1. clock) annotation (Line(
      points={{64,12.6},{64,12.6},{64,20.8}},
      color={175,175,175},
      pattern=LinePattern.Dot,
      thickness=0.5));
  connect(clock2.y, superSample.u) annotation (Line(
      points={{102,-13.4},{102,-1.2}},
      color={175,175,175},
      pattern=LinePattern.Dot,
      thickness=0.5,
      smooth=Smooth.None));
  connect(superSample.y, sample2.clock) annotation (Line(
      points={{102,12.6},{102,18.8}},
      color={175,175,175},
      pattern=LinePattern.Dot,
      thickness=0.5));
  connect(sample3.y, shiftSample1.u) annotation (Line(
      points={{142.6,26},{150.8,26}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(clock3.y, sample3.clock) annotation (Line(
      points={{136,-13.4},{136,18.8}},
      color={175,175,175},
      pattern=LinePattern.Dot,
      thickness=0.5,
      smooth=Smooth.None));
  connect(eventClock.u, realToBoolean.y) annotation (Line(
      points={{-54,-10.8},{-54,17.5}},
      color={255,0,255},
      smooth=Smooth.None));
  connect(realToBoolean.u, sine.y) annotation (Line(
      points={{-54,29},{-54,70},{-59,70}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(sample2.u, sine.y) annotation (Line(
      points={{94.8,26},{88,26},{88,70},{-59,70}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(sample3.u, sine.y) annotation (Line(
      points={{128.8,26},{114,26},{114,70},{-59,70}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(eventClock1.u, realToBoolean1.y) annotation (Line(
      points={{-4,-10.8},{-4,17.5}},
      color={255,0,255},
      smooth=Smooth.None));
  connect(realToBoolean1.u, sine.y) annotation (Line(
      points={{-4,29},{-4,70},{-59,70}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(eventClock.y, sample4.clock) annotation (Line(
      points={{-54,-24.6},{-48,-24.6},{-48,-24},{-42,-24},{-42,14.8},{-30,14.8}},
      color={175,175,175},
      pattern=LinePattern.Dot,
      thickness=0.5,
      smooth=Smooth.None));

  connect(sample4.u, sine.y) annotation (Line(
      points={{-37.2,22},{-38,22},{-38,70},{-59,70}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(eventClock1.y, sample5.clock) annotation (Line(
      points={{-4,-24.6},{-4,-30},{26,-30},{26,12.8}},
      color={175,175,175},
      pattern=LinePattern.Dot,
      thickness=0.5,
      smooth=Smooth.None));
  connect(sample5.u, sine.y) annotation (Line(
      points={{18.8,20},{18,20},{18,70},{-59,70}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(sample1.u, sine.y) annotation (Line(
      points={{56.8,28},{52,28},{52,70},{-59,70}},
      color={0,0,127},
      smooth=Smooth.None));
  annotation (uses(Modelica_Synchronous(version="0.92.1"), Modelica(version="3.2.1")),
      Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
            180,100}}),
                    graphics),
    Icon(coordinateSystem(extent={{-100,-100},{180,100}})));
end MultipleBaseClocks;
