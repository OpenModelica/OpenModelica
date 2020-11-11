// name: Return2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model Return2
algorithm
  return;
end Return2;

// Result:
// Error processing file: Return2.mo
// [flattening/modelica/scodeinst/Return2.mo:9:3-9:9:writable] Error: 'return' may not be used outside function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
