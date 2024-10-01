// name: NoEvent1
// keywords: noEvent
// status: incorrect
//
// Tests the builtin noEvent operator.
//

model NoEvent1
  Real x = time;
  Boolean b = noEvent(x > 1);
end NoEvent1;

// Result:
// Error processing file: NoEvent1.mo
// [flattening/modelica/scodeinst/NoEvent1.mo:10:3-10:29:writable] Error: Component b of variability discrete has binding 'noEvent(x > 1)' of higher variability continuous.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
