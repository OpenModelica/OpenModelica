// name: Extends4.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that inherited components are not instantiated in the scope they're
// inherited into.
//

model A
  C c;
end A;

model Extends4
  model C
    Real x;
  end C;

  extends A;
end Extends4;

// Result:
// Error processing file: Extends4.mo
// [flattening/modelica/scodeinst/Extends4.mo:11:3-11:6:writable] Error: Class C not found in scope A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
