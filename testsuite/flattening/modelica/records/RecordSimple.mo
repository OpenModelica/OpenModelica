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
// class RecordSimple
// end RecordSimple;
// endResult
