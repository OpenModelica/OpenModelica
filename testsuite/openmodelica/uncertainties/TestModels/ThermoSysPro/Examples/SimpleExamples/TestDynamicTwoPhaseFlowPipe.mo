within ThermoSysPro.Examples.SimpleExamples;
model TestDynamicTwoPhaseFlowPipe
  ThermoSysPro.WaterSteam.HeatExchangers.DynamicTwoPhaseFlowPipe dynamicTwoPhaseFlowPipe(L=20, advection=false) annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP annotation(Placement(transformation(x=-50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP annotation(Placement(transformation(x=30.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSource heatSource(T0={1000,1100,1200,1300,1400,1500,1600,1700,1800,1900}, option_temperature=2, W0={7000000.0,7000000.0,7000000.0,7000000.0,7000000.0,7000000.0,7000000.0,7000000.0,7000000.0,7000000.0}) annotation(Placement(transformation(x=-10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.HeatTransfer.HeatExchangerWall heatExchangerWall(Ns=10) annotation(Placement(transformation(x=-10.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP.C,dynamicTwoPhaseFlowPipe.C1) annotation(Line(points={{-40,30},{-20,30}}, color={0,0,255}));
  connect(dynamicTwoPhaseFlowPipe.C2,sinkP.C) annotation(Line(points={{0,30},{20,30}}, color={0,0,255}));
  connect(heatSource.C,heatExchangerWall.WT2) annotation(Line(points={{-10,60.2},{-10,52}}, color={191,95,0}));
  connect(heatExchangerWall.WT1,dynamicTwoPhaseFlowPipe.CTh) annotation(Line(points={{-10,48},{-10,33}}, color={191,95,0}));
end TestDynamicTwoPhaseFlowPipe;
