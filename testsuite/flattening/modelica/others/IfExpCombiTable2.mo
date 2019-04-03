// name: IfExpCombiTable2
// status: incorrect
// This should succeed fail with a good error message (for example, c not found)

class IfExpCombiTable2
  parameter Boolean b = false;
  Real r = if not b then c else q();
end IfExpCombiTable2;

// Result:
// Error processing file: IfExpCombiTable2.mo
// [flattening/modelica/others/IfExpCombiTable2.mo:7:3-7:36:writable] Error: Variable c not found in scope IfExpCombiTable2.
// Error: Error occurred while flattening model IfExpCombiTable2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
