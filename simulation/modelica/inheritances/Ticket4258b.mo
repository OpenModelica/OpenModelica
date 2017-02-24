model Eco
replaceable package MediumFG=Modelica.Media.IdealGases.MixtureGases.FlueGasSixComponents constrainedby
    Modelica.Media.Interfaces.PartialMedium;
replaceable package MediumST=Modelica.Media.Water.StandardWater constrainedby
    Modelica.Media.Interfaces.PartialMedium;
  Modelica.Fluid.Pipes.DynamicPipe FGchannel(redeclare package Medium = MediumFG, diameter = 1, length = 1, use_HeatTransfer = false)  annotation(
    Placement(visible = true, transformation(origin = {-30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
Modelica.Fluid.Pipes.DynamicPipe STbundle(redeclare package Medium =MediumST , diameter = 0.1, length = 10, nParallel = 10, use_HeatTransfer = false)  annotation(
    Placement(visible = true, transformation(origin = {30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
Modelica.Fluid.Sources.MassFlowSource_T GT(redeclare package Medium = MediumFG, T = 873, nPorts = 1, use_m_flow_in = true)  annotation(
    Placement(visible = true, transformation(origin = {-70, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
Modelica.Fluid.Sources.Boundary_ph Stack(redeclare package Medium = MediumFG, nPorts = 1)  annotation(
    Placement(visible = true, transformation(origin = {-70, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
Modelica.Blocks.Sources.Ramp GTexhFlow(duration = 10, height = 130, offset = 1, startTime = 1)  annotation(
    Placement(visible = true, transformation(origin = {-110, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
Modelica.Fluid.Sources.MassFlowSource_h FWpump(redeclare package Medium =MediumST, h = 2.6e6, nPorts = 1, use_m_flow_in = true)  annotation(
    Placement(visible = true, transformation(origin = {70, -30}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
Modelica.Fluid.Sources.Boundary_ph STsink(redeclare package Medium =MediumST, h = 2.6e6, nPorts = 1, p = 90e5)  annotation(
    Placement(visible = true, transformation(origin = {70, 10}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
Modelica.Blocks.Sources.Ramp FWflow(duration = 10, height = 20, startTime = 1)  annotation(
    Placement(visible = true, transformation(origin = {110, -30}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
inner Modelica.Fluid.System system annotation(
    Placement(visible = true, transformation(origin = {-110, 90}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
  connect(FWpump.m_flow_in, FWflow.y) annotation(
    Line(points = {{80, -22}, {91, -22}, {91, -30}, {99, -30}}, color = {0, 0, 127}));
  connect(STbundle.port_b, STsink.ports[1]) annotation(
    Line(points = {{40, 10}, {60, 10}, {60, 10}, {60, 10}}, color = {0, 127, 255}));
  connect(FWpump.ports[1], STbundle.port_a) annotation(
    Line(points = {{60, -30}, {8, -30}, {8, 10}, {20, 10}, {20, 10}}, color = {0, 127, 255}));
  connect(GTexhFlow.y, GT.m_flow_in) annotation(
    Line(points = {{-98, 10}, {-92, 10}, {-92, 18}, {-80, 18}, {-80, 18}}, color = {0, 0, 127}));
  connect(FGchannel.port_b, Stack.ports[1]) annotation(
    Line(points = {{-20, 10}, {-14, 10}, {-14, -30}, {-60, -30}}, color = {0, 127, 255}));
  connect(GT.ports[1], FGchannel.port_a) annotation(
    Line(points = {{-60, 10}, {-40, 10}}, color = {0, 127, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, -100}, {120, 100}})));
end Eco;

