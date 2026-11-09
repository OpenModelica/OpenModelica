// name:     ArrayModTypeError2
// keywords: modification array type
// status:   incorrect
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
// [flattening/modelica/modification/ArrayModTypeError2.mo:13:27-13:57:writable] Notification: From here:
// [flattening/modelica/modification/ArrayModTypeError2.mo:7:3-7:15:writable] Error: Type mismatch in binding 'start = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}}', expected array dimensions [2, 2], got [2, 3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
