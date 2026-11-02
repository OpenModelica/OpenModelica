within ;

package RecordChoicesAllMatching

  record BaseRecord
    parameter Real value = 0;
  end BaseRecord;

  record RecordA
    extends BaseRecord(value = 1);
  end RecordA;

  record RecordB
    extends BaseRecord(value = 2);
  end RecordB;

  model ClassWithRecordParam
    parameter BaseRecord recordParam annotation(choicesAllMatching=true);
  end ClassWithRecordParam;

  model ClassWithInstance
    RecordChoicesAllMatching.ClassWithRecordParam classWithRecordParam(
      recordParam = RecordChoicesAllMatching.RecordA())
      annotation(Placement(transformation(origin = {-10, 10}, extent = {{-10, -10}, {10, 10}})));
  end ClassWithInstance;

end RecordChoicesAllMatching;
