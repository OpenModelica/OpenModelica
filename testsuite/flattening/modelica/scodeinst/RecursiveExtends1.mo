// name: RecursiveExtends1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that the compiler catches recursive extends.
//

model RecursiveExtends1
  extends RecursiveExtends1;
end RecursiveExtends1;

// Result:
// Error processing file: RecursiveExtends1.mo
// [flattening/modelica/scodeinst/RecursiveExtends1.mo:10:3-10:28:writable] Error: extends RecursiveExtends1 causes an instantiation loop.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
