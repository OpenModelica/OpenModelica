// name: CyclicBindingConditional
// keywords: cyclic
// status: incorrect
//
// Tests cyclic binding of parameters
//

model CyclicBindingConditional
  parameter
  Boolean a = true if b;
  parameter
  Boolean b = true if a;
end CyclicBindingConditional;

// Result:
// Error processing file: CyclicBindingConditional.mo
// Error: Cyclically dependent constants or parameters found in scope CyclicBindingConditional: {b,a} (ignore with -d=ignoreCycles).
// Error: Error occurred while flattening model CyclicBindingConditional
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
