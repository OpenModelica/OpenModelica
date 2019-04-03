model PartialFn10

record InnerRecord
  Real r1;
  Real r2;
end InnerRecord;

record TestRecord
  InnerRecord inner1;
  InnerRecord inner2;
end TestRecord;

function CreateTestRecord
  input InnerRecord i1;
  input InnerRecord i2;
  input InRecordConstructor rc;
  output TestRecord tr;

  partial function InRecordConstructor
    input InnerRecord i1;
    input InnerRecord i2;
    output TestRecord tr;
  end InRecordConstructor;
algorithm
  tr := rc(i1, i2);
end CreateTestRecord;

function TestCreateTestRecord
  input Real r1;
  input Real r2;
  output Real o;
protected
  InnerRecord i1;
  InnerRecord i2;
  TestRecord tr;
algorithm
  i1 := InnerRecord(r1,r2);
  i2 := InnerRecord(r2,r1);
  tr := CreateTestRecord(i1, i2, TestRecord);
  o := tr.inner1.r1;
end TestCreateTestRecord;

Real r1;
Real r2;
Real tr;

equation
  r1 = 17.0;
  r2 = -12.0;
  tr = TestCreateTestRecord(r1,r2);
end PartialFn10;
