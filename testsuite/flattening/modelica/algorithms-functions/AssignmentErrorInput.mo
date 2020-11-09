// name: AssignmentErrorInput
// status: incorrect
// cflags: -d=-newInst

function Func
  input Real x;
algorithm
  x := 3.0;
end Func;

model AssignmentErrorInput
equation
  Func(2);
end AssignmentErrorInput;

// Result:
// Error processing file: AssignmentErrorInput.mo
// [flattening/modelica/algorithms-functions/AssignmentErrorInput.mo:8:3-8:11:writable] Error: Trying to assign to input component x.
// Error: Error occurred while flattening model AssignmentErrorInput
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
