// name: RecordNonPublic
// keywords: record
// status: correct
//
// Tests the declaration and instantiation of a record
// that has non-public components
// THIS TEST SHOULD FAIL
//

record TestRecord
  protected
    Integer i;
end TestRecord;

model RecordNonPublic
  TestRecord tr;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end RecordNonPublic;

// Result:
// function TestRecord "Automatically generated record constructor for TestRecord"
//   protected Integer i;
//   output TestRecord res;
// end TestRecord;
//
// class RecordNonPublic
//   protected Integer tr.i;
// end RecordNonPublic;
// Warning: Protected record member i has no binding and is not modifiable by a record constructor.
//
// endResult
