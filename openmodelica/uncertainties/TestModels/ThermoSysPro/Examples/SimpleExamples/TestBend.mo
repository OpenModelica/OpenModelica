within ThermoSysPro.Examples.SimpleExamples;
model TestBend
  annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP SourceP1 annotation(Placement(visible=true, transformation(origin={-90.0,36.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP SinkP1 annotation(Placement(visible=true, transformation(origin={70.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSteam.PressureLosses.Bend Bend annotation(Placement(visible=true, transformation(origin={-10.0,36.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
equation
  connect(SourceP1.C,Bend.C1) annotation(Line(visible=true, points={{-80.0,36.0},{-20.0,36.0}}, color={0,0,255}));
  connect(Bend.C2,SinkP1.C) annotation(Line(visible=true, points={{-10.0,26.0},{-10.0,10.0},{60.0,10.0}}, color={0,0,255}));
end TestBend;
