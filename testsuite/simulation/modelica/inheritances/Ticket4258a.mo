model simple_BasicHX_water_gas
  import SI = Modelica.SIunits;
  parameter SI.AbsolutePressure p_start = 101325 "Initial value of pressure";
  parameter SI.Temperature T_start = 293.15 "Initial value of temperature";
  parameter Modelica.Fluid.Types.ModelStructure pipeModelStructure = Modelica.Fluid.Types.ModelStructure.a_v_b;
  package Medium1 = Modelica.Media.IdealGases.SingleGases.N2;
  package Medium2 = Modelica.Media.Water.ConstantPropertyLiquidWater "Medium model";
  inner Modelica.Fluid.System system(T_ambient = T_start, p_ambient = p_start, m_flow_small = 1e-6, momentumDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial, energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial, massDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial) annotation(Placement(transformation(extent = {{-90, 70}, {-70, 90}})));
  Modelica.Fluid.Sources.MassFlowSource_T Ambient_in(redeclare package Medium = Medium1, T = 273.15 + 80, nPorts = 1, use_m_flow_in = true) annotation(Placement(visible = true, transformation(origin = {-24, -52}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Fluid.Sources.Boundary_pT Ambient_out(redeclare package Medium = Medium1, T = 273.15 + 80, nPorts = 1, p = p_start) annotation(Placement(visible = true, transformation(origin = {-24, 12}, extent = {{10, -10}, {-10, 10}}, rotation = 90)));
  Modelica.Fluid.Sources.Boundary_pT Ambient2_out(redeclare package Medium = Medium2, T = T_start, nPorts = 1, p = p_start) annotation(Placement(visible = true, transformation(origin = {-72, -36}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Fluid.Sources.MassFlowSource_T Ambient2_in(redeclare package Medium = Medium2, T = T_start, nPorts = 1, use_m_flow_in = true) annotation(Placement(visible = true, transformation(origin = {16, -4}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.RealExpression ramp_m_dot1(y = 0 + 1 / 2 * (Modelica.Math.tanh(2 * 1 * (time - 60)) + 1) * 1) annotation(Placement(visible = true, transformation(origin = {-44, -76}, extent = {{-6, -6}, {6, 6}}, rotation = 0)));
  Modelica.Blocks.Sources.RealExpression ramp_m_dot2(y = 0 + 1 / 2 * (Modelica.Math.tanh(2 * 1 * (time - 60)) + 1) * 1) annotation(Placement(visible = true, transformation(origin = {44, 0}, extent = {{-6, -6}, {6, 6}}, rotation = 0)));
  Modelica.Fluid.Examples.HeatExchanger.BaseClasses.BasicHX WT_Nachreformer(redeclare package Medium_1 = Medium1, redeclare package Medium_2 = Medium2, redeclare model HeatTransfer_1 = Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.LocalPipeFlowHeatTransfer, redeclare model HeatTransfer_2 = Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.LocalPipeFlowHeatTransfer, redeclare model FlowModel_1 = Modelica.Fluid.Pipes.BaseClasses.FlowModels.DetailedPipeFlow, redeclare model FlowModel_2 = Modelica.Fluid.Pipes.BaseClasses.FlowModels.DetailedPipeFlow, T_start_1 = T_start, T_start_2 = T_start, Twall_start = T_start, area_h_1 = 1, area_h_2 = 1, c_wall = 477, crossArea_1 = 0.1, crossArea_2 = 0.01, dT = 0, k_wall = 15, length = 1, m_flow_start_1 = 0, m_flow_start_2 = 0, modelStructure_1 = pipeModelStructure, modelStructure_2 = pipeModelStructure, nNodes = 5, p_a_start1 = p_start, p_a_start2 = p_start, p_b_start1 = p_start, p_b_start2 = p_start, perimeter_1 = 0.3, perimeter_2 = 0.3, rho_wall(displayUnit = "kg/m3") = 8000, s_wall = 0.003) annotation(Placement(visible = true, transformation(origin = {-24, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));

equation
      connect(WT_Nachreformer.port_b2, Ambient2_out.ports[1]) annotation(Line(points = {{-28, -30}, {-28, -30}, {-28, -36}, {-62, -36}, {-62, -36}}, color = {0, 127, 255}));
      connect(Ambient2_in.ports[1], WT_Nachreformer.port_a2) annotation(Line(points = {{6, -4}, {-20, -4}, {-20, -8}, {-20, -8}}, color = {0, 127, 255}));
  connect(ramp_m_dot2.y, Ambient2_in.m_flow_in) annotation(Line(points = {{50.6, 0}, {39.3, 0}, {39.3, 4}, {26, 4}}, color = {0, 0, 127}));
  connect(ramp_m_dot1.y, Ambient_in.m_flow_in) annotation(Line(points = {{-38, -76}, {-32, -76}, {-32, -62}, {-32, -62}}, color = {0, 0, 127}));
  connect(WT_Nachreformer.port_b1, Ambient_out.ports[1]) annotation(Line(points = {{-24, -12}, {-24, -12}, {-24, 2}, {-24, 2}}, color = {0, 127, 255}));
  connect(Ambient_in.ports[1], WT_Nachreformer.port_a1) annotation(Line(points = {{-24, -42}, {-24, -42}, {-24, -28}, {-24, -28}}, color = {0, 127, 255}));
  annotation(Documentation(info = "<html>

</html>"), experiment(StopTime = 200, StartTime = 0, Tolerance = 1e-5, Interval = 0.2));
end simple_BasicHX_water_gas;
