model BooleanNetwork1 "Demonstrates the usage of blocks from Modelica.Blocks.MathBoolean"
  extends Modelica.Icons.Example;
  Modelica.Blocks.Interaction.Show.BooleanValue showValue annotation(Placement(transformation(extent = {{-36, 74}, {-16, 94}})));
  Modelica.Blocks.MathBoolean.And and1(nu = 3) annotation(Placement(transformation(extent = {{-58, 64}, {-46, 76}})));
  Modelica.Blocks.Sources.BooleanPulse booleanPulse1(width = 20, period = 1) annotation(Placement(transformation(extent = {{-100, 60}, {-80, 80}})));
  Modelica.Blocks.Sources.BooleanPulse booleanPulse2(period = 1, width = 80) annotation(Placement(transformation(extent = {{-100, -4}, {-80, 16}})));
  input Boolean booleanStep;
  Modelica.Blocks.MathBoolean.Or or1(nu = 2) annotation(Placement(transformation(extent = {{-28, 62}, {-16, 74}})));
  Modelica.Blocks.MathBoolean.Xor xor1(nu = 2) annotation(Placement(transformation(extent = {{-2, 60}, {10, 72}})));
  Modelica.Blocks.Interaction.Show.BooleanValue showValue2 annotation(Placement(transformation(extent = {{-2, 74}, {18, 94}})));
  Modelica.Blocks.Interaction.Show.BooleanValue showValue3 annotation(Placement(transformation(extent = {{24, 56}, {44, 76}})));
  Modelica.Blocks.MathBoolean.Nand nand1(nu = 2) annotation(Placement(transformation(extent = {{22, 40}, {34, 52}})));
  Modelica.Blocks.MathBoolean.Nor or2(nu = 2) annotation(Placement(transformation(extent = {{46, 38}, {58, 50}})));
  Modelica.Blocks.Interaction.Show.BooleanValue showValue4 annotation(Placement(transformation(extent = {{90, 34}, {110, 54}})));
  Modelica.Blocks.MathBoolean.Not nor1 annotation(Placement(transformation(extent = {{68, 40}, {76, 48}})));
  Modelica.Blocks.MathBoolean.OnDelay onDelay(delayTime = 1) annotation(Placement(transformation(extent = {{-56, -94}, {-48, -86}})));
  Modelica.Blocks.MathBoolean.RisingEdge rising annotation(Placement(transformation(extent = {{-56, -15}, {-48, -7}})));
  Modelica.Blocks.MathBoolean.MultiSwitch set1(nu = 2, expr = {false, true}) annotation(Placement(transformation(extent = {{-30, -23}, {10, -3}})));
  Modelica.Blocks.MathBoolean.FallingEdge falling annotation(Placement(transformation(extent = {{-56, -32}, {-48, -24}})));
  Modelica.Blocks.Sources.BooleanTable booleanTable(table = {2, 4, 6, 6.5, 7, 9, 11}) annotation(Placement(transformation(extent = {{-100, -100}, {-80, -80}})));
  Modelica.Blocks.MathBoolean.ChangingEdge changing annotation(Placement(transformation(extent = {{-56, -59}, {-48, -51}})));
  Modelica.Blocks.MathInteger.TriggeredAdd triggeredAdd annotation(Placement(transformation(extent = {{14, -56}, {26, -44}})));
  Modelica.Blocks.Sources.IntegerConstant integerConstant(k = 2) annotation(Placement(transformation(extent = {{-20, -60}, {0, -40}})));
  Modelica.Blocks.Interaction.Show.IntegerValue showValue1 annotation(Placement(transformation(extent = {{40, -60}, {60, -40}})));
  Modelica.Blocks.Interaction.Show.BooleanValue showValue5 annotation(Placement(transformation(extent = {{24, -23}, {44, -3}})));
  Modelica.Blocks.Interaction.Show.BooleanValue showValue6 annotation(Placement(transformation(extent = {{-32, -100}, {-12, -80}})));
  Modelica.Blocks.Logical.RSFlipFlop rSFlipFlop annotation(Placement(transformation(extent = {{70, -90}, {90, -70}})));
  Modelica.Blocks.Sources.SampleTrigger sampleTriggerSet(period = 0.5, startTime = 0) annotation(Placement(transformation(extent = {{40, -76}, {54, -62}})));
  Modelica.Blocks.Sources.SampleTrigger sampleTriggerReset(period = 0.5, startTime = 0.3) annotation(Placement(transformation(extent = {{40, -98}, {54, -84}})));
  output Boolean y, y2, y3, y4, Q, QI;
  output Integer y1;
