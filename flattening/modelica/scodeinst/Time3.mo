// name: Time3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

function f
  output Real x;
algorithm
  x := time;
end f;

model Time3
  Real x = f();
end Time3;

// Result:
// Error processing file: Time3.mo
// [flattening/modelica/scodeinst/Time3.mo:10:3-10:12:writable] Error: time is not allowed in a function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
