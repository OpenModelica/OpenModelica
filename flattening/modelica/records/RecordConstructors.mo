// name: RecordConstructors
// keywords: record
// status: correct
//
// Tests record constructor functions
//

record TestRecord
  Integer i;
end TestRecord;

model RecordConstructors
  TestRecord tr;
equation
  tr = TestRecord(1);
end RecordConstructors;

// Result:
// function TestRecord "Automatically generated record constructor for TestRecord"
//   input Integer i;
//   output TestRecord res;
// end TestRecord;
//
// class RecordConstructors
//   Integer tr.i;
// equation
//   tr.i = 1;
// end RecordConstructors;
// endResult
