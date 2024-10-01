// name: CyclicBindingConst
// keywords: cyclic
// status: incorrect
//
// Tests cyclic binding of constants
//

model CyclicBindingConst
  constant Real p = 2*q;
  constant Real q = 2*p;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end CyclicBindingConst;

// Result:
// Error processing file: CyclicBindingConst.mo
// Error: Cyclically dependent constants or parameters found in scope CyclicBindingConst: {q,p} (ignore with -d=ignoreCycles).
// Error: Error occurred while flattening model CyclicBindingConst
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
