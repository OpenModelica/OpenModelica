model asmaFlow
  import Modelica.Constants.pi;
  parameter Modelica.SIunits.AngularVelocity DeltaOmEl = 25 "Controller Delta Omega";
  Modelica.Electrical.Machines.Utilities.TerminalBox terminalBox annotation(Placement(transformation(extent = {{30,40},{50,60}})));
  Modelica.Electrical.Machines.BasicMachines.AsynchronousInductionMachines.AIM_SquirrelCage aimc(p = 2, fsNominal = 50, Rs = 0.435, Lssigma = 0.004, Lrsigma = 0.002, Rr = 0.4, Jr = 2, Lm = 0.06931) annotation(Placement(transformation(extent = {{28,10},{48,30}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(Placement(transformation(extent = {{-96,-6},{-76,14}})));
  Modelica.Electrical.MultiPhase.Basic.Star star annotation(Placement(transformation(extent = {{-10,-10},{10,10}}, rotation = 270, origin = {-86,38})));
  Modelica.Mechanics.Rotational.Sources.Torque torque annotation(Placement(transformation(extent = {{-10,-10},{10,10}}, rotation = 180, origin = {70,20})));
  Modelica.Blocks.Sources.Constant const(k = -15) annotation(Placement(transformation(extent = {{-6,-6},{6,6}}, rotation = 90, origin = {84,-10})));
  Modelica.Mechanics.Rotational.Sensors.SpeedSensor speedSensor annotation(Placement(transformation(extent = {{-7,-7},{7,7}}, rotation = 270, origin = {55,-9})));
  Modelica.Electrical.MultiPhase.Sources.SineVoltage sinevoltage1(V = 230 * sqrt(2) / sqrt(3) * ones(3), freqHz = 50 * ones(3)) annotation(Placement(visible = true, transformation(origin = {-43.6742,70.364}, extent = {{-10,-10},{10,10}}, rotation = 0)));
equation
  connect(sinevoltage1.plug_n,terminalBox.plugSupply) annotation(Line(points = {{-33.6742,70.364},{40.208,70.364},{40.208,42.6343},{40.208,42.6343}}));
  connect(sinevoltage1.plug_p,star.plug_p) annotation(Line(points = {{-53.6742,70.364},{-86.3085,70.364},{-86.3085,48.8735},{-86.3085,48.8735}}));
  connect(terminalBox.plug_sn,aimc.plug_sn) annotation(Line(points = {{34,40},{34,34},{32,34},{32,30}}, color = {0,0,255}, smooth = Smooth.None));
  connect(terminalBox.plug_sp,aimc.plug_sp) annotation(Line(points = {{46,40},{46,34},{44,34},{44,30}}, color = {0,0,255}, smooth = Smooth.None));
  connect(ground.p,star.pin_n) annotation(Line(points = {{-86,14},{-86,28}}, color = {0,0,255}, smooth = Smooth.None));
  connect(torque.flange,aimc.flange) annotation(Line(points = {{60,20},{48,20}}, color = {0,0,0}, smooth = Smooth.None));
  connect(const.y,torque.tau) annotation(Line(points = {{84,-3.4},{84,0},{90,0},{90,20},{82,20}}, color = {0,0,127}, smooth = Smooth.None));
  connect(speedSensor.flange,torque.flange) annotation(Line(points = {{55,-2},{55,13},{60,13},{60,20}}, color = {0,0,0}, smooth = Smooth.None));
  annotation(Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics), experiment(StopTime = 20, NumberOfIntervals = 10000), experimentSetupOutput, Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Text(extent = {{-90,94},{82,84}}, lineColor = {255,0,0}, textString = "Macch: 230V, 10 kVA, 8kWe, 50 Hz, p=2"),Text(extent = {{-100,-76},{-62,-84}}, lineColor = {0,0,0}, textString = "NOTA"),Text(extent = {{-102,-84},{84,-90}}, lineColor = {0,0,0}, textString = "Per avere a regime 50 Hz occorre mettere come frequenza nominale 50 Hz")}), Documentation(info = "<html>
<p>This system simulates variable-frequency start-up of an asyncronous motor.</p>
<p><br/>The motor supply is constituted by a thhree-phase system of quasi-sinusoidal shapes, created according to the following equations:</p>
<p>OmEl=OmMecc*PolePairs+DeltaOmEl</p>
<p>V=V0+(Vn-V0)*(OmEl)/OmNom</p>
<p>where:</p>
<p><ul>
<li>V0, Vn V, are initial, nominal actual voltage amplitudes</li>
<li>OmMecc, OmEl, are machine, mechanical and supply, electrical angular speeds</li>
<li>PolePairs are the machine pole pairs</li>
<li>delta OmEl is a fixed parameter during the simulation</li>
</ul></p>
</html>"), Commands, experiment(StopTime = 10, NumberOfIntervals = 10000), experimentSetupOutput, Icon(graphics = {Ellipse(extent = {{-90,110},{110,-90}}, lineColor = {95,95,95}, fillColor = {255,255,255}, fillPattern = FillPattern.Solid),Polygon(points = {{-26,70},{74,10},{-26,-50},{-26,70}}, lineColor = {0,0,255}, pattern = LinePattern.None, fillColor = {95,95,95}, fillPattern = FillPattern.Solid)}));
end asmaFlow;

