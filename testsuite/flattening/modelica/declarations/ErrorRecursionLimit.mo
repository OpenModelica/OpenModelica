// name: ErrorRecursionLimit
// status: incorrect

model ErrorRecursionLimit
  model M
    model N
      extends M;
    end N;
    N n;
  end M;

  M m;
end ErrorRecursionLimit;

// Result:
// Error processing file: ErrorRecursionLimit.mo
// [flattening/modelica/declarations/ErrorRecursionLimit.mo:7:7-7:16:writable] Error: extends M causes an instantiation loop.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
