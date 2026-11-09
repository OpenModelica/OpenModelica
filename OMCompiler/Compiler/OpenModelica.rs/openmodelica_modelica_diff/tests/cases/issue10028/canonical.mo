package Loop
  package GaInSn "TH properties of Galinstan"
    extends Modelica.Media.Incompressible.TableBased(mediumName = "Galistan", T_min = 283.15, T_max = 303.15, TinK = true, T0 = 293.15, npol = 1, tableDensity = [283.1, 6360; 303.15, 6360], tableHeatCapacity = [283.1, 1850; 303.15, 1852], tableConductivity = [283.1, 0.1302; 303.15, 0.1302], tableViscosity = [283.1, 1.895e-3; 303.15, 1.895e-3], tableVaporPressure = [283.1, 500; 303.15, 1.9e3]);
  end GaInSn;

  model flowLoop "Models the flow loop"
    import Modelica.Units.SI;
    parameter SI.Diameter pDiam = 0.0256 "Pipe diamter of main loop";
    //parameter SI.Diameter pDiam=0.00635 "Pipe diamter of main loop";
    parameter SI.Diameter bpDiam = 0.0256 "Bypass line Diamater";
    // Water pump paremeters
    parameter SI.VolumeFlowRate waterV[:] = {1.32E-04, 1.67E-04, 1.84E-04, 2.20E-04, 2.56E-04, 2.91E-04, 3.17E-04, 3.40E-04, 3.59E-04} "Water pump flow rates";
    parameter SI.Height waterHead[:] = {9.88, 8.60, 7.96, 6.70, 5.35, 3.79, 2.56, 1.29, 0.07} "Water pump head";
    // Electromagnetic Pump parameters pressure(bar) = 0.0981*head (m)
    // 400rev/min
    parameter SI.VolumeFlowRate electV[2] = {0, 1.4e-3} "Water pump flow rates";
    parameter SI.Height electHead[2] = {14.27, 7.645} "Water pump head";
    // 200rev/min
    parameter SI.VolumeFlowRate electV2[2] = {1.5e-3, 0} "Water pump flow rates";
    parameter SI.Height electHead2[2] = {0, 7.64} "Water pump head";
    Modelica.Fluid.Machines.PrescribedPump pump(redeclare package Medium = Loop.GaInSn, m_flow_start = 1, redeclare function flowCharacteristic = Modelica.Fluid.Machines.BaseClasses.PumpCharacteristics.polynomialFlow(V_flow_nominal = waterV, head_nominal = waterHead), N_nominal = 1200, V = 0.552e-3, use_N_in = false, N_const = 1200) annotation(
      Placement(transformation(extent = {{-2, -68}, {-22, -48}})));
    Modelica.Fluid.Pipes.DynamicPipe pipe1(redeclare package Medium = Loop.GaInSn, allowFlowReversal = true, nParallel = 1, length = 0.5, diameter = pDiam, height_ab = 0.15, redeclare model FlowModel = Modelica.Fluid.Pipes.BaseClasses.FlowModels.DetailedPipeFlow(show_Res = true), nNodes = 4, use_HeatTransfer = false) "inletToBufferTank" annotation(
      Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {-74, -36})));
    Modelica.Fluid.Pipes.DynamicPipe pipeRect(redeclare package Medium = Loop.GaInSn, allowFlowReversal = true, length = 0.5, isCircular = false, diameter = 0.04, crossArea = 0.003, perimeter = 0.26, redeclare model FlowModel = Modelica.Fluid.Pipes.BaseClasses.FlowModels.DetailedPipeFlow, p_a_start = 100000, nNodes = 6, use_HeatTransfer = false) "Test channel" annotation(
      Placement(transformation(extent = {{-22, -8}, {-2, 12}})));
    Modelica.Fluid.Vessels.OpenTank tank(height = 0.2, crossArea = 0.05, level_start = 0.1, redeclare package Medium = Loop.GaInSn, use_portsData = true, portsData = {Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter = pDiam, height = 0.15), Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter = pDiam, height = 0.05)}, m_flow_nominal = 1, nPorts = 2) annotation(
      Placement(transformation(extent = {{-84, 6}, {-62, 28}})));
    Modelica.Fluid.Pipes.DynamicPipe pipe2(redeclare package Medium = GaInSn, allowFlowReversal = true, length = 0.5, diameter = pDiam, height_ab = 0, nNodes = 4) "inletToPump" annotation(
      Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {54, -30})));
    Modelica.Fluid.Pipes.DynamicPipe bypass1(redeclare package Medium = GaInSn, allowFlowReversal = true, length = 0.5, diameter = bpDiam, height_ab = 0, nNodes = 4, use_HeatTransfer = false) "Bypass Pipe1" annotation(
      Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {-32, 38})));
    Modelica.Fluid.Pipes.DynamicPipe bypass2(redeclare package Medium = GaInSn, allowFlowReversal = true, length = 0.5, diameter = bpDiam, height_ab = 0, nNodes = 4) "Bypass Pipe2" annotation(
      Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {24, 38})));
    Modelica.Fluid.Valves.ValveIncompressible valveIncompressible(redeclare package Medium = Loop.GaInSn, allowFlowReversal = true, CvData = Modelica.Fluid.Types.CvTypes.Av, Av = bpDiam/4*Modelica.Constants.pi, dp_nominal = 10000, m_flow_nominal = 1, filteredOpening = true, checkValve = false, redeclare function valveCharacteristic = Modelica.Fluid.Valves.BaseClasses.ValveCharacteristics.linear) "Bypass valve" annotation(
      Placement(transformation(extent = {{-12, 54}, {2, 68}})));
    Modelica.Blocks.Sources.Step step(height = 1, startTime = 60) annotation(
      Placement(transformation(extent = {{-44, 78}, {-28, 94}})));
    inner Modelica.Fluid.System system annotation(
      Placement(visible = true, transformation(origin = {72, -74}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
    connect(pump.port_b, pipe1.port_a) annotation(
      Line(points = {{-22, -58}, {-74, -58}, {-74, -46}}, color = {0, 127, 255}));
    connect(pipe1.port_b, tank.ports[1]) annotation(
      Line(points = {{-74, -26}, {-74.1, -10}, {-74.1, 6}}, color = {0, 127, 255}));
    connect(pipeRect.port_a, tank.ports[2]) annotation(
      Line(points = {{-22, 2}, {-71.9, 2}, {-71.9, 6}}, color = {0, 127, 255}));
    connect(pipeRect.port_b, pipe2.port_a) annotation(
      Line(points = {{-2, 2}, {54, 2}, {54, -20}}, color = {0, 127, 255}));
    connect(pipe2.port_b, pump.port_a) annotation(
      Line(points = {{54, -40}, {54, -58}, {-2, -58}}, color = {0, 127, 255}));
    connect(step.y, valveIncompressible.opening) annotation(
      Line(points = {{-27.2, 86}, {-5, 86}, {-5, 66.6}}, color = {0, 0, 127}));
    connect(bypass1.port_a, pipeRect.port_a) annotation(
      Line(points = {{-42, 38}, {-46, 38}, {-46, 2}, {-22, 2}}, color = {0, 127, 255}));
    connect(bypass1.port_b, valveIncompressible.port_a) annotation(
      Line(points = {{-22, 38}, {-18, 38}, {-18, 61}, {-12, 61}}, color = {0, 127, 255}));
    connect(valveIncompressible.port_b, bypass2.port_a) annotation(
      Line(points = {{2, 61}, {8, 61}, {8, 38}, {14, 38}}, color = {0, 127, 255}));
    connect(bypass2.port_b, pipeRect.port_b) annotation(
      Line(points = {{34, 38}, {38, 38}, {38, 2}, {-2, 2}}, color = {0, 127, 255}));
    annotation(
      Icon(coordinateSystem(preserveAspectRatio = false)),
      Diagram(coordinateSystem(preserveAspectRatio = false)),
      experiment(StopTime = 300, __Dymola_Algorithm = "Euler"));
  end flowLoop;
  annotation(
    uses(Modelica(version = "4.0.0")));
end Loop;