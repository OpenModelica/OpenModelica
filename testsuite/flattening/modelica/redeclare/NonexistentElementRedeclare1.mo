// name:     NonexistentElementRedeclare1
// keywords: redeclare
// status:   incorrect
//
// Element redeclares must redeclare inherited elements.
//

model NonexistentElementRedeclare1
  redeclare Real x;
end NonexistentElementRedeclare1;

// Result:
// Error processing file: NonexistentElementRedeclare1.mo
// [flattening/modelica/redeclare/NonexistentElementRedeclare1.mo:9:3-9:19:writable] Error: Illegal redeclare of element x, no inherited element with that name exists.
// Error: Error occurred while flattening model NonexistentElementRedeclare1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
