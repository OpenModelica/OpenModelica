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
end ExternalAlgorithm;

// Result:
// Error processing file: ErrorExternalAlgorithm.mo
// [flattening/modelica/algorithms-functions/ErrorExternalAlgorithm.mo:8:3-11:8:writable] Error: Function b has more than one algorithm section or external declaration.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
