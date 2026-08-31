package CopyExtendModifier2
  model ClassWithExtend
  extends CopyExtendModifier2.ClassWithComponent(baseModel(a = 1, b = 2, redeclare CopyExtendModifier2.BaseRecord replRecord));
  end ClassWithExtend;

  model ClassWithComponent
  inner BaseModel baseModel(a = 10)  annotation(
      Placement(transformation(origin = {2, 0}, extent = {{-10, -10}, {10, 10}})));
  end ClassWithComponent;

  model BaseModel
  parameter Real a = 5;
  parameter Real b = 6;

  replaceable CopyExtendModifier2.BaseRecord replRecord;
  end BaseModel;

  record BaseRecord

  parameter Real realParam = 5;
  end BaseRecord;

end CopyExtendModifier2;
