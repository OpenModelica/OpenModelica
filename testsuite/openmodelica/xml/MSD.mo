model MSD
  Modelica.Mechanics.Translational.Components.Fixed fixed1 annotation(Placement(visible = true, transformation(origin = {61.5652,-3.13043}, extent = {{-10,-10},{10,10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Components.Spring spring1(c = 1) annotation(Placement(visible = true, transformation(origin = {1.73913,-2.78261}, extent = {{-10,-10},{10,10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Components.Mass mass1(m = 10) annotation(Placement(visible = true, transformation(origin = {-28.519,-1.91259}, extent = {{-10,-10},{10,10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Components.Damper damper1(d = 0.01) annotation(Placement(visible = true, transformation(origin = {34.2604,-2.60824}, extent = {{-10,-10},{10,10}}, rotation = 0)));
  Modelica.Mechanics.Translational.Sources.Force force1 annotation(Placement(visible = true, transformation(origin = {-60.3483,-2.43478}, extent = {{-10,-10},{10,10}}, rotation = 0)));
equation
  force1.f = sin(time);
  connect(force1.flange,mass1.flange_a) annotation(Line(points = {{-50.3483,-2.43478},{-41.0435,-2.43478},{-38.519,-2.43478},{-38.519,-1.91259}}));
  connect(damper1.flange_b,fixed1.flange) annotation(Line(points = {{44.2604,-2.60824},{61.2174,-2.60824},{61.2174,-3.13043},{61.5652,-3.13043}}));
  connect(spring1.flange_b,damper1.flange_a) annotation(Line(points = {{11.7391,-2.78261},{25.3913,-2.78261},{24.2604,-3.13043},{24.2604,-2.60824}}));
  connect(mass1.flange_b,spring1.flange_a) annotation(Line(points = {{-18.519,-1.91259},{-9.04348,-1.91259},{-9.04348,-3.82609},{-7.56522,-2.78261},{-8.26087,-2.78261}}));
  annotation(Icon(coordinateSystem(extent = {{-100,-100},{100,100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})), Diagram(coordinateSystem(extent = {{-100,-100},{100,100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})));
end MSD;

