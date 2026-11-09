within ;

package DefaultParamToParamWithoutDefault

type SomeType = enumeration(
      Type1
     "Type1",
      Type2
     "Type2");

  record BaseRecord
    parameter DefaultParamToParamWithoutDefault.SomeType typeParam annotation(Dialog(enable=false),HideResult = true, Evaluate = true);
    parameter Real realParam1 = 1 annotation(Dialog(enable=typeParam == DefaultParamToParamWithoutDefault.SomeType.Type1), HideResult = false, Evaluate = false);
    parameter Real realParam2 = 1 annotation(Dialog(enable=typeParam == DefaultParamToParamWithoutDefault.SomeType.Type2), HideResult = false, Evaluate = false);
  end BaseRecord;

  record SomeRecord
    extends DefaultParamToParamWithoutDefault.BaseRecord(realParam1=2, realParam2=2);
  end SomeRecord;

  model ClassWithReplaceables

  parameter DefaultParamToParamWithoutDefault.SomeType typeParam = DefaultParamToParamWithoutDefault.SomeType.Type1 annotation(Evaluate = true, HideResult = true);

    replaceable parameter DefaultParamToParamWithoutDefault.SomeRecord replRecord1 constrainedby DefaultParamToParamWithoutDefault.BaseRecord(final typeParam=typeParam)
    annotation(choices(choice(redeclare DefaultParamToParamWithoutDefault.SomeRecord replRecord1)), HideResult = true);

  end ClassWithReplaceables;

  model ClassWithInstance
  ClassWithReplaceables classWithReplaceables annotation(
      Placement(transformation(origin = {-10, 10}, extent = {{-10, -10}, {10, 10}})))
  ;
  end ClassWithInstance;

end DefaultParamToParamWithoutDefault;
