model ModifierDisplayUnit
  Modelica.Mechanics.Translational.Components.Spring spring(c = 35, s_rel(displayUnit="cm"), f(displayUnit="kN")) annotation(
    Placement(transformation(origin = {-6, 2}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Mechanics.Translational.Components.Fixed fixed annotation(
    Placement(transformation(origin = {-48, 6}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(fixed.flange, spring.flange_a) annotation(
    Line(points = {{-48, 6}, {-16, 6}, {-16, 2}}, color = {0, 127, 0}));

annotation(
    uses(Modelica(version = "4.1.0")));
end ModifierDisplayUnit;
