within ThermoSysPro.Examples.SimpleExamples;
model TestAirHumidity
  ThermoSysPro.FlueGases.BoundaryConditions.SourcePQ sourceFlueGasesPQ(P0=100000.0, T0=293) annotation(Placement(visible=true, transformation(origin={-70.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.FlueGases.BoundaryConditions.AirHumidity airHumidity(hum0=0.9) annotation(Placement(visible=true, transformation(origin={-30.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.FlueGases.PressureLosses.SingularPressureLoss singularPressureLoss(K=1e-05) annotation(Placement(visible=true, transformation(origin={10.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.FlueGases.BoundaryConditions.Sink sinkFlueGases annotation(Placement(visible=true, transformation(origin={50.0,10.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics));
equation
  connect(singularPressureLoss.C2,sinkFlueGases.C) annotation(Line(visible=true, points={{20.0,10.0},{40.2,10.0}}, thickness=1));
  connect(airHumidity.C2,singularPressureLoss.C1) annotation(Line(visible=true, points={{-20.0,10.0},{0.0,10.0}}, thickness=1));
  connect(sourceFlueGasesPQ.C,airHumidity.C1) annotation(Line(visible=true, points={{-60.0,10.0},{-40.0,10.0}}, thickness=1));
end TestAirHumidity;
