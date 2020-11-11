// name:     ArrayModTypeError2
// keywords: modification array type
// status:   incorrect
// cflags: -d=-newInst
//

model ArrayModTypeError
  Real y[2, 2];
equation
  der(y) = -y;
end ArrayModTypeError;

model ArrayModTypeError2
  ArrayModTypeError arr(y(start = {{1, 2, 3}, {4, 5, 6}}));
end ArrayModTypeError2;

// Result:
// Error processing file: ArrayModTypeError2.mo
// [flattening/modelica/modification/ArrayModTypeError2.mo:14:27-14:57:writable] Notification: From here:
// [flattening/modelica/modification/ArrayModTypeError2.mo:8:3-8:15:writable] Error: Array dimension mismatch, expression {4, 5, 6} has type Integer[3], expected array dimensions [2].
// Error: Error occurred while flattening model ArrayModTypeError2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
