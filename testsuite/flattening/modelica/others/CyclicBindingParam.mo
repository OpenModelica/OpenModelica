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
// [flattening/modelica/others/CyclicBindingParam.mo:9:3-9:25:writable] Error: Cyclically dependent constants or parameters found in scope CyclicBindingParam: {p, q} (ignore with -d=ignoreCycles).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
