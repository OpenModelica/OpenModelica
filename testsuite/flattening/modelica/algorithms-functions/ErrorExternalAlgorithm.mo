// name: ExternalAlgorithm
// status: incorrect

model ExternalAlgorithm
  function a
  algorithm
  end a;
  function b
    extends a;
  external sin();
  end b;
algorithm
   b();
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ExternalAlgorithm;

// Result:
// Error processing file: ErrorExternalAlgorithm.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/algorithms-functions/ErrorExternalAlgorithm.mo:8:3-11:8:writable] Error: Element is not allowed in function context: algorithm
// [flattening/modelica/algorithms-functions/ErrorExternalAlgorithm.mo:13:4-13:7:writable] Error: Class b not found in scope ExternalAlgorithm (looking for a function or record).
// Error: Error occurred while flattening model ExternalAlgorithm
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
