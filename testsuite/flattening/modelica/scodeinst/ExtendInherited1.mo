// name: ExtendInherited1
// keywords:
// status: incorrect
//

model A
  Real x;

  model A
    Real x;
  end A;
end A;

model ExtendInherited1
  extends A;
end ExtendInherited1;

// Result:
// Error processing file: ExtendInherited1.mo
// [flattening/modelica/scodeinst/ExtendInherited1.mo:15:3-15:12:writable] Notification: From here:
// [flattening/modelica/scodeinst/ExtendInherited1.mo:9:3-11:8:writable] Error: Found other base class for extends A after instantiating extends.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
