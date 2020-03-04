within DataReconciliationSimpleTests.Lib;
model HalfSimpleCircuit_QP

  QPLib.WaterSteam.BoundaryConditions.SourceQ        sourceQ1(Q0=250)
                                                              annotation(Placement(visible=true, transformation(origin={-139,0},      extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.BoundaryConditions.SinkP
                                          sink2 annotation (Placement(visible=
          true, transformation(
        origin={49.059,20},
        extent={{-10.0,-10.0},{10.0,10.0}},
        rotation=0)));
  QPLib.WaterSteam.PressureLosses.PipePressureLoss        pipePressureLoss1                   annotation(Placement(visible=true, transformation(origin={-80,0},     extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.Junctions.Splitter2        splitter21 annotation(Placement(visible=true, transformation(origin={-44.0534,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.PressureLosses.PipePressureLoss        pipePressureLoss2                   annotation(Placement(visible=true, transformation(origin={10,20},     extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.PressureLosses.PipePressureLoss        pipePressureLoss3                   annotation(Placement(visible=true, transformation(origin={10.0,-20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  QPLib.WaterSteam.BoundaryConditions.SinkP
                                          sink3 annotation (Placement(visible=
          true, transformation(
        origin={49.059,-20},
        extent={{-10.0,-10.0},{10.0,10.0}},
        rotation=0)));
equation
  connect(pipePressureLoss1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-59.2678,-0.0}, points={{
          -10.7322,0},{5.2144,0}},                                                                                                               color={0,0,255}));
  connect(pipePressureLoss2.C1, splitter21.Cs1) annotation (Line(points={{0,20},{
          -40.0534,20},{-40.0534,10}},  color={0,0,255}));
  connect(pipePressureLoss3.C1, splitter21.Cs2) annotation (Line(points={{0,-20},
          {-40.0534,-20},{-40.0534,-10}}, color={0,0,255}));
  connect(pipePressureLoss1.C1,sourceQ1. C)
    annotation (Line(points={{-90,0},{-129,0}}, color={0,0,255}));
  connect(pipePressureLoss2.C2, sink2.C)
    annotation (Line(points={{20,20},{39.059,20}}, color={0,0,255}));
  connect(pipePressureLoss3.C2, sink3.C)
    annotation (Line(points={{20,-20},{39.059,-20}}, color={0,0,255}));
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}},     preserveAspectRatio=true, initialScale=0.1, grid={1,1})),
      DymolaStoredErrors);
end HalfSimpleCircuit_QP;
