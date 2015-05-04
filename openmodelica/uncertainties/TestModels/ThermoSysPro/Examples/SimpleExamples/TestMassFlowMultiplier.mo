within ThermoSysPro.Examples.SimpleExamples;
model TestMassFlowMultiplier
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourcePQ annotation(Placement(transformation(x=-90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink sink annotation(Placement(transformation(x=70.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss annotation(Placement(transformation(x=-50.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss1 annotation(Placement(transformation(x=30.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Junctions.MassFlowMultiplier massFlowMultiplier annotation(Placement(transformation(x=-10.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourcePQ.C,singularPressureLoss.C1) annotation(Line(points={{-80,10},{-60,10}}, color={0,0,255}));
  connect(singularPressureLoss1.C2,sink.C) annotation(Line(points={{40,10},{60,10}}, color={0,0,255}));
  connect(singularPressureLoss.C2,massFlowMultiplier.Ce) annotation(Line(points={{-40,10},{-20,10}}, color={0,0,255}));
  connect(massFlowMultiplier.Cs,singularPressureLoss1.C1) annotation(Line(points={{0,10},{20,10}}, color={0,0,255}));
end TestMassFlowMultiplier;
