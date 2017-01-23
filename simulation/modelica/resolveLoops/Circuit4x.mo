model Circuit4x
  Modelica.Electrical.Analog.Sources.ConstantVoltage Voltage_Source(V = 2) annotation(Placement(visible = true, transformation(origin = {-56, 6}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Capacitor Cgd(C = 1) annotation(Placement(visible = true, transformation(origin = {-4, 68}, extent = {{10, -10}, {-10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor R_Load(R = 1) annotation(Placement(visible = true, transformation(origin = {34, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor R_Source(R = 1) annotation(Placement(visible = true, transformation(origin = {-56, 42}, extent = {{10, -10}, {-10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Ground Ground annotation(Placement(visible = true, transformation(origin = {-56, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor Cds(C = 1) annotation(Placement(visible = true, transformation(origin = {34, 52}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Capacitor Cgs(C = 1) annotation(Placement(visible = true, transformation(origin = {-4, 36}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor R_Gate(R = 1) annotation(Placement(visible = true, transformation(origin = {-30, 26}, extent = {{10, -10}, {-10, 10}}, rotation = 90)));
equation
  connect(R_Load.n, Ground.p) annotation(Line(points = {{34, -10}, {-56, -10}, {-56, -20}, {-56, -20}}, color = {0, 0, 255}));
  connect(R_Load.p, R_Gate.n) annotation(Line(points = {{34, 10}, {34, 16}, {-30, 16}}, color = {0, 0, 255}));
  connect(Cgs.p, R_Gate.p) annotation(Line(points = {{-4, 46}, {-30, 46}, {-30, 36}}, color = {0, 0, 255}));
  connect(Cgd.p, Cgs.p) annotation(Line(points = {{-4, 58}, {-4, 46}}, color = {0, 0, 255}));
  connect(Cgs.n, Cds.n) annotation(Line(points = {{-4, 26}, {-4, 16}, {34, 16}, {34, 42}}, color = {0, 0, 255}));
  connect(Cgd.n, Cds.p) annotation(Line(points = {{-4, 78}, {-4, 88}, {34, 88}, {34, 75}, {34, 75}, {34, 62}}, color = {0, 0, 255}));
  connect(R_Source.p, Cds.p) annotation(Line(points = {{-56, 52}, {-56, 88}, {34, 88}, {34, 62}}, color = {0, 0, 255}));
  connect(R_Load.p, Cds.n) annotation(Line(points = {{34, 10}, {34, 42}}, color = {0, 0, 255}));
  connect(Voltage_Source.p, R_Source.n) annotation(Line(points = {{-56, 16}, {-56, 32}}, color = {0, 0, 255}));
  connect(Ground.p, Voltage_Source.n) annotation(Line(points = {{-56, -20}, {-56, -20}, {-56, -4}, {-56, -4}}, color = {0, 0, 255}));
  annotation(Icon, Diagram, experiment(StartTime = 0, StopTime = 10, Tolerance = 1e-06, Interval = 0.001), uses(Modelica(version = "3.2.1")));
end Circuit4x;