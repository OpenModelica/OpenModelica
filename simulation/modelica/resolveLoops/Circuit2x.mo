model Circuit2x
  Modelica.Electrical.Analog.Basic.Ground Ground annotation(Placement(visible = true, transformation(origin = {-58, -34.4017}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor Cds(C = 1) annotation(Placement(visible = true, transformation(origin = {15.1747,44.8253}, extent = {{10,-10},{-10,10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Capacitor Cgd(C = 1) annotation(Placement(visible = true, transformation(origin = {-18.5502, 44.4759}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor R_Load(R = 1) annotation(Placement(visible = true, transformation(origin = {4.99587, -0.84732}, extent = {{-10, 10}, {10, -10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor R_Source(R = 1) annotation(Placement(visible = true, transformation(origin = {-58, 42.5502}, extent = {{-10, 10}, {10, -10}}, rotation = -90)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage Voltage_Source(V = 2) annotation(Placement(visible = true, transformation(origin = {-57.1747, 5.92572}, extent = {{-10, 10}, {10, -10}}, rotation = -90)));
equation
  connect(R_Source.p, Cds.p) annotation(Line(points = {{-58, 52}, {-58, 52}, {-58, 64}, {16, 64}, {16, 54}, {16, 54}}, color = {0, 0, 255}));
  connect(Cds.p, Cgd.n) annotation(Line(points = {{16, 54}, {16, 54}, {16, 64}, {-18, 64}, {-18, 56}, {-18, 56}, {-18, 54}}, color = {0, 0, 255}));
  connect(Cgd.p, R_Load.p) annotation(Line(points = {{-18, 34}, {-18, 10}, {5, 10}, {5, 9}}, color = {0, 0, 255}));
  connect(Cds.n, R_Load.p) annotation(Line(points = {{16, 34}, {16, 10}, {5, 10}, {5, 9}}, color = {0, 0, 255}));
  connect(Ground.p, R_Load.n) annotation(Line(points = {{-58, -24}, {6, -24}, {6, -11}, {5, -11}}, color = {0, 0, 255}));
  connect(Voltage_Source.n, Ground.p) annotation(Line(points = {{-58, -4}, {-58, -4}, {-58, -24}, {-58, -24}}, color = {0, 0, 255}));
  connect(R_Source.n, Voltage_Source.p) annotation(Line(points = {{-58, 32}, {-56, 32}, {-56, 16}, {-58, 16}}, color = {0, 0, 255}));
  annotation(Icon, Diagram, experiment(StartTime = 0, StopTime = 10, Tolerance = 1e-06, Interval = 0.001));
end Circuit2x;