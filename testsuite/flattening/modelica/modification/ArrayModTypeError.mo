// name:     ArrayModTypeError
// keywords: modification array type
// status:   incorrect
// cflags: -d=-newInst
//

model ArrayModTypeError
  Real y[2, 2](start = {{1, 2, 3}, {4, 5, 6}});
equation
  der(y) = -y;
end ArrayModTypeError;

// Result:
// Error processing file: ArrayModTypeError.mo
// [flattening/modelica/modification/ArrayModTypeError.mo:8:16-8:46:writable] Notification: From here:
// [flattening/modelica/modification/ArrayModTypeError.mo:8:3-8:47:writable] Error: Array dimension mismatch, expression {4, 5, 6} has type Integer[3], expected array dimensions [2].
// Error: Error occurred while flattening model ArrayModTypeError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
