// name: Break2
// keywords:
// status: incorrect
// cflags: -d=newInst
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
// [flattening/modelica/scodeinst/Break2.mo:12:3-12:8:writable] Error: 'break' may only be used in a while- or for-loop.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
