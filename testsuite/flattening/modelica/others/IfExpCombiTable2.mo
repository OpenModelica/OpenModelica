// name: IfExpCombiTable2
// status: incorrect
// This should succeed fail with a good error message (for example, c not found)

class IfExpCombiTable2
  parameter Boolean b = false;
  Real r = if not b then c else q();
end IfExpCombiTable2;

// Result:
// Error processing file: IfExpCombiTable2.mo
// [flattening/modelica/others/IfExpCombiTable2.mo:6:3-6:30:writable] Warning: Components are deprecated in class.
// [flattening/modelica/others/IfExpCombiTable2.mo:7:3-7:36:writable] Warning: Components are deprecated in class.
// [flattening/modelica/others/IfExpCombiTable2.mo:7:3-7:36:writable] Error: Function q not found in scope IfExpCombiTable2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
