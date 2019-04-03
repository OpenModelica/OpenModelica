model CoupledClutches "Drive train with 3 dynamically coupled clutches"
  extends Modelica.Icons.Example;
  parameter Modelica.SIunits.Frequency freqHz = 0.2 "Frequency of sine function to invoke clutch1";
  parameter Modelica.SIunits.Time T2 = 0.4 "Time when clutch2 is invoked";
  parameter Modelica.SIunits.Time T3 = 0.9 "Time when clutch3 is invoked";
  Modelica.Mechanics.Rotational.Components.Inertia J1(J = 1, phi(fixed = true, start = 0), w(start = 10, fixed = true)) annotation(Placement(transformation(extent = {{-70, -10}, {-50, 10}}, rotation = 0)));
  Modelica.Mechanics.Rotational.Sources.Torque torque(useSupport = true) annotation(Placement(transformation(extent = {{-100, -10}, {-80, 10}}, rotation = 0)));
  Modelica.Mechanics.Rotational.Components.Clutch clutch1(peak = 1.1, fn_max = 20) annotation(Placement(transformation(extent = {{-40, -10}, {-20, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.Sine sin1(amplitude = 10, freqHz = 5) annotation(Placement(transformation(extent = {{-130, -10}, {-110, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.Step step1(startTime = T2) annotation(Placement(transformation(origin = {25, 35}, extent = {{-5, -5}, {15, 15}}, rotation = 270)));
  Modelica.Mechanics.Rotational.Components.Inertia J2(J = 1, phi(fixed = true, start = 0), w(fixed = true, start = 0)) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Mechanics.Rotational.Components.Clutch clutch2(peak = 1.1, fn_max = 20) annotation(Placement(transformation(extent = {{20, -10}, {40, 10}}, rotation = 0)));
  Modelica.Mechanics.Rotational.Components.Inertia J3(J = 1, phi(fixed = true, start = 0), w(fixed = true, start = 0)) annotation(Placement(transformation(extent = {{50, -10}, {70, 10}}, rotation = 0)));
  Modelica.Mechanics.Rotational.Components.Clutch clutch3(peak = 1.1, fn_max = 20) annotation(Placement(transformation(extent = {{80, -10}, {100, 10}}, rotation = 0)));
  Modelica.Mechanics.Rotational.Components.Inertia J4(J = 1, phi(fixed = true, start = 0), w(fixed = true, start = 0)) annotation(Placement(transformation(extent = {{110, -10}, {130, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.Sine sin2(amplitude = 1, freqHz = freqHz, phase = 1.57) annotation(Placement(transformation(origin = {-35, 35}, extent = {{-5, -5}, {15, 15}}, rotation = 270)));
  input Real step2;
  output Real J1_w1, J2_w1, J3_w1, J4_w1;
  Modelica.Mechanics.Rotational.Components.Fixed fixed annotation(Placement(transformation(extent = {{-100, -30}, {-80, -10}}, rotation = 0)));
equation
  J1_w1 = J1.w;
  J2_w1 = J2.w;
  J3_w1 = J3.w;
  J4_w1 = J4.w;
  connect(torque.flange, J1.flange_a) annotation(Line(points = {{-80, 0}, {-70, 0}}, color = {0, 0, 0}));
  connect(J1.flange_b, clutch1.flange_a) annotation(Line(points = {{-50, 0}, {-40, 0}}, color = {0, 0, 0}));
  connect(clutch1.flange_b, J2.flange_a) annotation(Line(points = {{-20, 0}, {-10, 0}}, color = {0, 0, 0}));
  connect(J2.flange_b, clutch2.flange_a) annotation(Line(points = {{10, 0}, {10, 0}, {20, 0}}, color = {0, 0, 0}));
  connect(clutch2.flange_b, J3.flange_a) annotation(Line(points = {{40, 0}, {50, 0}}, color = {0, 0, 0}));
  connect(J3.flange_b, clutch3.flange_a) annotation(Line(points = {{70, 0}, {80, 0}}, color = {0, 0, 0}));
  connect(clutch3.flange_b, J4.flange_a) annotation(Line(points = {{100, 0}, {110, 0}}, color = {0, 0, 0}));
  connect(sin1.y, torque.tau) annotation(Line(points = {{-109, 0}, {-102, 0}}, color = {0, 0, 127}));
  connect(sin2.y, clutch1.f_normalized) annotation(Line(points = {{-30, 19}, {-30, 19}, {-30, 11}}, color = {0, 0, 127}));
  connect(step1.y, clutch2.f_normalized) annotation(Line(points = {{30, 19}, {30, 19}, {30, 10}, {30, 11}}, color = {0, 0, 127}));
  connect(step2, clutch3.f_normalized) annotation(Line(points = {{90, 19}, {90, 19}, {90, 11}}, color = {0, 0, 127}));
  connect(fixed.flange, torque.support) annotation(Line(points = {{-90, -20}, {-90, -11}, {-90, -10}}, color = {0, 0, 0}));
  annotation(Documentation(info = "<html>
<p>This example demonstrates how variable structure
drive trains are handled. The drive train consists
of 4 inertias and 3 clutches, where the clutches
are controlled by input signals. The system has
2^3=8 different configurations and 3^3 = 27
different states (every clutch may be in forward
sliding, backward sliding or locked mode when the
relative angular velocity is zero). By invoking the
clutches at different time instances, the switching
of the configurations can be studied.</p>
<p>Simulate the system for 1.2 seconds with the
following initial values:<br>
J1.w = 10.</p>
<p>Plot the following variables:<br>
angular velocities of inertias (J1.w, J2.w, J3.w,
J4.w), frictional torques of clutches (clutchX.tau),
frictional mode of clutches (clutchX.mode) where
mode = -1/0/+1 means backward sliding,
locked, forward sliding.</p>

</HTML>"), __Dymola_Commands(file = "modelica://Modelica/Resources/Scripts/Dymola/Mechanics/Rotational/CoupledClutches.mos" "Simulate and Plot"), experiment(StopTime = 1.5, Interval = 0.001), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-140, -100}, {140, 100}})), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})));
end CoupledClutches;