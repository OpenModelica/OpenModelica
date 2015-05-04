// name: RecordAssignment
// keywords: record
// status: correct
//
// Tests assignment of records
//

record TestRecord
  Integer i;
end TestRecord;

model RecordAssignment
  TestRecord tr1,tr2;
equation
  tr1.i = 1;
  tr2 = tr1;
end RecordAssignment;

// Result:
// function TestRecord "Automatically generated record constructor for TestRecord"
//   input Integer i;
//   output TestRecord res;
// end TestRecord;
//
// class RecordAssignment
//   Integer tr1.i;
//   Integer tr2.i;
// equation
//   tr1.i = 1;
//   tr2.i = tr1.i;
// end RecordAssignment;
// endResult
