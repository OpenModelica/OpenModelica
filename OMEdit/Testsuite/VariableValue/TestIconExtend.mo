package TestIconExtend
  partial model MyBasicIconClass
    parameter String MyCostumString = "TobeShownInIcon";
    parameter Real nonString = 1;
  equation

    annotation(
      Icon(graphics = {Rectangle(origin = {-2, 0}, lineColor = {28, 108, 200}, extent = {{-98, 100}, {102, -100}}), Text(origin = {-88, 28},textColor = {28, 108, 200}, extent = {{-72, 32}, {270, -20}}, textString = "%MyCostumString"), Text(origin = {8, 18},textColor = {28, 108, 200}, extent = {{-168, -38}, {174, -90}}, textString = "%nonString")}));
  end MyBasicIconClass;

  model MyClass
    extends TestIconExtend.MyBasicIconClass(MyCostumString = "TestStringmanuel", nonString = 10);
  equation

  end MyClass;

  model MyClass2
    parameter String MyStringParameter = "Wont be shown in icon";
    parameter Real relParam = 2;
    extends TestIconExtend.MyBasicIconClass(MyCostumString = MyStringParameter, nonString = relParam);
  equation

  end MyClass2;

  model MyClass3
    MyClass myClass annotation(
      Placement(visible = true, transformation(origin = {-22, 12}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation

    annotation(
      Icon(graphics = {Text(origin = {0, 40},extent = {{-160, 40}, {160, -40}}, textString = "%{myClass.MyCostumString}"), Rectangle(origin = {-2, 0}, lineColor = {28, 108, 200}, extent = {{-98, 100}, {102, -100}}), Text(origin = {0, -40}, extent = {{-160, 40}, {160, -40}}, textString = "%{myClass.nonString}")}),
  Diagram(graphics));
  end MyClass3;

  model View
    MyClass3 myClass3 annotation(
      Placement(transformation(origin = {42, 42}, extent = {{-10, -10}, {10, 10}})));
    MyClass2 myClass2 annotation(
      Placement(transformation(origin = {-34, -18}, extent = {{-10, -10}, {10, 10}})));
    MyClass myClass annotation(
      Placement(transformation(origin = {-94, 28}, extent = {{-10, -10}, {10, 10}})));
  equation

  end View;
end TestIconExtend;
