package IconsWithValues
  model Component
    parameter Real p;
    output Real y = sqrt(p);
    annotation(Icon(graphics = {Text(origin = {-57, 36}, extent = {{-35, 16}, {149, -30}}, textString = "p = %p", fontName = "DejaVu Sans Mono"),  Rectangle(origin = {0, -1}, extent = {{-94, 93}, {94, -93}}), Text(origin = {-57, -30}, extent = {{-35, 16}, {149, -30}}, textString = "y = %y", fontName = "DejaVu Sans Mono")}, coordinateSystem(initialScale = 0.1)));
  end Component;
  model Test1
    Component component1(p = 4) annotation(Placement(visible = true, transformation(origin = {3, 51}, extent = {{-43, -43}, {43, 43}}, rotation = 0)));
  end Test1;
  model Test2
  extends Test1(component1(p = 44));
  end Test2;
end IconsWithValues;
