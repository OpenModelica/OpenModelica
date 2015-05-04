within ThermoSysPro.Examples.SimpleExamples;
model TestSimpleStaticCondenser
  ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser simpleStaticCondenser annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP annotation(Placement(transformation(x=-50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP1(T0=400) annotation(Placement(transformation(x=-50.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP annotation(Placement(transformation(x=30.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP1 annotation(Placement(transformation(x=30.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP.C,simpleStaticCondenser.Ef) annotation(Line(points={{-40,30},{-20,30}}, color={0,0,255}));
  connect(sourceP1.C,simpleStaticCondenser.Ec) annotation(Line(points={{-40,-10},{-16,-10},{-16,20}}, color={0,0,255}));
  connect(simpleStaticCondenser.Sf,sinkP.C) annotation(Line(points={{0,29.9},{10,29.9},{10,30},{20,30}}, color={0,0,255}));
  connect(simpleStaticCondenser.Sc,sinkP1.C) annotation(Line(points={{-4,20},{-4,-10},{20,-10}}, color={0,0,255}));
end TestSimpleStaticCondenser;
