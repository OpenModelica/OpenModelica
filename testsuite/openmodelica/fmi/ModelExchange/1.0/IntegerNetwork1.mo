model IntegerNetwork1 "Demonstrates the usage of blocks from Modelica.Blocks.MathInteger"
  extends Modelica.Icons.Example;
  Modelica.Blocks.MathInteger.Sum sum(nu = 3) annotation(Placement(transformation(extent = {{-14, 64}, {-2, 76}})));
  Modelica.Blocks.Sources.Sine sine(amplitude = 3, freqHz = 0.1) annotation(Placement(transformation(extent = {{-100, 60}, {-80, 80}})));
  Modelica.Blocks.Math.RealToInteger realToInteger annotation(Placement(transformation(extent = {{-60, 60}, {-40, 80}})));
  input Integer integerStep;
  Modelica.Blocks.Sources.IntegerConstant integerConstant(k = 1) annotation(Placement(transformation(extent = {{-60, -10}, {-40, 10}})));
  Modelica.Blocks.Interaction.Show.IntegerValue showValue annotation(Placement(transformation(extent = {{40, 60}, {60, 80}})));
  Modelica.Blocks.MathInteger.Product product(nu = 2) annotation(Placement(transformation(extent = {{16, 24}, {28, 36}})));
  Modelica.Blocks.Interaction.Show.IntegerValue showValue1 annotation(Placement(transformation(extent = {{40, 20}, {60, 40}})));
  Modelica.Blocks.MathInteger.TriggeredAdd triggeredAdd(use_reset = false, use_set = false) annotation(Placement(transformation(extent = {{16, -6}, {28, 6}})));
  Modelica.Blocks.Sources.BooleanPulse booleanPulse1(period = 1) annotation(Placement(transformation(extent = {{-12, -30}, {8, -10}})));
  Modelica.Blocks.Interaction.Show.IntegerValue showValue2 annotation(Placement(transformation(extent = {{40, -10}, {60, 10}})));
  Modelica.Blocks.MathInteger.MultiSwitch multiSwitch1(nu = 2, expr = {4, 6}, y_default = 2, use_pre_as_default = false) annotation(Placement(transformation(extent = {{28, -60}, {68, -40}})));
  Modelica.Blocks.Sources.BooleanPulse booleanPulse2(period = 2, width = 80) annotation(Placement(transformation(extent = {{-12, -70}, {8, -50}})));
  Modelica.Blocks.Interaction.Show.IntegerValue showValue3(use_numberPort = false, number = multiSwitch1.y) annotation(Placement(transformation(extent = {{40, -84}, {60, -64}})));
  output Integer y, y1, y2, y3, y4;
  output Real y5;
equation
  y = multiSwitch1.y;
  y1 = product.y;
  y2 = realToInteger.y;
  y3 = sum.y;
  y4 = triggeredAdd.y;
  y5 = sine.y;
  connect(sine.y, realToInteger.u) annotation(Line(points = {{-79, 70}, {-62, 70}}, color = {0, 0, 127}, smooth = Smooth.None));
  connect(realToInteger.y, sum.u[1]) annotation(Line(points = {{-39, 70}, {-32, 70}, {-32, 72}, {-14, 72}, {-14, 72.8}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(integerStep, sum.u[2]) annotation(Line(points = {{-39, 40}, {-28, 40}, {-28, 70}, {-14, 70}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(integerConstant.y, sum.u[3]) annotation(Line(points = {{-39, 0}, {-22, 0}, {-22, 67.2}, {-14, 67.2}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(sum.y, showValue.numberPort) annotation(Line(points = {{-1.1, 70}, {38.5, 70}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(sum.y, product.u[1]) annotation(Line(points = {{-1.1, 70}, {4, 70}, {4, 32.1}, {16, 32.1}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(integerStep, product.u[2]) annotation(Line(points = {{-39, 40}, {-8, 40}, {-8, 27.9}, {16, 27.9}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(product.y, showValue1.numberPort) annotation(Line(points = {{28.9, 30}, {38.5, 30}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(integerConstant.y, triggeredAdd.u) annotation(Line(points = {{-39, 0}, {13.6, 0}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(booleanPulse1.y, triggeredAdd.trigger) annotation(Line(points = {{9, -20}, {18.4, -20}, {18.4, -7.2}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(triggeredAdd.y, showValue2.numberPort) annotation(Line(points = {{29.2, 0}, {38.5, 0}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(booleanPulse1.y, multiSwitch1.u[1]) annotation(Line(points = {{9, -20}, {18, -20}, {18, -48}, {28, -48}, {28, -48.5}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanPulse2.y, multiSwitch1.u[2]) annotation(Line(points = {{9, -60}, {18, -60}, {18, -52}, {28, -52}, {28, -51.5}}, color = {255, 0, 255}, smooth = Smooth.None));
  annotation(experiment(StopTime = 10), Documentation(info = "<html>
<p>
This example demonstrates a network of Integer blocks.
from package <a href=\"modelica://Modelica.Blocks.MathInteger\">Modelica.Blocks.MathInteger</a>.
Note, that
</p>

<ul>
<li> at the right side of the model, several MathInteger.ShowValue blocks
     are present, that visualize the actual value of the respective Integer
     signal in a diagram animation.</li>

<li> the Boolean values of the input and output signals are visualized
     in the diagram animation, by the small \"circles\" close to the connectors.
     If a \"circle\" is \"white\", the signal is <b>false</b>. If a
     \"circle\" is \"green\", the signal is <b>true</b>.</li>

</ul>

</html>"));
end IntegerNetwork1;