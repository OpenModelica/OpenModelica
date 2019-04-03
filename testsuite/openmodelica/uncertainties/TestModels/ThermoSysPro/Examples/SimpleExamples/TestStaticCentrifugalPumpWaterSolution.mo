within ThermoSysPro.Examples.SimpleExamples;
model TestStaticCentrifugalPumpWaterSolution
  annotation(Diagram);
  ThermoSysPro.InstrumentationAndControl.Blocks.Logique.Pulse Pulse1(width=200, period=400) annotation(Placement(transformation(x=-30.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Pulse pulse(width=200, period=500, amplitude=1000, offset=400) annotation(Placement(transformation(x=-30.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.PressureLosses.SingularPressureLoss singularPressureLossWaterLiBr annotation(Placement(transformation(x=50.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Machines.StaticCentrifugalPump staticCentrifugalPumpWaterLiBr annotation(Placement(transformation(x=10.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.BoundaryConditions.SourcePQ sourceSolution annotation(Placement(transformation(x=-70.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.BoundaryConditions.Sink sinkSolution annotation(Placement(transformation(x=90.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(pulse.y,staticCentrifugalPumpWaterLiBr.VRotation) annotation(Line(points={{-19,10},{10,10},{10,29}}, color={0,0,255}));
  connect(Pulse1.yL,staticCentrifugalPumpWaterLiBr.commandePompe) annotation(Line(points={{-19,70},{10,70},{10,51}}, color={0,0,255}));
  connect(staticCentrifugalPumpWaterLiBr.C2,singularPressureLossWaterLiBr.C1) annotation(Line(points={{20,40},{30,40},{30,40},{41,40}}, color={0,0,0}));
  connect(sourceSolution.Cs,staticCentrifugalPumpWaterLiBr.C1) annotation(Line(points={{-60,40},{0,40}}, color={0,0,0}));
  connect(singularPressureLossWaterLiBr.C2,sinkSolution.Ce) annotation(Line(points={{59,40},{80,40}}, color={0,0,0}));
end TestStaticCentrifugalPumpWaterSolution;
