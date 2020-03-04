within DataReconciliationSimpleTests.Lib;
model SimpleCircuit_QP

  parameter Real rho=1000;
  QPLib.WaterSteam.BoundaryConditions.SourceQ        sourceQ1(Q0=250)
                                                              annotation(Placement(visible=true, transformation(origin={-140.0,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.BoundaryConditions.SinkP sink1 annotation (Placement(visible=
         true, transformation(
        origin={136.0591,0.0},
        extent={{-10.0,-10.0},{10.0,10.0}},
        rotation=0)));
  QPLib.WaterSteam.PressureLosses.PipePressureLoss        pipePressureLoss1(          p_rho=
        rho)                      annotation(Placement(visible=true, transformation(origin={-80,0},     extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.Junctions.Splitter2        splitter21 annotation(Placement(visible=true, transformation(origin={-44.0534,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.Junctions.Mixer2        mixer21 annotation(Placement(visible=true, transformation(origin={43.7284,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.PressureLosses.PipePressureLoss        pipePressureLoss2(          p_rho=
        rho)                  annotation(Placement(visible=true, transformation(origin={10,20},     extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.PressureLosses.PipePressureLoss        pipePressureLoss3(          p_rho=
        rho)                  annotation(Placement(visible=true, transformation(origin={10.0,-20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.PressureLosses.PipePressureLoss        pipePressureLoss4(          p_rho=
        rho)                      annotation(Placement(visible=true, transformation(origin={110.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
equation
  connect(pipePressureLoss1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-59.2678,-0.0}, points={{
          -10.7322,0},{5.2144,0}},                                                                                                               color={0,0,255}));
  connect(pipePressureLoss3.C2,mixer21.Ce2) annotation(Line(visible=true, origin={33.5937,-16.7254}, points={{
          -13.5937,-3.2746},{6.1347,-3.2746},{6.1347,6.7254}},                                                                                                    color={0,0,255}));
  connect(pipePressureLoss2.C2,mixer21.Ce1) annotation(Line(visible=true, origin={33.5485,16.5671}, points={{
          -13.5485,3.4329},{6.1799,3.4329},{6.1799,-6.5671}},                                                                                                    color={0,0,255}));
  connect(pipePressureLoss4.C2, sink1.C) annotation (Line(
      visible=true,
      origin={124.024,-0.1018},
      points={{-4.024,0.1018},{0.6553,0.1018},{2.0351,0.1018}},
      color={0,0,255}));
  connect(mixer21.Cs, pipePressureLoss4.C1)
    annotation (Line(points={{53.7284,0},{100,0}}, color={0,0,255}));
  connect(pipePressureLoss2.C1, splitter21.Cs1) annotation (Line(points={{0,20},
          {-40.0534,20},{-40.0534,10}}, color={0,0,255}));
  connect(pipePressureLoss3.C1, splitter21.Cs2) annotation (Line(points={{0,-20},
          {-40.0534,-20},{-40.0534,-10}}, color={0,0,255}));
  connect(pipePressureLoss1.C1,sourceQ1. C)
    annotation (Line(points={{-90,0},{-130,0}}, color={0,0,255}));
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}},     preserveAspectRatio=true, initialScale=0.1, grid={1,1})),
      DymolaStoredErrors);
end SimpleCircuit_QP;
