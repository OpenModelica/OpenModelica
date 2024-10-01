// name: Break2
// keywords:
// status: incorrect
//

function f
  input Integer n;
  output Integer res;
algorithm
  res := n * n;
  break;
end f;

model Break2
  Real x1 = f(4);
end Break2;

// Result:
// Error processing file: Break2.mo
// [flattening/modelica/scodeinst/Break2.mo:11:3-11:8:writable] Error: 'break' may only be used in a while- or for-loop.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
