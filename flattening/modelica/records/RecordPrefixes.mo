// name: RecordPrefixes.mo
// keywords: record
// status: incorrect
//
// Tests that prefixed components can't be used in records.
//

record TestRecord
  input Integer i;
end TestRecord;

model RecordPrefixes
  TestRecord tr;
equation
  tr.i = 1;
end RecordPrefixes;

// Result:
// function TestRecord "Automatically generated record constructor for TestRecord"
//   input Integer i;
//   output TestRecord res;
// end TestRecord;
//
// class RecordPrefixes
//   input Integer tr.i;
// equation
//   tr.i = 1;
// end RecordPrefixes;
// endResult
