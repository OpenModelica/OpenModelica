// name: FuncBuiltinPromoteInvalid1
// keywords: sum
// status: incorrect
//
// Tests the builtin promote operator.
//

model FuncBuiltinPromoteInvalid1
  Real y[2, 2];
  Real r[:] = promote(y, 1);
  annotation(__OpenModelica_commandLineOptions="--std=experimental");
end FuncBuiltinPromoteInvalid1;

// Result:
// Error processing file: FuncBuiltinPromoteInvalid1.mo
// [flattening/modelica/scodeinst/FuncBuiltinPromoteInvalid1.mo:10:3-10:28:writable] Error: The second argument '1' of promote may not be smaller than the number of dimensions (2) of the first argument.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
