within ThermoSysPro.Examples.SimpleExamples;
model TestSensors
  ThermoSysPro.WaterSteam.Sensors.SensorH specificEnthalpySensor annotation(Placement(transformation(x=-50.0, y=18.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Sensors.SensorQ massFlowSensor annotation(Placement(transformation(x=-10.0, y=18.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Sensors.SensorQv volumetricFlowSensor annotation(Placement(transformation(x=30.0, y=18.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Sensors.SensorP pressureSensor annotation(Placement(transformation(x=-50.0, y=-22.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Sensors.SensorT temperatureSensor annotation(Placement(transformation(x=-10.0, y=-22.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP annotation(Placement(transformation(x=70.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP annotation(Placement(transformation(x=-90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe perteDP annotation(Placement(transformation(x=30.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP.C,specificEnthalpySensor.C1) annotation(Line(points={{-80,10},{-60,10}}, color={0,0,255}));
  connect(specificEnthalpySensor.C2,massFlowSensor.C1) annotation(Line(points={{-39.8,10},{-20,10}}, color={0,0,255}));
  connect(massFlowSensor.C2,volumetricFlowSensor.C1) annotation(Line(points={{0.2,10},{20,10}}, color={0,0,255}));
  connect(volumetricFlowSensor.C2,pressureSensor.C1) annotation(Line(points={{40.2,10},{60,10},{60,0},{-80,0},{-80,-30},{-60,-30}}, color={0,0,255}));
  connect(pressureSensor.C2,temperatureSensor.C1) annotation(Line(points={{-39.8,-30},{-20,-30}}, color={0,0,255}));
  connect(temperatureSensor.C2,perteDP.C1) annotation(Line(points={{0.2,-30},{20,-30}}, color={0,0,255}));
  connect(perteDP.C2,puitsP.C) annotation(Line(points={{40,-30},{60,-30}}, color={0,0,255}));
end TestSensors;
