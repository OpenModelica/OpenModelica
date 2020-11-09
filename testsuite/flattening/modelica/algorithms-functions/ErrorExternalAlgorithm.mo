// name: ExternalAlgorithm
// status: incorrect
// cflags: -d=-newInst

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
end ExternalAlgorithm;

// Result:
// Error processing file: ErrorExternalAlgorithm.mo
// [flattening/modelica/algorithms-functions/ErrorExternalAlgorithm.mo:9:3-12:8:writable] Error: Element is not allowed in function context: algorithm
// [flattening/modelica/algorithms-functions/ErrorExternalAlgorithm.mo:14:4-14:7:writable] Error: Class b not found in scope ExternalAlgorithm (looking for a function or record).
// Error: Error occurred while flattening model ExternalAlgorithm
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
