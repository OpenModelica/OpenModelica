within ThermoSysPro.Examples.SimpleExamples;
model TestFlueGasesVolumes
  annotation(Diagram, Diagram(coordinateSystem(scale=0.1, extent={{-200,-150},{200,150}})), Icon(coordinateSystem(scale=0.1, extent={{-200,-150},{200,150}})));
  ThermoSysPro.FlueGases.BoundaryConditions.SourcePQ Source_Fumees(Xso2=0, Xco2=0.0, Xh2o=0.006, Xo2=0.23, Q0=2, T0=300, P0=130000.0) annotation(Placement(transformation(x=-110.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  ThermoSysPro.FlueGases.BoundaryConditions.Sink Puits_Fumees annotation(Placement(transformation(x=130.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false, rotation=-180.0)));
  ThermoSysPro.FlueGases.Volumes.VolumeDTh dynamicExchanger annotation(Placement(transformation(x=-30.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSource heatSource(option_temperature=2, W0={20000.0}) annotation(Placement(transformation(x=-70.0, y=52.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.PressureLosses.SingularPressureLoss singularPressureLossFlueGases(K(fixed=true)=10, Q(fixed=false, start=10)) annotation(Placement(transformation(x=10.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.PressureLosses.SingularPressureLoss singularPressureLossFlueGases1(K(fixed=true)=0.01, Q(fixed=false, start=11)) annotation(Placement(transformation(x=-70.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Rampe rampe(Starttime=50, Duration=50, Initialvalue=10000.0, Finalvalue=20000.0) annotation(Placement(transformation(x=-30.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.FlueGases.Machines.StaticFan staticFan(VRotn=2700, rm=1, VRot=3000, a1=45.876, a2=-50, b1=-3.0752) annotation(Placement(transformation(x=50.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.PressureLosses.SingularPressureLoss singularPressureLossFlueGases2(K(fixed=true)=10, Q(fixed=false, start=10)) annotation(Placement(transformation(x=90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(Source_Fumees.C,singularPressureLossFlueGases1.C1) annotation(Line(points={{-100,10},{-80,10}}, color={0,0,0}, thickness=1.0));
  connect(singularPressureLossFlueGases.C2,staticFan.C1) annotation(Line(points={{20,10},{40,10}}, color={0,0,0}, thickness=1.0));
  connect(staticFan.C2,singularPressureLossFlueGases2.C1) annotation(Line(points={{60,10},{80,10}}, color={0,0,0}, thickness=1.0));
  connect(singularPressureLossFlueGases1.C2,dynamicExchanger.Ce) annotation(Line(points={{-60,10},{-40,10}}, color={0,0,0}, thickness=1.0));
  connect(dynamicExchanger.Cs3,singularPressureLossFlueGases.C1) annotation(Line(points={{-20,10},{0,10}}, color={0,0,0}, thickness=1.0));
  connect(singularPressureLossFlueGases2.C2,Puits_Fumees.C) annotation(Line(points={{100,10},{110.1,10},{110.1,10},{120.2,10}}, color={0,0,0}, thickness=1.0));
  connect(rampe.y,heatSource.ISignal) annotation(Line(points={{-41,70},{-70,70},{-70,57}}, color={0,0,255}));
  connect(heatSource.C[1],dynamicExchanger.Cth) annotation(Line(points={{-70,42.2},{-30,10}}, color={191,95,0}));
end TestFlueGasesVolumes;
