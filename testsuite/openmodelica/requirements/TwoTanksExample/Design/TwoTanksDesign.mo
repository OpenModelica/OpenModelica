within TwoTanksExample.Design;

model TwoTanksDesign
  extends VVDRlib.Verification.Design;
  public TwoTanksExample.Design.Components.Tank tank1 annotation(
    Placement(visible = true, transformation(origin = {-25, 21}, extent = {{-29, -29}, {29, 29}}, rotation = 0)));
  public TwoTanksExample.Design.Components.Tank tank2 annotation(
    Placement(visible = true, transformation(origin = {47, 21}, extent = {{-29, -29}, {29, 29}}, rotation = 0)));
  TwoTanksExample.Design.Components.PIContinuousController pIContinuousController1 annotation(
    Placement(visible = true, transformation(origin = {-24, -50}, extent = {{22, -22}, {-22, 22}}, rotation = 0)));
  TwoTanksExample.Design.Components.PIContinuousController pIContinuousController2 annotation(
    Placement(visible = true, transformation(origin = {49, -51}, extent = {{25, -25}, {-25, 25}}, rotation = 0)));
  public TwoTanksExample.Design.Components.Source source annotation(
    Placement(visible = true, transformation(origin = {-88, 18}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(pIContinuousController1.cOut, tank1.tActuator) annotation(
    Line(points = {{-42, -48}, {-56, -48}, {-56, 12}, {-44, 12}, {-44, 10}}, color = {0, 0, 127}));
  connect(tank1.tSensor, pIContinuousController1.cIn) annotation(
    Line(points = {{-4, 10}, {2, 10}, {2, -48}, {-6, -48}, {-6, -50}}));
  connect(pIContinuousController2.cOut, tank2.tActuator) annotation(
    Line(points = {{28, -48}, {20, -48}, {20, 10}, {28, 10}, {28, 10}}, color = {0, 0, 127}));
  connect(tank2.tSensor, pIContinuousController2.cIn) annotation(
    Line(points = {{68, 10}, {78, 10}, {78, -50}, {68, -50}, {68, -50}}));
  connect(tank1.qOut, tank2.qIn) annotation(
    Line(points = {{-4, 26}, {30, 26}, {30, 26}, {28, 26}}));
  connect(source.qOut, tank1.qIn) annotation(
    Line(points = {{-80, 20}, {-60, 20}, {-60, 28}, {-44, 28}, {-44, 26}}, color = {0, 0, 127}));



end TwoTanksDesign;