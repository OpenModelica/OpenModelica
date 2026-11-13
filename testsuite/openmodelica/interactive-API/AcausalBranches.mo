// Two fan + resistance branches between one source and one sink (Buildings);
// AcausalBranchesRewired connects the branches to the sink ports in reverse order.
model AcausalBranches
  Buildings.Fluid.Sources.Boundary_pT sou(redeclare package Medium = Buildings.Media.Air, T = 273.15 + 20, nPorts = 2);
  Buildings.Fluid.Sources.Boundary_pT sin(redeclare package Medium = Buildings.Media.Air, T = 273.15 + 10, p(displayUnit = "Pa") = 101325, nPorts = 2);
  Buildings.Fluid.Movers.FlowControlled_m_flow mov1(redeclare package Medium = Buildings.Media.Air, energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, redeclare Buildings.Fluid.Movers.Data.Fans.Greenheck.BIDW12 per, m_flow_nominal = 1, m_flow_start = 1);
  Buildings.Fluid.FixedResistances.PressureDrop res1(redeclare package Medium = Buildings.Media.Air, allowFlowReversal = false, m_flow_nominal = 0.2, dp_nominal = 20);
  Modelica.Blocks.Sources.Constant k1(k = 0.60);
  Buildings.Fluid.Movers.FlowControlled_m_flow mov2(redeclare package Medium = Buildings.Media.Air, energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, redeclare Buildings.Fluid.Movers.Data.Fans.Greenheck.BIDW12 per, m_flow_nominal = 1, m_flow_start = 1);
  Buildings.Fluid.FixedResistances.PressureDrop res2(redeclare package Medium = Buildings.Media.Air, allowFlowReversal = false, m_flow_nominal = 0.2, dp_nominal = 20);
  Modelica.Blocks.Sources.Constant k2(k = 0.60);
equation
  connect(sou.ports[1], mov1.port_a);
  connect(mov1.port_b, res1.port_a);
  connect(res1.port_b, sin.ports[1]);
  connect(k1.y, mov1.m_flow_in);
  connect(sou.ports[2], mov2.port_a);
  connect(mov2.port_b, res2.port_a);
  connect(res2.port_b, sin.ports[2]);
  connect(k2.y, mov2.m_flow_in);
end AcausalBranches;

model AcausalBranchesRewired
  Buildings.Fluid.Sources.Boundary_pT sou(redeclare package Medium = Buildings.Media.Air, T = 273.15 + 20, nPorts = 2);
  Buildings.Fluid.Sources.Boundary_pT sin(redeclare package Medium = Buildings.Media.Air, T = 273.15 + 10, p(displayUnit = "Pa") = 101325, nPorts = 2);
  Buildings.Fluid.Movers.FlowControlled_m_flow mov1(redeclare package Medium = Buildings.Media.Air, energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, redeclare Buildings.Fluid.Movers.Data.Fans.Greenheck.BIDW12 per, m_flow_nominal = 1, m_flow_start = 1);
  Buildings.Fluid.FixedResistances.PressureDrop res1(redeclare package Medium = Buildings.Media.Air, allowFlowReversal = false, m_flow_nominal = 0.2, dp_nominal = 20);
  Modelica.Blocks.Sources.Constant k1(k = 0.60);
  Buildings.Fluid.Movers.FlowControlled_m_flow mov2(redeclare package Medium = Buildings.Media.Air, energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, redeclare Buildings.Fluid.Movers.Data.Fans.Greenheck.BIDW12 per, m_flow_nominal = 1, m_flow_start = 1);
  Buildings.Fluid.FixedResistances.PressureDrop res2(redeclare package Medium = Buildings.Media.Air, allowFlowReversal = false, m_flow_nominal = 0.2, dp_nominal = 20);
  Modelica.Blocks.Sources.Constant k2(k = 0.60);
equation
  connect(sou.ports[1], mov1.port_a);
  connect(mov1.port_b, res1.port_a);
  connect(res1.port_b, sin.ports[2]);
  connect(k1.y, mov1.m_flow_in);
  connect(sou.ports[2], mov2.port_a);
  connect(mov2.port_b, res2.port_a);
  connect(res2.port_b, sin.ports[1]);
  connect(k2.y, mov2.m_flow_in);
end AcausalBranchesRewired;
