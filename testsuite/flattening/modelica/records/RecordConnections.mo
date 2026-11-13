// name: RecordConnections
// keywords: record
// status: incorrect
//
// Tests if records can be used in connections
// THIS TEST SHOULD FAIL
//

record TestRecord
  Integer i;
end TestRecord;

model RecordConnections
  TestRecord tr1,tr2;
equation
  tr1.i = 3;
  connect(tr1.i,tr2.i);
end RecordConnections;

// Result:
// Error processing file: RecordConnections.mo
// [flattening/modelica/records/RecordConnections.mo:17:3-17:23:writable] Error: tr1.i is not a valid connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
