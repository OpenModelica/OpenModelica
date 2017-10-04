// name: ExtendsInherited1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  Real x;

  model A
    Real x;
  end A;
end A;

model ExtendsInherited1
  extends A;
end ExtendsInherited1;

// Result:
// Error processing file: ExtendInherited1.mo
// [flattening/modelica/scodeinst/ExtendInherited1.mo:16:3-16:12:writable] Notification: From here:
// [flattening/modelica/scodeinst/ExtendInherited1.mo:10:3-12:8:writable] Error: Found other base class for extends A after instantiating extends.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
