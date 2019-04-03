// name: RecursiveInst3
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  A a;
end A;

model RecursiveInst3
  A a;
end RecursiveInst3;

// Result:
// Error processing file: RecursiveInst3.mo
// [flattening/modelica/scodeinst/RecursiveInst3.mo:9:3-9:6:writable] Error: Declaration of element a causes recursive definition of class A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
