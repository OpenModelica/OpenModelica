// name: ProtectedMod4
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  protected Real x = 1.0;
end A;

model B = A;

model ProtectedMod4
  B b(x = 1.0);
end ProtectedMod4;

// Result:
// Error processing file: ProtectedMod4.mo
// [flattening/modelica/scodeinst/ProtectedMod4.mo:9:13-9:25:writable] Error: Protected element ‘x‘ may not be modified, got ‘x = 1.0‘.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
