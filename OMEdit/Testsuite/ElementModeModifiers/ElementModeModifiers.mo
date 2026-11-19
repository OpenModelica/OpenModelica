package ElementModeModifiers
  model M1
    parameter Real p;
    annotation(Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}})}));
  end M1;

  model M2
    M1 m1 annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}})));
    annotation(Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}})}));
  end M2;

  model S1
    M2 m2(m1(p = 1)) annotation(Placement(transformation(origin = {2, -2}, extent = {{-10, -10}, {10, 10}})));
  end S1;

  model S2
    extends S1;
  end S2;

  model S3
    extends S1(m2(m1(p = 2)));
  end S3;
end ElementModeModifiers;
