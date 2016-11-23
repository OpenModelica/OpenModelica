// name: extends3.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// Checks that inherited components are not instantiated in the scope they're
// inherited into.
//

model A
  C c;
end A;

model B
  model C
    Real x;
  end C;

  extends A;
end B;

// Result:
// Error processing file: extends3.mo
// [flattening/modelica/scodeinst/extends3.mo:11:3-11:6:writable] Error: Class C not found in scope <unknown>.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
