// name: RecordSimple
// keywords: record
// status: correct
//
// Tests very simple record declaration and instantiation
//

record TestRecord
end TestRecord;

model RecordSimple
  TestRecord tr;
end RecordSimple;

// Result:
// function TestRecord "Automatically generated record constructor for TestRecord"
//   output TestRecord res;
// end TestRecord;
//
// class RecordSimple
// end RecordSimple;
// endResult
