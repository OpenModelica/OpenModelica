// name: TerminateInvalid2
// keywords:
// status: incorrect
//
//

function f
  output Integer n = 2;
algorithm
  terminate("terminating");
end f;

model TerminateInvalid2
  constant Real x = f();
end TerminateInvalid2;

// Result:
// Error processing file: TerminateInvalid2.mo
// [flattening/modelica/scodeinst/TerminateInvalid2.mo:10:3-10:27:writable] Error: terminate is not allowed in a function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
