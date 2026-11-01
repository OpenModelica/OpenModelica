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
// [flattening/modelica/others/CyclicBindingConditional.mo:9:3-10:24:writable] Error: Variable 'a' has a cyclic dependency and has variability parameter.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
