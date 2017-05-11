within TwoTanksExample.Design.Components;

partial model BaseController
  parameter Real K= 2;
  parameter Real T= 10;
  input Real ref= 0.25;
  Real error;
  Real outCtr;
  TwoTanksExample.Design.Interfaces.ReadSignalIn cIn annotation(
    Placement(visible = true, transformation(origin = {-78, 4}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-78, 4}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Interfaces.ActSignalOut cOut annotation(
    Placement(visible = true, transformation(origin = {82, 8}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {82, 8}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
    error = ref - cIn;
    cOut = outCtr;
annotation(
    Diagram,
    Icon(graphics = {Rectangle(origin = {2, 10}, extent = {{-70, 52}, {70, -52}}), Line(origin = {3.51258, 14.8423}, points = {{-59.5126, -32.8423}, {-37.5126, 9.15768}, {14.4874, -36.8423}, {54.4874, 33.1577}, {62.4874, 15.1577}, {62.4874, 17.1577}, {62.4874, 17.1577}, {60.4874, 19.1577}})}));end BaseController;