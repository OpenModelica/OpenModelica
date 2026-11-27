within ;
package CreateModelFromSelectionTest
  model M
    Modelica.Blocks.Sources.Step step annotation(
      Placement(transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Math.Gain gain(k = 2) annotation(
      Placement(transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Continuous.Integrator integrator annotation(
      Placement(transformation(origin = {40, 0}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Math.Add add annotation(
      Placement(transformation(origin = {80, 0}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(step.y, gain.u) annotation(
      Line(points = {{-49, 0}, {-12, 0}}, color = {0, 0, 127}));
    connect(gain.y, integrator.u) annotation(
      Line(points = {{11, 0}, {28, 0}}, color = {0, 0, 127}));
    connect(integrator.y, add.u1) annotation(
      Line(points = {{51, 0}, {60, 0}, {60, 6}, {68, 6}}, color = {0, 0, 127}));
    connect(integrator.y, add.u2) annotation(
      Line(points = {{51, 0}, {60, 0}, {60, -6}, {68, -6}}, color = {0, 0, 127}));
  end M;
  annotation(
    uses(Modelica(version = "4.1.0")));
end CreateModelFromSelectionTest;
