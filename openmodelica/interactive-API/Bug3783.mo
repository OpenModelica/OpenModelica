model Bug3783
  replaceable package liquid = Modelica.Media.Water.StandardWater;
  Modelica.Fluid.Sources.FixedBoundary boundary(redeclare package Medium = liquid, p=100) annotation(Placement(visible = true, transformation(origin = {-26, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  annotation(uses(Modelica(version = "3.2.1")));
end Bug3783;