equation
  y = and1.y;
  y1 = triggeredAdd.y;
  y2 = booleanPulse2.y;
  y3 = set1.y;
  y4 = onDelay.y;
  Q = rSFlipFlop.Q;
  QI = rSFlipFlop.QI;
  connect(booleanPulse1.y, and1.u[1]) annotation(Line(points = {{-79, 70}, {-68, 70}, {-68, 72.8}, {-58, 72.8}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanStep, and1.u[2]) annotation(Line(points = {{-79, 38}, {-64, 38}, {-64, 70}, {-58, 70}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanPulse2.y, and1.u[3]) annotation(Line(points = {{-79, 6}, {-62, 6}, {-62, 67.2}, {-58, 67.2}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(and1.y, or1.u[1]) annotation(Line(points = {{-45.1, 70}, {-36.4, 70}, {-36.4, 70.1}, {-28, 70.1}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanPulse2.y, or1.u[2]) annotation(Line(points = {{-79, 6}, {-40, 6}, {-40, 65.9}, {-28, 65.9}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(or1.y, xor1.u[1]) annotation(Line(points = {{-15.1, 68}, {-8, 68}, {-8, 68.1}, {-2, 68.1}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanPulse2.y, xor1.u[2]) annotation(Line(points = {{-79, 6}, {-12, 6}, {-12, 63.9}, {-2, 63.9}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(and1.y, showValue.activePort) annotation(Line(points = {{-45.1, 70}, {-42, 70}, {-42, 84}, {-37.5, 84}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(or1.y, showValue2.activePort) annotation(Line(points = {{-15.1, 68}, {-12, 68}, {-12, 84}, {-3.5, 84}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(xor1.y, showValue3.activePort) annotation(Line(points = {{10.9, 66}, {22.5, 66}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(xor1.y, nand1.u[1]) annotation(Line(points = {{10.9, 66}, {16, 66}, {16, 48.1}, {22, 48.1}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanPulse2.y, nand1.u[2]) annotation(Line(points = {{-79, 6}, {16, 6}, {16, 44}, {22, 44}, {22, 43.9}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(nand1.y, or2.u[1]) annotation(Line(points = {{34.9, 46}, {46, 46}, {46, 46.1}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanPulse2.y, or2.u[2]) annotation(Line(points = {{-79, 6}, {42, 6}, {42, 41.9}, {46, 41.9}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(or2.y, nor1.u) annotation(Line(points = {{58.9, 44}, {66.4, 44}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(nor1.y, showValue4.activePort) annotation(Line(points = {{76.8, 44}, {88.5, 44}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanPulse2.y, rising.u) annotation(Line(points = {{-79, 6}, {-62, 6}, {-62, -11}, {-57.6, -11}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(rising.y, set1.u[1]) annotation(Line(points = {{-47.2, -11}, {-38.6, -11}, {-38.6, -11.5}, {-30, -11.5}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(falling.y, set1.u[2]) annotation(Line(points = {{-47.2, -28}, {-40, -28}, {-40, -14.5}, {-30, -14.5}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanPulse2.y, falling.u) annotation(Line(points = {{-79, 6}, {-62, 6}, {-62, -28}, {-57.6, -28}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanTable.y, onDelay.u) annotation(Line(points = {{-79, -90}, {-57.6, -90}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(booleanPulse2.y, changing.u) annotation(Line(points = {{-79, 6}, {-62, 6}, {-62, -55}, {-57.6, -55}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(integerConstant.y, triggeredAdd.u) annotation(Line(points = {{1, -50}, {11.6, -50}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(changing.y, triggeredAdd.trigger) annotation(Line(points = {{-47.2, -55}, {-30, -55}, {-30, -74}, {16.4, -74}, {16.4, -57.2}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(triggeredAdd.y, showValue1.numberPort) annotation(Line(points = {{27.2, -50}, {38.5, -50}}, color = {255, 127, 0}, smooth = Smooth.None));
  connect(set1.y, showValue5.activePort) annotation(Line(points = {{11, -13}, {22.5, -13}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(onDelay.y, showValue6.activePort) annotation(Line(points = {{-47.2, -90}, {-33.5, -90}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(sampleTriggerSet.y, rSFlipFlop.S) annotation(Line(points = {{54.7, -69}, {60, -69}, {60, -74}, {68, -74}}, color = {255, 0, 255}, smooth = Smooth.None));
  connect(sampleTriggerReset.y, rSFlipFlop.R) annotation(Line(points = {{54.7, -91}, {60, -91}, {60, -86}, {68, -86}}, color = {255, 0, 255}, smooth = Smooth.None));
  annotation(experiment(StopTime = 10), Documentation(info = "<html>
<p>
This example demonstrates a network of Boolean blocks
from package <a href=\"modelica://Modelica.Blocks.MathBoolean\">Modelica.Blocks.MathBoolean</a>.
Note, that
</p>

<ul>
<li> at the right side of the model, several MathBoolean.ShowValue blocks
     are present, that visualize the actual value of the respective Boolean
     signal in a diagram animation (\"green\" means \"true\").</li>

<li> the Boolean values of the input and output signals are visualized
     in the diagram animation, by the small \"circles\" close to the connectors.
     If a \"circle\" is \"white\", the signal is <b>false</b>. If a
     \"circle\" is \"green\", the signal is <b>true</b>.</li>

</ul>

</html>"));
end BooleanNetwork1;