model Circuit1x
  Modelica.Electrical.Analog.Basic.Ground Ground annotation(Placement(visible = true, transformation(origin = {-56, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Ground Ground annotation(Placement(visible = true, transformation(origin = {-56, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor Cgd(C = 1) annotation(Placement(visible = true, transformation(origin = {-14, 42}, extent = {{-10, 10}, {10, -10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Capacitor Cds(C = 1) annotation(Placement(visible = true, transformation(origin = {16, 42}, extent = {{10, 10}, {-10, -10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor R_Load(R = 1) annotation(Placement(visible = true, transformation(origin = {16, 0}, extent = {{-10, 10}, {10, -10}}, rotation = -90)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage Voltage_Source(V = 2) annotation(Placement(visible = true, transformation(origin = {-56, 4}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor R_Source(R = 1) annotation(Placement(visible = true, transformation(origin = {-56, 42}, extent = {{-10, 10}, {10, -10}}, rotation = -90)));
equation
  connect(R_Load.n, Ground.p) annotation(Line(points = {{16, -10}, {16, -20}, {-56, -20}}, color = {0, 0, 255}));
  connect(Cds.n, R_Load.p) annotation(Line(points = {{16, 32}, {16, 10}}, color = {0, 0, 255}));
  connect(Cgd.n, Cds.p) annotation(Line(points = {{-14, 52}, {-14, 52}, {-14, 60}, {16, 60}, {16, 52}, {16, 52}, {16, 52}}, color = {0, 0, 255}));
  connect(R_Source.p, Cds.p) annotation(Line(points = {{-56, 52}, {-56, 52}, {-56, 60}, {16, 60}, {16, 52}, {16, 52}}, color = {0, 0, 255}));
  connect(Ground.p, Voltage_Source.n) annotation(Line(points = {{-56, -20}, {-56, -20}, {-56, -6}, {-56, -6}}, color = {0, 0, 255}));
  connect(Voltage_Source.p, R_Source.n) annotation(Line(points = {{-56, 14}, {-56, 14}, {-56, 32}, {-56, 32}}, color = {0, 0, 255}));
  connect(Cgd.p, Cds.n) annotation(Line(points = {{-14, 32}, {-14, 32}, {-14, 22}, {16, 22}, {16, 32}, {16, 32}}, color = {0, 0, 255}));
  annotation(Icon, Diagram, experiment(StartTime = 0, StopTime = 10, Tolerance = 1e-06, Interval = 0.001));
end Circuit1x;