within TwoTanksExample.Design.Components;

model Tank

parameter Real flowGain= 0.05;
parameter Real minV= 0;
parameter Real maxV= 10;
parameter Real area= 1;
parameter Real height= 2;


  TwoTanksExample.Design.Interfaces.LiquidFlowIn qIn annotation(
    Placement(visible = true, transformation(origin = {-64, 20}, extent = {{-18, -18}, {18, 18}}, rotation = 0), iconTransformation(origin = {-64, 20}, extent = {{-18, -18}, {18, 18}}, rotation = 0)));
  TwoTanksExample.Design.Interfaces.LiquidFlowOut qOut annotation(
    Placement(visible = true, transformation(origin = {72, 18}, extent = {{-16, -16}, {16, 16}}, rotation = 0), iconTransformation(origin = {72, 18}, extent = {{-16, -16}, {16, 16}}, rotation = 0)));
  TwoTanksExample.Design.Interfaces.ReadSignalOut tSensor annotation(
    Placement(visible = true, transformation(origin = {72, -36}, extent = {{-16, -16}, {16, 16}}, rotation = 0), iconTransformation(origin = {72, -36}, extent = {{-16, -16}, {16, 16}}, rotation = 0)));
  TwoTanksExample.Design.Interfaces.ActSignalIn tActuator annotation(
    Placement(visible = true, transformation(origin = {-64, -36}, extent = {{-18, -18}, {18, 18}}, rotation = 0), iconTransformation(origin = {-64, -36}, extent = {{-18, -18}, {18, 18}}, rotation = 0)));

public Real volume= area * height;
public Real levelOfLiquid;

equation
// Mass balance equation
  der(levelOfLiquid) = (qIn - qOut)/area; qOut =
  TwoTanksExample.Design.Components.limitValue(minV, maxV, -flowGain*tActuator);

tSensor = levelOfLiquid;

annotation(
    Icon(graphics = {Rectangle(origin = {5, 36}, extent = {{-51, 16}, {51, -16}}), Rectangle(origin = {5, 4}, fillColor = {82, 235, 205}, fillPattern = FillPattern.VerticalCylinder, extent = {{-51, 16}, {51, -70}})}));
end Tank;