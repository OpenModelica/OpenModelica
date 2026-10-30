// name: CyclicBindingParam
// keywords: cyclic
// status: incorrect
//
// Tests cyclic binding of parameters
//

model CyclicBindingParam
  parameter Real p = 2*q;
  parameter Real q = 2*p;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end CyclicBindingParam;

// Result:
// Error processing file: CyclicBindingParam.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// Error: Cyclically dependent constants or parameters found in scope CyclicBindingParam: {q,p} (ignore with -d=ignoreCycles).
// Error: Error occurred while flattening model CyclicBindingParam
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
