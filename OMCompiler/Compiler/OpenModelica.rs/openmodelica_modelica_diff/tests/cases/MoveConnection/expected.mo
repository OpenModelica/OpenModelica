model test_linebreaks2_orig
  Modelica.Fluid.Sources.FixedBoundary boundary(use_p=false,
                                                use_T=false,
                                                p=1e5) annotation(Placement(visible = true, transformation(origin = {0, 62}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Fluid.Sources.Boundary_pT boundary1 annotation(Placement(visible = true, transformation(origin = {-24, -32}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(boundary.ports[1], boundary1.ports[1]) annotation(Line(points = {{10, 62}, {10, 7}, {-14, 7}, {-14, -32}}, color = {0, 127, 255}));
  annotation(uses(Modelica(version = "4.1.0")), Icon(graphics = {Polygon(origin = {-13.1502, 17.2813}, points = {{-20.8498, 26.7187}, {75.1502, 6.71867}, {15.1502, 54.7187}, {-74.8498, 22.7187}, {-42.8498, -55.2813}, {-20.8498, 26.7187}})}));
end test_linebreaks2_orig;