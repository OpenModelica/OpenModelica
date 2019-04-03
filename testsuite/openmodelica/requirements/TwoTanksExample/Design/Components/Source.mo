within TwoTanksExample.Design.Components;

model Source

input Real flowLevel= 0;
  TwoTanksExample.Design.Interfaces.LiquidFlowOut qOut annotation(
    Placement(visible = true, transformation(origin = {74, 12}, extent = {{-24, -24}, {24, 24}}, rotation = 0), iconTransformation(origin = {74, 12}, extent = {{-24, -24}, {24, 24}}, rotation = 0)));
equation

qOut = flowLevel;

annotation(
    Diagram,
    Icon(graphics = {Ellipse(origin = {-14, 10}, fillColor = {82, 235, 205}, fillPattern = FillPattern.Sphere, extent = {{-64, 62}, {64, -62}}, endAngle = 360)}));end Source;