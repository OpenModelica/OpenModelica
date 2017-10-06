// name: CyclicBindingParam
// keywords: cyclic
// status: incorrect
//
// Tests cyclic binding of parameters
//

model CyclicBindingParam
  parameter Real p = 2*q;
  parameter Real q = 2*p;
end CyclicBindingParam;

// Result:
// Error processing file: CyclicBindingParam.mo
// Error: Cyclically dependent constants or parameters found in scope CyclicBindingParam: {q,p} (ignore with -d=ignoreCycles).
// Error: Error occurred while flattening model CyclicBindingParam
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
