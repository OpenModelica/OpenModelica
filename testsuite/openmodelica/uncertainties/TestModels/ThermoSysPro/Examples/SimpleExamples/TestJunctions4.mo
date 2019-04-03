within ThermoSysPro.Examples.SimpleExamples;
model TestJunctions4
  ThermoSysPro.WaterSteam.Junctions.DeheaterMixer2 deheaterMixer2_1(Tmax=308) annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss annotation(Placement(transformation(x=-50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss1 annotation(Placement(transformation(x=30.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss2 annotation(Placement(transformation(x=-50.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkQ sinkP annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP(T0=310) annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.Source source(h0=30000) annotation(Placement(transformation(x=-90.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(singularPressureLoss.C2,deheaterMixer2_1.Ce) annotation(Line(points={{-40,30},{-30,30},{-30,36},{-20,36}}, color={0,0,255}));
  connect(deheaterMixer2_1.Cs,singularPressureLoss1.C1) annotation(Line(points={{0,36},{10,36},{10,30},{20,30}}, color={0,0,255}));
  connect(singularPressureLoss2.C2,deheaterMixer2_1.Ce_mix) annotation(Line(points={{-40,-10},{-9.9,-10},{-9.9,20}}, color={0,0,255}));
  connect(singularPressureLoss1.C2,sinkP.C) annotation(Line(points={{40,30},{60,30}}, color={0,0,255}));
  connect(sourceP.C,singularPressureLoss.C1) annotation(Line(points={{-80,30},{-60,30}}, color={0,0,255}));
  connect(source.C,singularPressureLoss2.C1) annotation(Line(points={{-80,-10},{-60,-10}}, color={0,0,255}));
end TestJunctions4;
