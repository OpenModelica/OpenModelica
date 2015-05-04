within ThermoSysPro.Examples.SimpleExamples;
model TestCentrifugalPumpWaterSolution
  ThermoSysPro.WaterSolution.BoundaryConditions.RefP refP annotation(Placement(visible=true, transformation(origin={-90.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante constante(k=200000.0) annotation(Placement(visible=true, transformation(origin={-90.0,70.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSolution.Machines.StaticCentrifugalPump pump annotation(Placement(visible=true, transformation(origin={-10.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSolution.LoopBreakers.LoopBreakerQ loopBreakerQ annotation(Placement(visible=true, transformation(origin={20.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSolution.LoopBreakers.LoopBreakerT loopBreakerH annotation(Placement(visible=true, transformation(origin={50.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSolution.BoundaryConditions.RefT refT annotation(Placement(visible=true, transformation(origin={-60.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSolution.PressureLosses.SingularPressureLoss lumpedStraightPipe annotation(Placement(visible=true, transformation(origin={-10.0,-30.0}, extent={{10.0,-10.0},{-10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSolution.LoopBreakers.LoopBreakerXh2o loopBreakerXh20_1 annotation(Placement(visible=true, transformation(origin={80.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSolution.BoundaryConditions.RefXh2o refXh2o annotation(Placement(visible=true, transformation(origin={-34.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
equation
  connect(lumpedStraightPipe.C2,refP.C1) annotation(Line(visible=true, points={{-19.0,-30.0},{-100.0,-30.0},{-100.0,10.0}}));
  connect(loopBreakerXh20_1.Cs,lumpedStraightPipe.C1) annotation(Line(visible=true, points={{90.0,10.0},{100.0,10.0},{100.0,-30.0},{-1.0,-30.0}}));
  connect(refXh2o.C2,pump.C1) annotation(Line(visible=true, points={{-24.0,10.0},{-20.0,10.0}}));
  connect(refT.C2,refXh2o.C1) annotation(Line(visible=true, points={{-50.0,10.0},{-44.0,10.0}}));
  connect(loopBreakerH.Cs,loopBreakerXh20_1.Ce) annotation(Line(visible=true, points={{60.0,10.0},{70.0,10.0}}));
  connect(pump.C2,loopBreakerQ.Ce) annotation(Line(visible=true, points={{0.0,10.0},{10.0,10.0}}));
  connect(constante.y,refP.IPressure) annotation(Line(visible=true, points={{-79.0,70.0},{-60.0,70.0},{-60.0,34.0},{-90.0,34.0},{-90.0,21.0}}, color={0,0,255}));
  connect(refP.C2,refT.C1) annotation(Line(visible=true, points={{-80.0,10.0},{-70.0,10.0}}, color={0,0,255}));
  connect(loopBreakerQ.Cs,loopBreakerH.Ce) annotation(Line(visible=true, points={{30.0,10.0},{40.0,10.0}}, color={0,0,255}));
  annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics));
end TestCentrifugalPumpWaterSolution;
