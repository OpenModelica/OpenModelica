// name: Visibility3
// keywords:
// status: incorrect
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
// [flattening/modelica/scodeinst/Visibility3.mo:7:13-7:19:writable] Error: Illegal access of protected element x.
// [flattening/modelica/scodeinst/Visibility3.mo:11:3-11:15:writable] Error: Variable a.x not found in scope Visibility3.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
