within ThermoSysPro.Examples.SimpleExamples;
model TestSteamEngine
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Machines.SteamEngine steamEngine1 annotation(Placement(transformation(x=-50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP(mode=0, P0=100000) annotation(Placement(transformation(x=-10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP(h0=3000000.0, option_temperature=2, mode=2, P0=1600000.0) annotation(Placement(transformation(x=-90.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP.C,steamEngine1.C1) annotation(Line(points={{-80,70},{-57,70}}, color={0,0,255}));
  connect(steamEngine1.C2,puitsP.C) annotation(Line(points={{-43,70},{-31.5,70},{-31.5,70},{-20,70}}, color={0,0,255}));
end TestSteamEngine;
