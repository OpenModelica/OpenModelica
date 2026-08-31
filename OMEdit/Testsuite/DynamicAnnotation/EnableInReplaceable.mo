package EnableInReplaceable
    model ClassWithInstances
  ClassWithReplaceable classWithReplaceable annotation(
      Placement(transformation(origin = {-50, 10}, extent = {{-10, -10}, {10, 10}})));
  MainClass mainClass annotation(
      Placement(transformation(origin = {10, 10}, extent = {{-10, -10}, {10, 10}})));
  MainRecord mainRecord annotation(
      Placement(transformation(origin = {70, 10}, extent = {{-10, -10}, {10, 10}})));
  equation

  end ClassWithInstances;

  model ClassWithReplaceable

  replaceable parameter EnableInReplaceable.MainRecord replParamRecord
  annotation(choices(choice( redeclare EnableInReplaceable.MainRecord replParamRecord "Replaceable record parameter")));

  replaceable EnableInReplaceable.MainClass replInstance
  annotation(choices(choice( redeclare EnableInReplaceable.MainClass replInstance "Replaceable instance")));

  replaceable model replModel = EnableInReplaceable.MainClass
  annotation(choices(choice( redeclare model replModel=EnableInReplaceable.MainClass "Replaceable model")));

  end ClassWithReplaceable;

  model MainClass
    parameter Boolean booleanParam = true annotation(choices(checkBox = true));
    parameter Real realParam = 5 annotation(Dialog(enable = booleanParam));
  end MainClass;

  record MainRecord
    parameter Boolean booleanParam = true annotation(choices(checkBox = true), HideResult = true, Evaluate = true);
    parameter Real realParam = 5 annotation(Dialog(enable = booleanParam));
  end MainRecord;

end EnableInReplaceable;
