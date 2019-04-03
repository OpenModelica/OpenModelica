// name: Visibility3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  protected Real x;
end A;

model Visibility3
  Real x = a.x;
  A a;
end Visibility3;

// Result:
// Error processing file: Visibility3.mo
// [flattening/modelica/scodeinst/Visibility3.mo:8:13-8:19:writable] Error: Illegal access of protected element x.
// [flattening/modelica/scodeinst/Visibility3.mo:12:3-12:15:writable] Error: Variable a.x not found in scope Visibility3.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
