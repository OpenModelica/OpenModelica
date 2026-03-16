package CopyExtendModifier
  model ClassWithExtend
  extends CopyExtendModifier.ClassWithComponent(baseModel(a = 1, b = 2));
  end ClassWithExtend;

  model ClassWithComponent
  BaseModel baseModel(a = 10)  annotation(
      Placement(transformation(origin = {2, 0}, extent = {{-10, -10}, {10, 10}})));
  end ClassWithComponent;

  model BaseModel
  parameter Real a = 5;
  parameter Real b = 6;
  end BaseModel;

end CopyExtendModifier;
