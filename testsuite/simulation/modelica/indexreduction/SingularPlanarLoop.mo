model SingularPlanarLoop
  Modelica.Mechanics.MultiBody.Joints.Revolute revolute1(n = {1,0,0}) annotation(Placement(visible = true, transformation(origin = {-12.0482,26.0241}, extent = {{-12,-12},{12,12}}, rotation = 0)));
  inner Modelica.Mechanics.MultiBody.World world annotation(Placement(visible = true, transformation(origin = {-54.9398,26.506}, extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyShape bodyshape1(r = {0,0,1}, r_CM = {0,0,0.5}, m = 1) annotation(Placement(visible = true, transformation(origin = {30.8434,26.0241}, extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Revolute revolute2(n = {1,0,0}) annotation(Placement(visible = true, transformation(origin = {64.5783,25.5422}, extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Joints.Revolute revolute3(n = {1,0,0}) annotation(Placement(visible = true, transformation(origin = {55.9036,-41.9277}, extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyShape bodyshape2(r = {0,0,1}, r_CM = {0,0,0.5}, m = 1) annotation(Placement(visible = true, transformation(origin = {20.7229,-41.9277}, extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Mechanics.MultiBody.Parts.BodyShape bodyshape3(r = {0,0,1}, r_CM = {0,0,0.5}, m = 1) annotation(Placement(visible = true, transformation(origin = {84.3373,-12.5301}, extent = {{-12,12},{12,-12}}, rotation = -90)));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedtranslation1(r = {0,0,1}) annotation(Placement(visible = true, transformation(origin = {-42.4096,-15.9036}, extent = {{-12,12},{12,-12}}, rotation = -90)));
equation
  connect(fixedtranslation1.frame_b,bodyshape2.frame_a) annotation(Line(points = {{-42.4096,-27.9036},{-41.9277,-27.9036},{-41.9277,-41.9277},{8.7229,-41.9277}}));
  connect(fixedtranslation1.frame_a,world.frame_b) annotation(Line(points = {{-42.4096,-3.90361},{-42.8916,-3.90361},{-42.8916,26.506},{-42.9398,26.506}}));
  connect(revolute3.frame_a,bodyshape2.frame_b) annotation(Line(points = {{43.9036,-41.9277},{32.7711,-41.9277},{32.7711,-41.9277},{32.7229,-41.9277}}));
  connect(revolute3.frame_b,bodyshape3.frame_b) annotation(Line(points = {{67.9036,-41.9277},{83.3735,-41.9277},{83.3735,-23.1325},{84.3373,-23.1325},{84.3373,-24.5301}}));
  connect(bodyshape3.frame_a,revolute2.frame_b) annotation(Line(points = {{84.3373,-0.53012},{84.8193,-0.53012},{84.8193,25.5422},{76.5783,25.5422}}));
  connect(revolute2.frame_a,bodyshape1.frame_b) annotation(Line(points = {{52.5783,25.5422},{42.8916,25.5422},{42.8916,26.0241},{42.8434,26.0241}}));
  connect(bodyshape1.frame_a,revolute1.frame_b) annotation(Line(points = {{18.8434,26.0241},{0,26.0241},{0,26.0241},{-0.0481928,26.0241}}));
  connect(world.frame_b,revolute1.frame_a) annotation(Line(points = {{-42.9398,26.506},{-23.1325,26.506},{-23.1325,26.0241},{-24.0482,26.0241}}));
  annotation(uses(Modelica(version = "3.2.1")), Diagram(graphics));
end SingularPlanarLoop;
