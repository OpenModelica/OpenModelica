// name:     NonexistentElementRedeclare2
// keywords: redeclare
// status:   incorrect
//
// Element redeclares must redeclare inherited elements.
//

model NonexistentElementRedeclare2
  redeclare class C end C;
end NonexistentElementRedeclare2;

// Result:
// Error processing file: NonexistentElementRedeclare2.mo
// [flattening/modelica/redeclare/NonexistentElementRedeclare2.mo:9:13-9:26:writable] Error: Illegal redeclare of element C, no inherited element with that name exists.
// Error: Error occurred while flattening model NonexistentElementRedeclare2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
