// name:     BuiltinTimeInvalid2
// keywords: time builtin
// status:   incorrect
//
// Checks that time is not a valid component name.
//

model BuiltinTimeInvalid2
  Real time = 1.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end BuiltinTimeInvalid2;

// Result:
// Error processing file: BuiltinTimeInvalid2.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/declarations/BuiltinTimeInvalid2.mo:9:3-9:18:writable] Error: Identifier time is reserved for the built-in element with the same name.
// Error: Error occurred while flattening model BuiltinTimeInvalid2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
