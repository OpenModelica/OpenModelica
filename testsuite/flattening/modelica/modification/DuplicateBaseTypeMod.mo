// name:     DuplicateBaseTypeMod
// keywords: modification
// status:   incorrect
//
// Checks that duplicate modifiers on base types are caught.
//

model DuplicateBaseTypeMod
  Real x(start = 1, start = 0.0, fixed = true, fixed = false, nominal = 1.0, nominal = 0.0);
equation
  der(x) = 0.0;
end DuplicateBaseTypeMod;

// Result:
// Error processing file: DuplicateBaseTypeMod.mo
// [flattening/modelica/modification/DuplicateBaseTypeMod.mo:9:21-9:32:writable] Notification: From here:
// [flattening/modelica/modification/DuplicateBaseTypeMod.mo:9:10-9:19:writable] Error: Duplicate modification of element start on component x.
// Error: Error occurred while flattening model DuplicateBaseTypeMod
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
