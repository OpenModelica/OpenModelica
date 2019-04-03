within ThermoSysPro.Examples.SimpleExamples;
model TestRefP
  ThermoSysPro.WaterSteam.BoundaryConditions.RefP refP annotation(Placement(transformation(x=-80.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante constante(k=200000.0) annotation(Placement(transformation(x=-90.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Machines.StaticCentrifugalPump pump annotation(Placement(transformation(x=-20.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.LoopBreakers.LoopBreakerQ loopBreakerQ annotation(Placement(transformation(x=10.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.LoopBreakers.LoopBreakerH loopBreakerH annotation(Placement(transformation(x=40.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.RefT refT annotation(Placement(transformation(x=-50.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe lumpedStraightPipe annotation(Placement(transformation(x=70.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(refP.C2,refT.C1) annotation(Line(points={{-70,10},{-60,10}}, color={0,0,255}));
  connect(refT.C2,pump.C1) annotation(Line(points={{-40,10},{-30,10}}, color={0,0,255}));
  connect(constante.y,refP.IPressure) annotation(Line(points={{-79,70},{-60,70},{-60,34},{-80,34},{-80,21}}, color={0,0,255}));
  connect(lumpedStraightPipe.C2,refP.C1) annotation(Line(points={{80,10},{100,10},{100,-20},{-100,-20},{-100,10},{-90,10}}, color={0,0,255}));
  connect(pump.C2,loopBreakerQ.C1) annotation(Line(points={{-10,10},{0,10}}, color={0,0,255}));
  connect(loopBreakerQ.C2,loopBreakerH.C1) annotation(Line(points={{20,10},{30,10}}, color={0,0,255}));
  connect(loopBreakerH.C2,lumpedStraightPipe.C1) annotation(Line(points={{50,10},{60,10}}, color={0,0,255}));
end TestRefP;
