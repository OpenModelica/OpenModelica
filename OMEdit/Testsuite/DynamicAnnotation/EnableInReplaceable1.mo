package EnableInReplaceable1
  type SomeType = enumeration(
      Type1
     "Type1",
      Type2
     "Type2");
  record BaseRecord
    parameter EnableInReplaceable1.SomeType typeParam = EnableInReplaceable1.SomeType.Type1;
    parameter Real realParam1 = 1 annotation(Dialog(enable=typeParam == EnableInReplaceable1.SomeType.Type1));
    parameter Real realParam2 = 1 annotation(Dialog(enable=typeParam == EnableInReplaceable1.SomeType.Type2));
  end BaseRecord;

  record SomeRecord
    extends EnableInReplaceable1.BaseRecord(realParam1=2, realParam2=2);
  end SomeRecord;

  model ClassWithReplaceables

  parameter EnableInReplaceable1.SomeType typeParam = EnableInReplaceable1.SomeType.Type1;

    replaceable parameter EnableInReplaceable1.BaseRecord replRecord1 constrainedby EnableInReplaceable1.BaseRecord(typeParam=typeParam, realParam2=3)
      annotation(choices(choice(redeclare EnableInReplaceable1.SomeRecord replRecord1)));

  end ClassWithReplaceables;

  model ClassWithInstance
    ClassWithReplaceables classWithRecords(typeParam=EnableInReplaceable1.SomeType.Type2)         annotation (Placement(transformation(origin={-10,10}, extent={{-10,-10},{10,10}})));
    SomeRecord someRecord annotation (Placement(transformation(extent={{20,0},{40,20}})));
  end ClassWithInstance;
end EnableInReplaceable1;
